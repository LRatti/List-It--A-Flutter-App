# Bug Fix: Shopping List Not Synced After Logout/Login

## Problem Description

When a user:
1. Logs in
2. Logs out
3. Creates a new shopping list (while logged out as anonymous user)
4. Logs back in

The newly created shopping list is **NOT** propagated to Firebase, even though other data syncs correctly.

## Root Cause

The bug has two parts:

### Part 1: SyncManager Not Invalidated on Auth State Change
- The `syncManagerProvider` FutureProvider doesn't depend on the auth state
- When the user logs out → back in, the same SyncManager instance is reused
- This old instance has outdated state and may be using old Firestore user paths

### Part 2: Stale `lastSyncedAt` Timestamp
- When SyncManager initializes for a new user, it uses the `lastSyncedAt` timestamp from SharedPreferences
- This timestamp was set during the *previous* user session
- During the cold-start sync, the query filters: `lastModified > lastSyncedAt`
- Items created while the user was logged out may have timestamps newer than the stale `lastSyncedAt`, but the sync still fails because:
  - The push sync tries to write to the wrong Firestore path (old user ID)
  - The SyncManager hasn't been properly reset

## Solution

### Fix 1: Invalidate SyncManager on Auth State Change
**File**: [lib/providers/real_app_providers/sync_manager_provider.dart](lib/providers/real_app_providers/sync_manager_provider.dart)

Added a new `currentUserIdProvider` that tracks the authenticated user's ID. The `syncManagerProvider` now depends on this provider:

```dart
// Tracks the current authenticated user ID to detect auth state changes
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.whenData((user) => user?.uid).value;
});

// syncManagerProvider now watches currentUserIdProvider
final syncManagerProvider = FutureProvider<SyncManager>((ref) async {
  // Watch the current user ID - when this changes, this provider will be invalidated
  final currentUserId = ref.watch(currentUserIdProvider);
  
  // ... rest of initialization
});
```

**Effect**: 
- When `authProvider` updates (user logs in/out), `currentUserIdProvider` changes
- This automatically invalidates `syncManagerProvider`
- The old SyncManager is disposed and a new one is created
- This forces a fresh initialization with the new user context

### Fix 2: Reset `lastSyncedAt` During Initialization
**File**: [lib/services/sync/sync_manager.dart](lib/services/sync/sync_manager.dart)

In the `initialize()` method, added:

```dart
// CRITICAL FIX: Reset lastSyncedAt for each initialization
// This ensures a clean cold-start sync when the user logs in/out or switches accounts.
// Without this, the sync engine would use stale timestamps from previous user sessions.
_prefs.remove('lastSyncedAt');
_logger.i('SyncManager: Reset lastSyncedAt to enable full cold-start sync');
```

**Effect**:
- Every time SyncManager initializes, `lastSyncedAt` is reset to null
- The cold-start sync uses `DateTime(2000)` as the default timestamp
- This ensures ALL remote data (from the new user's perspective) is pulled
- Ensures items created while logged out are properly synced

## How It Works (After Fix)

### Scenario: User logs out, creates a list, logs back in

1. **User logs in** → SyncManager initializes with clean state
2. **User logs out** 
   - `authProvider` updates (user becomes anonymous)
   - `currentUserIdProvider` changes (uid changes from "user1" to "anonXXX")
   - `syncManagerProvider` is automatically invalidated
   - Old SyncManager is disposed
3. **User creates shopping list** (while logged out as "anonXXX")
   - List is stored locally with `lastModified = now`
   - Entry is added to sync_box
4. **User logs back in** (as "user1" again, or different account "user2")
   - `currentUserIdProvider` changes again
   - `syncManagerProvider` is invalidated (creates NEW SyncManager)
   - SyncManager.initialize() runs:
     - **Resets `lastSyncedAt`** to null
     - Pulls all remote data (cold start from year 2000)
     - Sets up live listeners
     - Starts periodic push sync
   - Push sync processes the pending shopping list
   - List is written to Firebase under the correct user path

## Files Modified

1. [lib/providers/real_app_providers/sync_manager_provider.dart](lib/providers/real_app_providers/sync_manager_provider.dart)
   - Added `currentUserIdProvider`
   - Modified `syncManagerProvider` to depend on `currentUserIdProvider`

2. [lib/services/sync/sync_manager.dart](lib/services/sync/sync_manager.dart)
   - Added `_prefs.remove('lastSyncedAt')` in `initialize()`

## Testing

To verify the fix works:

1. Start the app (logs in / anonymous)
2. Log in with a test account (or skip if already logged in)
3. Log out (returns to anonymous)
4. Create a shopping list
5. Log back in (can be same or different account)
6. Check Firebase Firestore:
   - Navigate to: `Users/{userId}/shopping_list`
   - The shopping list created while logged out should be present
   - It should have the correct structure and timestamps

## Notes

- The fix maintains backward compatibility
- No database migrations needed
- The reset of `lastSyncedAt` is safe and intentional
- It's better to pull extra data than to miss syncing important changes
- For large datasets, the initial cold-start sync might take longer, but this only happens on fresh initialization
