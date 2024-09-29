import 'dart:io';

import 'package:Mirarr/moviesPage/functions/get_imdb_rating.dart';
import 'package:Mirarr/moviesPage/functions/movie_tmdb_actions.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:Mirarr/moviesPage/functions/torrent_links.dart';
import 'package:Mirarr/moviesPage/functions/watch_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/moviesPage/functions/check_availability.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:Mirarr/widgets/image_gallery_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieDetailPage extends StatefulWidget {
  final String movieTitle;
  final int movieId;

  const MovieDetailPage(
      {super.key, required this.movieTitle, required this.movieId});

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late Future<List<String>> _castImagesFuture;
  bool? isMovieWatchlist;
  bool? isMovieFavorite;
  bool isUserLoggedIn = false;
  dynamic isMovieRated;
  double? userRating;
  double? userScore;

  final apiKey = dotenv.env['TMDB_API_KEY'];

  Map<String, dynamic>? moviedetails;
  Map<String, dynamic>? movieInfo;

  double? popularity;
  int? budget;
  int? revenue;
  List<dynamic>? genres;
  List<dynamic>? productionCountries;
  List<dynamic>? productionCompanies;
  List<dynamic>? spokenLanguages;

  String? backdrops;
  double? score;
  String? about;
  int? duration;
  String? releaseDate;
  String? language;
  String? imdbId;
  String? imdbRating;
  String rottenTomatoesRating = 'N/A';

  @override
  void initState() {
    super.initState();
    checkUserLogin();
    fetchMovieDetails();
    checkAccountState();
    _loadMovieImages();

    fetchCredits(widget.movieId);
  }

  void _loadMovieImages() {
    _castImagesFuture = _fetchMovieImages(widget.movieId);
  }

  void _openImageGallery(List<String> imageUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryPage(imageUrls: imageUrls),
      ),
    );
  }

  Future<List<dynamic>> _fetchOtherMoviesByDirector(int castId) async {
    final response = await http.get(
      Uri.parse(
          'https://tmdb.maybeparsa.top/tmdb/person/$castId/movie_credits?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> movies = decoded['crew'];

      Set<int> movieIds = {};

      List<dynamic> filteredMovies = [];

      for (var movie in movies) {
        // Check if the crew member's job is "Director"
        if (movie['job'] == 'Director') {
          // Add the movie only if it has a poster path and not already added
          if (movie['poster_path'] != null &&
              movie['poster_path'] != '' &&
              !movieIds.contains(movie['id'])) {
            filteredMovies.add(movie);
            movieIds.add(movie['id']);
          }
        }
      }
      return filteredMovies;
    } else {
      throw Exception('Failed to load other movies');
    }
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
        'https://tmdb.maybeparsa.top/tmdb/movie/${widget.movieId}/account_states?api_key=$apiKey&session_id=$sessionId',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        isMovieWatchlist = responseData['watchlist'];
        isMovieFavorite = responseData['favorite'];
        isMovieRated = responseData['rated'];
        if (isMovieRated != false) {
          userRating = responseData['rated']['value'];
        }
      });
    }
  }

  Future<List<String>> _fetchMovieImages(int movieId) async {
    final response = await http.get(
      Uri.parse(
          'https://tmdb.maybeparsa.top/tmdb/movie/$movieId/images?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['backdrops'];
      return data.map((image) => image['file_path'] as String).toList();
    } else {
      throw Exception('Failed to load cast images');
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

  Future<void> fetchMovieDetails() async {
    try {
      // Make an HTTP GET request to fetch movie details from the first API
      final response = await http.get(
        Uri.parse(
          'https://tmdb.maybeparsa.top/tmdb/movie/${widget.movieId}?api_key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          moviedetails = responseData;
          budget = responseData['budget'];
          revenue = responseData['revenue'];
          genres = responseData['genres'];
          backdrops = responseData['backdrop_path'];
          score = responseData['vote_average'];
          about = responseData['overview'];
          duration = responseData['runtime'];
          releaseDate = responseData['release_date'];
          language = responseData['original_language'];
          productionCountries = responseData['production_countries'];
          productionCompanies = responseData['production_companies'];
          spokenLanguages = responseData['spoken_languages'];
          imdbId = responseData['imdb_id'];
        });
        if (imdbId != null) {
          await getMovieRatings(
              imdbId, updateImdbRating, updateRottenTomatoesRating);
        }
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchCredits(
      int movieId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://tmdb.maybeparsa.top/tmdb/movie/$movieId/credits?api_key=$apiKey',
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
    int? hours = duration != null ? duration! ~/ 60 : null;
    int? minutes = duration != null ? duration! % 60 : null;
    String year = releaseDate != null && releaseDate!.isNotEmpty
        ? releaseDate!.substring(0, 4)
        : 'NA';
    return Scaffold(
      body: moviedetails == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      _castImagesFuture.then((imageUrls) {
                        _openImageGallery(imageUrls);
                      });
                    },
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              'https://tmdbpics.maybeparsa.top/t/p/original$backdrops',
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
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
                                fontSize: 12,
                                color: Colors.white,
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
                                  fontSize: 12,
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
                                  fontSize: 12,
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
                                width: MediaQuery.of(context).size.width - 20,
                                child: Text(
                                  widget.movieTitle,
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                if (isMovieWatchlist == null) {
                                  return;
                                }
                                final movieId = widget.movieId;
                                final openbox =
                                    await Hive.openBox('sessionBox');
                                final String accountId =
                                    openbox.get('accountId');
                                final String sessionData =
                                    openbox.get('sessionData');
                                if (isMovieWatchlist!) {
                                  // Remove from watchlist
                                  removeFromWatchList(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isMovieWatchlist = false;
                                  });
                                } else {
                                  // Add to watchlist
                                  addWatchList(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isMovieWatchlist = true;
                                  });
                                }
                              },
                              child: Icon(
                                isMovieWatchlist == null
                                    ? Icons.bookmark_border
                                    : isMovieWatchlist!
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
                                if (isMovieFavorite == null) {
                                  return;
                                }
                                final movieId = widget.movieId;
                                final openbox =
                                    await Hive.openBox('sessionBox');
                                final String accountId =
                                    openbox.get('accountId');
                                final String sessionData =
                                    openbox.get('sessionData');
                                if (isMovieFavorite!) {
                                  removeFromFavorite(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isMovieFavorite = false;
                                  });
                                } else {
                                  addFavorite(
                                      accountId, sessionData, movieId, context);
                                  setState(() {
                                    isMovieFavorite = true;
                                  });
                                }
                              },
                              child: Icon(
                                isMovieFavorite == null
                                    ? Icons.favorite_border
                                    : isMovieFavorite!
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
                            isMovieRated != false &&
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
                                              final movieId = widget.movieId;
                                              final openbox =
                                                  await Hive.openBox(
                                                      'sessionBox');

                                              final String sessionData =
                                                  openbox.get('sessionData');
                                              addRating(sessionData, movieId,
                                                  rating, context);
                                              setState(() {
                                                isMovieRated != false;
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
                                                widget.movieId, context);
                                            Navigator.of(context).pop();
                                            setState(() {
                                              isMovieRated = false;
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
                            isMovieRated == false &&
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
                                                      widget.movieId;
                                                  final openbox =
                                                      await Hive.openBox(
                                                          'sessionBox');

                                                  final String sessionData =
                                                      openbox
                                                          .get('sessionData');
                                                  addRating(sessionData,
                                                      movieId, rating, context);
                                                  setState(() {
                                                    isMovieRated =
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
                  ),
                  Center(
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
                  const CustomDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          about!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.left,
                        )),
                  ),
                  const CustomDivider(),
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
                                  'Duration',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${hours}H ${minutes}M",
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
                                  'Year',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    year,
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
                          child: FutureBuilder(
                              future: checkAvailability(widget.movieId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Display loading indicator while fetching data
                                  return const SizedBox();
                                } else if (snapshot.hasError) {
                                  // Display error message if fetching data fails
                                  return const Text('Error loading data');
                                } else {
                                  // Display check mark if results are not empty
                                  return snapshot.data == true
                                      ? SizedBox(
                                          width: double.maxFinite,
                                          child: FloatingActionButton(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            onPressed: () => showWatchOptions(
                                                context, widget.movieId),
                                            child: const Text(
                                              'Watch',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : const SizedBox();
                                }
                              }),
                        )
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
                                widget.movieId,
                                widget.movieTitle,
                                releaseDate,
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
                    future: fetchCredits(widget.movieId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                  const CustomDivider(),
                  FutureBuilder(
                    future: fetchCredits(widget.movieId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Text(
                            'Error loading cast and crew details');
                      } else {
                        final Map<String, List<Map<String, dynamic>>> data =
                            snapshot.data
                                as Map<String, List<Map<String, dynamic>>>;

                        final List<Map<String, dynamic>> crewList =
                            data['crew'] ?? [];

                        Map<String, dynamic>? director;

                        for (var crewMember in crewList) {
                          if (crewMember['job'] == 'Director') {
                            director = crewMember;
                            break;
                          }
                        }

                        if (director != null) {
                          return Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 0, 10, 0),
                                  child: Text(
                                    "Movies by ${director['name']}",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future:
                                    _fetchOtherMoviesByDirector(director['id']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return const Text(
                                        'Error loading other movies');
                                  } else {
                                    List<dynamic> movies =
                                        snapshot.data as List<dynamic>;

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: movies.map((movie) {
                                          return Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Card(
                                                    elevation: 4,
                                                    child: GestureDetector(
                                                      onTap: () => Platform
                                                                  .isAndroid ||
                                                              Platform.isIOS
                                                          ? onTapMovie(
                                                              movie['title'],
                                                              movie['id'],
                                                              context)
                                                          : onTapMovieDesktop(
                                                              movie['title'],
                                                              movie['id'],
                                                              context),
                                                      child: Container(
                                                        height: 200,
                                                        width: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          image: movie[
                                                                      'poster_path']
                                                                  .isNotEmpty
                                                              ? DecorationImage(
                                                                  image:
                                                                      CachedNetworkImageProvider(
                                                                    'https://tmdbpics.maybeparsa.top/t/p/w200${movie['poster_path']}',
                                                                  ),
                                                                  fit: BoxFit
                                                                      .cover,
                                                                )
                                                              : null, // No image if there's no poster path
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 70,
                                                    child: Text(
                                                      movie['title'],
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ));
                                        }).toList(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                    },
                  ),
                  const CustomDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Container(
                      alignment: Alignment.center,
                      child: ExpansionTile(
                        collapsedIconColor: Theme.of(context).primaryColor,
                        title: Text(
                          'Other Info',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(25, 10, 0, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    budget != null && budget != 0
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Budget',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                              ),
                                              Text(
                                                '\$${NumberFormat("#,##0").format(budget)}',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    const CustomDivider(),
                                    revenue != null && revenue != 0
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Revenue',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                              ),
                                              Text(
                                                '\$${NumberFormat("#,##0").format(revenue)}',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    const CustomDivider(),
                                    Text(
                                      'Production Countries',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          (productionCountries as List<dynamic>)
                                              .map<Widget>((productionCountry) {
                                        return Text(
                                          productionCountry['name'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w200,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const CustomDivider(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Production Companies',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: (productionCompanies
                                                  as List<dynamic>)
                                              .map<Widget>((productionCompany) {
                                            return Text(
                                              productionCompany['name'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w200,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                    const CustomDivider(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Spoken Languages',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: (spokenLanguages
                                                  as List<dynamic>)
                                              .map<Widget>((spokenLanguage) {
                                            return Text(
                                              spokenLanguage['name'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w200,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
