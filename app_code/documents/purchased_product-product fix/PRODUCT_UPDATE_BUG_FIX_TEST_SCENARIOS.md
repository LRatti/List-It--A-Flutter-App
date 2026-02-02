# Product Update Bug Fix - Test Scenarios

## Overview

This document provides detailed test scenarios to verify that the product update bug fix works correctly in all situations.

## Test Scenario 1: Basic Rename with Unique Name

**Setup:**
- Create List A with Supermarket X
- Add product "Apple" to List A
- Create List B with Supermarket X
- Add product "Apple" to List B

**Action:**
- Open List A
- Rename "Apple" to "Red Apple"
- Save List A

**Expected Result:**
- List A shows "Red Apple" ✓
- List B still shows "Apple" ✓
- Database contains two separate products: "Apple" and "Red Apple" ✓

**Verification Steps:**
1. Navigate to List A - verify product name is "Red Apple"
2. Navigate to List B - verify product name is still "Apple"
3. Check database:
   - Two product records exist
   - PurchasedProduct in List A references "Red Apple" product
   - PurchasedProduct in List B references "Apple" product

---

## Test Scenario 2: Rename to Existing Product Name

**Setup:**
- Create List A with Supermarket X
- Add product "Apple" to List A
- Add product "Orange" to List A
- Create List B with Supermarket X
- Add product "Apple" to List B

**Action:**
- Open List A
- Rename "Apple" to "Orange" (which already exists in List A)
- Save List A

**Expected Result:**
- List A's renamed product now references the same "Orange" product as the other orange item
- Products are deduplicated (same product object referenced twice)
- List B still shows "Apple" ✓

**Verification Steps:**
1. In List A, both "Orange" items should be linked to the same product
2. Changing one should not affect the other (different PurchasedProducts)
3. List B's "Apple" remains unchanged

---

## Test Scenario 3: Rename Across Different Supermarkets

**Setup:**
- Create List A with Supermarket X
- Create List B with Supermarket Y
- Add "Apple" to both lists (different supermarkets)

**Action:**
- Open List A
- Rename "Apple" to "Red Apple"
- Save List A
- Open List B
- Check "Apple" name

**Expected Result:**
- List A (Supermarket X): "Red Apple" ✓
- List B (Supermarket Y): "Apple" (unchanged) ✓
- Each supermarket can have independent product names

---

## Test Scenario 4: Multiple Products in Different Lists

**Setup:**
- Create List A (Supermarket X) with products: ["Apple", "Banana"]
- Create List B (Supermarket X) with products: ["Apple", "Orange"]
- Create List C (Supermarket Y) with products: ["Apple"]

**Action:**
- Rename List A's "Apple" to "Granny Smith"

**Expected Result:**
- List A: ["Granny Smith", "Banana"] ✓
- List B: ["Apple", "Orange"] ✓
- List C: ["Apple"] ✓

**Impact Analysis:**
- Products in Lists B and C unaffected because they reference different product objects ✓

---

## Test Scenario 5: Product Category Association Preservation

**Setup:**
- Supermarket X has categories: ["Fruits", "Vegetables"]
- List A with Supermarket X
- Add "Apple" associated with "Fruits" category

**Action:**
- Rename "Apple" to "Red Apple"

**Expected Result:**
- New "Red Apple" product inherits the "Fruits" category association ✓
- Original "Apple" product remains with "Fruits" association ✓
- If another List B also has "Apple", it still references the original "Apple" product with "Fruits" association ✓

**Verification Steps:**
1. After renaming, check that "Red Apple" appears in the Fruits section
2. Verify product associations are preserved in database

---

## Test Scenario 6: Undo/Revert (If Available)

**Setup:**
- List A with "Apple"
- Rename to "Red Apple"

**Action:**
- If undo is available, undo the rename
- Or manually rename back to "Apple"

**Expected Result:**
- Can successfully revert the change
- Original "Apple" product still exists and can be referenced again

---

## Test Scenario 7: Rapid Consecutive Renames

**Setup:**
- List A with "Apple"

**Action:**
- Rename to "Red Apple"
- Rename to "Green Apple"
- Rename to "Apple" (back to original)
- Save

**Expected Result:**
- Final state: product named "Apple"
- Old temporary products ("Red Apple", "Green Apple") may exist in database or can be cleaned up
- No data corruption

---

## Test Scenario 8: Rename with Special Characters

**Setup:**
- List A with "Apple"

**Action:**
- Rename to "Apple (Red)"
- Rename to "Apple's Best"
- Rename to "Pomme (Apple) - Fresh"

**Expected Result:**
- All special characters handled correctly
- Names stored and retrieved properly
- No database constraints violated

---

## Test Scenario 9: Empty/Whitespace Names

**Setup:**
- List A with "Apple"

**Action:**
- Try to rename to "" (empty string)
- Try to rename to "   " (whitespace)

**Expected Result:**
- Empty names rejected or trimmed appropriately
- Original product retained
- User receives appropriate feedback

---

## Test Scenario 10: Case Sensitivity

**Setup:**
- List A with "apple" (lowercase)
- List B with "Apple" (capitalized)

**Action:**
- Rename List A's "apple" to "Apple"

**Expected Result:**
- Verify how the system handles case differences
- Should it create a new product or reference existing?
- This depends on the system's case-sensitivity design

---

## Test Scenario 11: Sync Consistency

**Setup:**
- List A with "Apple" (Supermarket X)
- Device A and Device B synced

**Action:**
- On Device A: Rename "Apple" to "Red Apple"
- Observe Device B

**Expected Result:**
- Device B eventually sees "Red Apple" in List A
- List B (if it exists) still has "Apple"
- Sync engine correctly propagates changes
- No conflicts or data loss

---

## Test Scenario 12: Offline Changes

**Setup:**
- App in offline mode
- List A with "Apple"

**Action:**
- Rename "Apple" to "Red Apple"
- Go online

**Expected Result:**
- Changes synced when online
- Remote database updated correctly
- No conflicts or data loss

---

## Regression Tests

### Test: Original Behavior Still Works

**Scenario:** Regular updates to quantity, price, category still work

**Action:**
- Rename product
- Change quantity
- Change price
- Change category
- Save

**Expected Result:**
- All changes persist correctly
- No side effects from the product update fix

### Test: Product Deletion

**Scenario:** Deleting purchased products with renamed products

**Action:**
- Rename product
- Delete the purchased product
- Verify original product still exists (if referenced elsewhere)

**Expected Result:**
- Purchased product deleted
- Original product remains if referenced
- No orphaned data

### Test: Product Visibility

**Scenario:** Visibility flag preserved during rename

**Action:**
- Mark product as hidden
- Rename it
- Check visibility

**Expected Result:**
- Visibility flag preserved on new product reference

---

## Performance Considerations

### Test: Large Number of Products

**Setup:**
- List with 100+ products

**Action:**
- Rename multiple products rapidly
- Observe performance

**Expected Result:**
- No noticeable lag
- Rename operations complete quickly
- UI remains responsive

---

## Edge Cases

### Test: Rename to Very Long Name
- Product name with 255+ characters
- Should be handled or rejected gracefully

### Test: Rename to Same Name
- Rename "Apple" to "Apple"
- Should detect no change and skip update

### Test: Concurrent Edits
- Two devices rename the same product to different names
- Should handle merge correctly or show conflict

---

## Automated Test Implementation

```dart
// Example test for the fix
test('Renaming product in one list does not affect same product in another list', () async {
  // Setup
  final supermarket = Supermarket(id: 'sm1', name: 'Market X');
  final listA = ShoppingList(id: 'listA', name: 'List A', supermarket: supermarket);
  final listB = ShoppingList(id: 'listB', name: 'List B', supermarket: supermarket);
  
  final apple = Product(id: 'prod1', name: 'Apple');
  final categoryFruit = Category(id: 'cat1', name: 'Fruits');
  
  // Add same product to both lists
  final ppA = PurchasedProduct(
    listId: 'listA',
    product: apple,
    category: categoryFruit,
  );
  final ppB = PurchasedProduct(
    listId: 'listB', 
    product: apple,
    category: categoryFruit,
  );
  
  // Action: Rename in List A
  final handler = PurchasedProductUpdateHandler();
  final updatedPpA = await handler.updateProductName(ppA, 'Red Apple');
  
  // Verification
  expect(updatedPpA.product.getName(), 'Red Apple');
  expect(ppB.product.getName(), 'Apple'); // Should be unchanged
  expect(updatedPpA.product.id, isNot(apple.id)); // New product instance
});
```

---

## Summary Checklist

- [ ] Test Scenario 1: Basic rename with unique name ✓
- [ ] Test Scenario 2: Rename to existing product ✓
- [ ] Test Scenario 3: Different supermarkets ✓
- [ ] Test Scenario 4: Multiple products in lists ✓
- [ ] Test Scenario 5: Category associations preserved ✓
- [ ] Test Scenario 6: Undo/revert if available ✓
- [ ] Test Scenario 7: Rapid renames ✓
- [ ] Test Scenario 8: Special characters ✓
- [ ] Test Scenario 9: Empty names handling ✓
- [ ] Test Scenario 10: Case sensitivity ✓
- [ ] Test Scenario 11: Sync consistency ✓
- [ ] Test Scenario 12: Offline mode ✓
- [ ] Regression: Original functionality intact ✓
- [ ] Performance: No lag with many products ✓
- [ ] Edge cases: Long names, concurrent edits ✓
