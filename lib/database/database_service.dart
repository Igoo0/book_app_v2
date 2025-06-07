import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/favorite.dart';
import '../models/search_history.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bookverse.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        profile_image TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        book_id TEXT NOT NULL,
        book_title TEXT NOT NULL,
        book_authors TEXT NOT NULL,
        book_thumbnail TEXT,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, book_id)
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        query TEXT NOT NULL,
        searched_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Books cache table (for offline access)
    await db.execute('''
      CREATE TABLE books_cache (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        authors TEXT NOT NULL,
        description TEXT,
        thumbnail TEXT,
        published_date TEXT,
        publisher TEXT,
        page_count INTEGER,
        categories TEXT,
        average_rating REAL,
        ratings_count INTEGER,
        preview_link TEXT,
        info_link TEXT,
        industry_identifiers TEXT,
        language TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Favorites operations
  Future<int> insertFavorite(Favorite favorite) async {
    final db = await database;
    return await db.insert('favorites', favorite.toMap());
  }

  Future<List<Favorite>> getFavoritesByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_at DESC',
    );

    return List.generate(maps.length, (i) => Favorite.fromMap(maps[i]));
  }

  Future<bool> isFavorite(int userId, String bookId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
    );

    return maps.isNotEmpty;
  }

  Future<int> deleteFavorite(int userId, String bookId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
    );
  }

  // Search history operations
  Future<int> insertSearchHistory(SearchHistory searchHistory) async {
    final db = await database;
    return await db.insert('search_history', searchHistory.toMap());
  }

  Future<List<SearchHistory>> getSearchHistoryByUserId(int userId, {int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'search_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'searched_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => SearchHistory.fromMap(maps[i]));
  }

  Future<int> deleteSearchHistory(int userId) async {
    final db = await database;
    return await db.delete(
      'search_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Books cache operations
  Future<int> insertBookCache(Map<String, dynamic> book) async {
    final db = await database;
    book['cached_at'] = DateTime.now().toIso8601String();
    return await db.insert('books_cache', book, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getBookFromCache(String bookId) async {
    final db = await database;
    final maps = await db.query(
      'books_cache',
      where: 'id = ?',
      whereArgs: [bookId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearOldCache({int daysOld = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await db.delete(
      'books_cache',
      where: 'cached_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
} 
