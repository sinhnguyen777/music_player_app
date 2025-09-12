import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DBService {
  static final DBService _inst = DBService._();
  factory DBService() => _inst;
  DBService._();

  Database? _db;
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'music_app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT UNIQUE,
          password TEXT,
          avatar TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE playlists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          title TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE playlist_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlistId INTEGER,
          trackId TEXT,
          trackData TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          trackId TEXT,
          trackData TEXT
        )
      ''');
      },
    );
  }

  // USERS
  Future<int> createUser(UserModel u) async {
    final database = await db;
    return database.insert('users', u.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final database = await db;
    final res = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }

  Future<UserModel?> getUserById(int id) async {
    final database = await db;
    final res = await database.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }
}
