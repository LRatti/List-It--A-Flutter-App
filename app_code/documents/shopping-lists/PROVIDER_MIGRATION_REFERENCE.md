# Provider-Based Refactoring: Quick Reference

## Side-by-Side Comparison

### 1. Class Construction

**BEFORE:**
```dart
ListDetailController({
  required ShoppingList shoppingList,
  Supermarket? initialSupermarket,
  List<PurchasedProduct>? initialProducts,
})
```

**AFTER:**
```dart
ListDetailController({
  required ShoppingList shoppingList,
  required Ref ref,  // ← NEW: Riverpod dependency injection
  Supermarket? initialSupermarket,
  List<PurchasedProduct>? initialProducts,
})
```

---

### 2. Marking Associations

**BEFORE:**
```dart
void _markAssociationChanged(String productId, String supermarketId, String categoryId) {
  if (!_pendingAssociations.containsKey(productId)) {
    _pendingAssociations[productId] = {};
  }
  _pendingAssociations[productId]![supermarketId] = categoryId;
}
```

**AFTER:**
```dart
void _markAssociationChanged(String productId, String supermarketId, String categoryId) {
  final associationsNotifier = _ref.read(associationsProvider.notifier);
  associationsNotifier.markAssociationChanged(productId, supermarketId, categoryId);
}
```

---

### 3. Saving Shopping List

**BEFORE:**
```dart
await _listRepo.update(_originalList);
```

**AFTER:**
```dart
final listNotifier = _ref.read(shoppingListsProvider.notifier);
await listNotifier.updateList(_originalList);
```

---

### 4. Saving Products

**BEFORE:**
```dart
final check = await _productRepo.getById(product.id);
if (check == null) {
  await _productRepo.add(product);
} else {
  await _productRepo.update(product);
}
```

**AFTER:**
```dart
final productsNotifier = _ref.read(productsProvider.notifier);
final check = await productsNotifier.getProductById(product.id);
if (check == null) {
  await productsNotifier.addProduct(product);
} else {
  await productsNotifier.updateProduct(product);
}
```

---

### 5. Saving Purchased Products

**BEFORE:**
```dart
final existingPurchased = await _purchasedProductRepo.getById(purchasedProduct.id);
if (existingPurchased == null) {
  await _purchasedProductRepo.add(purchasedProduct);
} else {
  await _purchasedProductRepo.update(purchasedProduct);
}
```

**AFTER:**
```dart
final purchasedProductsNotifier = _ref.read(purchasedProductsProvider.notifier);
final existingPurchased = await purchasedProductsNotifier.getPurchasedProductById(purchasedProduct.id);
if (existingPurchased == null) {
  await purchasedProductsNotifier.addPurchasedProduct(purchasedProduct);
} else {
  await purchasedProductsNotifier.updatePurchasedProduct(purchasedProduct);
}
```

---

### 6. Deleting Purchased Products

**BEFORE:**
```dart
for (var deletedId in deletedIds) {
  await _purchasedProductRepo.deleteById(deletedId);
}
```

**AFTER:**
```dart
for (var deletedId in deletedIds) {
  await purchasedProductsNotifier.deletePurchasedProductById(deletedId);
}
```

---

### 7. Flushing Associations

**BEFORE:**
```dart
if (_pendingAssociations.isNotEmpty) {
  await _associationRepo.addBatch(_pendingAssociations);
}
_pendingAssociations.clear();
```

**AFTER:**
```dart
final associationsNotifier = _ref.read(associationsProvider.notifier);
if (associationsNotifier.hasPendingAssociations()) {
  await associationsNotifier.flushAssociations();
}
```

---

### 8. Deleting List

**BEFORE:**
```dart
Future<void> deleteList() async {
  _originalList.setIsInTheTrash(true);
  await _listRepo.update(_originalList);
}
```

**AFTER:**
```dart
Future<void> deleteList() async {
  _originalList.setIsInTheTrash(true);
  final listNotifier = _ref.read(shoppingListsProvider.notifier);
  await listNotifier.updateList(_originalList);
}
```

---

## What Stayed the Same

✅ In-memory state management (products list, selected supermarket, etc.)
✅ Controller's public methods and getters
✅ UI interaction flow
✅ Sync and offline capabilities
✅ Data model structures

---

## Provider Architecture Map

```
┌─────────────────────────────────────────────┐
│       list_detail_controller.dart            │
│  (Manages UI state + orchestrates saves)     │
└──────────────┬──────────────────────────────┘
               │ Uses Ref to access:
       ┌───────┴───────┬──────────────┬────────────┐
       ▼               ▼              ▼            ▼
   shoppingLists   products    purchasedProducts associations
   Provider        Provider      Provider         Provider
   Notifier        Notifier      Notifier         Notifier
       │               │            │              │
       └───────────────┴────────────┴──────────────┘
                       │
              Repositories (Sync-Aware)
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
      SQLite                   Sync-Engine
                                  │
                                  ▼
                           Firebase Firestore
```

---

## How to Use the Refactored Controller

### Creating the Controller in a Provider
```dart
final listDetailControllerProvider =
    ChangeNotifierProvider.family<ListDetailController, ShoppingList>((ref, shoppingList) {
      return ListDetailController(
        shoppingList: shoppingList,
        ref: ref,  // ← Pass the Riverpod ref
      );
    });
```

### Using in a Screen
```dart
ConsumerState {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(listDetailControllerProvider(widget.shoppingList));
    
    return WillPopScope(
      onWillPop: () async {
        controller.updateListName(_nameController.text.trim());
        await controller.save();  // Uses providers internally
        return true;
      },
      child: YourWidget(),
    );
  }
}
```

---

## Benefits Summary

| Benefit | Impact |
|---------|--------|
| **Consistency** | Uses same pattern as ShoppingListsNotifier, SupermarketsNotifier, CategoriesNotifier |
| **Testability** | Providers can be easily mocked/overridden |
| **Reusability** | Products, purchased products, associations accessible throughout app |
| **Maintainability** | Clear separation: UI state vs persistence operations |
| **Scalability** | Other screens can now use product/association providers |
| **Offline-First** | Maintains sync-engine integration for offline support |

---

## Transition Checklist

- [x] Create repository providers
- [x] Create products notifier
- [x] Create purchased products notifier  
- [x] Create associations notifier
- [x] Refactor ListDetailController
- [x] Update list_detail_controller provider
- [x] Verify no compilation errors
- [x] Document changes
- [ ] Run tests (next step)
- [ ] Test UI in running app (next step)
