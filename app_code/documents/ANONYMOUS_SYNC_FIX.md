# Anonymous User Sync Fix - Complete Implementation

## Problem Statement
The sync engine was pushing data to Firestore even when the user was not logged in (anonymous user). This created unwanted data accumulation in Firestore for users who were just browsing anonymously.

**Desired Behavior:**
- ✅ **Anonymous users**: Data saved locally only (SQLite)
- ✅ **Authenticated users**: Data synced to Firestore
- ✅ **Login transition**: When anonymous user logs in, pending local changes are pushed to Firestore

## Solution Overview

The fix implements three key changes to the sync engine:

### 1. **SyncEnginePush** - Prevent anonymous users from pushing to Firestore
**File**: `lib/services/sync/sync_engine_push.dart`

**Change**: Added anonymous check in `processPendingSync()` method:
```dart
// Skip push sync for anonymous users
// Anonymous users should only save data locally; sync to Firestore after login
if (user.isAnonymous) {
  _logger.d('SyncEngine: User is anonymous, skipping Firestore push (data saved locally only)');
  return;
}
```

**Effect**: 
- When `processPendingSync()` is called periodically (every 10 seconds), it immediately returns if the user is anonymous
- Pending sync entries remain in the `sync_box` table (SQLite) waiting for the user to log in
- No Firestore writes occur for anonymous users

### 2. **SyncEnginePull** - Prevent anonymous users from pulling from Firestore
**File**: `lib/services/sync/sync_engine_pull.dart`

**Change A**: Added anonymous check in `_coldStartSync()` method:
```dart
// Skip pull sync for anonymous users
// Anonymous users should only work with local data
if (user.isAnonymous) {
  _logger.d('SyncEnginePull: User is anonymous, skipping cold start (local data only)');
  return;
}
```

**Change B**: Added anonymous check in `_setupLiveListeners()` method:
```dart
// Skip live listeners for anonymous users
// Anonymous users should only work with local data
if (user.isAnonymous) {
  _logger.d('SyncEnginePull: User is anonymous, skipping live listeners (local data only)');
  return;
}
```

**Effect**:
- Anonymous users don't receive updates from other devices/cloud
- Their local SQLite database contains only data they created locally
- No wasted Firestore bandwidth listening to remote changes

### 3. **SyncManager Provider** - Trigger sync when anonymous user logs in
**File**: `lib/providers/real_app_providers/sync_manager_provider.dart`

**Change A**: Added new provider to track authentication status:
```dart
/// Tracks the current user's authentication status (anonymous vs authenticated)
/// Used to detect when a user logs in from anonymous state
final currentUserAuthStatusProvider = Provider<({String? uid, bool isAnonymous})>((ref) {
  final authState = ref.watch(authProvider);
  return authState.whenData((user) {
    if (user == null) {
      return (uid: null, isAnonymous: false);
    }
    return (uid: user.uid, isAnonymous: user.isAnonymous);
  }).value ?? (uid: null, isAnonymous: false);
});
```

**Change B**: Enhanced `syncManagerProvider` to trigger post-login sync:
```dart
// Also watch auth status to detect anonymous -> authenticated transitions
final authStatus = ref.watch(currentUserAuthStatusProvider);

// ... initialize sync manager ...

// If user just transitioned from anonymous to authenticated,
// trigger a manual sync to push pending changes that were queued while offline
if (currentUserId != null && !authStatus.isAnonymous) {
  // Small delay to ensure Firestore user document structure is ready
  await Future.delayed(const Duration(milliseconds: 200));
  
  try {
    // Trigger a manual sync to push any pending local changes to Firestore
    await syncManager.triggerManualSync();
    Logger().i('SyncManager: Post-login sync triggered to push queued changes');
  } catch (e) {
    Logger().w('SyncManager: Post-login sync error (non-fatal)', error: e);
  }
}
```

**Effect**:
- When an anonymous user logs in, the `syncManagerProvider` detects the auth status change
- A manual sync is triggered which processes all pending sync entries in `sync_box`
- These entries are now pushed to Firestore since the user is no longer anonymous
- The sync manager is automatically re-initialized with `lastSyncedAt` reset for proper cold-start sync

## Data Flow - Before vs After

### Before Fix (Broken)
```
Anonymous User Creates Shopping List
  ↓
SQLite: Saves locally ✓
  ↓
sync_box: Queue entry created ✓
  ↓
SyncEnginePush: Pushes to Firestore ✗ (WRONG - shouldn't happen)
  ↓
Firestore: Shopping list data saved ✗ (WRONG - pollutes cloud)
```

### After Fix (Correct)
```
Anonymous User Creates Shopping List
  ↓
SQLite: Saves locally ✓
  ↓
sync_box: Queue entry created ✓
  ↓
SyncEnginePush: Checks isAnonymous, returns early ✓
  ↓
Firestore: No change ✓
  ↓
User Logs In
  ↓
Auth state changes (anonymous → authenticated)
  ↓
syncManagerProvider detects change
  ↓
triggerManualSync() called
  ↓
SyncEnginePush: Checks isAnonymous (now false), processes entries ✓
  ↓
Firestore: Shopping list data synced ✓
```

## Testing Checklist

- [ ] **Anonymous browsing**: Create a shopping list without logging in
  - Verify: SQLite has the list, sync_box has entry, Firestore is empty
  
- [ ] **Login transition**: Log in from anonymous state
  - Verify: Data appears in Firestore within a few seconds
  - Verify: Log shows "Post-login sync triggered"
  
- [ ] **No Firestore pollution**: Browse anonymously for 5+ minutes
  - Verify: Firestore Users collection has no new entries
  - Verify: Logs show "User is anonymous, skipping Firestore push"
  
- [ ] **Data integrity**: Add items while anonymous, log in, add more items
  - Verify: All items appear in Firestore
  - Verify: sync_box is eventually empty (entries cleaned up)
  
- [ ] **Multiple devices**: Anonymous on device A, log in, verify data appears
  - Verify: Other authenticated devices see the data
  - Verify: Live listeners pick up the new items

## Implementation Notes

1. **Lazy Initialization**: The sync manager initializes lazily on first access in `MyApp.build()`
2. **Automatic Invalidation**: When auth state changes, `syncManagerProvider` is automatically invalidated and recreated by Riverpod
3. **Clean State**: Each new SyncManager instance resets `lastSyncedAt` to enable proper cold-start sync
4. **Non-blocking**: Post-login sync is wrapped in try-catch to prevent UI blocking even if sync fails
5. **Backward Compatible**: No database schema changes needed; existing anonymous data in sync_box will sync when user logs in

## Related Files Modified

1. `lib/services/sync/sync_engine_push.dart` - Added isAnonymous check
2. `lib/services/sync/sync_engine_pull.dart` - Added isAnonymous checks (2 locations)
3. `lib/providers/real_app_providers/sync_manager_provider.dart` - Added auth status tracking and post-login sync trigger

## Monitoring & Logging

Key log messages to look for:

```
// Anonymous user skipping sync
"SyncEngine: User is anonymous, skipping Firestore push (data saved locally only)"
"SyncEnginePull: User is anonymous, skipping cold start (local data only)"
"SyncEnginePull: User is anonymous, skipping live listeners (local data only)"

// Post-login sync triggered
"SyncManager: Post-login sync triggered to push queued changes"

// Actual sync happening
"SyncManager: Triggering sync cycle"
"SyncEngine: Processing X pending sync entries"
```

## Future Enhancements

1. **Selective Sync**: Allow users to choose which data to keep offline vs cloud
2. **Sync Conflict UI**: If a local document and remote document conflict, show user a choice
3. **Offline Indicator**: Show visual indicator when sync is blocked (anonymous mode)
4. **Export**: Allow users to export anonymous browsing data before logging in
