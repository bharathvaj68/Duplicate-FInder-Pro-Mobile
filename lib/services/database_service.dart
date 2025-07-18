import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/duplicate_file.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  static DatabaseService get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'dupfile.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        directory_path TEXT NOT NULL,
        scan_date TEXT NOT NULL,
        duplicate_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE duplicate_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER NOT NULL,
        paths TEXT NOT NULL,
        size INTEGER NOT NULL,
        hash TEXT NOT NULL,
        count INTEGER NOT NULL,
        FOREIGN KEY (scan_id) REFERENCES scan_results (id)
      )
    ''');
  }

  Future<void> saveScanResult(String directoryPath, List<DuplicateFile> duplicates) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insert scan result
      final scanId = await txn.insert('scan_results', {
        'directory_path': directoryPath,
        'scan_date': DateTime.now().toIso8601String(),
        'duplicate_count': duplicates.length,
      });

      // Insert duplicate files
      for (final duplicate in duplicates) {
        await txn.insert('duplicate_files', {
          'scan_id': scanId,
          'paths': duplicate.paths.join('|'),
          'size': duplicate.size,
          'hash': duplicate.hash,
          'count': duplicate.count,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final db = await database;
    return await db.query(
      'scan_results',
      orderBy: 'scan_date DESC',
    );
  }

  Future<List<DuplicateFile>> getDuplicatesForScan(int scanId) async {
    final db = await database;
    final results = await db.query(
      'duplicate_files',
      where: 'scan_id = ?',
      whereArgs: [scanId],
    );

    return results.map((map) => DuplicateFile.fromMap(map)).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('duplicate_files');
      await txn.delete('scan_results');
    });
  }
}