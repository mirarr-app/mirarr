import 'dart:io';
import 'dart:ui';
import 'package:Mirarr/functions/fetchers/fetch_movies_by_genre.dart';
import 'package:Mirarr/functions/fetchers/fetch_popular_movies.dart';
import 'package:Mirarr/functions/fetchers/fetch_trending_movies.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_gridview_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'dart:async';

class MovieSearchScreen extends StatefulWidget {
  static final GlobalKey<_MovieSearchScreenState> movieSearchKey =
      GlobalKey<_MovieSearchScreenState>();

  const MovieSearchScreen({super.key});
  @override
  _MovieSearchScreenState createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final apiKey = dotenv.env['TMDB_API_KEY'];

  List<Movie> trendingMovies = [];
  List<Movie> popularMovies = [];
  List<Genre> genres = [];
  Map<int, List<Movie>> moviesByGenre = {};
  Future<void> _fetchTrendingMovies() async {
    try {
      final movies = await fetchTrendingMovies();
      setState(() {
        trendingMovies = movies;
      });
    } catch (e) {
      throw Exception('Failed to load trending movies');
    }
  }

  Future<void> _fetchPopularMovies() async {
    try {
      final movies = await fetchPopularMovies();
      setState(() {
        popularMovies = movies;
      });
    } catch (e) {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<void> _fetchGenresAndMovies() async {
    try {
      genres = await fetchGenres();
      for (var genre in genres) {
        final movies = await fetchMoviesByGenre(genre.id);
        setState(() {
          moviesByGenre[genre.id] = movies;
        });
      }
    } catch (e) {
      throw Exception('Failed to load movies by movies');
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

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();
  }

  Future<void> checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      handleNetworkError(ClientException('No internet connection'));
    } else {
      // Internet connection available, fetch data
      _fetchTrendingMovies();
      _fetchPopularMovies();
      await _fetchGenresAndMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            'Movies',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Card(
                  shadowColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Container(
                      color: Colors.black,
                      child: Column(
                        children: <Widget>[
                          const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
                                child: Text(
                                  textAlign: TextAlign.left,
                                  'Trending Movies',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            height: 320, // Set the height for the movie cards
                            child: ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: trendingMovies.length,
                                itemBuilder: (context, index) {
                                  final movie = trendingMovies[index];
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
                          const SizedBox(
                            height: 10,
                          ),
                          const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
                                child: Text(
                                  'Popular Movies',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 320, // Set the height for the movie cards
                            child: ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: popularMovies.length,
                                itemBuilder: (context, index) {
                                  final movie = popularMovies[index];
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
                          for (var genre in genres)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 15, 0, 0),
                                  child: GestureDetector(
                                    onTap: () => onTapGridMovie(
                                        moviesByGenre[genre.id]!, context),
                                    child: Row(
                                      children: [
                                        Text(
                                          genre.name,
                                          style: const TextStyle(
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
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 320,
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                        PointerDeviceKind.trackpad,
                                      },
                                    ),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          moviesByGenre[genre.id]?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final movie =
                                            moviesByGenre[genre.id]![index];
                                        return GestureDetector(
                                          onTap: () => Platform.isAndroid ||
                                                  Platform.isIOS
                                              ? onTapMovie(movie.title,
                                                  movie.id, context)
                                              : onTapMovieDesktop(movie.title,
                                                  movie.id, context),
                                          child: CustomMovieWidget(
                                            movie: movie,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  )),
            )
          ],
        ),
        bottomNavigationBar: const BottomBar());
  }
}
