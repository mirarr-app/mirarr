import 'package:Mirarr/seriesPage/UI/seasons_details.dart';
import 'package:Mirarr/seriesPage/function/get_imdb_rating_series.dart';
import 'package:Mirarr/seriesPage/function/series_tmdb_actions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/widgets/custom_divider.dart';

class SerieDetailPage extends StatefulWidget {
  final String serieName;
  final int serieId;

  const SerieDetailPage(
      {super.key, required this.serieName, required this.serieId});

  @override
  _SerieDetailPageState createState() => _SerieDetailPageState();
}

int _selectedIndex = 0;

class _SerieDetailPageState extends State<SerieDetailPage> {
  final apiKey = dotenv.env['TMDB_API_KEY'];
  Map<String, dynamic>? serieDetails;
  Map<String, dynamic>? externalIds;

  Map<String, dynamic>? serieInfo;
  bool? isSerieWatchlist;
  bool? isSerieFavorite;
  bool isUserLoggedIn = false;
  dynamic isSerieRated;
  double? userRating;
  double? userScore;

  double? popularity;
  int? budget;
  List<dynamic>? genres;
  String? backdrops;
  double? score;
  String? about;
  int? duration;
  String? releaseDate;
  String? language;
  int? seasons;
  int? episodes;
  String? imdbId;
  String? imdbRating;
  String rottenTomatoesRating = 'N/A';

  @override
  void initState() {
    super.initState();
    checkUserLogin();

    checkAccountState();
    fetchSerieDetails();
    fetchCredits(widget.serieId);
    fetchExternalId();
  }

  Future<void> checkUserLogin() async {
    final openbox = await Hive.openBox('sessionBox');
    final sessionData = openbox.get('sessionData');
    if (sessionData != null) {
      setState(() {
        isUserLoggedIn = true;
      });
    }
  }

  Future<void> checkAccountState() async {
    final openbox = await Hive.openBox('sessionBox');
    final sessionId = openbox.get('sessionData');
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/tv/${widget.serieId}/account_states?api_key=$apiKey&session_id=$sessionId',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        isSerieWatchlist = responseData['watchlist'];
        isSerieFavorite = responseData['favorite'];
        isSerieRated = responseData['rated'];
        if (isSerieRated != false) {
          userRating = responseData['rated']['value'];
        }
      });
    }
  }

  Future<void> fetchSerieDetails() async {
    try {
      // Make an HTTP GET request to fetch movie details from the first API
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/${widget.serieId}?api_key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          serieDetails = responseData;
          budget = responseData['budget'];
          genres = responseData['genres'];
          backdrops = responseData['backdrop_path'];
          score = responseData['vote_average'];
          about = responseData['overview'];
          duration = responseData['runtime'];
          releaseDate = responseData['release_date'];
          language = responseData['original_language'];
          seasons = responseData['number_of_seasons'];
          episodes = responseData['number_of_episodes'];
        });
      } else {
        throw Exception('Failed to load serie details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  void updateImdbRating(String rating) {
    setState(() {
      imdbRating = rating;
    });
  }

  void updateRottenTomatoesRating(String rating) {
    setState(() {
      rottenTomatoesRating = rating;
    });
  }

  Future<void> fetchExternalId() async {
    try {
      // Make an HTTP GET request to fetch movie details from the first API
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/${widget.serieId}/external_ids?api_key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          externalIds = responseData;
          imdbId = responseData['imdb_id'];
        });
        if (imdbId != null) {
          await getSerieRatings(
              imdbId, updateImdbRating, updateRottenTomatoesRating);
        }
      } else {
        throw Exception('Failed to load serie details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchCredits(
      int serieId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/$serieId/credits?api_key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> castList = responseData['cast'];
        final List<Map<String, dynamic>> allCastList =
            castList.cast<Map<String, dynamic>>().toList();

        // Fetch director details
        final List<dynamic> crewList = responseData['crew'];
        final List<Map<String, dynamic>> allCrewList =
            crewList.cast<Map<String, dynamic>>().toList();

        return {
          'cast': allCastList,
          'crew': allCrewList,
        };
      } else {
        throw Exception('Failed to load cast and crew details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return {
        'cast': [],
        'crew': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: serieDetails == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/original$backdrops',
                          placeholder: (context, url) => const Center(
                              child:
                                  CircularProgressIndicator()), // Placeholder widget while loading.
                          errorWidget: (context, url, error) => const Icon(Icons
                              .error), // Widget to display when there's an error loading the image.
                          imageBuilder: (context, imageProvider) => Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: imageProvider,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 320,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black, Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 70,
                          left: 10,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: Colors.black38,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30))),
                            child: Text(
                              'TMDB⭐ ${score?.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13,
                                color: Colors
                                    .white, // Text color on top of the image
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: imdbRating != null && imdbRating!.isNotEmpty,
                          child: Positioned(
                            bottom: 70,
                            left: 110,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: Text(
                                'IMDB⭐ $imdbRating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: rottenTomatoesRating != 'N/A',
                          child: Positioned(
                            bottom: 70,
                            left: 210,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: Text(
                                'Rotten Tomatoes🍅 $rottenTomatoesRating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                width: MediaQuery.of(context).size.width -
                                    20, // Adjust the width as needed
                                child: Text(
                                  widget.serieName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                width: MediaQuery.of(context).size.width - 20,
                                child: Text(
                                  widget.serieName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: isUserLoggedIn == true,
                          child: Positioned(
                            top: 40,
                            right: 30,
                            child: GestureDetector(
                              onTap: () async {
                                if (isSerieWatchlist == null) {
                                  return;
                                }
                                final movieId = widget.serieId;
                                final openbox =
                                    await Hive.openBox('sessionBox');
                                final String accountId =
                                    openbox.get('accountId');
                                final String sessionData =
                                    openbox.get('sessionData');
                                if (isSerieWatchlist!) {
                                  // Remove from watchlist
                                  removeFromWatchList(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isSerieWatchlist = false;
                                  });
                                } else {
                                  // Add to watchlist
                                  addWatchList(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isSerieWatchlist = true;
                                  });
                                }
                              },
                              child: Icon(
                                isSerieWatchlist == null
                                    ? Icons.bookmark_border
                                    : isSerieWatchlist!
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isUserLoggedIn == true,
                          child: Positioned(
                            top: 40,
                            right: 80,
                            child: GestureDetector(
                              onTap: () async {
                                if (isSerieFavorite == null) {
                                  return;
                                }
                                final movieId = widget.serieId;
                                final openbox =
                                    await Hive.openBox('sessionBox');
                                final String accountId =
                                    openbox.get('accountId');
                                final String sessionData =
                                    openbox.get('sessionData');
                                if (isSerieFavorite!) {
                                  removeFromFavorite(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isSerieFavorite = false;
                                  });
                                } else {
                                  addFavorite(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isSerieFavorite = true;
                                  });
                                }
                              },
                              child: Icon(
                                isSerieFavorite == null
                                    ? Icons.favorite_border
                                    : isSerieFavorite!
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        // logged in and rated
                        if (isUserLoggedIn == true &&
                            isSerieRated != false &&
                            userRating != null)
                          Positioned(
                            top: 40,
                            left: 8,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RatingBar.builder(
                                            initialRating: userRating ?? 0,
                                            minRating: 1,
                                            maxRating: 10,
                                            itemSize: 35,
                                            unratedColor: Colors.grey,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 10,
                                            itemPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 0),
                                            itemBuilder: (context, _) =>
                                                const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            onRatingUpdate: (rating) async {
                                              final movieId = widget.serieId;
                                              final openbox =
                                                  await Hive.openBox(
                                                      'sessionBox');

                                              final String sessionData =
                                                  openbox.get('sessionData');
                                              addRating(sessionData, movieId,
                                                  rating, context);
                                              setState(() {
                                                isSerieRated != false;
                                                userRating = rating;
                                              });
                                            },
                                          ),
                                        ),
                                        const CustomDivider(),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final openbox = await Hive.openBox(
                                                'sessionBox');

                                            final String sessionData =
                                                openbox.get('sessionData');
                                            removeRating(sessionData,
                                                widget.serieId, context);
                                            Navigator.of(context).pop();
                                            setState(() {
                                              isSerieRated = false;
                                              userRating = null;
                                            });
                                          },
                                          child: const Text(
                                            ' 🗑️ Delete Rating',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                child: Text(
                                  '👤 ${userRating?.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        //logged in not rated
                        if (isUserLoggedIn == true &&
                            isSerieRated == false &&
                            userRating == null)
                          Positioned(
                            top: 40,
                            left: 20,
                            child: Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30))),
                                child: IconButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              RatingBar.builder(
                                                initialRating: 5,
                                                minRating: 1,
                                                maxRating: 10,
                                                itemSize: 35,
                                                unratedColor: Colors.grey,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 10,
                                                itemPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 0),
                                                itemBuilder: (context, _) =>
                                                    const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                onRatingUpdate: (rating) async {
                                                  final movieId =
                                                      widget.serieId;
                                                  final openbox =
                                                      await Hive.openBox(
                                                          'sessionBox');

                                                  final String sessionData =
                                                      openbox
                                                          .get('sessionData');
                                                  addRating(sessionData,
                                                      movieId, rating, context);
                                                  setState(() {
                                                    isSerieRated =
                                                        '"value":$rating';
                                                    userRating = rating;
                                                  });
                                                },
                                              ),
                                              const SizedBox(
                                                height: 40,
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_reaction,
                                      color: Colors.white,
                                    ))),
                          ),
                      ],
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                (genres as List<dynamic>).map<Widget>((genre) {
                              return Text(
                                genre['name'] + ' | ',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w200),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Divider(color: Colors.white60, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            about!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300),
                            textAlign: TextAlign.left,
                          )),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Divider(color: Colors.white60, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Seasons',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$seasons',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Episodes',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$episodes',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Language',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      language != null
                                          ? language!.toUpperCase()
                                          : 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                              onPressed: () => seasonsAndEpisodes(context,
                                  widget.serieId, widget.serieName, imdbId!),
                              child: const Text(
                                'Details',
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
                      future: fetchCredits(widget.serieId),
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
                              data['cast'] ?? [];
                          final List<Map<String, dynamic>> crewList =
                              data['crew'] ?? [];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                    child: Text(
                                      'Cast',
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  )
                                ],
                              ),
                              const CustomDivider(),
                              buildCastRow(castList, context),
                              Row(
                                children: [
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
                                ],
                              ),
                              const CustomDivider(),
                              buildCrewRow(crewList, context)
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: const BottomBar());
  }
}
