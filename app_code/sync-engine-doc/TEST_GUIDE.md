# Sync Engine Test Guide

This guide validates the current sync implementation end-to-end and highlights common failure points.

## 0) Preflight Checks (5–10 min)
- Ensure Firebase Auth is working and a user is signed in.
- Confirm Firestore collections exist at Users/{uid}/{entityType}.
- Verify each document has lastModified and isDeleted fields.
- Confirm SQLite schema includes last_modified and is_deleted in all synced tables.

## 1) Smoke Test (Local Only)
- Launch app offline.
- Create, update, and delete one item in each entity type.
- Confirm UI reads are from SQLite and no crashes occur.

## 2) Offline Write Queue
- Stay offline.
- Create 2–3 items, update one, delete one.
- Ensure sync_box receives entries (upsert/delete) for each action.
- Restart the app while still offline and confirm entries persist.

## 3) Online Push Sync
- Go online.
- Confirm sync_box drains and documents appear in Firestore.
- Validate lastModified values in Firestore are server timestamps.

## 4) Remote Pull Sync (Cold Start)
- Kill the app.
- Modify data directly in Firestore (add/update/delete).
- Relaunch the app.
- Verify SQLite reflects remote changes and soft deletes are handled.

## 5) Remote Pull Sync (Live Listener)
- With the app running, update a Firestore doc from another device.
- Confirm local SQLite updates without creating sync_box entries.

## 6) Conflict Resolution (LWW)
- On device A (offline), update an entity.
- On device B (online), update the same entity.
- Bring device A online and verify last-write-wins behavior.
- Confirm older local changes do not override newer remote data.

## 7) Dirty State Protection
- While offline, update an entity locally (creates sync_box entry).
- While still offline, update the same entity in Firestore.
- Reconnect and verify local pending change is preserved until pushed.

## 8) Soft Delete Flow
- Delete an entity locally (soft delete).
- Reconnect and verify Firestore isDeleted becomes true.
- Confirm local physical delete occurs only after remote echo.

## 9) Cascading Deletes
- Delete a parent (e.g., shopping_list).
- Ensure child records (purchased_product) are deleted locally.
- Validate no orphan rows remain.

## 10) Crash Recovery
- Start a sync, then force close the app during push.
- Restart and confirm pending entries remain and sync resumes.

## 11) Performance Spot Check
- Create 100+ entities offline.
- Reconnect and ensure sync completes without timeouts.

## Expected Signals
- sync_box drains to zero after successful push.
- lastSyncedAt updates in SharedPreferences after pull.
- Firestore lastModified uses server time.
- No sync_box entries created by applyRemoteUpdate.

## If Something Fails
- Check logs in SyncEnginePush and SyncEnginePull.
- Validate field names mapping (lastModified vs last_modified).
- Confirm registry contains all entity types.
- Verify soft deletes are mapped to isDeleted and is_deleted consistently.
