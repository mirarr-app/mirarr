import 'package:Mirarr/widgets/profile.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Mirarr/functions/platform_helper.dart';

import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/functions/fetchers/fetch_movie_credits.dart';
import 'package:Mirarr/functions/fetchers/fetch_movie_details.dart';
import 'package:Mirarr/functions/fetchers/fetch_other_movies_by_director.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/share_content.dart';
import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
import 'package:Mirarr/moviesPage/functions/get_imdb_rating.dart';
import 'package:Mirarr/moviesPage/functions/movie_tmdb_actions.dart';
import 'package:Mirarr/moviesPage/functions/torrent_links.dart';
import 'package:Mirarr/moviesPage/functions/watch_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui';

part 'movieDetailPageMobile.dart';
part 'movieDetailPageDesktop.dart';

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
  Future<dynamic>? _creditsFuture;
  Future<dynamic>? _availabilityFuture;
  Future<dynamic>? _directorMoviesFuture;
  bool? isMovieFavorite;
  bool isUserLoggedIn = false;
  dynamic isMovieRated;
  double? userRating;
  double? userScore;
  final screenshotController = ScreenshotController();

  void updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }


  // Watch history variables
  final WatchHistoryDatabase _watchHistoryDb = WatchHistoryDatabase();
  bool isWatched = false;
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
  String? posterPath;

  String? imdbId;
  String? imdbRating;
  String rottenTomatoesRating = 'N/A';

  @override
  void initState() {
    super.initState();
    checkUserLogin();
    _fetchMovieDetails();
    checkAccountState();
    _loadMovieImages();
    _checkWatchedStatus();
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    _availabilityFuture = checkAvailability(widget.movieId, region);
    _creditsFuture = fetchCredits(widget.movieId, region).then((data) {
      final List<dynamic> crewList = data['crew'] ?? [];
      for (var crewMember in crewList) {
        if (crewMember['job'] == 'Director') {
          if (mounted) {
            setState(() {
              _directorMoviesFuture = fetchOtherMoviesByDirector(crewMember['id'], region);
            });
          }
          break;
        }
      }
      return data;
    });
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

  Future<void> checkUserLogin() async {
    final openbox = Hive.box('sessionBox');
    final sessionData = openbox.get('sessionData');
    if (sessionData != null) {
      if (mounted) {
        setState(() {
          isUserLoggedIn = true;
        });
      }
    }
  }

  Future<void> checkAccountState() async {
    final openbox = Hive.box('sessionBox');
    final sessionId = openbox.get('sessionData');
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}movie/${widget.movieId}/account_states?api_key=$apiKey&session_id=$sessionId',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (mounted) {
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
  }

  Future<List<String>> _fetchMovieImages(int movieId) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse('${baseUrl}movie/$movieId/images?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['backdrops'];
      return data.map((image) => image['file_path'] as String).toList();
    } else {
      throw Exception('Failed to load cast images');
    }
  }

  void updateImdbRating(String rating) {
    if (mounted) {
      setState(() {
        imdbRating = rating;
      });
    }
  }

  void updateRottenTomatoesRating(String rating) {
    if (mounted) {
      setState(() {
        rottenTomatoesRating = rating;
      });
    }
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final responseData = await fetchMovieDetails(widget.movieId, region);
      if (mounted) {
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
          posterPath = responseData['poster_path'];
  
          productionCountries = responseData['production_countries'];
          productionCompanies = responseData['production_companies'];
          spokenLanguages = responseData['spoken_languages'];
          imdbId = responseData['imdb_id'];
        });
      }
      if (imdbId != null) {
        await getMovieRatings(
            imdbId, updateImdbRating, updateRottenTomatoesRating);
      }
    } catch (e) {
      throw Exception('Failed to load movie details');
    }
  }

  Future<void> _checkWatchedStatus() async {
    final watched = await _watchHistoryDb.isWatched(widget.movieId, 'movie');
    if (mounted) {
      setState(() {
        isWatched = watched;
      });
    }
  }

  Future<void> _markAsWatched() async {
    try {
      await _watchHistoryDb.addMovieToHistory(
        tmdbId: widget.movieId,
        title: widget.movieTitle,
        posterPath: posterPath,
        userRating: userRating,
      );
      
      if (mounted) {
        setState(() {
          isWatched = true;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.movieTitle} marked as watched!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking movie as watched: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeFromWatched() async {
    try {
      final watchHistory = await _watchHistoryDb.getWatchHistoryByTmdbId(widget.movieId, 'movie');
      if (watchHistory.isNotEmpty) {
        await _watchHistoryDb.deleteWatchHistoryItem(watchHistory.first.id!);
        if (mounted) {
          setState(() {
            isWatched = false;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.movieTitle} removed from watched!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing movie from watched: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void onTapMovie(String movieTitle, int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MovieDetailPage(movieTitle: movieTitle, movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobileLayout = AppPlatform.isMobile || (kIsWeb && MediaQuery.of(context).size.width < 800);
    if (isMobileLayout) {
      return _MovieDetailPageMobile(this);
    } else {
      return _MovieDetailPageDesktop(this);
    }
  }
}
