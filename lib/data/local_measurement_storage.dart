import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/measurement.dart';


class LocalMeasurementStorage {
	static Database? _database;

	Future<Database> get database async {
		if (_database != null) return _database!;
		_database = await _initDB();
		return _database!;
	}

	Future<Database> _initDB() async {
		final dbPath = await getDatabasesPath();
		final path = join(dbPath, 'sensor_measurements.db');

		return await openDatabase(
			path,
			version: 2,
			onCreate: (db, version) async {
				await db.execute('''
					CREATE TABLE measurements (
						id TEXT PRIMARY KEY,
						payload TEXT NOT NULL,
						created_at TEXT NOT NULL,
						is_sync INTEGER NOT NULL DEFAULT 0
					)
				''');
			},
			onUpgrade: (db, oldVersion, newVersion) async {
				if (oldVersion < 2) {
					await db.execute('ALTER TABLE measurements ADD COLUMN is_sync INTEGER NOT NULL DEFAULT 0');
				}
			},
		);
	}

	Future<int> saveMeasurement(Measurement measurement, {bool isSync = false}) async {
		final db = await database;
		return await db.insert(
			'measurements',
			{
				'id': measurement.id,
				'payload': measurement.toJsonString(),
				'created_at': measurement.timestamp.toIso8601String(),
				'is_sync': isSync ? 1 : 0,
			},
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<List<Map<String, dynamic>>> getMeasurementsAsJson() async {
		final db = await database;
		final rows = await db.query('measurements', orderBy: 'created_at DESC');

		return rows.map((row) {
			final map = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
			map['is_sync'] = (row['is_sync'] as int) == 1;
			return map;
		}).toList();
	}

	Future<List<Map<String, dynamic>>> getUnsyncedMeasurementsRaw() async {
		final db = await database;
		final rows = await db.query(
			'measurements',
			where: 'is_sync = ?',
			whereArgs: [0],
			orderBy: 'created_at ASC',
		);

		return rows.map((row) {
			final map = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
			map['is_sync'] = false;
			return map;
		}).toList();
	}

	Future<void> markAsSynced(List<String> ids) async {
		if (ids.isEmpty) return;
		final db = await database;
		final whereIn = List.filled(ids.length, '?').join(',');
		await db.update(
			'measurements',
			{'is_sync': 1},
			where: 'id IN ($whereIn)',
			whereArgs: ids,
		);
	}

	Future<int> clearStorage() async {
		final db = await database;
		return await db.delete('measurements');
	}
}