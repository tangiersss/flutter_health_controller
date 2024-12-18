import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Stopwatch stopwatch = Stopwatch()..start();

    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'healthData.db');

    if (!await databaseExists(path)) {
      try {
        await Directory(dirname(path)).create(recursive: true);

        final db = await openDatabase(path, version: 1, onCreate: _onCreate);
        stopwatch.stop();
        print('Database initialized in ${stopwatch.elapsedMilliseconds} ms');
        return db;
      } catch (e) {
        print("Error initializing database: $e");
        rethrow;
      }
    } else {}

    return await openDatabase(path, version: 1);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dates (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS heart_rate_data (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        heart_rate TEXT NOT NULL,
        _did INTEGER,
        FOREIGN KEY (_did) REFERENCES dates(_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pressure_data (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        pressure TEXT NOT NULL,
        _did INTEGER,
        FOREIGN KEY (_did) REFERENCES dates(_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sleeping_hours (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        hours INTEGER NOT NULL,
        _did INTEGER,
        FOREIGN KEY (_did) REFERENCES dates(_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS steps_data (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        steps TEXT NOT NULL,
        _did INTEGER,
        FOREIGN KEY (_did) REFERENCES dates(_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_data (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight TEXT NOT NULL,
        _did INTEGER,
        FOREIGN KEY (_did) REFERENCES dates(_id)
      );
    ''');
  }

  Future<void> deleteAllTables() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS dates;');
    await db.execute('DROP TABLE IF EXISTS heart_rate_data;');
    await db.execute('DROP TABLE IF EXISTS pressure_data;');
    await db.execute('DROP TABLE IF EXISTS sleeping_hours;');
    await db.execute('DROP TABLE IF EXISTS steps_data;');
    await db.execute('DROP TABLE IF EXISTS weight_data;');
  }

  Future<void> resetDatabase() async {
    await deleteAllTables();
    final db = await database;
    await _onCreate(db, 1);
  }

  Future<int> addTodayDate() async {
    final db = await database;

    DateTime now = DateTime.now();

    String formattedDate =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}";

    return await db.insert('dates', {'date': formattedDate});
  }

  Future<void> addSomeDate(String date) async {
    final db = await database;
    await db.insert('dates', {'date': date});
  }

  Future<void> addHeartRate(String heartRate, int dateId) async {
    final db = await database;
    Stopwatch stopwatch = Stopwatch()..start();

    await db
        .insert('heart_rate_data', {'heart_rate': heartRate, '_did': dateId});
    stopwatch.stop();
    print('Query time ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<void> addPressureData(String pressure, int dateId) async {
    final db = await database;
    Stopwatch stopwatch = Stopwatch()..start();

    await db.insert('pressure_data', {'pressure': pressure, '_did': dateId});
    stopwatch.stop();
    print('Query time ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<void> addSleepingHours(int hours, int dateId) async {
    final db = await database;

    await db.insert('sleeping_hours', {'hours': hours, '_did': dateId});
  }

  Future<void> addStepsData(String steps, int dateId) async {
    final db = await database;
    Stopwatch stopwatch = Stopwatch()..start();

    await db.insert('steps_data', {'steps': steps, '_did': dateId});
    stopwatch.stop();
    print('Query time ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<void> addWeightData(String weight, int dateId) async {
    final db = await database;
    Stopwatch stopwatch = Stopwatch()..start();

    await db.insert('weight_data', {'weight': weight, '_did': dateId});
    stopwatch.stop();
    print('Query time ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<List<Map<String, dynamic>>> getDates() async {
    final db = await database;
    return await db.query('dates');
  }

  Future<List<Map<String, dynamic>>> getHeartRateData(int dateId) async {
    final db = await database;
    return await db
        .query('heart_rate_data', where: '_did = ?', whereArgs: [dateId]);
  }

  Future<List<Map<String, dynamic>>> getPressureData(int dateId) async {
    final db = await database;
    return await db
        .query('pressure_data', where: '_did = ?', whereArgs: [dateId]);
  }

  Future<List<Map<String, dynamic>>> getSleepingHoursData(int dateId) async {
    final db = await database;
    return await db
        .query('sleeping_hours', where: '_did = ?', whereArgs: [dateId]);
  }

  Future<List<Map<String, dynamic>>> getStepsData(int dateId) async {
    final db = await database;
    return await db.query('steps_data', where: '_did = ?', whereArgs: [dateId]);
  }

  Future<List<Map<String, dynamic>>> getWeightData(int dateId) async {
    final db = await database;
    return await db
        .query('weight_data', where: '_did = ?', whereArgs: [dateId]);
  }

  Future<List<Map<String, dynamic>>> getStepsWithDates(int dateId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.steps, d.date
      FROM steps_data s
      JOIN dates d ON s._did = d._id
      WHERE s._did = ?
    ''', [dateId]);
  }

  static Future<List<Map<String, dynamic>>> getChartData(
      String chartType) async {
    final db = await database;
    String query;
    String tableName;

    switch (chartType) {
      case "steps":
        tableName = "steps_data";
        query = '''
        SELECT d.date, s.steps AS value 
        FROM dates d 
        JOIN steps_data s ON d._id = s._did
      ''';
        break;
      case "heart_rate":
        tableName = "heart_rate_data";
        query = '''
        SELECT d.date, t.heart_rate AS value
        FROM dates d
        JOIN heart_rate_data t ON d._id = t._did
      ''';
        break;
      case "sleep":
        tableName = "sleeping_hours";
        query = '''
        SELECT d.date, s.hours AS value
        FROM dates d
        JOIN sleeping_hours s ON d._id = s._did
      ''';
        break;
      case "weight":
        tableName = "weight_data";
        query = '''
        SELECT d.date, w.weight AS value
        FROM dates d
        JOIN weight_data w ON d._id = w._did
      ''';
        break;
      default:
        throw Exception("Unknown chart type: $chartType");
    }

    if (!await tableExists(tableName)) {
      throw Exception("Table $tableName does not exist");
    }

    if (!await hasData(tableName)) {
      return [];
    }

    return await db.rawQuery(query);
  }

  static Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]);
    return result.isNotEmpty;
  }

  static Future<bool> hasData(String tableName) async {
    final db = await database;
    final result =
        await db.rawQuery("SELECT COUNT(*) AS count FROM $tableName");

    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  static Future<List<String>> getAllDates() async {
    final db = await database;
    final List<Map<String, dynamic>> datesData = await db.query('dates');

    return List.generate(datesData.length, (index) {
      return datesData[index]['date'] as String;
    });
  }
}
