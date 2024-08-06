import 'dart:io';
import 'dart:ui';

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

class SerieDetailPageDesktop extends StatefulWidget {
  final String serieName;
  final int serieId;

  const SerieDetailPageDesktop(
      {super.key, required this.serieName, required this.serieId});

  @override
  _SerieDetailPageDesktopState createState() => _SerieDetailPageDesktopState();
}

int _selectedIndex = 0;

class _SerieDetailPageDesktopState extends State<SerieDetailPageDesktop> {
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
  String? posterPath;
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
          posterPath = responseData['poster_path'];
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
      appBar: Platform.isLinux || Platform.isWindows || Platform.isMacOS
          ? AppBar(
              toolbarHeight: 40,
              backgroundColor: Theme.of(context).primaryColor,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Text(
                    widget.serieName,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            )
          : null,
      body: serieDetails == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
                scrollbars: true,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                'https://image.tmdb.org/t/p/original$backdrops'),
                            fit: BoxFit.fitWidth,
                            opacity: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  'https://image.tmdb.org/t/p/original$posterPath',
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                height: 800,
                                width: 600,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20)),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: imageProvider,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                  ),
                                  child: Text(
                                    widget.serieName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // IconButton(
                                    //   onPressed: () {
                                    //     _castImagesFuture.then((imageUrls) {
                                    //       _openImageGallery(imageUrls);
                                    //     });
                                    //   },
                                    //   icon: const Icon(
                                    //     Icons.image_rounded,
                                    //     color: Colors.white,
                                    //   ),
                                    // ),
                                    Visibility(
                                      visible: isUserLoggedIn == true,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (isSerieWatchlist == null) {
                                            return;
                                          }
                                          final serieId = widget.serieId;
                                          final openbox =
                                              await Hive.openBox('sessionBox');
                                          final String accountId =
                                              openbox.get('accountId');
                                          final String sessionData =
                                              openbox.get('sessionData');
                                          if (isSerieWatchlist!) {
                                            // Remove from watchlist
                                            removeFromWatchList(accountId,
                                                sessionData, serieId, context);
                                            setState(() {
                                              isSerieWatchlist = false;
                                            });
                                          } else {
                                            // Add to watchlist
                                            addWatchList(accountId, sessionData,
                                                serieId, context);
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
                                    Visibility(
                                      visible: isUserLoggedIn == true,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (isSerieFavorite == null) {
                                            return;
                                          }
                                          final serieId = widget.serieId;
                                          final openbox =
                                              await Hive.openBox('sessionBox');
                                          final String accountId =
                                              openbox.get('accountId');
                                          final String sessionData =
                                              openbox.get('sessionData');
                                          if (isSerieFavorite!) {
                                            removeFromFavorite(accountId,
                                                sessionData, serieId, context);
                                            setState(() {
                                              isSerieFavorite = false;
                                            });
                                          } else {
                                            addFavorite(accountId, sessionData,
                                                serieId, context);
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
                                    // logged in and rated
                                    if (isUserLoggedIn == true &&
                                        isSerieRated != false &&
                                        userRating != null)
                                      Container(
                                        margin: const EdgeInsets.all(10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30))),
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: RatingBar.builder(
                                                      initialRating:
                                                          userRating ?? 0,
                                                      minRating: 1,
                                                      maxRating: 10,
                                                      itemSize: 35,
                                                      unratedColor: Colors.grey,
                                                      direction:
                                                          Axis.horizontal,
                                                      allowHalfRating: true,
                                                      itemCount: 10,
                                                      itemPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 0),
                                                      itemBuilder:
                                                          (context, _) =>
                                                              const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      onRatingUpdate:
                                                          (rating) async {
                                                        final serieId =
                                                            widget.serieId;
                                                        final openbox =
                                                            await Hive.openBox(
                                                                'sessionBox');

                                                        final String
                                                            sessionData =
                                                            openbox.get(
                                                                'sessionData');
                                                        addRating(
                                                            sessionData,
                                                            serieId,
                                                            rating,
                                                            context);
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
                                                      final openbox =
                                                          await Hive.openBox(
                                                              'sessionBox');

                                                      final String sessionData =
                                                          openbox.get(
                                                              'sessionData');
                                                      removeRating(
                                                          sessionData,
                                                          widget.serieId,
                                                          context);
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        isSerieRated = false;
                                                        userRating = null;
                                                      });
                                                    },
                                                    child: const Text(
                                                      ' 🗑️ Delete Rating',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                    //logged in not rated
                                    if (isUserLoggedIn == true &&
                                        isSerieRated == false &&
                                        userRating == null)
                                      Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          child: IconButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        RatingBar.builder(
                                                          initialRating: 5,
                                                          minRating: 1,
                                                          maxRating: 10,
                                                          itemSize: 35,
                                                          unratedColor:
                                                              Colors.grey,
                                                          direction:
                                                              Axis.horizontal,
                                                          allowHalfRating: true,
                                                          itemCount: 10,
                                                          itemPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      0),
                                                          itemBuilder:
                                                              (context, _) =>
                                                                  const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                          ),
                                                          onRatingUpdate:
                                                              (rating) async {
                                                            final serieId =
                                                                widget.serieId;
                                                            final openbox =
                                                                await Hive.openBox(
                                                                    'sessionBox');

                                                            final String
                                                                sessionData =
                                                                openbox.get(
                                                                    'sessionData');
                                                            addRating(
                                                                sessionData,
                                                                serieId,
                                                                rating,
                                                                context);
                                                            setState(() {
                                                              isSerieRated =
                                                                  '"value":$rating';
                                                              userRating =
                                                                  rating;
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
                                    Container(
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30))),
                                      child: Text(
                                        '⭐ ${score?.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: imdbRating != null &&
                                          imdbRating!.isNotEmpty,
                                      child: Container(
                                        margin: const EdgeInsets.all(5),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30))),
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
                                    Visibility(
                                      visible: rottenTomatoesRating != 'N/A',
                                      child: Container(
                                        margin: const EdgeInsets.all(5),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30))),
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

                                    Center(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: (genres as List<dynamic>)
                                              .map<Widget>((genre) {
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
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 10, 25, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                          child: SizedBox(
                                        width: 400,
                                        child: FloatingActionButton(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          onPressed: () => seasonsAndEpisodes(
                                              context,
                                              widget.serieId,
                                              widget.serieName,
                                              imdbId!),
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
                                const CustomDivider(),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  child: Container(
                                      width: 600,
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
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          margin: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                                padding:
                                                    const EdgeInsets.all(8.0),
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
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          margin: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                                padding:
                                                    const EdgeInsets.all(8.0),
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
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          margin: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                                padding:
                                                    const EdgeInsets.all(8.0),
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
                              ],
                            ),
                          ],
                        ),
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
                                          fontSize: Platform.isAndroid ||
                                                  Platform.isIOS
                                              ? 18
                                              : 30,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  )
                                ],
                              ),
                              const CustomDivider(),
                              buildCastRowDesktop(castList, context),
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
                                          fontSize: Platform.isAndroid ||
                                                  Platform.isIOS
                                              ? 18
                                              : 30,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const CustomDivider(),
                              buildCrewRowDesktop(crewList, context)
                            ],
                          );
                        }
                      },
                    ),
                    const CustomDivider(),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    //   child: Container(
                    //     alignment: Alignment.center,
                    //     child: ExpansionTile(
                    //       collapsedIconColor: Theme.of(context).primaryColor,
                    //       title: Text(
                    //         'Other Info',
                    //         style: TextStyle(
                    //           color: Theme.of(context).primaryColor,
                    //           fontSize:
                    //               Platform.isAndroid || Platform.isIOS ? 18 : 30,
                    //         ),
                    //       ),
                    //       children: [
                    //         Padding(
                    //           padding: const EdgeInsets.fromLTRB(25, 10, 0, 0),
                    //           child: Row(
                    //             mainAxisAlignment: MainAxisAlignment.start,
                    //             children: [
                    //               Column(
                    //                 crossAxisAlignment: CrossAxisAlignment.start,
                    //                 children: [
                    //                   budget != null && budget != 0
                    //                       ? Column(
                    //                           crossAxisAlignment:
                    //                               CrossAxisAlignment.start,
                    //                           mainAxisAlignment:
                    //                               MainAxisAlignment.start,
                    //                           children: [
                    //                             Text(
                    //                               'Budget',
                    //                               style: TextStyle(
                    //                                   fontSize: 18,
                    //                                   color: Theme.of(context)
                    //                                       .primaryColor),
                    //                             ),
                    //                             Text(
                    //                               '\$${NumberFormat("#,##0").format(budget)}',
                    //                               style: const TextStyle(
                    //                                   fontSize: 18,
                    //                                   color: Colors.white),
                    //                             ),
                    //                           ],
                    //                         )
                    //                       : Container(),
                    //                   const CustomDivider(),
                    //                   revenue != null && revenue != 0
                    //                       ? Column(
                    //                           crossAxisAlignment:
                    //                               CrossAxisAlignment.start,
                    //                           mainAxisAlignment:
                    //                               MainAxisAlignment.start,
                    //                           children: [
                    //                             Text(
                    //                               'Revenue',
                    //                               style: TextStyle(
                    //                                   fontSize: 18,
                    //                                   color: Theme.of(context)
                    //                                       .primaryColor),
                    //                             ),
                    //                             Text(
                    //                               '\$${NumberFormat("#,##0").format(revenue)}',
                    //                               style: const TextStyle(
                    //                                   fontSize: 18,
                    //                                   color: Colors.white),
                    //                             ),
                    //                           ],
                    //                         )
                    //                       : Container(),
                    //                   const CustomDivider(),
                    //                   Text(
                    //                     'Production Countries',
                    //                     style: TextStyle(
                    //                         fontSize: 18,
                    //                         color:
                    //                             Theme.of(context).primaryColor),
                    //                   ),
                    //                   Column(
                    //                     crossAxisAlignment:
                    //                         CrossAxisAlignment.start,
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.center,
                    //                     children:
                    //                         (productionCountries as List<dynamic>)
                    //                             .map<Widget>((productionCountry) {
                    //                       return Text(
                    //                         productionCountry['name'],
                    //                         style: const TextStyle(
                    //                           fontSize: 14,
                    //                           color: Colors.white,
                    //                           fontWeight: FontWeight.w200,
                    //                         ),
                    //                       );
                    //                     }).toList(),
                    //                   ),
                    //                   const CustomDivider(),
                    //                   Column(
                    //                     crossAxisAlignment:
                    //                         CrossAxisAlignment.start,
                    //                     children: [
                    //                       Text(
                    //                         'Production Companies',
                    //                         style: TextStyle(
                    //                             fontSize: 18,
                    //                             color: Theme.of(context)
                    //                                 .primaryColor),
                    //                       ),
                    //                       Column(
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         mainAxisAlignment:
                    //                             MainAxisAlignment.center,
                    //                         children: (productionCompanies
                    //                                 as List<dynamic>)
                    //                             .map<Widget>((productionCompany) {
                    //                           return Text(
                    //                             productionCompany['name'],
                    //                             style: const TextStyle(
                    //                               fontSize: 14,
                    //                               color: Colors.white,
                    //                               fontWeight: FontWeight.w200,
                    //                             ),
                    //                           );
                    //                         }).toList(),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                   const CustomDivider(),
                    //                   Column(
                    //                     crossAxisAlignment:
                    //                         CrossAxisAlignment.start,
                    //                     children: [
                    //                       Text(
                    //                         'Spoken Languages',
                    //                         style: TextStyle(
                    //                             fontSize: 18,
                    //                             color: Theme.of(context)
                    //                                 .primaryColor),
                    //                       ),
                    //                       Column(
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         mainAxisAlignment:
                    //                             MainAxisAlignment.center,
                    //                         children: (spokenLanguages
                    //                                 as List<dynamic>)
                    //                             .map<Widget>((spokenLanguage) {
                    //                           return Text(
                    //                             spokenLanguage['name'],
                    //                             style: const TextStyle(
                    //                               fontSize: 14,
                    //                               color: Colors.white,
                    //                               fontWeight: FontWeight.w200,
                    //                             ),
                    //                           );
                    //                         }).toList(),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ],
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
