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
			version: 1,
			onCreate: (db, version) async {
				await db.execute('''
					CREATE TABLE measurements (
						id TEXT PRIMARY KEY,
						payload TEXT NOT NULL,
						created_at TEXT NOT NULL
					)
				''');
			},
		);
	}

	Future<int> saveMeasurement(Measurement measurement) async {
		final db = await database;
		return await db.insert(
			'measurements',
			{
				'id': measurement.id,
				'payload': measurement.toJsonString(),
				'created_at': measurement.timestamp.toIso8601String(),
			},
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<List<Map<String, dynamic>>> getMeasurementsAsJson() async {
		final db = await database;
		final rows = await db.query('measurements', orderBy: 'created_at DESC');

		return rows.map((row) {
			return jsonDecode(row['payload'] as String) as Map<String, dynamic>;
		}).toList();
	}

	Future<List<Measurement>> getMeasurements() async {
		final db = await database;
		final rows = await db.query('measurements', orderBy: 'created_at DESC');

		return rows.map((row) {
			return Measurement.fromJsonString(row['payload'] as String);
		}).toList();
	}

	Future<int> clearStorage() async {
		final db = await database;
		return await db.delete('measurements');
	}
}