# Category Persistence Fix for Shopping List Products

## Issue

When users dragged purchased products between categories in `list_detail_screen_mobile`, the category change was not persisted correctly. Upon reopening the list, products would revert to "uncategorized" instead of displaying under the categories they were moved to.

## Root Cause

The bug had **three** root causes:

### 1. Product Associations Not Loaded
When loading purchased products from the database via `ManagePurchasedProduct.getPurchasedProductsByList()`, the method created `Product` objects with **empty associations** (`associations: {}`). This meant:
- Products didn't have their supermarket→category mappings
- The system couldn't determine the correct category for products
- Products would fall back to "uncategorized"

### 2. Category Update Not Explicitly Triggered
While the controller's `moveProductToCategory()` method updated the in-memory category, it didn't explicitly mark the `PurchasedProduct` as modified, which could cause the update to be missed during the save operation.

### 3. **CRITICAL**: Category Class Missing Equality Implementation
The `Category` class did not implement the `==` operator and `hashCode`. This caused a critical bug in the `getProductsByCategory()` method:

**The Problem:**
```dart
// This uses object reference equality, not value equality!
if (grouped.containsKey(category)) {
    grouped[category]!.add(product);
}
```

**What Happened:**
1. Supermarket's categories are loaded from database (e.g., `Category(id="123", name="Dairy")`)
2. Product's category is loaded from database as a **different instance** (also `Category(id="123", name="Dairy")`)
3. Even though they have the same ID and name, they're different objects
4. `grouped.containsKey(category)` returns `false` because Dart uses reference equality by default
5. Product falls into the `else` block and gets placed in "uncategorized"

This is why categories appeared to "work" in memory but failed when reloading from the database - the Category instances were different objects.

## Solution

### Fix 1: Load Product Associations When Loading Purchased Products

Modified three methods in `lib/services/database/sqlite/manage_purchased_product.dart`:
- `getPurchasedProductsByList()`
- `getPurchasedProductById()`
- `getPurchasedProductByName()`

Each method now:
1. Loads the purchased product data
2. Queries the `associations` table for the product's supermarket→category mappings
3. Creates `Product` objects with the correct associations loaded

**Example:**
```dart
// Load associations from database
final associationRows = await db.query(
  'associations',
  where: 'product_id = ?',
  whereArgs: [productId],
);

final associations = <String, String>{};
for (final assocRow in associationRows) {
  final supermarketId = assocRow['supermarket_id'] as String;
  final categoryId = assocRow['category_id'] as String;
  associations[supermarketId] = categoryId;
}

// Create product with associations
final product = Product.fromDatabase(
  {...},
  associations: associations,
);
```

### Fix 2: Ensure Category Changes Are Persisted

Modified `moveProductToCategory()` in `lib/screens/lists/controllers/list_detail_controller.dart` to:
1. Update the category on both the internal list item and the parameter
2. Update product associations for the current supermarket
3. Mark the association change for persistence
4. Explicitly update the `PurchasedProduct.lastModified` timestamp

**Key changes:**
```dart
// Update both references to ensure consistency
_products[index].category = newCategory;
product.category = newCategory;

// Update association and mark for persistence
_products[index].product.addAssociation(
  _selectedSupermarket!.id,
  newCategory.id,
);
_markAssociationChanged(
  _products[index].product.id,
  _selectedSupermarket!.id,
  newCategory.id,
);

// Trigger timestamp update (ensures persistence)
_products[index].lastModified = DateTime.now();
```

### Fix 3: Implement Proper Equality for Category Class

**Modified `lib/models/category.dart`** to implement `==` operator and `hashCode`:

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is Category && other.id == id;
}

@override
int get hashCode => id.hashCode;
```

This ensures that two `Category` objects with the same ID are considered equal, even if they're different instances.

### Fix 4: Use ID-Based Category Matching

**Modified `getProductsByCategory()`** in the controller to match categories by ID instead of object reference:

```dart
// Find matching category in supermarket's categories by ID
final productCategoryId = product.category.id;
final matchingCategory = categories.firstWhere(
  (cat) => cat.id == productCategoryId,
  orElse: () => UncategorizedCategoryUtils.fallbackFrom(categories),
);
```

This provides a robust solution that works even if category equality was not implemented.

## Data Flow

### When a Product is Moved to a New Category:

1. **UI Event:** User drags product P1 from category C1 to C2
2. **Controller Update:** `moveProductToCategory()` updates:
   - `PurchasedProduct.category` → C2 (in-memory)
   - `Product.associations[supermarketId]` → C2 (in-memory)
   - Adds to `_pendingAssociations` for batch persistence
3. **Save Operation:** On screen exit, `save()` method:
   - Calls `_purchasedProductRepo.update()` → saves category_id to `purchased_product` table
   - Calls `_associationRepo.addBatch()` → saves association to `associations` table
   - Both operations append to `sync_box` for Firestore sync
4. **Database State:**
   - `purchased_product.category_id` = C2 ✅
   - `associations` table has P1, S1 → C2 ✅
   - `sync_box` has entries for both updates ✅

### When the List is Reopened:

1. **Load List:** `ShoppingListRepository.getAll()` loads the shopping list
2. **Load Products:** `ManagePurchasedProduct.getPurchasedProductsByList()`:
   - Loads purchased product with category_id = C2
   - Loads product associations: S1 → C2
   - Returns `PurchasedProduct` with correct category and associations
3. **Display:** UI displays product under category C2 ✅

## Sync-Engine Integration

The fix maintains full compatibility with the sync-engine:

1. **Local Persistence:**
   - Category changes are saved to both `purchased_product` and `associations` tables
   - Each update generates a `sync_box` entry with monotonic timestamps

2. **Firestore Sync:**
   - Sync-engine processes `sync_box` entries
   - Updates are pushed to Firestore
   - Other devices pull updates and apply them locally

3. **Multi-Device Consistency:**
   - Device A: User moves product to new category → saved locally and synced
   - Device B: Sync-engine pulls update → applies to local database
   - Device B: User opens list → sees product under new category ✅

## Database Schema

The fix leverages two tables:

### `purchased_product` Table
Stores individual instances of products in shopping lists:
- `id`: Purchased product ID
- `list_id`: Shopping list ID
- `product_id`: Product ID (foreign key)
- `category_id`: **Category ID for this instance** ← Updated by fix
- `quantity`, `price`, etc.

### `associations` Table
Stores global product→supermarket→category mappings:
- `product_id`: Product ID
- `supermarket_id`: Supermarket ID
- `category_id`: **Category ID for this product in this supermarket** ← Updated by fix

## Testing Recommendations

1. **Basic Flow:**
   - Create a list with products
   - Drag a product to a different category
   - Save and exit
   - Reopen the list
   - Verify product is under the new category

2. **Multi-Device Sync:**
   - Perform category change on Device A
   - Wait for sync to complete
   - Open list on Device B
   - Verify product shows under new category

3. **Multiple Products:**
   - Move multiple products to different categories
   - Verify all persist correctly

4. **Same Product, Different Lists:**
   - Add same product to two different lists
   - Move it to different categories in each list
   - Verify each list maintains its own category

## Edge Cases Handled

1. **Product Not in Supermarket's Categories:**
   - Falls back to "Uncategorized" category
   - Handled by `getProductsByCategory()` method

2. **Associations Missing:**
   - Product created with empty associations
   - Placed in "Uncategorized" when categorized

3. **Supermarket Change:**
   - `_recategorizeProductsForSupermarket()` updates categories based on new supermarket's associations
   - Only triggered when user explicitly changes supermarket

## Files Modified

1. **`lib/models/category.dart`**
   - Added `==` operator implementation (equality based on category ID)
   - Added `hashCode` override
   - This ensures categories with the same ID are considered equal

2. **`lib/services/database/sqlite/manage_purchased_product.dart`**
   - `getPurchasedProductsByList()`: Load product associations
   - `getPurchasedProductById()`: Load product associations
   - `getPurchasedProductByName()`: Load product associations

3. **`lib/screens/lists/controllers/list_detail_controller.dart`**
   - `moveProductToCategory()`: Ensure category update is persisted
   - `getProductsByCategory()`: Match categories by ID instead of object reference

## Why This Fix Works

The combination of all four fixes addresses the issue comprehensively:

1. **Associations are loaded**: Products have correct category mappings from the associations table
2. **Categories are persisted**: When moved, both `purchased_product.category_id` and `associations` table are updated
3. **Object equality works**: Category instances with the same ID are treated as equal
4. **ID-based matching**: Even without object equality, categories are matched by ID

The fourth fix (ID-based matching) is the **critical piece** that solves the "uncategorized" problem. Even though we also added equality to Category (which is good practice), the ID-based matching in `getProductsByCategory()` ensures products are correctly categorized regardless of object instance differences.

## Implementation Principles

✅ **Separation of Concerns:** Database layer handles data loading, controller handles business logic  
✅ **Sync-Engine Compatible:** All updates go through repositories that append to sync_box  
✅ **Offline-First:** Changes work offline and sync when connectivity returns  
✅ **Consistency:** Both `purchased_product.category_id` and `associations` table are updated  
✅ **Testability:** Clear data flow and state management  

## Unresolved Issues

None. The implementation fully addresses the category persistence problem while maintaining architectural consistency with the app's sync-engine design.
