import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/seriesPage/UI/tvchart_table.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/seriesPage/function/fetch_episode_cast_crew.dart';
import 'package:Mirarr/seriesPage/function/to_video_player_series.dart';
import 'package:Mirarr/seriesPage/function/torrent_links_series.dart';
import 'package:Mirarr/seriesPage/function/watch_links_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:Mirarr/moviesPage/functions/check_direct_streams.dart';
import 'package:Mirarr/database/watch_history_database.dart';

final apiKey = dotenv.env['TMDB_API_KEY'];
final apiOmdbKey = dotenv.env['OMDB_API_KEY_FOR_EPISODES'];


final _cache = <String, dynamic>{};

Future<T> _cachedApiCall<T>(String url, Future<T> Function() apiCall) async {
  if (_cache.containsKey(url)) {
    return _cache[url] as T;
  }
  final result = await apiCall();
  _cache[url] = result;
  return result;
}

Future<String?> fetchImdbRating(
    String imdbId, int seasonNumber, int episodeNumber) async {
  return _cachedApiCall('imdb_rating_$imdbId$seasonNumber$episodeNumber',
      () async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://www.omdbapi.com/?i=$imdbId&season=$seasonNumber&Episode=$episodeNumber&apikey=$apiOmdbKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imdbRating'];
      }
    } catch (e) {
      throw Exception('Error fetching IMDb rating: $e');
    }
    return null;
  });
}

Future<Map<int, String>> fetchSeasonImdbRatings(
    String imdbId, int seasonNumber) async {
  return _cachedApiCall('season_ratings_$imdbId$seasonNumber', () async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://www.omdbapi.com/?i=$imdbId&Season=$seasonNumber&apikey=$apiOmdbKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final episodes = data['Episodes'] as List<dynamic>;
        return {
          for (var episode in episodes)
            episode['Episode'] is int
                ? episode['Episode'] as int
                : int.parse(episode['Episode']): episode['imdbRating'] as String
        };
      }
    } catch (e) {
      throw Exception('Error fetching IMDb rating: $e');
    }
    return {};
  });
}

Future<List<dynamic>> fetchSeasons(int serieId, BuildContext context) async {
  return _cachedApiCall('seasons_$serieId', () async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse('${baseUrl}tv/$serieId?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['seasons'];
    } else {
      throw Exception('Failed to load seasons');
    }
  });
}

void seasonsAndEpisodes(
    BuildContext context, int serieId, String serieName, String imdbId, {VoidCallback? onWatchStatusChanged}) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FutureBuilder<List<dynamic>>(
            future: fetchSeasons(serieId, context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No seasons found.'));
              } else {
                final seasons = snapshot.data!;
                seasons.sort((a, b) {
                  if (a['season_number'] == 0) return 1;
                  if (b['season_number'] == 0) return -1;
                  return a['season_number'].compareTo(b['season_number']);
                });

                return Container(
                  padding: const EdgeInsets.all(10),
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      physics: const BouncingScrollPhysics(),
                      scrollbars: true,
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TvChartTable(
                                          imdbId: imdbId,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        getSeriesColor(context, serieId),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text('View Episode Ratings Table',
                                      style: getSeriesButtonTextStyle(serieId)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 0, 16),
                                child: Text('Seasons',
                                    style: getSeriesTitleTextStyle(serieId)),
                              ),
                            ],
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final season = seasons[index];
                              final region = Provider.of<RegionProvider>(context,
                                      listen: false)
                                  .currentRegion;
                              final coverUrl = season['poster_path'] != null
                                  ? '${getImageBaseUrl(region)}/t/p/w500${season['poster_path']}'
                                  : null;
                              final isAirDateNull = season['air_date'] == null;
                              final isEpisodeCountZero =
                                  season['episode_count'] == 0;
                              return Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      width: 100,
                                      height: 100,
                                      color: coverUrl != null ? null : Colors.black,
                                      child: coverUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: CachedNetworkImage(
                                                imageUrl: coverUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(
                                                  color: Colors.black,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      season['season_number'] == 0
                                          ? 'Specials'
                                          : 'Season ${season['season_number']}',
                                      style: TextStyle(
                                        color: isAirDateNull
                                            ? Colors.grey
                                            : Colors.white,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Watch toggle icon for season
                                        SeasonWatchToggle(
                                          serieId: serieId,
                                          serieName: serieName,
                                          seasonNumber: season['season_number'],
                                          posterPath: season['poster_path'],
                                          onToggle: () {
                                            onWatchStatusChanged?.call();
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: isAirDateNull
                                              ? Colors.grey
                                              : getSeriesColor(context, serieId),
                                        ),
                                      ],
                                    ),
                                    onTap: isAirDateNull && isEpisodeCountZero
                                        ? null
                                        : () => episodesGuide(
                                            season['season_number'],
                                            context,
                                            serieId,
                                            serieName,
                                            imdbId,
                                            onWatchStatusChanged: onWatchStatusChanged),
                                  ),
                                  const CustomDivider()
                                ],
                              );
                            },
                            childCount: seasons.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      );
    },
  );
}

Future<List<dynamic>> fetchEpisodesGuide(BuildContext context, int seasonNumber,
    int serieId, String serieName, String imdbId) async {
  return _cachedApiCall('episodes_guide_$serieId$seasonNumber', () async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final episodesResponse = await http.get(
      Uri.parse('${baseUrl}tv/$serieId/season/$seasonNumber?api_key=$apiKey'),
    );

    final ratingsMap = await fetchSeasonImdbRatings(imdbId, seasonNumber);

    if (episodesResponse.statusCode == 200) {
      final data = json.decode(episodesResponse.body);
      final episodes = data['episodes'];

      for (var episode in episodes) {
        final episodeNumber = episode['episode_number'];
        episode['imdb_rating'] = ratingsMap[episodeNumber] ?? 'N/A';
      }

      return episodes;
    } else {
      throw Exception('Failed to load episodes');
    }
  });
}

void episodesGuide(int seasonNumber, BuildContext context, int serieId,
    String serieName, String imdbId, {VoidCallback? onWatchStatusChanged}) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FutureBuilder<List<dynamic>>(
            future: fetchEpisodesGuide(
                context, seasonNumber, serieId, serieName, imdbId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No episodes found.'));
              } else {
                final episodes = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(10),
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    children: [
                      Text('Episodes', style: getSeriesTitleTextStyle(serieId)),
                      const SizedBox(height: 10),
                      ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          scrollbars: true,
                          physics: const BouncingScrollPhysics(),
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: Expanded(
                          child: ListView.builder(
                            itemCount: episodes.length,
                            itemBuilder: (context, index) {
                              final episode = episodes[index];
                              final region = Provider.of<RegionProvider>(context,
                                      listen: false)
                                  .currentRegion;
                              final coverUrl = episode['still_path'] != null
                                  ? '${getImageBaseUrl(region)}/t/p/w500${episode['still_path']}'
                                  : null;

                              bool isReleased = true;
                              int daysUntilRelease = 0;
                              if (episode['air_date'] != null) {
                                final airDate = DateTime.parse(episode['air_date']);
                                isReleased = airDate.isBefore(DateTime.now());
                                if (!isReleased) {
                                  daysUntilRelease =
                                      airDate.difference(DateTime.now()).inDays;
                                }
                              }
                              return Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      width: 100,
                                      height: 100,
                                      color: coverUrl != null ? null : Colors.black,
                                      child: coverUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: CachedNetworkImage(
                                                imageUrl: coverUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(
                                                  color: Colors.black,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      episode['episode_number'] == 0
                                          ? 'Specials'
                                          : 'Episode ${episode['episode_number']}',
                                      style: TextStyle(
                                          color: isReleased
                                              ? Colors.white
                                              : Colors.grey),
                                    ),
                                    subtitle: episode['name'] != null ? Text(
                                      episode['name'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ) : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isReleased && daysUntilRelease >= 0)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 0, 8, 0),
                                            child: Text(
                                              '$daysUntilRelease days',
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        if (episode['imdb_rating'] != null &&
                                            episode['imdb_rating'] != 'N/A')
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Text(
                                              '⭐ ${episode['imdb_rating']}',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        // Watch toggle icon for episode
                                        EpisodeWatchToggle(
                                          serieId: serieId,
                                          serieName: serieName,
                                          seasonNumber: seasonNumber,
                                          episodeNumber: episode['episode_number'],
                                          episodeTitle: episode['name'],
                                          posterPath: coverUrl,
                                          onToggle: () {
                                            onWatchStatusChanged?.call();
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward,
                                            color: isReleased
                                                ? getSeriesColor(context, serieId)
                                                : Colors.grey),
                                      ],
                                    ),
                                    onTap: () => episodeDetails(
                                        seasonNumber,
                                        episode['episode_number'],
                                        context,
                                        serieId,
                                        serieName,
                                        imdbId,
                                        coverUrl,
                                        onWatchStatusChanged: onWatchStatusChanged),
                                  ),
                                  const CustomDivider()
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      );
    },
  );
}

Future<Map<String, dynamic>> fetchEpisodesDetails(BuildContext context,
    int seasonNumber, int episodeNumber, int serieId) async {
  return _cachedApiCall('episode_details_$serieId$seasonNumber$episodeNumber',
      () async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
          '${baseUrl}tv/$serieId/season/$seasonNumber/episode/$episodeNumber?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  });
}

void episodeDetails(int seasonNumber, int episodeNumber, BuildContext context,
    int serieId, String serieName, String imdbId, String? coverUrl, {VoidCallback? onWatchStatusChanged}) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: Future.wait([
              fetchEpisodesDetails(context, seasonNumber, episodeNumber, serieId),
              fetchImdbRating(imdbId, seasonNumber, episodeNumber),
              checkXprimeSeries(serieId, seasonNumber, episodeNumber, serieName),
              checkRiveSeries(serieId, seasonNumber, episodeNumber, serieName)
            ]).then((results) =>
                {'episodeDetails': results[0], 'imdbRating': results[1], 'xprimeAvailable': results[2], 'riveAvailable': results[3]}),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No data found.'));
              } else {
                final episodeDetails =
                    snapshot.data!['episodeDetails'] as Map<String, dynamic>;
                final imdbRating = snapshot.data!['imdbRating'];
                final overview =
                    episodeDetails['overview'] ?? 'No overview available.';
                final episodeName = episodeDetails['name'];
                final xprimeAvailable = snapshot.data!['xprimeAvailable'];
                final riveAvailable = snapshot.data!['riveAvailable'];
                return SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 10, 0, 0),
                          child: episodeName.isNotEmpty ? Text(episodeName,
                              style: getSeriesTitleTextStyle(serieId)) : Text('Episode Overview',
                              style: getSeriesTitleTextStyle(serieId)),
                        ),
                        const SizedBox(height: 10),
                        if (imdbRating != null && imdbRating.isNotEmpty && imdbRating != 'N/A')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Text(
                              'IMDB⭐ $imdbRating',
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        // Episode watch toggle button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: EpisodeWatchToggleButton(
                            serieId: serieId,
                            serieName: serieName,
                            seasonNumber: seasonNumber,
                            episodeNumber: episodeNumber,
                            episodeTitle: episodeName,
                            posterPath: coverUrl,
                            onToggle: () {
                              onWatchStatusChanged?.call();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Text(
                            overview,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                  child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: FloatingActionButton(
                                        backgroundColor: getSeriesColor(context, serieId),
                                        onPressed: () => showWatchOptions(context,
                                            serieId, seasonNumber, episodeNumber),
                                        child: Text(
                                          'Watch',
                                          style: getSeriesButtonTextStyle(serieId),
                                        ),
                                      ),
                                    ),
                                   xprimeAvailable && !Platform.isIOS || riveAvailable && !Platform.isIOS
                                        ? const SizedBox(width: 6)
                                        : const SizedBox(),
                                    Visibility(
                                      visible: xprimeAvailable && !Platform.isIOS || riveAvailable && !Platform.isIOS,
                                      child: FloatingActionButton(onPressed: () => showWatchOptionsDirectTV(context, serieId, seasonNumber, episodeNumber),
                                        child: Image.asset(
                                            'assets/images/vlc.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                        ),
                                    ),
                                  ],
                                ),
                              ))
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                  child: SizedBox(
                                width: double.infinity,
                                child: FloatingActionButton(
                                  backgroundColor: getSeriesColor(context, serieId),
                                  onPressed: () => showTorrentOptions(
                                      context,
                                      serieName,
                                      serieId,
                                      seasonNumber,
                                      episodeNumber,
                                      imdbId),
                                  child: Text(
                                    'Torrent Search',
                                    style: getSeriesButtonTextStyle(serieId),
                                  ),
                                ),
                              ))
                            ],
                          ),
                        ),
                        FutureBuilder(
                          future: fetchEpisodeCastAndCrew(
                              serieId, seasonNumber, episodeNumber, region),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Text(
                                  'Error loading cast and crew details');
                            } else {
                              final Map<String, List<Map<String, dynamic>>> data =
                                  snapshot.data
                                      as Map<String, List<Map<String, dynamic>>>;
                              final List<Map<String, dynamic>> castList =
                                  data['guest_stars'] ?? [];
                              final List<Map<String, dynamic>> crewList =
                                  data['crew'] ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (castList.isNotEmpty) ...[
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                      child: Text(
                                        'Guest Stars',
                                        textAlign: TextAlign.justify,
                                        style: getSeriesTitleTextStyle(serieId),
                                      ),
                                    ),
                                    const CustomDivider(),
                                    buildCastRow(castList, context),
                                  ],
                                  if (crewList.isNotEmpty) ...[
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                      child: Text(
                                        'Crew',
                                        textAlign: TextAlign.justify,
                                        style: getSeriesTitleTextStyle(serieId),
                                      ),
                                    ),
                                    const CustomDivider(),
                                    buildCrewRow(crewList, context)
                                  ],
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      );
    },
  );
}

// Watch history helper functions
final WatchHistoryDatabase _watchHistoryDb = WatchHistoryDatabase();

Future<bool> isSeasonWatched(int serieId, int seasonNumber, BuildContext context) async {
  try {
    // Get all episodes for this season from API
    final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final episodesResponse = await http.get(
      Uri.parse('${baseUrl}tv/$serieId/season/$seasonNumber?api_key=$apiKey'),
    );
    
    if (episodesResponse.statusCode == 200) {
      final episodeData = json.decode(episodesResponse.body);
      final episodesList = episodeData['episodes'] as List<dynamic>;
      final totalEpisodes = episodesList.length;
      
      if (totalEpisodes == 0) return false;
      
      // Get watched episodes for this season
      final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(serieId, 'tv');
      final watchedEpisodesInSeason = watchHistory.where((item) => item.seasonNumber == seasonNumber).length;
      
      return watchedEpisodesInSeason == totalEpisodes;
    }
  } catch (e) {
    // Fallback to old logic if API call fails
    final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(serieId, 'tv');
    final seasonEpisodes = watchHistory.where((item) => item.seasonNumber == seasonNumber).toList();
    return seasonEpisodes.isNotEmpty;
  }
  
  return false;
}

Future<bool> isEpisodeWatched(int serieId, int seasonNumber, int episodeNumber) async {
  return await _watchHistoryDb.isWatched(serieId, 'tv', seasonNumber: seasonNumber, episodeNumber: episodeNumber);
}

Future<void> toggleSeasonWatched(int serieId, String serieName, int seasonNumber, String? posterPath, BuildContext context, {VoidCallback? onToggle}) async {
  final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
  final baseUrl = getBaseUrl(region);
  
  // Check if season is currently watched
  final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(serieId, 'tv');
  final seasonEpisodes = watchHistory.where((item) => item.seasonNumber == seasonNumber).toList();
  
  if (seasonEpisodes.isNotEmpty) {
    // Remove all episodes of this season
    for (final episode in seasonEpisodes) {
      await _watchHistoryDb.deleteWatchHistoryItem(episode.id!);
    }
  } else {
    // Mark all episodes of this season as watched
    try {
      final episodesResponse = await http.get(
        Uri.parse('${baseUrl}tv/$serieId/season/$seasonNumber?api_key=$apiKey'),
      );
      
      if (episodesResponse.statusCode == 200) {
        final episodeData = json.decode(episodesResponse.body);
        final episodesList = episodeData['episodes'] as List<dynamic>;
        
        for (final episode in episodesList) {
          await _watchHistoryDb.addShowToHistory(
            tmdbId: serieId,
            title: serieName,
            posterPath: posterPath,
            seasonNumber: seasonNumber,
            episodeNumber: episode['episode_number'],
            episodeTitle: episode['name'],
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle season watch status: $e');
    }
  }
  
  // Call the callback to refresh parent state
  onToggle?.call();
}

Future<void> toggleEpisodeWatched(int serieId, String serieName, int seasonNumber, int episodeNumber, String? episodeTitle, String? posterPath, {VoidCallback? onToggle}) async {
  final isWatched = await isEpisodeWatched(serieId, seasonNumber, episodeNumber);
  
  if (isWatched) {
    // Remove episode from watch history
    final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(serieId, 'tv');
    final episode = watchHistory.firstWhere(
      (item) => item.seasonNumber == seasonNumber && item.episodeNumber == episodeNumber,
    );
    await _watchHistoryDb.deleteWatchHistoryItem(episode.id!);
  } else {
    // Add episode to watch history
    await _watchHistoryDb.addShowToHistory(
      tmdbId: serieId,
      title: serieName,
      posterPath: posterPath,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
    );
  }
  
  // Call the callback to refresh parent state
  onToggle?.call();
}

// Custom widget for smooth season watch toggle
class SeasonWatchToggle extends StatefulWidget {
  final int serieId;
  final String serieName;
  final int seasonNumber;
  final String? posterPath;
  final VoidCallback? onToggle;

  const SeasonWatchToggle({
    Key? key,
    required this.serieId,
    required this.serieName,
    required this.seasonNumber,
    required this.posterPath,
    this.onToggle,
  }) : super(key: key);

  @override
  State<SeasonWatchToggle> createState() => _SeasonWatchToggleState();
}

class _SeasonWatchToggleState extends State<SeasonWatchToggle> {
  bool? _isWatched;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchStatus();
  }

  Future<void> _loadWatchStatus() async {
    final isWatched = await isSeasonWatched(widget.serieId, widget.seasonNumber, context);
    if (mounted) {
      setState(() {
        _isWatched = isWatched;
      });
    }
  }

  Future<void> _toggleWatchStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await toggleSeasonWatched(
        widget.serieId,
        widget.serieName,
        widget.seasonNumber,
        widget.posterPath,
        context,
        onToggle: () {
          widget.onToggle?.call();
        },
      );
      
      // Update local state immediately for smooth transition
      setState(() {
        _isWatched = !(_isWatched ?? false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWatched == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey,
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleWatchStatus,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          _isWatched! ? Icons.check_circle : Icons.visibility_off,
          key: ValueKey(_isWatched),
          color: _isWatched! ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

// Custom widget for smooth episode watch toggle
class EpisodeWatchToggle extends StatefulWidget {
  final int serieId;
  final String serieName;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeTitle;
  final String? posterPath;
  final VoidCallback? onToggle;

  const EpisodeWatchToggle({
    Key? key,
    required this.serieId,
    required this.serieName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.posterPath,
    this.onToggle,
  }) : super(key: key);

  @override
  State<EpisodeWatchToggle> createState() => _EpisodeWatchToggleState();
}

class _EpisodeWatchToggleState extends State<EpisodeWatchToggle> {
  bool? _isWatched;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchStatus();
  }

  Future<void> _loadWatchStatus() async {
    final isWatched = await isEpisodeWatched(widget.serieId, widget.seasonNumber, widget.episodeNumber);
    if (mounted) {
      setState(() {
        _isWatched = isWatched;
      });
    }
  }

  Future<void> _toggleWatchStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await toggleEpisodeWatched(
        widget.serieId,
        widget.serieName,
        widget.seasonNumber,
        widget.episodeNumber,
        widget.episodeTitle,
        widget.posterPath,
        onToggle: () {
          widget.onToggle?.call();
        },
      );
      
      // Update local state immediately for smooth transition
      setState(() {
        _isWatched = !(_isWatched ?? false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWatched == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey,
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleWatchStatus,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          _isWatched! ? Icons.check_circle : Icons.visibility_off,
          key: ValueKey(_isWatched),
          color: _isWatched! ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

// Custom widget for smooth episode watch toggle button (for episode details)
class EpisodeWatchToggleButton extends StatefulWidget {
  final int serieId;
  final String serieName;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeTitle;
  final String? posterPath;
  final VoidCallback? onToggle;

  const EpisodeWatchToggleButton({
    Key? key,
    required this.serieId,
    required this.serieName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.posterPath,
    this.onToggle,
  }) : super(key: key);

  @override
  State<EpisodeWatchToggleButton> createState() => _EpisodeWatchToggleButtonState();
}

class _EpisodeWatchToggleButtonState extends State<EpisodeWatchToggleButton> {
  bool? _isWatched;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchStatus();
  }

  Future<void> _loadWatchStatus() async {
    final isWatched = await isEpisodeWatched(widget.serieId, widget.seasonNumber, widget.episodeNumber);
    if (mounted) {
      setState(() {
        _isWatched = isWatched;
      });
    }
  }

  Future<void> _toggleWatchStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await toggleEpisodeWatched(
        widget.serieId,
        widget.serieName,
        widget.seasonNumber,
        widget.episodeNumber,
        widget.episodeTitle,
        widget.posterPath,
        onToggle: () {
          widget.onToggle?.call();
        },
      );
      
      // Update local state immediately for smooth transition
      setState(() {
        _isWatched = !(_isWatched ?? false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWatched == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleWatchStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isWatched! ? Colors.green.withOpacity(0.7) : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Row(
            key: ValueKey(_isWatched),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isWatched! ? Icons.check_circle : Icons.visibility_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _isWatched! ? 'Watched' : 'Mark as Watched',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
