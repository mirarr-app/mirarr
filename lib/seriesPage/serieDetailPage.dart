import 'dart:io';

import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/functions/fetchers/fetch_serie_details.dart';
import 'package:Mirarr/functions/fetchers/fetch_series_credits.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/share_content.dart';
import 'package:Mirarr/seriesPage/UI/seasons_details.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/seriesPage/function/get_imdb_rating_series.dart';
import 'package:Mirarr/seriesPage/function/series_tmdb_actions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class SerieDetailPage extends StatefulWidget {
  final String serieName;
  final int serieId;

  const SerieDetailPage(
      {super.key, required this.serieName, required this.serieId});

  @override
  _SerieDetailPageState createState() => _SerieDetailPageState();
}

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
String? posterPath;
  final screenShotController = ScreenshotController();

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
  final WatchHistoryDatabase _watchHistoryDb = WatchHistoryDatabase();
  
  // Key to force refresh of ShowWatchToggle
  final GlobalKey<_ShowWatchToggleState> _showWatchToggleKey = GlobalKey<_ShowWatchToggleState>();

  @override
  void initState() {
    super.initState();
    checkUserLogin();

    checkAccountState();
    _fetchSerieDetails();

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    fetchCredits(widget.serieId, region);
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
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
          '${baseUrl}tv/${widget.serieId}/account_states?api_key=$apiKey&session_id=$sessionId'),
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

  Future<void> _fetchSerieDetails() async {
    try {
      // Make an HTTP GET request to fetch movie details from the first API
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final responseData = await fetchSerieDetails(widget.serieId, region);
      setState(() {
        serieDetails = responseData;
        budget = responseData['budget'];
        genres = responseData['genres'];
        backdrops = responseData['backdrop_path'];
        score = responseData['vote_average'];
        about = responseData['overview'];
        duration = responseData['runtime'];
                posterPath = responseData['poster_path'];

        releaseDate = responseData['release_date'];
        language = responseData['original_language'];
        seasons = responseData['number_of_seasons'];
        episodes = responseData['number_of_episodes'];
      });
    } catch (e) {
      throw Exception('Failed to load serie details');
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
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final baseUrl = getBaseUrl(region);
      final response = await http.get(
        Uri.parse(
            '${baseUrl}tv/${widget.serieId}/external_ids?api_key=$apiKey'),
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
      throw Exception('Failed to load external Id');
    }
  }

  void _refreshShowWatchStatus() {
    _showWatchToggleKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
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
                            '${getImageBaseUrl(region)}/t/p/original$backdrops',
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
                        visible: imdbRating != null &&
                            imdbRating!.isNotEmpty &&
                            imdbRating != 'N/A',
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
                              width: MediaQuery.of(context).size.width - 20,
                              child: Text(
                                widget.serieName,
                                softWrap: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: getSeriesTitleTextStyle(widget.serieId),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: Platform.isAndroid,
                        child: Positioned(
                          top: 140,
                          right: 30,
                          child: GestureDetector(
                            onTap: () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: '',
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        Container(),
                                transitionBuilder:
                                    (context, animation1, animation2, child) {
                                  final curvedValue = Curves.easeInOut
                                          .transform(animation1.value) -
                                      1.0;
                                  return Transform(
                                    transform: Matrix4.translationValues(
                                        curvedValue * 300, 0, 0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        height: 200,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  ShareContent.shareTVShow(
                                                      widget.serieId);
                                                },
                                                icon: const Icon(
                                                  Icons.share,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              IconButton(
                                                onPressed: () {
                                                  ShareContent
                                                      .sharePartialScreenshotTV(
                                                    screenShotController,
                                                    _buildScreenShotImage(),
                                                    widget.serieId,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.image,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
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
                              final openbox = await Hive.openBox('sessionBox');
                              final String accountId = openbox.get('accountId');
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
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: isUserLoggedIn == true,
                        child: Positioned(
                          top: 90,
                          right: 30,
                          child: GestureDetector(
                            onTap: () async {
                              if (isSerieFavorite == null) {
                                return;
                              }
                              final movieId = widget.serieId;
                              final openbox = await Hive.openBox('sessionBox');
                              final String accountId = openbox.get('accountId');
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
                              size: 25,
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
                                            final openbox = await Hive.openBox(
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
                                          final openbox =
                                              await Hive.openBox('sessionBox');

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
                          top: 90,
                          left: 15,
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
                                                final movieId = widget.serieId;
                                                final openbox =
                                                    await Hive.openBox(
                                                        'sessionBox');

                                                final String sessionData =
                                                    openbox.get('sessionData');
                                                addRating(sessionData, movieId,
                                                    rating, context);
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

                        Positioned(
                          top: 40,
                          left: 20,
                          child: ShowWatchToggle(
                            key: _showWatchToggleKey,
                            serieId: widget.serieId,
                            serieName: widget.serieName,
                            posterPath: posterPath,
                            onToggle: () {
                              // The widget handles its own state, no need to call _checkShowWatchedStatus
                            },
                          ),
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
                          style:
                              getSeriesAboutTextStyle(context, widget.serieId),
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
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
                            backgroundColor:
                                getSeriesColor(context, widget.serieId),
                            onPressed: () => seasonsAndEpisodes(context,
                                widget.serieId, widget.serieName, imdbId!,
                                onWatchStatusChanged: _refreshShowWatchStatus),
                            child: Text(
                              'Details',
                              style: getSeriesButtonTextStyle(widget.serieId),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: fetchCredits(widget.serieId, region),
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
                                      style: getSeriesTitleTextStyle(
                                          widget.serieId),
                                    )),
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
                                    style:
                                        getSeriesTitleTextStyle(widget.serieId),
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
      bottomNavigationBar: const BottomBar(),
    );
  }

  Widget _buildScreenShotImage() {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;

    return Container(
      constraints: const BoxConstraints(maxHeight: 800),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        color: Colors.black,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            CachedNetworkImage(
              imageUrl: '${getImageBaseUrl(region)}/t/p/original$backdrops',
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
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
              bottom: 28,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    width: MediaQuery.of(context).size.width - 20,
                    child: Text(
                      widget.serieName,
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (genres as List<dynamic>).map<Widget>((genre) {
                return Text(
                  genre['name'] + ' | ',
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'RobotoMono'),
                );
              }).toList(),
            ),
          ),
          const CustomDivider(),
          Container(
            alignment: Alignment.center,
            child: Text(
              about!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w200,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.left,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const CustomDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 110,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: BoxDecoration(
                    color: getSeriesBackgroundColor(context, widget.serieId),
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
                          fontFamily: 'RobotoMono',
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
                            fontFamily: 'Poppins',
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
                    color: getSeriesBackgroundColor(context, widget.serieId),
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
                          fontFamily: 'RobotoMono',
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
                            fontFamily: 'Poppins',
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
                    color: getSeriesBackgroundColor(context, widget.serieId),
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
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          language != null ? language!.toUpperCase() : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom widget for smooth show watch toggle
class ShowWatchToggle extends StatefulWidget {
  final int serieId;
  final String serieName;
  final String? posterPath;
  final VoidCallback? onToggle;

  const ShowWatchToggle({
    Key? key,
    required this.serieId,
    required this.serieName,
    required this.posterPath,
    this.onToggle,
  }) : super(key: key);

  @override
  State<ShowWatchToggle> createState() => _ShowWatchToggleState();
}

class _ShowWatchToggleState extends State<ShowWatchToggle> {
  bool? _isWatched;
  bool _isLoading = false;
  final WatchHistoryDatabase _watchHistoryDb = WatchHistoryDatabase();

  @override
  void initState() {
    super.initState();
    _loadWatchStatus();
  }

  Future<void> _loadWatchStatus() async {
    try {
      final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final baseUrl = getBaseUrl(region);
      final apiKey = dotenv.env['TMDB_API_KEY'];
      
      // Get total episode count for the show
      final seasonsResponse = await http.get(
        Uri.parse('${baseUrl}tv/${widget.serieId}?api_key=$apiKey'),
      );
      
      if (seasonsResponse.statusCode == 200) {
        final data = json.decode(seasonsResponse.body);
        final seasonsList = data['seasons'] as List<dynamic>;
        
        int totalEpisodes = 0;
        for (final season in seasonsList) {
          final seasonNumber = season['season_number'];
          if (seasonNumber == 0) continue; // Skip specials
          
          final episodesResponse = await http.get(
            Uri.parse('${baseUrl}tv/${widget.serieId}/season/$seasonNumber?api_key=$apiKey'),
          );
          
          if (episodesResponse.statusCode == 200) {
            final episodeData = json.decode(episodesResponse.body);
            final episodesList = episodeData['episodes'] as List<dynamic>;
            totalEpisodes += episodesList.length;
          }
        }
        
        // Check how many episodes are watched
        final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(widget.serieId, 'tv');
        final watchedEpisodes = watchHistory.where((item) => item.seasonNumber != 0).length; // Exclude specials
        
        if (mounted) {
          setState(() {
            _isWatched = totalEpisodes > 0 && watchedEpisodes == totalEpisodes;
          });
        }
      }
    } catch (e) {
      // Fallback to old logic if API calls fail
      final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(widget.serieId, 'tv');
      if (mounted) {
        setState(() {
          _isWatched = watchHistory.isNotEmpty;
        });
      }
    }
  }

  Future<void> _toggleWatchStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isWatched ?? false) {
        // Remove all episodes of this show from watch history
        final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(widget.serieId, 'tv');
        for (final item in watchHistory) {
          await _watchHistoryDb.deleteWatchHistoryItem(item.id!);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.serieName} removed from watched!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Mark entire show as watched by adding all episodes
        await _markEntireShowAsWatched();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.serieName} marked as watched!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Update local state immediately for smooth transition
      setState(() {
        _isWatched = !(_isWatched ?? false);
        _isLoading = false;
      });
      
      // Call the callback to refresh parent state
      widget.onToggle?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating watch status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markEntireShowAsWatched() async {
    final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];
    
    try {
      // Fetch all seasons
      final seasonsResponse = await http.get(
        Uri.parse('${baseUrl}tv/${widget.serieId}?api_key=$apiKey'),
      );
      
      if (seasonsResponse.statusCode == 200) {
        final data = json.decode(seasonsResponse.body);
        final seasonsList = data['seasons'] as List<dynamic>;
        
        for (final season in seasonsList) {
          final seasonNumber = season['season_number'];
          if (seasonNumber == 0) continue; // Skip specials
          
          // Fetch episodes for this season
          final episodesResponse = await http.get(
            Uri.parse('${baseUrl}tv/${widget.serieId}/season/$seasonNumber?api_key=$apiKey'),
          );
          
          if (episodesResponse.statusCode == 200) {
            final episodeData = json.decode(episodesResponse.body);
            final episodesList = episodeData['episodes'] as List<dynamic>;
            
            for (final episode in episodesList) {
              await _watchHistoryDb.addShowToHistory(
                tmdbId: widget.serieId,
                title: widget.serieName,
                posterPath: widget.posterPath,
                seasonNumber: seasonNumber,
                episodeNumber: episode['episode_number'],
                episodeTitle: episode['name'],
              );
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to mark entire show as watched: $e');
    }
  }

  // Method to refresh the watch status from external calls
  void refresh() {
    _loadWatchStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWatched == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.all(Radius.circular(30)),
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
                fontWeight: FontWeight.w300,
                fontSize: 13,
                color: Colors.white,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isWatched! ? Colors.green.withOpacity(0.7) : Colors.black38,
          borderRadius: const BorderRadius.all(Radius.circular(30)),
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
                _isWatched! ? Icons.check_circle : Icons.visibility,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _isWatched! ? 'Show Watched' : 'Mark Show as Watched',
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
