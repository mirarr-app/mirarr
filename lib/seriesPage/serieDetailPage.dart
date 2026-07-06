import 'package:Mirarr/widgets/profile.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Mirarr/functions/platform_helper.dart';

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
import 'dart:ui';


part 'serieDetailPageMobile.dart';
part 'serieDetailPageDesktop.dart';

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
  Future<dynamic>? _creditsFuture;
  bool isUserLoggedIn = false;
  dynamic isSerieRated;
  double? userRating;
  double? userScore;
  String? posterPath;
  final screenShotController = ScreenshotController();

  void updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

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
  
  // Key to force refresh of ShowWatchToggle
  final GlobalKey<_ShowWatchToggleState> _showWatchToggleKey = GlobalKey<_ShowWatchToggleState>();
  
  // Counter to force refresh of ShowWatchToggle on desktop
  int _showWatchToggleRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    checkUserLogin();

    checkAccountState();
    _fetchSerieDetails();

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    _creditsFuture = fetchCredits(widget.serieId, region);
    fetchExternalId();
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
          '${baseUrl}tv/${widget.serieId}/account_states?api_key=$apiKey&session_id=$sessionId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (mounted) {
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
  }

  Future<void> _fetchSerieDetails() async {
    try {
      // Make an HTTP GET request to fetch movie details from the first API
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final responseData = await fetchSerieDetails(widget.serieId, region);
      if (mounted) {
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
      }
    } catch (e) {
      throw Exception('Failed to load serie details');
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
        if (mounted) {
          setState(() {
            externalIds = responseData;
            imdbId = responseData['imdb_id'];
          });
        }
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
    setState(() {
      _showWatchToggleRefreshCounter++;
    });
  }

  void onTapSerie(String serieName, int serieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SerieDetailPage(serieName: serieName, serieId: serieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobileLayout = AppPlatform.isMobile || (kIsWeb && MediaQuery.of(context).size.width < 800);
    if (isMobileLayout) {
      return _SerieDetailPageMobile(this);
    } else {
      return _SerieDetailPageDesktop(this);
    }
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

    return TvFocusWrapper(
      borderRadius: 30.0,
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
