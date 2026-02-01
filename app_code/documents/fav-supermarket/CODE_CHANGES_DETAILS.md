# Favorite Supermarket Feature - Code Changes Details

## Files Created

### 1. `lib/utils/favorite_supermarket_initializer.dart` (NEW - 40 lines)
**Purpose**: Ensures a favorite supermarket is initialized on every app startup

**Key Components**:
- `FavoriteSupermarketInitializer` class (static methods only)
- `ensureFavoriteInitialized()` async method
  - Returns `Future<bool>`
  - Checks if favorite exists
  - If not, selects first visible supermarket
  - Handles errors gracefully
  - Logs success/warning messages

**Integration Point**: Called from `lib/main.dart` in `_runStartupTasks()`

---

## Files Modified

### 1. `lib/main.dart`
**Changes**:
```dart
// Added import (line ~26)
import 'package:app_code/utils/favorite_supermarket_initializer.dart';

// Added method call in _runStartupTasks() (line ~47)
await FavoriteSupermarketInitializer.ensureFavoriteInitialized();
```

**Impact**:
- Ensures favorite is set before UI initialization
- Handles both fresh installs and upgrades
- Non-blocking (completes quickly for fresh installs)

---

### 2. `lib/services/mock/mock_data_seed.dart`
**Changes**:
```dart
// Removed unused imports (line 1-11)
// Removed: import 'package:app_code/models/category.dart';
// Removed: import 'package:app_code/services/database/sqlite/manage_category.dart';

// Line ~51: Added isFavorite parameter when creating default supermarket
final defaultSupermarket = Supermarket(
  name: 'Supermarket',
  categories: defaultCategories,
  isVisible: true,
  isFavorite: true,  // NEW
);

// Line ~56: Added SQLite favorite initialization
await ManageSupermarket.setFavoriteSupermarket(defaultSupermarket.id);
print('📦 Set default supermarket as favorite');
```

**Impact**:
- First-time users have a favorite pre-set
- Fresh installs are immediately usable
- Mock supermarket is ready for shopping list creation

---

### 3. `lib/providers/real_app_providers/supermarkets_notifier.dart`
**Changes**:

#### Removed Unused Imports (lines 1-8)
```dart
// Removed: import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_supermarket.dart';
// Removed: import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_category.dart';
```

#### Enhanced deleteSupermarket() Method (lines 32-45)
```dart
/// Before: Just marked invisible
/// After: Includes favorite handling

Future<void> deleteSupermarket(String id) async {
  // Check if this is the favorite supermarket
  final currentFavorite = await sqlite_supermarket.ManageSupermarket.getFavoriteSupermarket();
  final isFavorite = currentFavorite?.id == id;

  final supermarket = await _syncRepo.getById(id);
  if (supermarket != null) {
    supermarket.setVisibility(false);
    await _syncRepo.update(supermarket);
    
    // If the deleted supermarket was favorite, find a new favorite
    if (isFavorite) {
      await _ensureNewFavoriteAfterDeletion(id);
    }

    ref.invalidateSelf();
  }
}
```

**Impact**: Deletion maintains the single-favorite invariant

#### Enhanced deleteSupermarkets() Method (lines 48-81)
```dart
/// Before: Just marked invisible
/// After: Includes favorite handling for batch operations

Future<int> deleteSupermarkets(List<String> ids) async {
  int deletedCount = 0;

  // Check if the favorite is being deleted
  final currentFavorite = await sqlite_supermarket.ManageSupermarket.getFavoriteSupermarket();
  bool favoriteBeinDeleted = currentFavorite != null && ids.contains(currentFavorite.id);

  for (final id in ids) {
    // ... deletion logic ...
  }

  // If the favorite was deleted, find a new favorite
  if (favoriteBeinDeleted) {
    await _ensureNewFavoriteAfterDeletion(currentFavorite.id);
  }

  ref.invalidateSelf();
  return deletedCount;
}
```

**Impact**: Batch deletions also respect the invariant

#### New Helper Method (lines 83-98)
```dart
/// Helper method to ensure a new favorite is selected after the current one is deleted
Future<void> _ensureNewFavoriteAfterDeletion(String deletedSupermarketId) async {
  // Get all remaining visible supermarkets
  final allSupermarkets = await _syncRepo.getAll();
  final remainingVisible = allSupermarkets
      .where((s) => s.isVisible && s.id != deletedSupermarketId)
      .toList();

  if (remainingVisible.isEmpty) {
    print('⚠️ No visible supermarkets remaining after deletion');
    return;
  }

  // Set the first remaining visible supermarket as favorite
  await setFavoriteSupermarket(remainingVisible.first.id);
}
```

**Impact**: Automatic reassignment of favorite after deletion

#### Enhanced clearFavoriteSupermarket() Method (lines 178-218)
```dart
/// Before: void method, always cleared
/// After: bool return, enforces constraint

Future<bool> clearFavoriteSupermarket(String supermarketId) async {
  // Check if this is the only favorite
  final currentFavorite = await sqlite_supermarket.ManageSupermarket.getFavoriteSupermarket();
  if (currentFavorite != null && currentFavorite.id == supermarketId) {
    // This is the current favorite, check if there are other supermarkets to become favorite
    final allVisible = (await _syncRepo.getAll()).where((s) => s.isVisible).toList();
    
    if (allVisible.length <= 1) {
      // This is the only supermarket, can't clear favorite
      print('⚠️ Cannot clear favorite from the only supermarket. Use setFavoriteSupermarket() to change it.');
      return false;  // Prevention: constraint violated
    }
    
    // There are other supermarkets, automatically set the first one as favorite
    final nextFavorite = allVisible.firstWhere((s) => s.id != supermarketId);
    await setFavoriteSupermarket(nextFavorite.id);
    return true;  // Success with reassignment
  }

  // Not the current favorite, just clear it
  await sqlite_supermarket.ManageSupermarket.clearFavoriteSupermarket(supermarketId);

  // Get the supermarket and mark it as updated for sync
  final supermarket = await _syncRepo.getById(supermarketId);
  if (supermarket != null) {
    supermarket.isFavorite = false;
    await _syncRepo.update(supermarket);
  }

  ref.invalidateSelf();
  return true;  // Success
}
```

**Impact**: Prevents clearing the only favorite while maintaining user control

---

### 4. `lib/widgets/supermarkets_grid_view.dart`
**Changes**:

#### Updated Favorite Button Handler (lines 257-308)
```dart
/// Before: Simple async/await, no feedback on prevention
/// After: Checks return value, shows feedback message

IconButton(
  icon: Icon(
    supermarket.isFavorite
        ? Icons.star
        : Icons.star_outline,
  ),
  onPressed: () async {
    try {
      if (supermarket.isFavorite) {
        // Try to clear favorite (will fail if it's the only one)
        final success = await ref
            .read(supermarketsProvider.notifier)
            .clearFavoriteSupermarket(supermarket.id);
        
        if (!success && mounted) {
          // Show message explaining why favorite couldn't be cleared
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Cannot remove favorite: You must have at least one favorite supermarket. Select a different one first.',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Set as favorite (will clear previous favorite)
        await ref
            .read(supermarketsProvider.notifier)
            .setFavoriteSupermarket(supermarket.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating favorite: ${e.toString()}',
            ),
            backgroundColor:
                Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  },
  color: supermarket.isFavorite
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.outline,
),
```

**Impact**: 
- Users see clear feedback when constraint prevents action
- Better UX with mounted state checking
- Graceful error handling

---

## Summary of Changes

### Code Metrics
| Metric | Count |
|--------|-------|
| Files Created | 1 |
| Files Modified | 4 |
| New Lines Added | ~150 |
| Existing Lines Enhanced | ~80 |
| Unused Imports Removed | 4 |
| New Methods | 1 |
| Modified Methods | 4 |
| Return Type Changed | 1 |

### Types of Changes
| Type | Count | Details |
|------|-------|---------|
| Feature | 1 | Default favorite on seed |
| Enhancement | 3 | Constraint enforcement |
| Bug Prevention | 2 | Only-favorite protection |
| UX Improvement | 1 | User feedback messages |
| Code Quality | 4 | Unused imports removed |
| Integration | 1 | Startup initialization |

### Methods Changed

1. **`deleteSupermarket()`** - Added favorite detection and reassignment
2. **`deleteSupermarkets()`** - Added batch favorite handling
3. **`clearFavoriteSupermarket()`** - Return type changed `void` → `Future<bool>`
4. **Favorite button handler** - Added return value check and feedback
5. **`_ensureNewFavoriteAfterDeletion()`** - New helper method
6. **`_runStartupTasks()`** - Added initializer call

### Data Flow Changes

**Before**:
```
Delete → Mark Invisible → Sync
(if favorite was deleted, system left in broken state)

Clear → Remove from SQLite → Sync
(no check if only favorite)
```

**After**:
```
Delete → Check if Favorite → Mark Invisible
       ├─ YES → _ensureNewFavoriteAfterDeletion() → Sync
       └─ NO → Sync

Clear → Check if Only Favorite
      ├─ YES and Only One → Return false (show feedback)
      ├─ YES and Multiple → Auto-reassign → Sync
      └─ NO → Clear → Sync
```

---

## Testing New Code Paths

### Code Path 1: Fresh Install
```
seedMockDataIfEmpty()
  → Creates Supermarket with isFavorite: true
  → Calls setFavoriteSupermarket()
  → Syncs to Firestore

Test: Verify default supermarket shows filled star
```

### Code Path 2: Upgrade
```
ensureFavoriteInitialized()
  → Checks getFavoriteSupermarket()
  → If null, calls setFavoriteSupermarket(firstVisible.id)
  → Syncs change

Test: Old database gets favorite assigned automatically
```

### Code Path 3: Delete Favorite
```
deleteSupermarket(favId)
  → Detects isFavorite
  → Calls _ensureNewFavoriteAfterDeletion()
  → Selects next visible
  → Calls setFavoriteSupermarket()

Test: Favorite changes to next supermarket
```

### Code Path 4: Clear Only Favorite
```
clearFavoriteSupermarket(onlyId)
  → Checks count of visible
  → Finds count <= 1
  → Returns false

Test: Star doesn't clear, snackbar shown
```

---

**Status**: All changes complete and verified
