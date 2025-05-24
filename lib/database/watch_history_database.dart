import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:Mirarr/models/watch_history_model.dart';

class WatchHistoryDatabase {
  static Database? _database;
  static const String _databaseName = 'watch_history.db';
  static const String _tableName = 'watch_history';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    final database = sqlite3.open(path);
    _onCreate(database);
    return database;
  }

  void _onCreate(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('movie', 'tv')),
        poster_path TEXT,
        watched_at INTEGER NOT NULL,
        season_number INTEGER,
        episode_number INTEGER,
        episode_title TEXT,
        user_rating REAL,
        notes TEXT,
        UNIQUE(tmdb_id, type, season_number, episode_number)
      )
    ''');

    // Create indexes for better performance
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_watched_at ON $_tableName (watched_at DESC)
    ''');
    
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_type ON $_tableName (type)
    ''');
    
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tmdb_id ON $_tableName (tmdb_id)
    ''');
  }

  Future<int> insertWatchHistoryItem(WatchHistoryItem item) async {
    final db = await database;
    
    try {
      final stmt = db.prepare('''
        INSERT INTO $_tableName (
          tmdb_id, title, type, poster_path, watched_at,
          season_number, episode_number, episode_title, user_rating, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      
      stmt.execute([
        item.tmdbId,
        item.title,
        item.type,
        item.posterPath,
        item.watchedAt.millisecondsSinceEpoch,
        item.seasonNumber,
        item.episodeNumber,
        item.episodeTitle,
        item.userRating,
        item.notes,
      ]);
      
      stmt.dispose();
      return db.lastInsertRowId;
    } catch (e) {
      // If it's a unique constraint violation, update the existing record
      if (e.toString().contains('UNIQUE constraint failed')) {
        await updateWatchHistoryItem(item);
        final existing = await _getExistingItem(item);
        return existing?.id ?? 0;
      }
      rethrow;
    }
  }

  Future<WatchHistoryItem?> _getExistingItem(WatchHistoryItem item) async {
    final db = await database;
    final result = db.select('''
      SELECT * FROM $_tableName 
      WHERE tmdb_id = ? AND type = ? AND 
            COALESCE(season_number, -1) = COALESCE(?, -1) AND 
            COALESCE(episode_number, -1) = COALESCE(?, -1)
    ''', [item.tmdbId, item.type, item.seasonNumber, item.episodeNumber]);
    
    if (result.isNotEmpty) {
      return WatchHistoryItem.fromMap(result.first);
    }
    return null;
  }

  Future<void> updateWatchHistoryItem(WatchHistoryItem item) async {
    final db = await database;
    db.execute('''
      UPDATE $_tableName SET
        title = ?, poster_path = ?, watched_at = ?,
        episode_title = ?, user_rating = ?, notes = ?
      WHERE tmdb_id = ? AND type = ? AND 
            COALESCE(season_number, -1) = COALESCE(?, -1) AND 
            COALESCE(episode_number, -1) = COALESCE(?, -1)
    ''', [
      item.title,
      item.posterPath,
      item.watchedAt.millisecondsSinceEpoch,
      item.episodeTitle,
      item.userRating,
      item.notes,
      item.tmdbId,
      item.type,
      item.seasonNumber,
      item.episodeNumber,
    ]);
  }

  Future<void> deleteWatchHistoryItem(int id) async {
    final db = await database;
    db.execute('DELETE FROM $_tableName WHERE id = ?', [id]);
  }

  Future<List<WatchHistoryItem>> getAllWatchHistory() async {
    final db = await database;
    final result = db.select('SELECT * FROM $_tableName ORDER BY watched_at DESC');
    return result.map((row) => WatchHistoryItem.fromMap(row)).toList();
  }

  Future<List<WatchHistoryItem>> getWatchedMovies() async {
    final db = await database;
    final result = db.select('''
      SELECT * FROM $_tableName 
      WHERE type = 'movie' 
      ORDER BY watched_at DESC
    ''');
    return result.map((row) => WatchHistoryItem.fromMap(row)).toList();
  }

  Future<List<WatchHistoryItem>> getWatchedShows() async {
    final db = await database;
    final result = db.select('''
      SELECT * FROM $_tableName 
      WHERE type = 'tv' 
      ORDER BY watched_at DESC
    ''');
    return result.map((row) => WatchHistoryItem.fromMap(row)).toList();
  }

  Future<List<WatchHistoryItem>> getWatchHistoryByTmdbId(int tmdbId, String type) async {
    final db = await database;
    final result = db.select('''
      SELECT * FROM $_tableName 
      WHERE tmdb_id = ? AND type = ? 
      ORDER BY watched_at DESC
    ''', [tmdbId, type]);
    return result.map((row) => WatchHistoryItem.fromMap(row)).toList();
  }

  Future<bool> isWatched(int tmdbId, String type, {int? seasonNumber, int? episodeNumber}) async {
    final db = await database;
    final result = db.select('''
      SELECT COUNT(*) as count FROM $_tableName 
      WHERE tmdb_id = ? AND type = ? AND 
            COALESCE(season_number, -1) = COALESCE(?, -1) AND 
            COALESCE(episode_number, -1) = COALESCE(?, -1)
    ''', [tmdbId, type, seasonNumber, episodeNumber]);
    
    return (result.first['count'] as int) > 0;
  }

  Future<List<WatchHistoryItem>> getRecentWatchHistory({int limit = 20}) async {
    final db = await database;
    final result = db.select('''
      SELECT * FROM $_tableName 
      ORDER BY watched_at DESC 
      LIMIT ?
    ''', [limit]);
    return result.map((row) => WatchHistoryItem.fromMap(row)).toList();
  }

  Future<Map<String, int>> getWatchStats() async {
    final db = await database;
    final movieCount = db.select('SELECT COUNT(*) as count FROM $_tableName WHERE type = "movie"');
    final showCount = db.select('SELECT COUNT(*) as count FROM $_tableName WHERE type = "tv"');
    
    return {
      'movies': movieCount.first['count'] as int,
      'shows': showCount.first['count'] as int,
    };
  }

  Future<void> close() async {
    if (_database != null) {
      _database!.dispose();
      _database = null;
    }
  }

  // Helper method to add a movie to watch history
  Future<int> addMovieToHistory({
    required int tmdbId,
    required String title,
    String? posterPath,
    DateTime? watchedAt,
    double? userRating,
    String? notes,
  }) async {
    final item = WatchHistoryItem(
      tmdbId: tmdbId,
      title: title,
      type: 'movie',
      posterPath: posterPath,
      watchedAt: watchedAt ?? DateTime.now(),
      userRating: userRating,
      notes: notes,
    );
    return await insertWatchHistoryItem(item);
  }

  // Helper method to add a TV show episode to watch history
  Future<int> addShowToHistory({
    required int tmdbId,
    required String title,
    String? posterPath,
    DateTime? watchedAt,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    double? userRating,
    String? notes,
  }) async {
    final item = WatchHistoryItem(
      tmdbId: tmdbId,
      title: title,
      type: 'tv',
      posterPath: posterPath,
      watchedAt: watchedAt ?? DateTime.now(),
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      userRating: userRating,
      notes: notes,
    );
    return await insertWatchHistoryItem(item);
  }
} 