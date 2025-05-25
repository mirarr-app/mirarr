import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/models/watch_history_model.dart';

class SupabaseSyncService {
  static const String _tableName = 'watch_history';
  
  final SupabaseClient? _client;
  final WatchHistoryDatabase _localDb;

  SupabaseSyncService(this._client) : _localDb = WatchHistoryDatabase();

  bool get isConfigured => _client != null;

  
  Future<void> initializeSupabaseTable() async {
    if (!isConfigured) return;

    try {
      
      await _client!.from(_tableName).select('id').limit(1);
    } catch (e) {
      
      
      debugPrint('Watch history table might not exist in Supabase.');
  
    }
  }

  
  Future<bool> uploadWatchHistory() async {
    if (!isConfigured) return false;

    try {
      final localHistory = await _localDb.getAllWatchHistory();
      
      
      final remoteResponse = await _client!
          .from(_tableName)
          .select('tmdb_id,type,season_number,episode_number');
      
      final List<dynamic> remoteData = remoteResponse as List<dynamic>;
      
      
      final localItemKeys = localHistory.map((item) {
        return '${item.tmdbId}_${item.type}_${item.seasonNumber ?? 'null'}_${item.episodeNumber ?? 'null'}';
      }).toSet();
      
      
      final itemsToDelete = remoteData.where((remoteItem) {
        final key = '${remoteItem['tmdb_id']}_${remoteItem['type']}_${remoteItem['season_number'] ?? 'null'}_${remoteItem['episode_number'] ?? 'null'}';
        return !localItemKeys.contains(key);
      }).toList();
      
      
      for (final itemToDelete in itemsToDelete) {
        await _client.from(_tableName).delete().match({
          'tmdb_id': itemToDelete['tmdb_id'],
          'type': itemToDelete['type'],
          'season_number': itemToDelete['season_number'],
          'episode_number': itemToDelete['episode_number'],
        });
      }
      
      debugPrint('Deleted ${itemsToDelete.length} items from Supabase that were removed locally');
      
      
      for (final item in localHistory) {
        final data = {
          'tmdb_id': item.tmdbId,
          'title': item.title,
          'type': item.type,
          'poster_path': item.posterPath,
          'watched_at': item.watchedAt.toIso8601String(),
          'season_number': item.seasonNumber,
          'episode_number': item.episodeNumber,
          'episode_title': item.episodeTitle,
          'user_rating': item.userRating,
          'notes': item.notes,
        };

        await _client.from(_tableName).upsert(
          data,
          onConflict: 'tmdb_id,type,season_number,episode_number',
        );
      }

      debugPrint('Successfully uploaded ${localHistory.length} watch history items to Supabase');
      return true;
    } catch (e) {
      debugPrint('Error uploading watch history to Supabase: $e');
      return false;
    }
  }

  
  Future<bool> downloadWatchHistory() async {
    if (!isConfigured) return false;

    try {
      final response = await _client!
          .from(_tableName)
          .select()
          .order('watched_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      for (final item in data) {
        final watchHistoryItem = WatchHistoryItem(
          tmdbId: item['tmdb_id'],
          title: item['title'],
          type: item['type'],
          posterPath: item['poster_path'],
          watchedAt: DateTime.parse(item['watched_at']),
          seasonNumber: item['season_number'],
          episodeNumber: item['episode_number'],
          episodeTitle: item['episode_title'],
          userRating: item['user_rating']?.toDouble(),
          notes: item['notes'],
        );

        
        await _localDb.insertWatchHistoryItem(watchHistoryItem);
      }

      debugPrint('Successfully downloaded ${data.length} watch history items from Supabase');
      return true;
    } catch (e) {
      debugPrint('Error downloading watch history from Supabase: $e');
      return false;
    }
  }

  
  Future<bool> syncWatchHistory() async {
    if (!isConfigured) return false;

    try {
      
      await downloadWatchHistory();
      
      
      await uploadWatchHistory();
      
      debugPrint('Watch history sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error syncing watch history: $e');
      return false;
    }
  }

  
  Future<bool> addWatchHistoryItem(WatchHistoryItem item) async {
    try {
      
      await _localDb.insertWatchHistoryItem(item);
      
      
      if (isConfigured) {
        final data = {
          'tmdb_id': item.tmdbId,
          'title': item.title,
          'type': item.type,
          'poster_path': item.posterPath,
          'watched_at': item.watchedAt.toIso8601String(),
          'season_number': item.seasonNumber,
          'episode_number': item.episodeNumber,
          'episode_title': item.episodeTitle,
          'user_rating': item.userRating,
          'notes': item.notes,
        };

        await _client!.from(_tableName).upsert(
          data,
          onConflict: 'tmdb_id,type,season_number,episode_number',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error adding watch history item: $e');
      return false;
    }
  }

  
  Future<bool> deleteWatchHistoryItem({
    required int tmdbId,
    required String type,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      
      
      final existingItems = await _localDb.getWatchHistoryByTmdbId(tmdbId, type);
      
      for (final item in existingItems) {
        if ((item.seasonNumber == seasonNumber || (item.seasonNumber == null && seasonNumber == null)) &&
            (item.episodeNumber == episodeNumber || (item.episodeNumber == null && episodeNumber == null))) {
          await _localDb.deleteWatchHistoryItem(item.id!);
          break;
        }
      }
      
      
      if (isConfigured) {
        final matchConditions = <String, Object>{
          'tmdb_id': tmdbId,
          'type': type,
        };
        
        if (seasonNumber != null) {
          matchConditions['season_number'] = seasonNumber;
        }
        
        if (episodeNumber != null) {
          matchConditions['episode_number'] = episodeNumber;
        }
        
        await _client!.from(_tableName).delete().match(matchConditions);
      }
      
      debugPrint('Successfully deleted watch history item: tmdb_id=$tmdbId, type=$type, season=$seasonNumber, episode=$episodeNumber');
      return true;
    } catch (e) {
      debugPrint('Error deleting watch history item: $e');
      return false;
    }
  }

  
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final localCount = (await _localDb.getAllWatchHistory()).length;
      
      int remoteCount = 0;
      if (isConfigured) {
        try {
          final response = await _client!
              .from(_tableName)
              .select('id')
              .count(CountOption.exact);
          remoteCount = response.count;
        } catch (e) {
          debugPrint('Error getting remote count: $e');
        }
      }

      return {
        'local_count': localCount,
        'remote_count': remoteCount,
        'is_configured': isConfigured,
        'last_sync': null, 
      };
    } catch (e) {
      debugPrint('Error getting sync status: $e');
      return {
        'local_count': 0,
        'remote_count': 0,
        'is_configured': isConfigured,
        'last_sync': null,
      };
    }
  }
} 