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
      
      // Get ALL remote data with pagination
      final allRemoteData = <Map<String, dynamic>>[];
      int offset = 0;
      const batchSize = 1000;
      
      while (true) {
        final remoteResponse = await _client!
            .from(_tableName)
            .select('tmdb_id,type,season_number,episode_number')
            .range(offset, offset + batchSize - 1);
        
        final List<dynamic> batch = remoteResponse as List<dynamic>;
        if (batch.isEmpty) break;
        
        allRemoteData.addAll(batch.cast<Map<String, dynamic>>());
        
        if (batch.length < batchSize) break; // Last batch
        offset += batchSize;
      }
      
      debugPrint('Retrieved ${allRemoteData.length} remote items for comparison');
      
      // Create a set of local items for efficient lookup
      final localItemKeys = localHistory.map((item) {
        return '${item.tmdbId}_${item.type}_${item.seasonNumber ?? 'null'}_${item.episodeNumber ?? 'null'}';
      }).toSet();
      
      // Find remote items that don't exist locally (i.e., were deleted locally)
      final itemsToDelete = allRemoteData.where((remoteItem) {
        final key = '${remoteItem['tmdb_id']}_${remoteItem['type']}_${remoteItem['season_number'] ?? 'null'}_${remoteItem['episode_number'] ?? 'null'}';
        return !localItemKeys.contains(key);
      }).toList();
      
      // Delete items from Supabase that were removed locally (in batches)
      int deletedCount = 0;
      for (final itemToDelete in itemsToDelete) {
        await _client.from(_tableName).delete().match({
          'tmdb_id': itemToDelete['tmdb_id'],
          'type': itemToDelete['type'],
          'season_number': itemToDelete['season_number'],
          'episode_number': itemToDelete['episode_number'],
        });
        deletedCount++;
      }
      
      debugPrint('Deleted $deletedCount items from Supabase that were removed locally');
      
      // Upload/update all local items in batches
      int uploadedCount = 0;
      const uploadBatchSize = 100; // Smaller batches for uploads to avoid timeouts
      
      for (int i = 0; i < localHistory.length; i += uploadBatchSize) {
        final batch = localHistory.skip(i).take(uploadBatchSize).toList();
        final batchData = batch.map((item) => {
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
        }).toList();

        await _client.from(_tableName).upsert(
          batchData,
          onConflict: 'tmdb_id,type,season_number,episode_number',
        );
        
        uploadedCount += batch.length;
        debugPrint('Uploaded batch: $uploadedCount/${localHistory.length} items');
      }

      debugPrint('Successfully uploaded $uploadedCount watch history items to Supabase');
      return true;
    } catch (e) {
      debugPrint('Error uploading watch history to Supabase: $e');
      return false;
    }
  }

  
  Future<bool> downloadWatchHistory() async {
    if (!isConfigured) return false;

    try {
      // Get ALL remote data with pagination
      final allRemoteData = <Map<String, dynamic>>[];
      int offset = 0;
      const batchSize = 1000;
      
      while (true) {
        final response = await _client!
            .from(_tableName)
            .select()
            .order('watched_at', ascending: false)
            .range(offset, offset + batchSize - 1);

        final List<dynamic> batch = response as List<dynamic>;
        if (batch.isEmpty) break;
        
        allRemoteData.addAll(batch.cast<Map<String, dynamic>>());
        
        if (batch.length < batchSize) break; // Last batch
        offset += batchSize;
        
        debugPrint('Downloaded batch: ${allRemoteData.length} items so far...');
      }
      
      debugPrint('Retrieved ${allRemoteData.length} total items from Supabase');
      
      // Get existing local items to avoid duplicates
      final existingLocalItems = await _localDb.getAllWatchHistory();
      final existingKeys = <String>{};
      
      for (final item in existingLocalItems) {
        final key = '${item.tmdbId}_${item.type}_${item.seasonNumber ?? 'null'}_${item.episodeNumber ?? 'null'}';
        existingKeys.add(key);
      }
      
      int newItemsCount = 0;
      int updatedItemsCount = 0;
      
      for (final item in allRemoteData) {
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

        final key = '${watchHistoryItem.tmdbId}_${watchHistoryItem.type}_${watchHistoryItem.seasonNumber ?? 'null'}_${watchHistoryItem.episodeNumber ?? 'null'}';
        
        if (existingKeys.contains(key)) {
          // Item already exists, check if we need to update it
          final existingItem = await _getExistingLocalItem(watchHistoryItem);
          if (existingItem != null && _shouldUpdateItem(existingItem, watchHistoryItem)) {
            await _localDb.updateWatchHistoryItem(watchHistoryItem);
            updatedItemsCount++;
          }
        } else {
          // New item, insert it
          await _localDb.insertWatchHistoryItem(watchHistoryItem);
          newItemsCount++;
        }
      }

      debugPrint('Successfully downloaded $newItemsCount new items and updated $updatedItemsCount items from Supabase');
      return true;
    } catch (e) {
      debugPrint('Error downloading watch history from Supabase: $e');
      return false;
    }
  }
  
  // Helper method to get existing local item
  Future<WatchHistoryItem?> _getExistingLocalItem(WatchHistoryItem item) async {
    final existingItems = await _localDb.getWatchHistoryByTmdbId(item.tmdbId, item.type);
    
    for (final existing in existingItems) {
      if ((existing.seasonNumber == item.seasonNumber || (existing.seasonNumber == null && item.seasonNumber == null)) &&
          (existing.episodeNumber == item.episodeNumber || (existing.episodeNumber == null && item.episodeNumber == null))) {
        return existing;
      }
    }
    return null;
  }
  
  // Helper method to determine if an item should be updated
  bool _shouldUpdateItem(WatchHistoryItem existing, WatchHistoryItem remote) {
    // Update if remote item is newer or has different data
    return remote.watchedAt.isAfter(existing.watchedAt) ||
           existing.title != remote.title ||
           existing.posterPath != remote.posterPath ||
           existing.episodeTitle != remote.episodeTitle ||
           existing.userRating != remote.userRating ||
           existing.notes != remote.notes;
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
          // Count items by fetching all IDs in batches (most reliable method)
          int offset = 0;
          const batchSize = 1000;
          
          while (true) {
            final response = await _client!
                .from(_tableName)
                .select('id')
                .range(offset, offset + batchSize - 1);
            
            final List<dynamic> batch = response as List<dynamic>;
            if (batch.isEmpty) break;
            
            remoteCount += batch.length;
            
            if (batch.length < batchSize) break;
            offset += batchSize;
          }
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