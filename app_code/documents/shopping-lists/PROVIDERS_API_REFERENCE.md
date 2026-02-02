# New Providers API Reference

## Quick Provider Index

| Provider | Type | Purpose | State Type |
|----------|------|---------|-----------|
| `productRepositoryProvider` | Provider | Access ProductRepositoryWithSync | `ProductRepositoryWithSync` |
| `purchasedProductRepositoryProvider` | Provider | Access PurchasedProductRepositoryWithSync | `PurchasedProductRepositoryWithSync` |
| `associationRepositoryProvider` | Provider | Access AssociationRepositoryWithSync | `AssociationRepositoryWithSync` |
| `productsProvider` | NotifierProvider | Manage products with caching | `Map<String, Product>` |
| `purchasedProductsProvider` | NotifierProvider | Manage purchased products with caching | `Map<String, PurchasedProduct>` |
| `associationsProvider` | NotifierProvider | Manage associations pending flush | `Map<String, Map<String, String>>` |

---

## ProductsNotifier API

```dart
// Provider
final productsProvider = NotifierProvider<ProductsNotifier, Map<String, Product>>(...)

// State
Map<String, Product> // Maps productId -> Product

// Methods (via ref.read(productsProvider.notifier))
Future<void> addProduct(Product product)
Future<void> updateProduct(Product product)
Future<void> deleteProductById(String id)
Future<Product?> getProductById(String id)
void cacheProduct(Product product)
Product? getCachedProduct(String id)
```

**Usage Example**:
```dart
final productsNotifier = ref.read(productsProvider.notifier);
await productsNotifier.addProduct(myProduct);
final product = await productsNotifier.getProductById('product-123');
```

---

## PurchasedProductsNotifier API

```dart
// Provider
final purchasedProductsProvider = NotifierProvider<PurchasedProductsNotifier, Map<String, PurchasedProduct>>(...)

// State
Map<String, PurchasedProduct> // Maps purchasedProductId -> PurchasedProduct

// Methods (via ref.read(purchasedProductsProvider.notifier))
Future<void> addPurchasedProduct(PurchasedProduct product)
Future<void> updatePurchasedProduct(PurchasedProduct product)
Future<void> deletePurchasedProductById(String id)
Future<PurchasedProduct?> getPurchasedProductById(String id)
void cachePurchasedProduct(PurchasedProduct product)
PurchasedProduct? getCachedPurchasedProduct(String id)
void removeCachedProduct(String id)
```

**Usage Example**:
```dart
final ppNotifier = ref.read(purchasedProductsProvider.notifier);
await ppNotifier.addPurchasedProduct(myPurchasedProduct);
final pp = await ppNotifier.getPurchasedProductById('pp-123');
```

---

## AssociationsNotifier API

```dart
// Provider
final associationsProvider = NotifierProvider<AssociationsNotifier, AssociationMap>(...)

// State Type
typedef AssociationMap = Map<String, Map<String, String>>;
// Structure: { productId: { supermarketId: categoryId } }

// Methods (via ref.read(associationsProvider.notifier))
void markAssociationChanged(String productId, String supermarketId, String categoryId)
Map<String, String>? getPendingAssociations(String productId)
bool hasPendingAssociations()
Future<void> flushAssociations()
void clearPending()
void clearPendingForProduct(String productId)
```

**Usage Example**:
```dart
final assocNotifier = ref.read(associationsProvider.notifier);

// Mark changes
assocNotifier.markAssociationChanged('product-1', 'supermarket-1', 'category-1');

// Check if there are pending changes
if (assocNotifier.hasPendingAssociations()) {
  await assocNotifier.flushAssociations();
}

// Get pending for specific product
final pending = assocNotifier.getPendingAssociations('product-1');
// Returns: { 'supermarket-1': 'category-1', 'supermarket-2': 'category-3' }
```

---

## Integration with ListDetailController

### Controller Constructor
```dart
ListDetailController({
  required ShoppingList shoppingList,
  required Ref ref,  // Pass from provider
  Supermarket? initialSupermarket,
  List<PurchasedProduct>? initialProducts,
})
```

### Inside save() Method
```dart
Future<void> save() async {
  // 1. Update list
  final listNotifier = _ref.read(shoppingListsProvider.notifier);
  await listNotifier.updateList(_originalList);

  // 2. Update products
  final productsNotifier = _ref.read(productsProvider.notifier);
  await productsNotifier.addProduct(product);

  // 3. Update purchased products
  final ppNotifier = _ref.read(purchasedProductsProvider.notifier);
  await ppNotifier.updatePurchasedProduct(purchasedProduct);

  // 4. Flush associations
  final assocNotifier = _ref.read(associationsProvider.notifier);
  await assocNotifier.flushAssociations();
}
```

---

## Creating Provider in Screen

```dart
final listDetailControllerProvider =
    ChangeNotifierProvider.family<ListDetailController, ShoppingList>((ref, shoppingList) {
      return ListDetailController(
        shoppingList: shoppingList,
        ref: ref,  // ← Pass Riverpod ref
      );
    });
```

---

## Usage in ConsumerWidget/ConsumerState

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access controller
    final controller = ref.watch(listDetailControllerProvider(myList));
    
    // Access products directly
    final productsCache = ref.watch(productsProvider);
    
    // Access associations
    final pendingAssociations = ref.watch(associationsProvider);
    
    return YourWidget(controller: controller);
  }
}
```

---

## Common Patterns

### Pattern 1: Add Product via Controller
```dart
final controller = ref.read(listDetailControllerProvider(list));
final newProduct = Product(...);
final category = Category(...);
final purchasedProduct = controller.addProduct(newProduct, category);
```

### Pattern 2: Save All Changes
```dart
final controller = ref.read(listDetailControllerProvider(list));
controller.updateListName("New Name");
await controller.save(); // Uses all providers internally
```

### Pattern 3: Access Products Cache
```dart
final productsNotifier = ref.read(productsProvider.notifier);
final product = productsNotifier.getCachedProduct('product-123');
```

### Pattern 4: Mark Association Without Saving
```dart
final assocNotifier = ref.read(associationsProvider.notifier);
assocNotifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
// Change is tracked in state, not persisted yet
```

### Pattern 5: Flush Associations Only
```dart
final assocNotifier = ref.read(associationsProvider.notifier);
if (assocNotifier.hasPendingAssociations()) {
  await assocNotifier.flushAssociations();
}
```

---

## Error Handling

All providers' methods can throw exceptions from the underlying repositories. Wrap in try-catch:

```dart
try {
  final ppNotifier = ref.read(purchasedProductsProvider.notifier);
  await ppNotifier.addPurchasedProduct(item);
} on DatabaseException catch (e) {
  // Handle database errors
} on SyncException catch (e) {
  // Handle sync errors
} catch (e) {
  // Handle other errors
}
```

---

## Testing with Overrides

```dart
test('controller saves products via provider', (WidgetTester tester) async {
  final mockProductsNotifier = MockProductsNotifier();
  
  await tester.pumpWidget(
    ProviderContainer(
      overrides: [
        productsProvider.overrideWithValue(FakeProductsNotifier()),
      ],
      child: MyApp(),
    ).listen((final ref) => ref),
  );
  
  // Now productsProvider will use the fake notifier
});
```

---

## File Imports

To use the new providers, import:

```dart
import 'package:app_code/providers/real_app_providers/product_repositories_provider.dart';
import 'package:app_code/providers/real_app_providers/products_notifier.dart';
import 'package:app_code/providers/real_app_providers/purchased_products_notifier.dart';
import 'package:app_code/providers/real_app_providers/associations_notifier.dart';
```

Or import the controller which imports them all:
```dart
import 'package:app_code/screens/lists/controllers/list_detail_controller.dart';
```

---

## Thread Safety

- All notifiers use immutable state updates
- All persistence operations are atomic
- All batch operations happen in database transactions
- Safe for concurrent access via Riverpod

---

## Performance Characteristics

| Operation | Complexity | Async |
|-----------|-----------|-------|
| `getCachedProduct()` | O(1) | Sync |
| `getProductById()` | O(n) database lookup | Async |
| `addProduct()` | O(1) + sync | Async |
| `updateProduct()` | O(1) + sync | Async |
| `markAssociationChanged()` | O(1) | Sync |
| `flushAssociations()` | O(n) batch + sync | Async |

---

## State Invalidation

If you need to refresh cached state:

```dart
// Invalidate all products cache
ref.invalidate(productsProvider);

// Invalidate all purchased products cache
ref.invalidate(purchasedProductsProvider);

// Clear pending associations without persisting
ref.read(associationsProvider.notifier).clearPending();
```

---

This API reference provides everything needed to use the new providers in your application.
