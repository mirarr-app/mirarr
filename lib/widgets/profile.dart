import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/functions/fetchers/fetch_serie_details.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_gridview_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:Mirarr/seriesPage/function/on_tap_gridview_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:Mirarr/widgets/settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/seriesPage/UI/customSeriesWidget.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/widgets/login.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

List<Serie> tvWatchList = [];
List<Movie> moviesWatchList = [];
List<Serie> tvFavorites = [];
List<Movie> movieFavorites = [];
List<Serie> tvRated = [];
List<Movie> movieRated = [];
List<Serie> recentEpisodes = [];

class _ProfilePageState extends State<ProfilePage> {
  final apiKey = dotenv.env['TMDB_API_KEY'];

  void _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final box = await Hive.openBox('sessionBox');
    await box.delete('sessionData');
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();
  }

  Future<void> fetchMovieWatchList(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/watchlist/movies?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Movie> movies = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final movie = Movie(
            title: result['title'],
            releaseDate: result['release_date'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] ?? '',
            score: result['vote_average'] ?? '');
        movies.add(movie);
      }

      setState(() {
        moviesWatchList = movies;
      });
    } else {
      throw Exception('Failed to load popular movie data');
    }
  }

  Future<void> fetchFavoriteMovies(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/favorite/movies?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Movie> movies = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final movie = Movie(
            title: result['title'],
            releaseDate: result['release_date'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] ?? '',
            score: result['vote_average'] ?? '');
        movies.add(movie);
      }

      setState(() {
        movieFavorites = movies;
      });
    } else {
      throw Exception('Failed to load popular movie data');
    }
  }

  Future<void> fetchRatedMovies(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/rated/movies?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Movie> movies = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final movie = Movie(
            title: result['title'],
            releaseDate: result['release_date'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] ?? '',
            score: result['vote_average'] ?? '');
        movies.add(movie);
      }

      setState(() {
        movieRated = movies;
      });
    } else {
      throw Exception('Failed to load popular movie data');
    }
  }

  void handleNetworkError(ClientException e) {
    if (e.message.contains('No address associated with hostname')) {
      // Handle case where there's no internet connection
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content:
                const Text('Please connect to the internet and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle other network-related errors
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titleTextStyle: TextStyle(
                color: Theme.of(context).secondaryHeaderColor, fontSize: 20),
            contentTextStyle:
                TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
            title: const Text('Network Error'),
            content: const Text(
                'An error occurred while fetching data. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  checkInternetAndFetchData();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      handleNetworkError(ClientException('No internet connection'));
    } else {
      // Internet connection available, fetch data
      fetchMovieWatchList(context);
      fetchTvWatchList(context);
      fetchFavoriteMovies(context);
      fetchRatedMovies(context);
      fetchFavoriteSeries(context);
      fetchRatedTv(context);
    }
  }

  Future<void> fetchTvWatchList(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/watchlist/tv?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Serie> series = [];
      final List<dynamic> results = json.decode(response.body)['results'];
      recentEpisodes.clear();
      for (var result in results) {
        final serie = Serie(
            name: result['name'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'] ?? '');
        series.add(serie);
      }

      setState(() {
        tvWatchList = series;
      });

      final today = DateTime.now();
      for (var serie in series) {
        final serieDetails = await fetchSerieDetails(serie.id, region);
        final serieLatestAir = serieDetails['last_air_date'];
        final serieLastEpisodeSeasonNumber = serieDetails['last_episode_to_air']['season_number'];
        final serieLastEpisodeEpisodeNumber = serieDetails['last_episode_to_air']['episode_number'];
        final serieLatestAirDate = DateTime.parse(serieLatestAir);
        //check if the serie is aired in the last 14 days
        final difference = today.difference(serieLatestAirDate).inDays;
        if (difference <= 14) {
          final updatedSerie = Serie(
            name: serie.name,
            posterPath: serie.posterPath,
            overView: serie.overView,
            id: serie.id,
            score: serie.score,
            lastAirDate: serieLatestAir,
            lastEpisodeSeasonNumber: serieLastEpisodeSeasonNumber,
            lastEpisodeEpisodeNumber: serieLastEpisodeEpisodeNumber,
          );
          recentEpisodes.add(updatedSerie);
        }
      }
      // Sort recentEpisodes by lastAirDate in descending order (newest first)
      recentEpisodes.sort((a, b) => DateTime.parse(b.lastAirDate!).compareTo(DateTime.parse(a.lastAirDate!)));
      setState(() {
        recentEpisodes = recentEpisodes;
      });
    } else {
      throw Exception('Failed to load trending series data');
    }
  }

  Future<void> fetchFavoriteSeries(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/favorite/tv?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Serie> series = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final serie = Serie(
            name: result['name'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'] ?? '');
        series.add(serie);
      }

      setState(() {
        tvFavorites = series;
      });
    } else {
      throw Exception('Failed to load trending series data');
    }
  }

  Future<void> fetchRatedTv(BuildContext context) async {
    final openbox = await Hive.openBox('sessionBox');
    final String accountId = openbox.get('accountId');
    final String sessionData = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}account/$accountId/rated/tv?api_key=$apiKey&session_id=$sessionData',
      ),
    );

    if (response.statusCode == 200) {
      final List<Serie> series = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final serie = Serie(
            name: result['name'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'] ?? '');
        series.add(serie);
      }

      setState(() {
        tvRated = series;
      });
    } else {
      throw Exception('Failed to load trending series data');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: Text(
                        'Are you sure you want to logout?',
                        style:
                            TextStyle(color: Theme.of(context).highlightColor),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _logout(context);
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(children: [
              Card(
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () =>
                                  onTapGridMovie(moviesWatchList, context),
                              child: Row(
                                children: [
                                  const Text(
                                    textAlign: TextAlign.left,
                                    'Movie Watch List',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: moviesWatchList.isNotEmpty,
                        child: SizedBox(
                          height: 320, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: moviesWatchList.length,
                              itemBuilder: (context, index) {
                                final movie = moviesWatchList[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapMovie(
                                              movie.title, movie.id, context)
                                          : onTapMovieDesktop(
                                              movie.title, movie.id, context),
                                  child: CustomMovieWidget(
                                    movie: movie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: moviesWatchList.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No movies in the watchlist yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),    const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () => onTapGridSerie(recentEpisodes, context),
                              child: Row(
                                children: [
                                  const Text(
                                    'Watchlist Recent Episodes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: recentEpisodes.isNotEmpty,
                        child: SizedBox(
                          height: 300, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentEpisodes.length,
                              itemBuilder: (context, index) {
  
                                final serie = recentEpisodes[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapSerie(
                                              serie.name, serie.id, context)
                                          : onTapSerieDesktop(
                                              serie.name, serie.id, context),
                                  child: Stack(
                                    children: [
                                      CustomSeriesWidget(
                                        serie: serie,
                                      ),
                                      Visibility(
                                        visible: serie.lastAirDate != null,
                                        child: Positioned(
                                          top: 50,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${serie.lastAirDate}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),  Visibility(
                                        visible: serie.lastEpisodeSeasonNumber != null && serie.lastEpisodeEpisodeNumber != null,
                                        child: Positioned(
                                          top: 80,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'S${serie.lastEpisodeSeasonNumber}E${serie.lastEpisodeEpisodeNumber}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: recentEpisodes.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No series in your watchlist aired in the last 14 days',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () => onTapGridSerie(tvWatchList, context),
                              child: Row(
                                children: [
                                  const Text(
                                    'TV Watch List',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: tvWatchList.isNotEmpty,
                        child: SizedBox(
                          height: 300, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: tvWatchList.length,
                              itemBuilder: (context, index) {
                                final serie = tvWatchList[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapSerie(
                                              serie.name, serie.id, context)
                                          : onTapSerieDesktop(
                                              serie.name, serie.id, context),
                                  child: CustomSeriesWidget(
                                    serie: serie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: tvWatchList.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No TV shows in the watchlist yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () =>
                                  onTapGridMovie(movieFavorites, context),
                              child: Row(
                                children: [
                                  const Text(
                                    textAlign: TextAlign.left,
                                    'Favorite Movies',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: movieFavorites.isNotEmpty,
                        child: SizedBox(
                          height: 320,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: movieFavorites.length,
                              itemBuilder: (context, index) {
                                final movie = movieFavorites[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapMovie(
                                              movie.title, movie.id, context)
                                          : onTapMovieDesktop(
                                              movie.title, movie.id, context),
                                  child: CustomMovieWidget(
                                    movie: movie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: movieFavorites.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No favorite movies yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () => onTapGridSerie(tvFavorites, context),
                              child: Row(
                                children: [
                                  const Text(
                                    'Favorite TV Shows',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: tvFavorites.isNotEmpty,
                        child: SizedBox(
                          height: 300, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: tvFavorites.length,
                              itemBuilder: (context, index) {
                                final serie = tvFavorites[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapSerie(
                                              serie.name, serie.id, context)
                                          : onTapSerieDesktop(
                                              serie.name, serie.id, context),
                                  child: CustomSeriesWidget(
                                    serie: serie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: tvFavorites.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No favorite TV shows yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () => onTapGridMovie(movieRated, context),
                              child: Row(
                                children: [
                                  const Text(
                                    textAlign: TextAlign.left,
                                    'Rated Movies',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: movieRated.isNotEmpty,
                        child: SizedBox(
                          height: 320, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: movieRated.length,
                              itemBuilder: (context, index) {
                                final movie = movieRated[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapMovie(
                                              movie.title, movie.id, context)
                                          : onTapMovieDesktop(
                                              movie.title, movie.id, context),
                                  child: CustomMovieWidget(
                                    movie: movie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: movieRated.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No rated movies yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 5),
                            child: GestureDetector(
                              onTap: () => onTapGridSerie(tvRated, context),
                              child: Row(
                                children: [
                                  const Text(
                                    'Rated TV Shows',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: tvRated.isNotEmpty,
                        child: SizedBox(
                          height: 300, // Set the height for the movie cards
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: tvRated.length,
                              itemBuilder: (context, index) {
                                final serie = tvRated[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapSerie(
                                              serie.name, serie.id, context)
                                          : onTapSerieDesktop(
                                              serie.name, serie.id, context),
                                  child: CustomSeriesWidget(
                                    serie: serie,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: tvRated.isEmpty,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'No rated TV shows yet',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
        bottomNavigationBar: const BottomBar());
  }
}
