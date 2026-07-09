import 'dart:ui';
import 'package:Mirarr/functions/fetchers/fetch_movies_by_genre.dart';
import 'package:Mirarr/functions/fetchers/fetch_popular_movies.dart';
import 'package:Mirarr/functions/fetchers/fetch_trending_movies.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_gridview_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'dart:async';
import 'package:Mirarr/database/watch_history_database.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  late RegionProvider _regionProvider;
  final WatchHistoryDatabase _watchHistoryDb = WatchHistoryDatabase();
  Set<int> _watchedMovieIds = {};

  Future<void> _loadWatchedMovies() async {
    try {
      final watched = await _watchHistoryDb.getWatchedMovies();
      if (mounted) {
        setState(() {
          _watchedMovieIds = watched.map((e) => e.tmdbId).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading watched movies: $e');
    }
  }

  Future<void> _onMovieTapped(Movie movie) async {
    await onTapMovie(movie.title, movie.id, context);
    if (mounted) {
      _loadWatchedMovies();
    }
  }

  final List<Movie> _dummyMovies = List.generate(
    5,
    (index) => Movie(
      title: 'Movie Title Placeholder',
      releaseDate: '2026-01-01',
      posterPath: '',
      overView: 'This is a description placeholder for the movie loading state.',
      id: -1 - index,
      score: 8.5,
    ),
  );

  final List<Genre> _dummyGenres = [
    Genre(id: -100, name: 'Genre Placeholder 1'),
    Genre(id: -101, name: 'Genre Placeholder 2'),
  ];

  late final Map<int, List<Movie>> _dummyMoviesByGenre = {
    -100: List.generate(
      5,
      (index) => Movie(
        title: 'Movie Title Placeholder',
        releaseDate: '2026-01-01',
        posterPath: '',
        overView: 'This is a description placeholder for the movie loading state.',
        id: -200 - index,
        score: 8.5,
      ),
    ),
    -101: List.generate(
      5,
      (index) => Movie(
        title: 'Movie Title Placeholder',
        releaseDate: '2026-01-01',
        posterPath: '',
        overView: 'This is a description placeholder for the movie loading state.',
        id: -300 - index,
        score: 8.5,
      ),
    ),
  };

  Future<void> _fetchTrendingMovies() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final movies = await fetchTrendingMovies(region);
      setState(() {
        trendingMovies = movies;
      });
    } catch (e) {
      throw Exception('Failed to load trending movies');
    }
  }

  Future<void> _fetchPopularMovies() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final movies = await fetchPopularMovies(region);
      setState(() {
        popularMovies = movies;
      });
    } catch (e) {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<void> _fetchGenresAndMovies() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final fetchedGenres = await fetchGenres(region);
      final tasks = fetchedGenres.map((genre) async {
        final movies = await fetchMoviesByGenre(genre.id, region);
        return MapEntry(genre.id, movies);
      });
      final results = await Future.wait(tasks);

      if (mounted) {
        setState(() {
          genres = fetchedGenres;
          moviesByGenre = Map.fromEntries(results);
        });
      }
    } catch (e) {
      throw Exception('Failed to load movies by genre');
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

  void _onRegionChanged() {
    checkInternetAndFetchData();
  }

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();
    _loadWatchedMovies();

    // Add listener for region changes
    _regionProvider = Provider.of<RegionProvider>(context, listen: false);
    _regionProvider.addListener(_onRegionChanged);
  }

  @override
  void dispose() {
    // Remove listener when disposing
    _regionProvider.removeListener(_onRegionChanged);
    super.dispose();
  }

  Future<void> checkInternetAndFetchData() async {
    setState(() {
      trendingMovies = [];
      popularMovies = [];
      genres = [];
      moviesByGenre = {};
    });
    _loadWatchedMovies();
    _fetchTrendingMovies();
    _fetchPopularMovies();
    await _fetchGenresAndMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
extendBody: true,
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
                              child: Skeletonizer(
                                enabled: trendingMovies.isEmpty,
                                containersColor: Colors.white.withOpacity(0.05),
                                effect: ShimmerEffect(
                                  baseColor: Colors.white.withOpacity(0.05),
                                  highlightColor: Colors.white.withOpacity(0.15),
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: trendingMovies.isEmpty
                                      ? _dummyMovies.length
                                      : trendingMovies.length,
                                  itemBuilder: (context, index) {
                                    final movie = trendingMovies.isEmpty
                                        ? _dummyMovies[index]
                                        : trendingMovies[index];
                                     final widget = TvFocusWrapper(
                                       autoFocus: index == 0 && trendingMovies.isNotEmpty,
                                       onTap: trendingMovies.isEmpty
                                           ? () {}
                                           : () => _onMovieTapped(movie),
                                       child: CustomMovieWidget(
                                         movie: movie,
                                         showAvailability: false,
                                         isWatched: _watchedMovieIds.contains(movie.id),
                                       ),
                                     );
                                    if (trendingMovies.isEmpty) {
                                      final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                      return Opacity(
                                        opacity: opacity,
                                        child: widget,
                                      );
                                    }
                                    return widget;
                                  },
                                ),
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
                              child: Skeletonizer(
                                enabled: popularMovies.isEmpty,
                                containersColor: Colors.white.withOpacity(0.05),
                                effect: ShimmerEffect(
                                  baseColor: Colors.white.withOpacity(0.05),
                                  highlightColor: Colors.white.withOpacity(0.15),
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: popularMovies.isEmpty
                                      ? _dummyMovies.length
                                      : popularMovies.length,
                                  itemBuilder: (context, index) {
                                    final movie = popularMovies.isEmpty
                                        ? _dummyMovies[index]
                                        : popularMovies[index];
                                     final widget = TvFocusWrapper(
                                       onTap: popularMovies.isEmpty
                                           ? () {}
                                           : () => _onMovieTapped(movie),
                                       child: CustomMovieWidget(
                                         movie: movie,
                                         showAvailability: false,
                                         isWatched: _watchedMovieIds.contains(movie.id),
                                       ),
                                     );
                                    if (popularMovies.isEmpty) {
                                      final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                      return Opacity(
                                        opacity: opacity,
                                        child: widget,
                                      );
                                    }
                                    return widget;
                                  },
                                ),
                              ),
                            ),
                          ),
                          for (var genre in (genres.isEmpty ? _dummyGenres : genres))
                            Skeletonizer(
                              enabled: genres.isEmpty,
                              containersColor: Colors.white.withOpacity(0.05),
                              effect: ShimmerEffect(
                                baseColor: Colors.white.withOpacity(0.05),
                                highlightColor: Colors.white.withOpacity(0.15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(15, 15, 0, 0),
                                    child: TvFocusWrapper(
                                      borderRadius: 8.0,
                                      onTap: genres.isEmpty
                                          ? () {}
                                          : () => onTapGridMovie(
                                              moviesByGenre[genre.id]!, context),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                        itemCount: genres.isEmpty
                                            ? (_dummyMoviesByGenre[genre.id]?.length ?? 0)
                                            : (moviesByGenre[genre.id]?.length ?? 0),
                                        itemBuilder: (context, index) {
                                          final movie = genres.isEmpty
                                              ? _dummyMoviesByGenre[genre.id]![index]
                                              : moviesByGenre[genre.id]![index];
                                           final widget = TvFocusWrapper(
                                             onTap: genres.isEmpty
                                                 ? () {}
                                                 : () => _onMovieTapped(movie),
                                             child: CustomMovieWidget(
                                               movie: movie,
                                               showAvailability: false,
                                               isWatched: _watchedMovieIds.contains(movie.id),
                                             ),
                                           );
                                          if (genres.isEmpty) {
                                            final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                            return Opacity(
                                              opacity: opacity,
                                              child: widget,
                                            );
                                          }
                                          return widget;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
            )
          ],
        ));
  }
}
