import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/incident_model.dart';

class OfflineService {
  static Database? _database;
  static final OfflineService _instance = OfflineService._internal();

  factory OfflineService() => _instance;
  OfflineService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nagrik_alert_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Pending incidents table (for offline reports)
        await db.execute('''
          CREATE TABLE pending_incidents (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            description TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            severity INTEGER NOT NULL,
            reporter_id TEXT,
            device_id TEXT,
            timestamp TEXT NOT NULL,
            media_paths TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        // Cached incidents table (for offline viewing)
        await db.execute('''
          CREATE TABLE cached_incidents (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');

        // Status history table
        await db.execute('''
          CREATE TABLE status_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            incident_id TEXT NOT NULL,
            old_status TEXT,
            new_status TEXT NOT NULL,
            changed_by TEXT,
            changed_at TEXT NOT NULL,
            notes TEXT
          )
        ''');
      },
    );
  }

  // Check if online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  // Save incident offline
  Future<void> savePendingIncident(Map<String, dynamic> incident) async {
    final db = await database;
    await db.insert(
      'pending_incidents',
      {
        'id': incident['id'],
        'type': incident['type'],
        'description': incident['description'],
        'latitude': incident['latitude'],
        'longitude': incident['longitude'],
        'severity': incident['severity'],
        'reporter_id': incident['reporter_id'],
        'device_id': incident['device_id'],
        'timestamp': incident['timestamp'],
        'media_paths': jsonEncode(incident['media_paths'] ?? []),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('📴 Saved incident offline: ${incident['id']}');
  }

  // Get pending incidents
  Future<List<Map<String, dynamic>>> getPendingIncidents() async {
    final db = await database;
    return await db.query('pending_incidents', where: 'synced = 0');
  }

  // Mark incident as synced
  Future<void> markAsSynced(String incidentId) async {
    final db = await database;
    await db.update(
      'pending_incidents',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [incidentId],
    );
  }

  // Cache incidents for offline viewing
  Future<void> cacheIncidents(List<IncidentModel> incidents) async {
    final db = await database;
    final batch = db.batch();
    
    for (var incident in incidents) {
      batch.insert(
        'cached_incidents',
        {
          'id': incident.id,
          'data': jsonEncode(incident.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    print('💾 Cached ${incidents.length} incidents offline');
  }

  // Get cached incidents
  Future<List<IncidentModel>> getCachedIncidents() async {
    final db = await database;
    final results = await db.query('cached_incidents', orderBy: 'cached_at DESC');
    
    return results.map((row) {
      final data = jsonDecode(row['data'] as String);
      return IncidentModel.fromJson(data);
    }).toList();
  }

  // Add status history
  Future<void> addStatusHistory({
    required String incidentId,
    String? oldStatus,
    required String newStatus,
    String? changedBy,
    String? notes,
  }) async {
    final db = await database;
    await db.insert('status_history', {
      'incident_id': incidentId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      'changed_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }

  // Get status history for an incident
  Future<List<Map<String, dynamic>>> getStatusHistory(String incidentId) async {
    final db = await database;
    return await db.query(
      'status_history',
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'changed_at ASC',
    );
  }

  // Sync pending incidents when online
  Future<int> syncPendingIncidents(Future<bool> Function(Map<String, dynamic>) uploadFn) async {
    if (!await isOnline()) return 0;

    final pending = await getPendingIncidents();
    int synced = 0;

    for (var incident in pending) {
      try {
        final success = await uploadFn(incident);
        if (success) {
          await markAsSynced(incident['id'] as String);
          synced++;
        }
      } catch (e) {
        print('❌ Failed to sync incident: $e');
      }
    }

    if (synced > 0) {
      print('✅ Synced $synced pending incidents');
    }
    return synced;
  }

  // Get pending count
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_incidents WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
