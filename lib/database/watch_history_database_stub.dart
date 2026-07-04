import 'package:Mirarr/models/watch_history_model.dart';

class WatchHistoryDatabase {
  Future<int> insertWatchHistoryItem(WatchHistoryItem item) => throw UnimplementedError();
  Future<void> importWatchHistory(List<WatchHistoryItem> items) => throw UnimplementedError();
  Future<void> updateWatchHistoryItem(WatchHistoryItem item) => throw UnimplementedError();
  Future<void> deleteWatchHistoryItem(int id) => throw UnimplementedError();
  Future<List<WatchHistoryItem>> getAllWatchHistory() => throw UnimplementedError();
  Future<List<WatchHistoryItem>> getWatchedMovies() => throw UnimplementedError();
  Future<List<WatchHistoryItem>> getWatchedShows() => throw UnimplementedError();
  Future<List<WatchHistoryItem>> getWatchHistoryByTmdbId(int tmdbId, String type) => throw UnimplementedError();
  Future<bool> isWatched(int tmdbId, String type, {int? seasonNumber, int? episodeNumber}) => throw UnimplementedError();
  Future<List<WatchHistoryItem>> getRecentWatchHistory({int limit = 20}) => throw UnimplementedError();
  Future<Map<String, int>> getWatchStats() => throw UnimplementedError();
  Future<void> close() => throw UnimplementedError();
  
  Future<int> addMovieToHistory({
    required int tmdbId,
    required String title,
    String? posterPath,
    DateTime? watchedAt,
    double? userRating,
    String? notes,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();
}
