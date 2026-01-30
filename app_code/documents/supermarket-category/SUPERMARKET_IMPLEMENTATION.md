# Supermarket & Category Management - Implementation Guide

## Overview

This document describes the complete implementation of the Supermarket and Category management system for the DIMA shopping app. The implementation follows the existing app architecture and integrates seamlessly with the sync-engine for offline-first, multi-device synchronization.

## Architecture

### Data Flow Diagram

```
┌─────────────────────────────────────────┐
│         UI Screens (Consumer)            │
├─────────────────────────────────────────┤
│ • supermarkets_screen_mobile.dart
│ • supermarket_customization_screen.dart  
│ • category_selection_screen.dart         
│ • category_editing_screen.dart           
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Riverpod Providers (State Mgmt)       │
├─────────────────────────────────────────┤
│ • supermarketsProvider (List<Supermarket>)
│ • categoriesProvider (List<Category>)    
│ • supermarketByIdProvider                
│ • visibleCategoriesProvider              
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Sync-Aware Repositories (Notifiers)    │
├─────────────────────────────────────────┤
│ • SupermarketRepositoryWithSync          
│ • CategoryRepositoryWithSync             
│   (with SyncRepositoryMixin)             
└──────────────┬──────────────────────────┘
               │
        ┌──────┴─────────┐
        │                │
   ┌────▼─────┐   ┌─────▼─────┐
   │  SQLite  │   │  Sync Box  │
   │  (Local) │   │  (Queue)   │
   └──────────┘   └─────┬──────┘
                        │
              ┌─────────▼─────────┐
              │   SyncManager     │
              │ (Orchestrator)    │
              ├───────────────────┤
              │ • Push Engine     │
              │ • Pull Engine     │
              │ • Connectivity    │
              │   Monitor         │
              └─────────┬─────────┘
                        │
                  ┌─────▼─────┐
                  │ Firestore │
                  │  (Remote) │
                  └───────────┘
```

### Key Components

#### 1. **Models**
- **Supermarket** (`lib/models/supermarket.dart`)
  - `id`: Unique identifier
  - `_name`: Supermarket name
  - `_categories`: List of categories (ordered)
  - `isVisible`: Soft delete flag
  - `createdAt`, `lastModified`: Timestamps

- **Category** (`lib/models/category.dart`)
  - `id`: Unique identifier
  - `_name`: Category name
  - `isDefault`: Flag for default categories from JSON
  - `isVisible`: Soft delete flag (not actually deleted)
  - `createdAt`, `lastModified`: Timestamps

#### 2. **Providers (State Management)**
- **supermarketsProvider**: Watches AsyncValue<List<Supermarket>>
- **categoriesProvider**: Watches AsyncValue<List<Category>>
- **supermarketByIdProvider**: Family provider for single supermarket lookup
- **visibleCategoriesProvider**: Returns only visible (non-deleted) categories
- **supermarketCategoriesProvider**: Family provider for categories in a supermarket

#### 3. **Sync-Aware Repositories**
- **SupermarketRepositoryWithSync** 
  - Extends `SyncRepositoryMixin`
  - Implements `SyncRepository` interface
  - All user operations append to sync_box
  - Remote updates bypass sync_box (silent)

- **CategoryRepositoryWithSync**
  - Similar pattern to SupermarketRepositoryWithSync
  - Note: Categories are never actually deleted, only marked invisible

#### 4. **Screens**
- **supermarkets_screen_mobile.dart**: List view with favorite/edit buttons
- **supermarket_customization_screen.dart**: Edit name, reorder/add/remove categories
- **category_selection_screen.dart**: Batch add categories to supermarket
- **category_editing_screen.dart**: Create or edit category names

#### 5. **Database**
- **Tables**:
  - `supermarket`: Core supermarket data
  - `category`: All categories (never deleted, only marked invisible)
  - `supermarket_category`: M:N relationship with order_index
  - `sync_box`: Pending sync operations (managed by sync-engine)

## Features Implemented

### ✅ Supermarket Management

- [x] List supermarkets with name and category count
- [x] Favorite/star button (UI ready, logic pending)
- [x] Edit button to customize supermarket
- [x] Add button (+) to create new supermarket
- [x] Dialog to enter supermarket name
- [x] Default supermarket created on first launch
- [x] Supermarkets initialized with last created supermarket's categories
- [x] Soft delete (mark as invisible)
- [x] Name editing with auto-save
- [x] Category reordering with drag handles
- [x] Category addition/removal UI
- [x] All changes synced to Firestore

### ✅ Category Management

- [x] Default categories loaded from JSON asset
- [x] 17 default categories defined
- [x] Categories marked as visible/invisible (soft delete)
- [x] Category creation with name input
- [x] Category editing/renaming
- [x] Categories never physically deleted (maintains consistency)
- [x] Batch add categories to supermarket
- [x] Filter available categories (not in supermarket)
- [x] All changes synced to Firestore

### ✅ Synchronization

- [x] All operations use sync-aware repositories
- [x] Automatic sync to Firestore via sync-engine
- [x] SyncManager provider updated to refresh UI on remote changes
- [x] User-initiated writes append to sync_box
- [x] Remote updates apply silently (no sync_box loop)
- [x] Last-Write-Wins (LWW) conflict resolution
- [x] Monotonic timestamps for causality tracking

### ✅ Data Persistence

- [x] SQLite for local offline-first storage
- [x] Database schema v3 with is_visible column
- [x] Schema migration for existing installations
- [x] Categories and supermarkets stored in M:N relationship
- [x] Category order preserved via order_index

## File Structure

```
lib/
├── models/
│   ├── supermarket.dart          (Updated with visibility tracking)
│   ├── category.dart             (Updated with visibility tracking)
│   └── ...
├── screens/supermarket/
│   ├── supermarkets_screen_mobile.dart
│   ├── supermarket_customization_screen.dart
│   ├── category_selection_screen.dart
│   └── category_editing_screen.dart
├── providers/real_app_providers/
│   ├── supermarkets_notifier.dart        (NEW)
│   ├── categories_notifier.dart          (NEW)
│   └── sync_manager_provider.dart        (Updated)
├── repositories/sync/
│   ├── supermarket_repository_sync.dart  (Existing)
│   ├── category_repository_sync.dart     (Existing)
│   └── ...
├── services/
│   ├── database/sqlite/
│   │   ├── database_helper.dart          (Updated: v3 schema)
│   │   └── manage_supermarket.dart       (Methods for reordering)
│   └── mock/mock_data_seed.dart          (Updated: load default categories)
├── utils/
│   └── default_categories_loader.dart    (NEW)
└── ...

assets/
└── data/
    └── default_categories.json           (NEW)

pubspec.yaml                              (Updated: asset path added)
```

## Testing Guide

### Manual Testing

#### Test 1: First Launch (Default Supermarket)
1. Clear app data / fresh install
2. Launch app
3. Navigate to Supermarkets screen
4. **Expected**: Default "Supermarket" with 17 categories visible
5. Verify categories match the JSON file

#### Test 2: Create New Supermarket
1. Click "+" button
2. Enter "My Market"
3. **Expected**: New supermarket created with same 17 categories
4. Verify it appears in the list

#### Test 3: Customize Supermarket
1. Click edit (pencil) on a supermarket
2. Change name to "New Name"
3. **Expected**: Name updates immediately (auto-save)
4. Delete a category using the "-" button
5. **Expected**: Category removed from this supermarket only
6. Drag a category to reorder
7. **Expected**: Order persists and syncs

#### Test 4: Add Categories
1. In customization screen, click "+"
2. Select multiple categories with checkboxes
3. Click "Add"
4. **Expected**: Categories added to supermarket

#### Test 5: Create New Category
1. In category selection screen, click "+" in AppBar
2. Enter category name "New Aisle"
3. Click "Create Category"
4. **Expected**: Category created and available for selection

#### Test 6: Sync Verification
1. Make changes to supermarket/categories
2. Switch to another screen and back
3. **Expected**: Changes visible (local sync works)
4. With Firebase enabled, verify data appears in Firestore
5. (Multi-device test) Open app on different device
6. **Expected**: Changes sync from Firestore

#### Test 7: Offline Functionality
1. Disable network connectivity
2. Create/modify supermarkets or categories
3. **Expected**: Changes saved locally
4. Re-enable network
5. **Expected**: Changes auto-sync to Firestore

### Unit Tests (TODO)

```dart
// Test supermarkets_notifier.dart
test('addSupermarket adds to list', () async {
  // Verify supermarket appears in list
  // Verify sync_box entry created
});

test('updateSupermarket updates existing', () async {
  // Verify name change persists
  // Verify timestamp updated
});

test('reorderCategories preserves order', () async {
  // Verify category order in database
  // Verify sync_box marked dirty
});

// Test categories_notifier.dart
test('addCategory creates visible by default', () async {
  // Verify isVisible = true
});

test('deleteCategory marks invisible', () async {
  // Verify isVisible = false
  // Verify not in visible categories
  // Verify still in database
});

test('visibleCategoriesProvider filters correctly', () async {
  // Verify only isVisible=true categories returned
});

// Test sync repositories
test('SupermarketRepositoryWithSync.add appends to sync_box', () async {
  // Verify sync_box entry created
});

test('SupermarketRepositoryWithSync.applyRemoteUpdate does not append sync_box', () async {
  // Verify sync_box NOT modified
  // Verify LWW logic works
});
```

## Unresolved Problems & Next Steps

### 1. **Favorite/Star Feature** ⏳
**Status**: UI ready, logic not implemented
**Issue**: No persistence layer for favorite supermarkets
**Next Step**: 
- Add `isFavorite` boolean to Supermarket model
- Add UI toggle logic
- Persist to SQLite and sync

### 2. **Category Editing in Customization Screen** ⏳
**Status**: Pencil button present but routes to error
**Issue**: Click handler commented out
**Next Step**:
- Uncomment navigation to `CategoryEditingScreen`
- Pass category in edit mode
- Test category update flow

### 3. **Performance with Many Categories** ⏠
**Status**: Not tested at scale
**Issue**: Reorderable list might be slow with 100+ categories
**Next Steps**:
- Add pagination or virtual scrolling if needed
- Profile app performance
- Consider lazy loading strategies

### 4. **Search/Filter for Categories** 🔍
**Status**: Not implemented
**Issue**: User requested searching among 17 default categories
**Next Step**:
- Add search field in category_selection_screen
- Filter as user types
- Match on partial names

### 5. **Category Icons/Colors** 🎨
**Status**: Not implemented
**Issue**: UI mockup suggested visual differentiation
**Next Step**:
- Add color/icon fields to Category model
- UI for selecting icon/color during creation
- Display in category lists

### 6. **Bulk Operations** 📦
**Status**: Not implemented
**Issue**: Removing/reordering many categories is tedious
**Next Step**:
- Add "select all" checkbox
- Batch delete / batch move to another supermarket
- Undo/redo functionality

### 7. **Import/Export Supermarket Configs** 💾
**Status**: Not implemented
**Issue**: Users can't share supermarket layouts
**Next Step**:
- Export supermarket config as JSON/file
- Import from file
- Share via social features

### 8. **Database Migration Edge Cases** 🔄
**Status**: Basic migration implemented
**Issue**: Might not handle concurrent installs
**Next Step**:
- Test migration on devices with various DB versions
- Add robust error handling
- Document rollback procedures

### 9. **Firestore Schema** 📋
**Status**: Assumed (not explicitly defined)
**Issue**: Category IDs in supermarket need structure definition
**Suggested Schema**:
```dart
// In Firestore: Users/{uid}/Supermarkets/{supermarketId}
{
  id: string,
  name: string,
  categoryIds: [string],  // Ordered array
  isVisible: boolean,
  createdAt: timestamp,
  lastModified: timestamp
}

// In Firestore: Users/{uid}/Categories/{categoryId}
{
  id: string,
  name: string,
  isDefault: boolean,
  isVisible: boolean,
  createdAt: timestamp,
  lastModified: timestamp
}
```

### 10. **Error Handling & User Feedback** ⚠️
**Status**: Basic snackbars present
**Issue**: Limited feedback for sync errors
**Next Steps**:
- Show sync status indicator
- Notify on sync failures
- Retry mechanisms
- Conflict resolution UI for LWW collisions

## Architecture Decisions Explained

### Why Soft Delete (Invisible Flag)?
- **Consistency**: References in statistics and historical data remain valid
- **Recovery**: User can "restore" deleted items if needed
- **Simplicity**: No need to cascade delete or handle orphaned references
- **Data Integrity**: Past purchases linked to categories remain queryable

### Why Categories in M:N Relationship?
- **Flexibility**: Allows future reuse patterns (categories by product type, by preference, etc.)
- **Order**: order_index enables user-customized ordering per supermarket
- **Scalability**: Doesn't duplicate category data across supermarkets

### Why Sync-Aware Repositories?
- **Automatic Sync**: All data changes automatically queued for Firestore
- **Offline-First**: Works seamlessly without network
- **Conflict Resolution**: LWW prevents overwrites of newer remote data
- **Consistency**: Single repository pattern prevents divergent data access

### Why Load Default Categories from JSON?
- **Immutable Defaults**: JSON never changes, ensuring consistency
- **Smaller App Size**: Categories embedded, not fetched on startup
- **Performance**: Instant loading on first launch
- **Translatable**: JSON can be localized for different languages

## Integration Checklist

- [x] Models updated with visibility tracking
- [x] Database schema v3 with migrations
- [x] Default categories JSON created
- [x] All 4 screens implemented
- [x] Riverpod providers created
- [x] Sync repositories configured
- [x] SyncManager provider updated for UI refresh
- [x] Mock data seed updated
- [x] Asset path added to pubspec.yaml
- [ ] Unit tests written
- [ ] Integration tests written
- [ ] Firebase Firestore rules defined
- [ ] Production testing completed
- [ ] Localization for categories (future)
- [ ] Performance benchmarking (future)

## Quick Start for Developers

### Running the Screens

```dart
// Navigate to Supermarkets screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const SupermarketsScreenMobile(),
  ),
);
```

### Accessing Data Programmatically

```dart
// In a ConsumerWidget
final supermarkets = ref.watch(supermarketsProvider);
final categories = ref.watch(categoriesProvider);

// Get a specific supermarket
final supermarket = ref.watch(
  supermarketByIdProvider('supermarket-id')
);

// Get visible categories only
final visible = ref.watch(visibleCategoriesProvider);
```

### Performing Operations

```dart
// Add supermarket
await ref.read(supermarketsProvider.notifier)
  .addSupermarket(newSupermarket);

// Update supermarket
await ref.read(supermarketsProvider.notifier)
  .updateSupermarket(updatedSupermarket);

// Add category
await ref.read(categoriesProvider.notifier)
  .addCategory(newCategory);

// Delete (mark invisible)
await ref.read(categoriesProvider.notifier)
  .deleteCategory(categoryId);

// Reorder categories
await ref.read(supermarketsProvider.notifier)
  .reorderCategories(supermarketId, reorderedList);
```

## References

- Sync Engine Documentation: `documents/sync-engine-doc/`
- App Architecture: UI → Controllers → Repositories → Services
- State Management: Riverpod with AsyncValue
- Database: SQLite local, Firestore remote
- Sync: Custom sync-engine with offline-first + LWW

---

**Implementation Status**: ✅ Core features complete
**Next Priority**: Unit tests, Firebase rules, production testing
**Last Updated**: January 30, 2026
