import 'dart:convert';

import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/seriesPage/function/fetch_episode_cast_crew.dart';
import 'package:Mirarr/seriesPage/function/torrent_links_series.dart';
import 'package:Mirarr/seriesPage/function/watch_links_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

Future<List<dynamic>> fetchSeasons(int serieId) async {
  final response = await http.get(
    Uri.parse('https://api.themoviedb.org/3/tv/$serieId?api_key=$apiKey'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final seasons = data['seasons'];
    return seasons;
  } else {
    throw Exception('Failed to load seasons');
  }
}

void seasonsAndEpisodes(
    BuildContext context, int serieId, String serieName, String imdbId) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<dynamic>>(
        future: fetchSeasons(serieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No seasons found.'));
          } else {
            final seasons = snapshot.data!;

            // Sort seasons to move "Specials" to the bottom
            seasons.sort((a, b) {
              if (a['season_number'] == 0) return 1;
              if (b['season_number'] == 0) return -1;
              return a['season_number'].compareTo(b['season_number']);
            });

            return Container(
              padding: const EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  const Text(
                    'Seasons',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: seasons.length,
                      itemBuilder: (context, index) {
                        final season = seasons[index];
                        final coverUrl = season['poster_path'] != null
                            ? 'https://image.tmdb.org/t/p/w500${season['poster_path']}'
                            : null;
                        final isAirDateNull = season['air_date'] == null;
                        final isEpisodeCountZero = season['episode_count'] == 0;
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
                                        child: Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
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
                                color:
                                    isAirDateNull ? Colors.grey : Colors.orange,
                              ),
                              onTap: isAirDateNull && isEpisodeCountZero
                                  ? null
                                  : () => episodesGuide(season['season_number'],
                                      context, serieId, serieName, imdbId),
                            ),
                            const CustomDivider()
                          ],
                        );
                      },
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

Future<List<dynamic>> fetchEpisodesGuide(
    int seasonNumber, int serieId, String serieName, String imdbId) async {
  final response = await http.get(
    Uri.parse(
        'https://api.themoviedb.org/3/tv/$serieId/season/$seasonNumber?api_key=$apiKey'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final episodes = data['episodes'];
    return episodes;
  } else {
    throw Exception('Failed to load episodes');
  }
}

void episodesGuide(seasonNumber, BuildContext context, int serieId,
    String serieName, String imdbId) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<dynamic>>(
        future: fetchEpisodesGuide(seasonNumber, serieId, serieName, imdbId),
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
                  const Text(
                    'Episodes',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        final coverUrl = episode['still_path'] != null
                            ? 'https://image.tmdb.org/t/p/w500${episode['still_path']}'
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
                                        child: Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
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
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 8, 0),
                                      child: Text(
                                        '$daysUntilRelease days',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  Icon(Icons.arrow_forward,
                                      color: isReleased
                                          ? Colors.orange
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
                ],
              ),
            );
          }
        },
      );
    },
  );
}

Future<Map<String, dynamic>> fetchEpisodesDetails(
    int seasonNumber, int episodeNumber, int serieId) async {
  final response = await http.get(
    Uri.parse(
        'https://api.themoviedb.org/3/tv/$serieId/season/$seasonNumber/episode/$episodeNumber?api_key=$apiKey'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Failed to load data');
  }
}

void episodeDetails(int seasonNumber, int episodeNumber, BuildContext context,
    int serieId, String serieName, String imdbId) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<Map<String, dynamic>>(
        future: fetchEpisodesDetails(seasonNumber, episodeNumber, serieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          } else {
            final data = snapshot.data!;
            final overview = data['overview'] ?? 'No overview available.';

            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(25, 10, 0, 0),
                      child: Text(
                        'Episode Overview',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            width: double.maxFinite,
                            child: FloatingActionButton(
                              backgroundColor: Theme.of(context).primaryColor,
                              onPressed: () => showWatchOptions(context,
                                  serieId, seasonNumber, episodeNumber),
                              child: const Text(
                                'Watch',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
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
                            width: double.maxFinite,
                            child: FloatingActionButton(
                              backgroundColor: Theme.of(context).primaryColor,
                              onPressed: () => showTorrentOptions(
                                  context,
                                  serieName,
                                  serieId,
                                  seasonNumber,
                                  episodeNumber,
                                  imdbId),
                              child: const Text(
                                'Torrent Search',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: fetchEpisodeCastAndCrew(
                          serieId, seasonNumber, episodeNumber),
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
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
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
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
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
