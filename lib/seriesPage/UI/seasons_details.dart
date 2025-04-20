import 'dart:convert';
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
import 'package:Mirarr/moviesPage/functions/check_xprime.dart';

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
    BuildContext context, int serieId, String serieName, String imdbId) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
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
                                trailing: Icon(
                                  Icons.arrow_forward,
                                  color: isAirDateNull
                                      ? Colors.grey
                                      : getSeriesColor(context, serieId),
                                ),
                                onTap: isAirDateNull && isEpisodeCountZero
                                    ? null
                                    : () => episodesGuide(
                                        season['season_number'],
                                        context,
                                        serieId,
                                        serieName,
                                        imdbId),
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
    String serieName, String imdbId) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
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
                                    imdbId),
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
    int serieId, String serieName, String imdbId) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          fetchEpisodesDetails(context, seasonNumber, episodeNumber, serieId),
          fetchImdbRating(imdbId, seasonNumber, episodeNumber),
          checkXprimeSeries(serieId, seasonNumber, episodeNumber) 
        ]).then((results) =>
            {'episodeDetails': results[0], 'imdbRating': results[1], 'xprimeAvailable': results[2]}),
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
            final xprimeAvailable = snapshot.data!['xprimeAvailable'];
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(25, 10, 0, 0),
                      child: Text('Episode Overview',
                          style: getSeriesTitleTextStyle(serieId)),
                    ),
                    const SizedBox(height: 10),
                    if (imdbRating != null && imdbRating.isNotEmpty)
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
                                xprimeAvailable
                                    ? const SizedBox(width: 6)
                                    : const SizedBox(),
                                Visibility(
                                  visible: xprimeAvailable,
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
}
