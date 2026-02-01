# Favorite Supermarket Implementation - Visual Guide

## Problem: No Favorite Supermarket on First Use
When users opened the app for the first time, no supermarket was marked as favorite, breaking the shopping list creation flow which depended on a pre-selected favorite.

## Solution Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FAVORITE SUPERMARKET SYSTEM                  │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ FRESH INSTALL (First Time User)                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  App Startup                                                     │
│      ↓                                                           │
│  seedMockDataIfEmpty()                                           │
│      ├─ Creates Default Supermarket                             │
│      ├─ Sets isFavorite: true  ← KEY: Set from the start       │
│      └─ Syncs to Firestore                                      │
│      ↓                                                           │
│  ensureFavoriteInitialized()                                    │
│      ├─ Checks for favorite ✓ (already exists from seed)       │
│      └─ Ready to use                                            │
│      ↓                                                           │
│  App Ready ✓                                                    │
│  → User can create shopping lists with auto-selected favorite   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ UPGRADE (Existing Database)                                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  App Startup                                                     │
│      ↓                                                           │
│  seedMockDataIfEmpty()                                           │
│      ├─ Checks database                                         │
│      └─ Database has data → SKIP ✓                             │
│      ↓                                                           │
│  ensureFavoriteInitializer()  ← KEY: New safety net            │
│      ├─ Is favorite set? NO                                    │
│      ├─ Get all visible supermarkets                           │
│      ├─ Select first one as favorite                           │
│      └─ Sync change to Firestore                               │
│      ↓                                                           │
│  App Ready ✓                                                    │
│  → Existing users now have a favorite supermarket              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ DELETE FAVORITE (Maintaining Invariant)                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User: Delete favorite supermarket                              │
│      ↓                                                           │
│  deleteSupermarket(id)                                          │
│      ├─ Is this the favorite? YES                              │
│      ├─ Mark as invisible                                       │
│      └─ Call _ensureNewFavoriteAfterDeletion()                 │
│           ├─ Get visible supermarkets                          │
│           ├─ Select first remaining one                        │
│           └─ setFavoriteSupermarket(newId)                     │
│      ↓                                                           │
│  Sync to Firestore (async)                                     │
│      ↓                                                           │
│  UI Updates ✓                                                   │
│  → New favorite now selected automatically                      │
│                                                                  │
│  INVARIANT MAINTAINED: Exactly 1 favorite always               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ CLEAR ONLY FAVORITE (Preventing Violation)                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User: Click star on only supermarket                           │
│      ↓                                                           │
│  clearFavoriteSupermarket(id)                                   │
│      ├─ Is this the current favorite? YES                       │
│      ├─ Count visible supermarkets: 1 (only this one)          │
│      └─ Cannot proceed → Return false ✗                        │
│      ↓                                                           │
│  UI Handler                                                      │
│      ├─ Detects false return                                   │
│      └─ Shows snackbar: "Cannot remove favorite..."            │
│      ↓                                                           │
│  UI Stays Same ✓                                                │
│  → Star remains filled, user is informed                        │
│                                                                  │
│  INVARIANT PROTECTED: Can't remove only favorite               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow Through Layers

```
┌───────────────────────────────────────────────────────────────────┐
│                          UI LAYER                                 │
│              (supermarkets_grid_view.dart)                        │
│  • Star icon to set/clear favorite                              │
│  • Snackbar feedback for constraint violations                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌───────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT LAYER                         │
│            (supermarkets_notifier.dart via Riverpod)             │
│  • setFavoriteSupermarket(id) → clears old, sets new            │
│  • clearFavoriteSupermarket(id) → enforces constraint            │
│  • deleteSupermarket(id) → auto-reassigns if favorite           │
│  • _ensureNewFavoriteAfterDeletion() → helper method            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌───────────────────────────────────────────────────────────────────┐
│                      REPOSITORY LAYER                             │
│            (SupermarketRepositoryWithSync)                        │
│  • update(supermarket) → queues sync                             │
│  • Maintains write-ahead pattern                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓ (Write-Ahead Pattern)
                    ┌────────┴────────┐
                    ↓                 ↓
        ┌──────────────────┐  ┌──────────────────┐
        │   SQLITE LOCAL   │  │  FIRESTORE SYNC  │
        │   (Source Truth) │  │   (Async)        │
        └──────────────────┘  └──────────────────┘
        • isFavorite flag    • Replicated to cloud
        • Immediate updates  • For multi-device sync
```

## Key Methods and Their Responsibilities

### 1. **seedMockDataIfEmpty()** - Fresh Install Setup
```dart
// Sets isFavorite: true on the default supermarket
final defaultSupermarket = Supermarket(
  name: 'Supermarket',
  categories: defaultCategories,
  isVisible: true,
  isFavorite: true,  ← NEW: Favorite from start
);
await supermarketRepo.add(defaultSupermarket);
await ManageSupermarket.setFavoriteSupermarket(defaultSupermarket.id);
```

### 2. **ensureFavoriteInitialized()** - Startup Safety Net
```dart
// Handles upgrade scenarios
final currentFavorite = await ManageSupermarket.getFavoriteSupermarket();
if (currentFavorite == null) {
  // No favorite found, select first visible
  final supermarketToFavor = visibleSupermarkets.first;
  await ManageSupermarket.setFavoriteSupermarket(supermarketToFavor.id);
}
```

### 3. **setFavoriteSupermarket(id)** - Setting New Favorite
```dart
// Clear old, set new (standard behavior)
await sqlite_supermarket.ManageSupermarket.setFavoriteSupermarket(id);
// Then sync to Firestore
await _syncRepo.update(supermarket);
```

### 4. **clearFavoriteSupermarket(id)** - Smart Clearing
```dart
// Returns bool: true=success, false=prevented
if (isOnlyFavorite) {
  return false;  // Prevent clearing only favorite
}
// Otherwise proceed with clearing
```

### 5. **deleteSupermarket(id)** - Delete with Reassignment
```dart
// Mark invisible
supermarket.setVisibility(false);
// If it was favorite, auto-select another
if (isFavorite) {
  _ensureNewFavoriteAfterDeletion(id);
}
```

## Critical Invariant: Single Favorite Always

```
┌────────────────────────────────────────────────────┐
│  INVARIANT: Exactly 1 Supermarket is Favorite      │
├────────────────────────────────────────────────────┤
│  ✓ Fresh install     → Initialized with default   │
│  ✓ Upgrade path      → Auto-initialized if missing │
│  ✓ Delete favorite   → Auto-reassigned             │
│  ✓ Clear attempt     → Blocked if only one         │
│  ✓ Delete operation  → Handles favorite case       │
│  ✓ Multi-device sync → Synced via Firestore       │
└────────────────────────────────────────────────────┘

This means:
• Users never see "no favorite selected"
• The list_detail_screen can always rely on getFavoriteSupermarket()
• Deletion doesn't leave system in broken state
• Multi-device sync respects the constraint
```

## Testing Checklist

```
□ Fresh Install
  └─ Default supermarket appears with filled star

□ Upgrade Scenario
  └─ First visible supermarket auto-selected as favorite

□ Delete Favorite
  ├─ Next supermarket becomes favorite
  └─ List updates properly

□ Clear Only Favorite
  ├─ Star doesn't clear
  ├─ Snackbar shows message
  └─ User can select different instead

□ Multiple Deletes
  ├─ Delete non-favorite → No change to favorite
  └─ Delete favorite → Next one selected

□ Sync Testing
  ├─ Change favorite on Device A
  └─ Device B receives update

□ UI Consistency
  ├─ Colors and icons match design
  ├─ Dark/light mode work
  └─ Responsive layout maintained
```

## Architecture Alignment

```
✓ UI → UI Controller → Repositories → Local services (SQLite)
  └─ SQLite ←→ Sync-Engine ←→ Remote Database (Firestore)

Maintained through:
• Riverpod for state management
• SupermarketRepositoryWithSync for data access
• ManageSupermarket for SQLite operations
• Write-ahead pattern for sync
• Clear separation of concerns
```

---

**Status**: ✅ Complete and Ready for Testing
