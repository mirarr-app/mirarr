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
      
      // Get ALL remote data with full details for comparison
      final allRemoteData = <Map<String, dynamic>>[];
      int offset = 0;
      const batchSize = 1000;
      
      while (true) {
        final remoteResponse = await _client!
            .from(_tableName)
            .select()
            .range(offset, offset + batchSize - 1);
        
        final List<dynamic> batch = remoteResponse as List<dynamic>;
        if (batch.isEmpty) break;
        
        allRemoteData.addAll(batch.cast<Map<String, dynamic>>());
        
        if (batch.length < batchSize) break; // Last batch
        offset += batchSize;
      }
      
      debugPrint('Retrieved ${allRemoteData.length} remote items for comparison');
      
      // Create lookup maps for efficient comparison
      final localItemMap = <String, WatchHistoryItem>{};
      final remoteItemMap = <String, Map<String, dynamic>>{};
      
      // Build local item map
      for (final item in localHistory) {
        final key = '${item.tmdbId}_${item.type}_${item.seasonNumber ?? 'null'}_${item.episodeNumber ?? 'null'}';
        localItemMap[key] = item;
      }
      
      // Build remote item map
      for (final item in allRemoteData) {
        final key = '${item['tmdb_id']}_${item['type']}_${item['season_number'] ?? 'null'}_${item['episode_number'] ?? 'null'}';
        remoteItemMap[key] = item;
      }
      
      // Find items to delete (exist remotely but not locally)
      final idsToDelete = <int>[];
      for (final remoteKey in remoteItemMap.keys) {
        if (!localItemMap.containsKey(remoteKey)) {
          idsToDelete.add(remoteItemMap[remoteKey]!['id']);
        }
      }
      
      // Bulk delete items that were removed locally
      if (idsToDelete.isNotEmpty) {
        const deleteBatchSize = 100;
        int deletedCount = 0;
        
        for (int i = 0; i < idsToDelete.length; i += deleteBatchSize) {
          final batch = idsToDelete.skip(i).take(deleteBatchSize).toList();
          await _client!.from(_tableName).delete().inFilter('id', batch);
          deletedCount += batch.length;
        }
        
        debugPrint('Deleted $deletedCount items from Supabase that were removed locally');
      }
      
      // Find items to insert or update
      final itemsToInsert = <Map<String, dynamic>>[];
      final itemsToUpdate = <Map<String, dynamic>>[];
      
      for (final localKey in localItemMap.keys) {
        final localItem = localItemMap[localKey]!;
        final data = {
          'tmdb_id': localItem.tmdbId,
          'title': localItem.title,
          'type': localItem.type,
          'poster_path': localItem.posterPath,
          'watched_at': localItem.watchedAt.toIso8601String(),
          'season_number': localItem.seasonNumber,
          'episode_number': localItem.episodeNumber,
          'episode_title': localItem.episodeTitle,
          'user_rating': localItem.userRating,
          'notes': localItem.notes,
        };
        
        if (remoteItemMap.containsKey(localKey)) {
          // Item exists remotely, check if we need to update it
          final remoteItem = remoteItemMap[localKey]!;
          final remoteWatchedAt = DateTime.parse(remoteItem['watched_at']);
          
          if (localItem.watchedAt.isAfter(remoteWatchedAt) ||
              localItem.title != remoteItem['title'] ||
              localItem.posterPath != remoteItem['poster_path'] ||
              localItem.episodeTitle != remoteItem['episode_title'] ||
              localItem.userRating != remoteItem['user_rating'] ||
              localItem.notes != remoteItem['notes']) {
            data['id'] = remoteItem['id']; // Include ID for update
            itemsToUpdate.add(data);
          }
        } else {
          // New item to insert
          itemsToInsert.add(data);
        }
      }
      
      // Bulk insert new items
      if (itemsToInsert.isNotEmpty) {
        const insertBatchSize = 100;
        int insertedCount = 0;
        
        for (int i = 0; i < itemsToInsert.length; i += insertBatchSize) {
          final batch = itemsToInsert.skip(i).take(insertBatchSize).toList();
          await _client!.from(_tableName).insert(batch);
          insertedCount += batch.length;
          
          if (insertedCount % 500 == 0 || insertedCount == itemsToInsert.length) {
            debugPrint('Inserted $insertedCount/${itemsToInsert.length} new items');
          }
        }
      }
      
      // Update existing items (these need individual requests, but much fewer than before)
      if (itemsToUpdate.isNotEmpty) {
        int updatedCount = 0;
        
        for (final item in itemsToUpdate) {
          final id = item.remove('id'); // Remove ID from data, use it for the where clause
          await _client!.from(_tableName).update(item).eq('id', id);
          updatedCount++;
          
          if (updatedCount % 100 == 0 || updatedCount == itemsToUpdate.length) {
            debugPrint('Updated $updatedCount/${itemsToUpdate.length} existing items');
          }
        }
      }

      final totalProcessed = itemsToInsert.length + itemsToUpdate.length;
      debugPrint('Successfully processed $totalProcessed watch history items to Supabase');
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
      // Add to local database first
      await _localDb.insertWatchHistoryItem(item);
      
      // Then add to Supabase if configured
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

        try {
          // Try to insert first (most common case for new items)
          await _client!.from(_tableName).insert(data);
        } catch (e) {
          // If insert fails due to conflict, try to update instead
          if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
            // Find the existing record and update it
            var query = _client!.from(_tableName)
                .select('id')
                .eq('tmdb_id', item.tmdbId)
                .eq('type', item.type);
                
            if (item.seasonNumber == null) {
              query = query.isFilter('season_number', null);
            } else {
              query = query.eq('season_number', item.seasonNumber!);
            }
            
            if (item.episodeNumber == null) {
              query = query.isFilter('episode_number', null);
            } else {
              query = query.eq('episode_number', item.episodeNumber!);
            }
            
            final existingResponse = await query;
            final List<dynamic> existing = existingResponse as List<dynamic>;
            
            if (existing.isNotEmpty) {
              final id = existing.first['id'];
              await _client!.from(_tableName).update(data).eq('id', id);
            }
          } else {
            // Re-throw if it's not a duplicate key error
            rethrow;
          }
        }
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
      // Delete from local database first
      // Find the matching item(s) in local database
      final existingItems = await _localDb.getWatchHistoryByTmdbId(tmdbId, type);
      
      for (final item in existingItems) {
        if ((item.seasonNumber == seasonNumber || (item.seasonNumber == null && seasonNumber == null)) &&
            (item.episodeNumber == episodeNumber || (item.episodeNumber == null && episodeNumber == null))) {
          await _localDb.deleteWatchHistoryItem(item.id!);
          break;
        }
      }
      
      // Then delete from Supabase if configured
      if (isConfigured) {
        var deleteQuery = _client!.from(_tableName).delete()
            .eq('tmdb_id', tmdbId)
            .eq('type', type);
            
        if (seasonNumber == null) {
          deleteQuery = deleteQuery.isFilter('season_number', null);
        } else {
          deleteQuery = deleteQuery.eq('season_number', seasonNumber);
        }
        
        if (episodeNumber == null) {
          deleteQuery = deleteQuery.isFilter('episode_number', null);
        } else {
          deleteQuery = deleteQuery.eq('episode_number', episodeNumber);
        }
        
        await deleteQuery;
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