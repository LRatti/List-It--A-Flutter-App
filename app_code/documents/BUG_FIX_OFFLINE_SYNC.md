# Bug Fix: Shopping List Not Synced When Created Offline

## Problem Description

When a user:
1. Goes offline
2. Creates a new shopping list
3. Comes back online

The newly created shopping list is **NOT** pushed to Firebase, even though the app should sync it.

## Root Cause

The bug is in the pull sync engine's `_silentUpdate()` method. There was a critical TODO comment that was never implemented:

**File**: [lib/services/sync/sync_engine_pull.dart](lib/services/sync/sync_engine_pull.dart#L252-L254)

```dart
// Check if entity is dirty (exists in sync_box)
// IF EXISTS: IGNORE the incoming update to preserve local changes
// TODO: Implement this check by calling ManageSyncBox.isEntityDirty()
// For now, we'll note that repositories should implement this internally
```

### What Happens

**Scenario: User offline → creates list → comes online**

1. **User is offline** → Creates shopping list
   - List is inserted into SQLite
   - Entry is added to sync_box with timestamp T1
   - Push sync can't run (no connectivity)

2. **User comes online**
   - SyncManager's connectivity listener detects connection
   - `_triggerSync()` is called
   - Push sync tries to sync the list to Firebase
   - **Meanwhile**, the pull sync initializes with live listeners
   - Live listeners set up snapshot subscriptions for all entity types

3. **Pull sync applies silent updates**
   - The live snapshot listener fires (even for local docs that haven't been pushed yet)
   - `_silentUpdate()` is called for the shopping list
   - **BUG**: There's NO check to see if the entity is dirty (in sync_box)
   - The pull sync might apply an empty or outdated remote state
   - Or worse, it might overwrite the local version before push can sync it

4. **Result**: The shopping list is marked as "synced" locally but never actually pushed to Firebase

## Solution

### Implement the Missing Dirty Check

**File**: [lib/services/sync/sync_engine_pull.dart](lib/services/sync/sync_engine_pull.dart)

Added the critical dirty state check in `_silentUpdate()`:

```dart
// CRITICAL: Check if entity is dirty (exists in sync_box)
// If entity has pending changes waiting to be synced, IGNORE the incoming remote update
// to preserve local changes that haven't been pushed yet.
// This prevents the pull from overwriting items created while offline before they can be pushed.
final isDirty = await ManageSyncBox.isEntityDirty(entityId, entityType);
if (isDirty) {
  _logger.d('SyncEnginePull: Entity $entityType/$entityId is dirty (pending sync), ignoring remote update to preserve local changes');
  return;
}
```

Also added the required import:
```dart
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
```

## How It Works (After Fix)

### Scenario: User offline → creates list → comes online

1. **User is offline** → Creates shopping list
   - List is inserted into SQLite
   - Entry is added to sync_box (marked as dirty)

2. **User comes online**
   - Connectivity restored
   - SyncManager triggers sync
   - Pull sync initializes live listeners

3. **Pull sync checks dirty state** ✅
   - Live listener fires for shopping list
   - `_silentUpdate()` checks: `ManageSyncBox.isEntityDirty(listId, 'shopping_list')`
   - Returns `true` (entry exists in sync_box)
   - **Ignores** the remote update to preserve local changes

4. **Push sync proceeds undisturbed** ✅
   - Push engine processes the sync_box entry
   - Pushes the shopping list to Firebase
   - Marks the sync_box entry as synced (deletes it)

5. **Result**: Shopping list successfully synced to Firebase ✓

## Files Modified

1. [lib/services/sync/sync_engine_pull.dart](lib/services/sync/sync_engine_pull.dart)
   - Added import for `ManageSyncBox`
   - Implemented the dirty state check in `_silentUpdate()`
   - Replaced TODO comment with actual implementation

## Why This Matters

This fix ensures the **critical invariant** of the sync system:

> **Local changes take priority over remote updates until they are successfully synced**

Without this check, the pull sync can interfere with pending local changes, breaking the offline-first architecture.

## Testing

To verify the fix works:

1. Start the app and sign in
2. Disconnect from the internet (turn off WiFi/cellular)
3. Create a new shopping list
4. Verify it appears in the local list
5. Check that an entry exists in the sync_box table (database inspection)
6. Reconnect to the internet
7. Wait for sync to complete (or trigger manual sync)
8. Check Firebase Firestore:
   - Navigate to: `Users/{userId}/shopping_list/{listId}`
   - The shopping list should be present with all correct data

## Related Issues

This fix complements the previous auth-state fix ([BUG_FIX_LOGOUT_SYNC.md](BUG_FIX_LOGOUT_SYNC.md)) by ensuring proper offline sync behavior in all scenarios.

Both fixes together ensure:
1. ✅ Auth state changes properly invalidate and reinitialize the sync manager
2. ✅ Items created while offline are protected from pull sync interference
3. ✅ Push sync can reliably sync pending changes when connectivity is restored
4. ✅ No data loss in offline-first scenarios
