# Sync Engine Implementation Checklist

## ✅ Core Infrastructure (COMPLETE)

- [x] SQLite schema updated with `sync_box` table
- [x] `SyncOperation` enum created
- [x] `LocalSyncEntry` model created with database serialization
- [x] `ManageSyncBox` database helper implemented
- [x] `SyncRepository` abstract class defined
- [x] `SyncRepositoryMixin` for common sync operations
- [x] `MonotonicTimestamp` utility for timestamp generation
- [x] `SyncEnginePush` (Local → Remote) implemented
- [x] `SyncEnginePull` (Remote → Local) implemented with cold start + live listeners
- [x] `ConnectivityMonitor` for offline awareness
- [x] `SyncManager` orchestrator created
- [x] Riverpod provider integration (`sync_manager_provider.dart`)
- [x] Main.dart updated to initialize sync
- [x] `connectivity_plus` added to pubspec.yaml
- [x] Example repository implementation (`shopping_list_repository_sync.dart`)
- [x] Comprehensive documentation (SYNC_ENGINE_GUIDE.md, SYNC_ENGINE_README.md)

## ⚠️ CRITICAL - Repository Integration (MUST DO NEXT)

### Shopping List Repository
- [ ] Update `lib/repositories/real_app_repo/shopping_list_repository_db.dart`
  - [ ] Implement `SyncRepository` interface
  - [ ] Add `SyncRepositoryMixin`
  - [ ] Update `add()` to call `appendUpsertToSyncBox()`
  - [ ] Update `update()` to use `MonotonicTimestamp` and `appendUpsertToSyncBox()`
  - [ ] Update `delete()` to set `isDeleted=1` and call `appendDeleteToSyncBox()`
  - [ ] Implement `applyRemoteUpdate()` with silent update logic
  - [ ] Implement `getLocalData()` and `getEntityType()`
  - [ ] Filter queries to exclude soft-deleted items (`is_deleted = 0`)

### Product Repository
- [ ] Create/Update product repository implementation
  - [ ] Implement `SyncRepository`
  - [ ] Add sync operations in write methods
  - [ ] Implement `applyRemoteUpdate()`
  - [ ] Filter soft-deleted products

### Purchased Product Repository
- [ ] Create/Update purchased product repository
  - [ ] Implement `SyncRepository`
  - [ ] Add sync operations
  - [ ] Implement `applyRemoteUpdate()`
  - [ ] Handle cascading deletes when parent list is deleted

### Category Repository
- [ ] Update category repository
  - [ ] Implement `SyncRepository`
  - [ ] Add sync operations
  - [ ] Implement `applyRemoteUpdate()`

### Supermarket Repository
- [ ] Update supermarket repository
  - [ ] Implement `SyncRepository`
  - [ ] Add sync operations
  - [ ] Implement `applyRemoteUpdate()`

### User Repository (if synced)
- [ ] [ ] Evaluate if user data should be synced
  - [ ] If yes: implement `SyncRepository`

## 📋 Registration & Setup

- [ ] Register all repositories in `syncRepositoryRegistryProvider`
  - [ ] Update `lib/providers/real_app_providers/sync_manager_provider.dart`
  - [ ] Map each entity type to repository instance
  - [ ] Verify all synced entities are registered

## 🗄️ Database Schema Updates

- [ ] Add `lastModified` column to all synced tables (if not present)
  - [ ] `shopping_list`
  - [ ] `product`
  - [ ] `purchased_product`
  - [ ] `category`
  - [ ] `supermarket`
  - [ ] Schema migration or re-initialization

- [ ] Ensure `isDeleted` column exists on tables supporting soft deletes
  - [ ] `shopping_list`
  - [ ] `purchased_product`

- [ ] Disable foreign keys for synced tables (handle cascades in repositories)
  - [ ] `associations` table
  - [ ] `supermarket_category` table
  - [ ] Any other child tables of synced entities

## 🔄 Model Updates

- [ ] Ensure all synced models have required fields:
  - [ ] `createdAt` (DateTime)
  - [ ] `lastModified` (DateTime)
  - [ ] `isDeleted` (bool) - for deletable entities
  
- [ ] Update `toDatabase()` methods to include sync fields
- [ ] Update `fromDatabase()` constructors to parse sync fields
- [ ] Add field name mapping helpers (Firebase → SQLite)

Models to update:
- [ ] `ShoppingList`
- [ ] `Product`
- [ ] `PurchasedProduct`
- [ ] `Category`
- [ ] `Supermarket`
- [ ] `User`

## 🔌 Provider Updates

- [ ] Update all repository providers to use new sync-enabled implementations
- [ ] Ensure Riverpod providers watch SQLite directly
- [ ] Configure providers to invalidate on sync updates
- [ ] No direct Firestore queries from Riverpod providers

## 🔐 Firestore Schema

- [ ] Verify all synced documents have `lastModified` field
- [ ] Set `lastModified` to `FieldValue.serverTimestamp()` on create
- [ ] Set `lastModified` to `FieldValue.serverTimestamp()` on update
- [ ] Add `isDeleted` boolean field to deletable entities
- [ ] Organize collections under `Users/{uid}`:
  - [ ] `Users/{uid}/shopping_list`
  - [ ] `Users/{uid}/product`
  - [ ] `Users/{uid}/purchased_product`
  - [ ] `Users/{uid}/category`
  - [ ] `Users/{uid}/supermarket`
  - [ ] `Users/{uid}/user` (if synced)

- [ ] Update Firestore security rules to handle sync:
  ```
  match /Users/{uid}/{document=**} {
    allow read, write: if request.auth.uid == uid;
  }
  ```

## 🧪 Testing

### Unit Tests
- [ ] Test `MonotonicTimestamp.generateNext()`
- [ ] Test `MonotonicTimestamp.merge()`
- [ ] Test `LocalSyncEntry` serialization
- [ ] Test `ManageSyncBox` CRUD operations
- [ ] Test sync entry deduplication (newer timestamp wins)

### Integration Tests
- [ ] Test offline write (creates sync_box entry)
- [ ] Test sync push (sends to Firestore)
- [ ] Test sync pull (receives from Firestore)
- [ ] Test cold start delta sync
- [ ] Test live snapshot listeners
- [ ] Test LWW conflict resolution
- [ ] Test soft delete flow (local → sync → remote → physical delete)
- [ ] Test dirty state blocking (ignore remote if entity is dirty)
- [ ] Test crash recovery (sync_box persists)
- [ ] Test connectivity monitoring (reconnect triggers sync)

### E2E Tests
- [ ] Multi-device sync (edit on device A, see on device B)
- [ ] Offline-then-online workflow
- [ ] Rapid updates during connectivity issues
- [ ] Kill app during sync, restart
- [ ] Large batch syncing (>100 items)

## 📊 UI/UX Updates

- [ ] Add sync status indicator to UI
  - [ ] Show pending sync count
  - [ ] Show sync in progress
  - [ ] Show sync errors
  - [ ] Manual sync trigger button

- [ ] Update edit screens to show "pending sync" badge
- [ ] Disable delete button if sync in progress
- [ ] Show error toasts if sync fails
- [ ] Show success notification on sync complete (optional)

## 📚 Documentation

- [x] `SYNC_ENGINE_GUIDE.md` - Integration guide
- [x] `SYNC_ENGINE_README.md` - Architecture & implementation status
- [ ] Update project README with sync feature documentation
- [ ] Add architecture diagrams to documentation
- [ ] Document Firestore schema changes

## 🔍 Code Review

- [ ] Verify repositories correctly implement `SyncRepository`
- [ ] Check that all user writes append to sync_box
- [ ] Check that `applyRemoteUpdate()` never appends to sync_box
- [ ] Verify timestamp comparisons use `isAfter()` not `>`
- [ ] Verify soft delete logic (local flag → sync → remote → physical)
- [ ] Check error handling in sync engine
- [ ] Review connectivity monitoring logic
- [ ] Verify proper disposal of resources

## 🚀 Deployment

- [ ] Test on Android emulator
- [ ] Test on iOS simulator
- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Database migration strategy (add new columns to existing DB)
- [ ] Firestore rules deployment
- [ ] Monitor sync engine logs in production
- [ ] Monitor Firestore quota usage

## 📋 Final Verification

- [ ] All sync_box entries are processed and cleaned up
- [ ] No sync entries left behind after successful sync
- [ ] Sync errors are retried in next cycle
- [ ] UI properly reflects all changes (local and remote)
- [ ] No duplicate entries in SQLite
- [ ] Soft-deleted items don't appear in queries
- [ ] Multi-device changes merge correctly
- [ ] App works offline and syncs when online
- [ ] Crashes don't lose data

## 🎯 Success Criteria

✅ When all items above are complete, the sync engine is fully integrated and:
- User can edit offline and see changes when online
- Other devices receive changes in real-time
- Conflicts are resolved using last-write-wins
- Soft deletes work correctly
- App recovers gracefully from crashes
- No data loss in any scenario
- UI stays responsive during sync

---

**Start Date**: January 29, 2026  
**Target Completion**: TBD  
**Current Status**: Core infrastructure complete, awaiting repository integration
