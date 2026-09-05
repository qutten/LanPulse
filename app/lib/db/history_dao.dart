import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/speed_result.dart';

/// SQLite 历史测速记录 DAO
///
/// 建表 SQL 幂等（IF NOT EXISTS），字段与 SpeedResult 一一对应。
class HistoryDao {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = join(dir, 'lan_pulse.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS speed_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time INTEGER NOT NULL,
            serverName TEXT NOT NULL,
            serverIp TEXT NOT NULL,
            serverPort INTEGER NOT NULL,
            durationSec INTEGER NOT NULL,
            concurrency INTEGER NOT NULL,
            testUpload INTEGER NOT NULL,
            testPing INTEGER NOT NULL,
            downloadMbps REAL NOT NULL,
            uploadMbps REAL NOT NULL,
            pingMin REAL,
            pingAvg REAL,
            pingMax REAL,
            jitterMs REAL,
            lossPct REAL,
            samplesJson TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  /// 插入一条历史记录，返回新行 id
  Future<int> insert(SpeedResult result) async {
    final db = await _database;
    return db.insert('speed_history', result.toMap());
  }

  /// 全部历史记录（最新在前）
  Future<List<SpeedResult>> getAll() async {
    final db = await _database;
    final rows = await db.query('speed_history',
        orderBy: 'time DESC, id DESC');
    return rows.map(SpeedResult.fromMap).toList();
  }

  /// 删除指定 id 的记录
  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('speed_history', where: 'id = ?', whereArgs: [id]);
  }

  /// 清空全部历史记录
  Future<void> clear() async {
    final db = await _database;
    await db.delete('speed_history');
  }
}
