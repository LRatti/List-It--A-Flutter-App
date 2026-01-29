import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

/// Database management class for the sync_box table
/// Handles all CRUD operations for local sync queue entries
class ManageSyncBox {
  /// Append or update a sync entry in the queue
  /// If an entry with the same entityId exists and has older lastModified,
  /// it will be replaced. Otherwise, it will be ignored.
  static Future<void> addOrUpdateSyncEntry(LocalSyncEntry entry) async {
    final db = await DatabaseHelper.database;

    // Check if entry already exists
    final existing = await db.query(
      'sync_box',
      where: 'entity_id = ? AND entity_type = ?',
      whereArgs: [entry.entityId, entry.entityType],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final existingEntry = LocalSyncEntry.fromDatabase(existing.first);
      // Only replace if new entry is newer
      if (entry.lastModified.isAfter(existingEntry.lastModified)) {
        await db.update(
          'sync_box',
          entry.toDatabase(),
          where: 'entity_id = ? AND entity_type = ?',
          whereArgs: [entry.entityId, entry.entityType],
        );
      }
      // If existing is newer or equal, ignore the new entry
      return;
    }

    // If no existing entry, insert the new one
    await db.insert(
      'sync_box',
      entry.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all pending sync entries, optionally filtered by entity type
  static Future<List<LocalSyncEntry>> getAllSyncEntries({
    String? entityType,
  }) async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> rows;
    if (entityType != null) {
      rows = await db.query(
        'sync_box',
        where: 'entity_type = ?',
        whereArgs: [entityType],
      );
    } else {
      rows = await db.query('sync_box');
    }

    return rows.map((row) => LocalSyncEntry.fromDatabase(row)).toList();
  }

  /// Retrieve a specific sync entry by entity ID and type
  static Future<LocalSyncEntry?> getSyncEntry(
    String entityId,
    String entityType,
  ) async {
    final db = await DatabaseHelper.database;

    final rows = await db.query(
      'sync_box',
      where: 'entity_id = ? AND entity_type = ?',
      whereArgs: [entityId, entityType],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return LocalSyncEntry.fromDatabase(rows.first);
  }

  /// Delete a specific sync entry after successful remote sync
  /// Only deletes if the lastModified matches to prevent race conditions
  /// where the user modified the entity while the sync was in flight.
  static Future<int> deleteSyncEntry(String entityId, String entityType, DateTime lastModified) async {
    final db = await DatabaseHelper.database;

    return db.delete(
      'sync_box',
      where: 'entity_id = ? AND entity_type = ? AND last_modified <= ?',
      whereArgs: [entityId, entityType, lastModified.toIso8601String()],
    );
  }

  /// Delete all sync entries of a specific entity type
  /// Used during cleanup or testing
  static Future<int> deleteSyncEntriesByType(String entityType) async {
    final db = await DatabaseHelper.database;

    return db.delete(
      'sync_box',
      where: 'entity_type = ?',
      whereArgs: [entityType],
    );
  }

  /// Check if an entity has pending sync operations (is dirty)
  static Future<bool> isEntityDirty(String entityId, String entityType) async {
    final db = await DatabaseHelper.database;

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM sync_box WHERE entity_id = ? AND entity_type = ?',
        [entityId, entityType],
      ),
    );

    return count! > 0;
  }

  /// Clear all sync entries (use with caution, typically only during testing)
  static Future<int> clearAllSyncEntries() async {
    final db = await DatabaseHelper.database;
    return db.delete('sync_box');
  }

  /// Get sync entries sorted by last_modified to process them in order
  static Future<List<LocalSyncEntry>> getSyncEntriesByModificationTime({
    String? entityType,
    bool ascending = true,
  }) async {
    final db = await DatabaseHelper.database;

    final order = ascending ? 'ASC' : 'DESC';
    final List<Map<String, dynamic>> rows;

    if (entityType != null) {
      rows = await db.query(
        'sync_box',
        where: 'entity_type = ?',
        whereArgs: [entityType],
        orderBy: 'last_modified $order',
      );
    } else {
      rows = await db.query(
        'sync_box',
        orderBy: 'last_modified $order',
      );
    }

    return rows.map((row) => LocalSyncEntry.fromDatabase(row)).toList();
  }
}
