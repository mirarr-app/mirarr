import 'dart:async';
import 'package:Mirarr/functions/platform_helper.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
import 'package:Mirarr/moviesPage/movieDetailPage.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/seriesPage/serieDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/models/watch_history_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:provider/provider.dart';
import 'package:Mirarr/functions/navigation_provider.dart';
import 'package:intl/intl.dart';

class ShelfPage extends StatefulWidget {
  const ShelfPage({super.key});

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  int _lastIndex = -1;

  Future<void> _navigateToMovie(String title, int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(movieTitle: title, movieId: id),
      ),
    );
    if (mounted) {
      _loadWatchHistory();
    }
  }

  Future<void> _navigateToSerie(String title, int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SerieDetailPage(serieName: title, serieId: id),
      ),
    );
    if (mounted) {
      _loadWatchHistory();
    }
  }

  final WatchHistoryDatabase _database = WatchHistoryDatabase();
  final TextEditingController _movieSearchController = TextEditingController();
  final TextEditingController _showSearchController = TextEditingController();
  final TextEditingController _diarySearchController = TextEditingController();
  Timer? _searchDebounceTimer;
  
  String _movieQuery = '';
  String _showQuery = '';
  String _diaryQuery = '';

  List<WatchHistoryItem> watchedMovies = [];
  List<WatchHistoryItem> watchedShows = [];
  List<WatchHistoryItem> diaryItems = [];

  bool isLoading = true;

  // View state management
  String _activeSection = 'movies'; // 'movies', 'shows', 'diary'
  String _movieViewMode = 'grid'; // 'grid', 'list', 'compact'
  String _showViewMode = 'list'; // 'list' (episodes), 'grid' (grouped shows), 'compact' (grouped compact)
  String _diaryViewMode = 'timeline'; // 'timeline', 'list', 'grid'

  // Watch stats and runtime calculation state
  Box? _runtimesBox;
  int totalMovieMinutes = 0;
  int totalTvMinutes = 0;
  bool needsCalculation = false;
  int uncachedItemsCount = 0;
  bool isCalculating = false;
  double calculationProgress = 0.0;

  Future<Box> _getBox() async {
    if (_runtimesBox == null || !_runtimesBox!.isOpen) {
      _runtimesBox = await Hive.openBox('tmdbRuntimes');
    }
    return _runtimesBox!;
  }

  @override
  void initState() {
    super.initState();
    _loadWatchHistory();
  }

  @override
  void dispose() {
    _movieSearchController.dispose();
    _showSearchController.dispose();
    _diarySearchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final movies = await _database.getWatchedMovies();
      final shows = await _database.getWatchedShows();
      final diary = await _database.getAllWatchHistory();

      final runtimesBox = await _getBox();
      
      int uncachedCount = 0;
      int movieMins = 0;
      int tvMins = 0;

      for (final m in movies) {
        final runtimeVal = runtimesBox.get('movie_${m.tmdbId}');
        if (runtimeVal == null) {
          uncachedCount++;
        } else {
          movieMins += runtimeVal as int;
        }
      }

      for (final s in shows) {
        final runtimeVal = runtimesBox.get('tv_ep_${s.tmdbId}_${s.seasonNumber}_${s.episodeNumber}');
        if (runtimeVal == null) {
          uncachedCount++;
        } else {
          tvMins += runtimeVal as int;
        }
      }

      setState(() {
        watchedMovies = movies;
        watchedShows = shows;
        diaryItems = diary;
        totalMovieMinutes = movieMins;
        totalTvMinutes = tvMins;
        needsCalculation = uncachedCount > 0;
        uncachedItemsCount = uncachedCount;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading watch history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _debouncedSetState(void Function() fn) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(fn);
    });
  }

  Future<void> _fetchRuntimes() async {
    final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TMDB API Key not found in environment.')),
      );
      return;
    }

    setState(() {
      isCalculating = true;
      calculationProgress = 0.0;
    });

    try {
      final runtimesBox = await _getBox();

      // 1. Gather all uncached items
      final List<WatchHistoryItem> uncachedMovies = [];
      for (final m in watchedMovies) {
        if (!runtimesBox.containsKey('movie_${m.tmdbId}')) {
          uncachedMovies.add(m);
        }
      }

      // Group TV shows episodes by tvId and season number to request season runtimes
      final Map<String, List<WatchHistoryItem>> uncachedTvGroups = {};
      for (final s in watchedShows) {
        final key = 'tv_ep_${s.tmdbId}_${s.seasonNumber}_${s.episodeNumber}';
        if (!runtimesBox.containsKey(key)) {
          final groupKey = '${s.tmdbId}_${s.seasonNumber}';
          uncachedTvGroups.putIfAbsent(groupKey, () => []).add(s);
        }
      }

      final totalSteps = uncachedMovies.length + uncachedTvGroups.length;
      int completedSteps = 0;

      // 2. Fetch movies runtimes
      for (final movie in uncachedMovies) {
        try {
          final response = await http.get(Uri.parse('${baseUrl}movie/${movie.tmdbId}?api_key=$apiKey'));
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final runtime = data['runtime'] as int? ?? 100;
            await runtimesBox.put('movie_${movie.tmdbId}', runtime);
          } else {
            await runtimesBox.put('movie_${movie.tmdbId}', 100);
          }
        } catch (_) {
          await runtimesBox.put('movie_${movie.tmdbId}', 100);
        }
        completedSteps++;
        if (mounted) {
          setState(() {
            calculationProgress = completedSteps / totalSteps;
          });
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 3. Fetch TV season runtimes
      for (final entry in uncachedTvGroups.entries) {
        final parts = entry.key.split('_');
        final tvId = int.parse(parts[0]);
        final seasonNum = int.parse(parts[1]);
        final eps = entry.value;

        try {
          final response = await http.get(Uri.parse('${baseUrl}tv/$tvId/season/$seasonNum?api_key=$apiKey'));
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final List<dynamic>? episodesList = data['episodes'] as List<dynamic>?;
            
            final Map<int, int> runtimesMap = {};
            if (episodesList != null) {
              for (final ep in episodesList) {
                final epNum = ep['episode_number'] as int?;
                final runtimeVal = ep['runtime'] as int?;
                if (epNum != null) {
                  runtimesMap[epNum] = runtimeVal ?? 45;
                }
              }
            }

            for (final epItem in eps) {
              final runtime = runtimesMap[epItem.episodeNumber] ?? 45;
              await runtimesBox.put(
                'tv_ep_${epItem.tmdbId}_${epItem.seasonNumber}_${epItem.episodeNumber}',
                runtime,
              );
            }
          } else {
            for (final epItem in eps) {
              await runtimesBox.put(
                'tv_ep_${epItem.tmdbId}_${epItem.seasonNumber}_${epItem.episodeNumber}',
                45,
              );
            }
          }
        } catch (_) {
          for (final epItem in eps) {
            await runtimesBox.put(
              'tv_ep_${epItem.tmdbId}_${epItem.seasonNumber}_${epItem.episodeNumber}',
              45,
            );
          }
        }

        completedSteps++;
        if (mounted) {
          setState(() {
            calculationProgress = completedSteps / totalSteps;
          });
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        setState(() {
          isCalculating = false;
        });
        _loadWatchHistory();
      }
    } catch (e) {
      print('Error calculating runtimes: $e');
      if (mounted) {
        setState(() {
          isCalculating = false;
        });
        _loadWatchHistory();
      }
    }
  }

  void _showCalculationWarningDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Fetch Watch Times', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'This will query TMDB API for $uncachedItemsCount uncached watch logs to calculate exact runtimes. This may take a while depending on network conditions.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _fetchRuntimes();
              },
              child: const Text('Calculate Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _formatWatchTime(int totalMinutes) {
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    if (navProvider.currentIndex == 3 && _lastIndex != 3) {
      _lastIndex = 3;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWatchHistory();
      });
    } else if (navProvider.currentIndex != 3) {
      _lastIndex = navProvider.currentIndex;
    }

    final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width >= 800 || AppPlatform.isDesktop;

    return Scaffold(
      extendBody: true,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isLargeScreen
              ? _buildDesktopLayout(region)
              : _buildMobileLayout(region),
    );
  }

  // Desktop Shell Layout
  Widget _buildDesktopLayout(String region) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(),
              Expanded(
                child: _buildMainContent(region),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile Shell Layout
  Widget _buildMobileLayout(String region) {
    final double topPadding = AppPlatform.isMobile ? 36.0 : 12.0;

    return Column(
      children: [
        SizedBox(height: topPadding),
        _buildMobileSegmentControl(),
        _buildMobileControls(),
        _buildMobileWatchTimeBanner(),
        Expanded(
          child: _buildMainContent(region),
        ),
      ],
    );
  }

  // Desktop Left Sidebar
  Widget _buildDesktopSidebar() {
    final sections = [
      {'id': 'movies', 'label': 'Movies', 'icon': Icons.movie, 'desc': 'Watched films'},
      {'id': 'shows', 'label': 'TV Shows', 'icon': Icons.tv, 'desc': 'Logged episodes'},
      {'id': 'diary', 'label': 'Watch Diary', 'icon': Icons.book, 'desc': 'Chronological feed'},
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.shelves, size: 28, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MY SHELF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Local Database',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Sidebar Nav buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: sections.map((sec) {
                final isSelected = _activeSection == sec['id'];
                int count = 0;
                if (sec['id'] == 'movies') count = watchedMovies.length;
                if (sec['id'] == 'shows') count = watchedShows.length;
                if (sec['id'] == 'diary') count = diaryItems.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _activeSection = sec['id'] as String),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sec['icon'] as IconData,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sec['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sec['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          // Stats box
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 18, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'SHELF STATS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem('Movies Logged', watchedMovies.length.toString()),
                  const SizedBox(height: 10),
                  _buildStatItem('TV Episodes Logged', watchedShows.length.toString()),
                  const SizedBox(height: 10),
                  _buildStatItem('Unique Shows', watchedShows.map((s) => s.tmdbId).toSet().length.toString()),
                  const SizedBox(height: 10),
                  _buildStatItem('Movies Time', _formatWatchTime(totalMovieMinutes)),
                  const SizedBox(height: 10),
                  _buildStatItem('TV Shows Time', _formatWatchTime(totalTvMinutes)),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatItem('Total Watch Time', _formatWatchTime(totalMovieMinutes + totalTvMinutes)),
                  if (isCalculating) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: calculationProgress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fetching runtimes... ${(calculationProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ] else if (needsCalculation) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Badge(
                          backgroundColor: Colors.amber,
                          label: const Text('!', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                          child: const Icon(Icons.refresh, size: 14),
                        ),
                        label: Text(
                          'Fetch watch times ($uncachedItemsCount logs)',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showCalculationWarningDialog,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white30)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // Desktop Header
  Widget _buildDesktopHeader() {
    final activeController = _activeSection == 'movies'
        ? _movieSearchController
        : _activeSection == 'shows'
            ? _showSearchController
            : _diarySearchController;

    String sectionTitle = '';
    if (_activeSection == 'movies') sectionTitle = 'Watched Movies';
    if (_activeSection == 'shows') sectionTitle = 'TV Shows';
    if (_activeSection == 'diary') sectionTitle = 'Watch Diary';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Text(
            sectionTitle,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: activeController,
              style: TextStyle(color: Theme.of(context).primaryColor),
              cursorColor: Theme.of(context).primaryColor,
              onChanged: (value) => _debouncedSetState(() {
                if (_activeSection == 'movies') _movieQuery = value;
                if (_activeSection == 'shows') _showQuery = value;
                if (_activeSection == 'diary') _diaryQuery = value;
              }),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor, size: 20),
                hintText: 'Search logs...',
                hintStyle: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildViewSwitcher(),
        ],
      ),
    );
  }

  // Mobile top segment selector
  Widget _buildMobileSegmentControl() {
    final sections = [
      {'id': 'movies', 'label': 'Movies', 'icon': Icons.movie},
      {'id': 'shows', 'label': 'Shows', 'icon': Icons.tv},
      {'id': 'diary', 'label': 'Diary', 'icon': Icons.book},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: sections.map((sec) {
          final isSelected = _activeSection == sec['id'];
          int count = 0;
          if (sec['id'] == 'movies') count = watchedMovies.length;
          if (sec['id'] == 'shows') count = watchedShows.length;
          if (sec['id'] == 'diary') count = diaryItems.length;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSection = sec['id'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sec['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sec['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Mobile controls (Search & View Modes)
  Widget _buildMobileControls() {
    final activeController = _activeSection == 'movies'
        ? _movieSearchController
        : _activeSection == 'shows'
            ? _showSearchController
            : _diarySearchController;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: activeController,
              style: TextStyle(color: Theme.of(context).primaryColor),
              cursorColor: Theme.of(context).primaryColor,
              onChanged: (value) => _debouncedSetState(() {
                if (_activeSection == 'movies') _movieQuery = value;
                if (_activeSection == 'shows') _showQuery = value;
                if (_activeSection == 'diary') _diaryQuery = value;
              }),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor, size: 18),
                hintText: 'Search $_activeSection...',
                hintStyle: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.02),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildViewSwitcher(),
        ],
      ),
    );
  }

  // Mobile watch stats banner
  Widget _buildMobileWatchTimeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Movies Time', style: TextStyle(fontSize: 10, color: Colors.white30)),
                  const SizedBox(height: 2),
                  Text(_formatWatchTime(totalMovieMinutes), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(width: 1, height: 20, color: Colors.white10),
              Column(
                children: [
                  const Text('TV Shows Time', style: TextStyle(fontSize: 10, color: Colors.white30)),
                  const SizedBox(height: 2),
                  Text(_formatWatchTime(totalTvMinutes), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(width: 1, height: 20, color: Colors.white10),
              Column(
                children: [
                  const Text('Total Time', style: TextStyle(fontSize: 10, color: Colors.white30)),
                  const SizedBox(height: 2),
                  Text(
                    _formatWatchTime(totalMovieMinutes + totalTvMinutes),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ],
          ),
          if (isCalculating) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: calculationProgress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Fetching runtimes... ${(calculationProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ] else if (needsCalculation) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Badge(
                  backgroundColor: Colors.amber,
                  label: const Text('!', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                  child: const Icon(Icons.refresh, size: 12),
                ),
                label: Text(
                  'Update watch times ($uncachedItemsCount logs pending)',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
                onPressed: _showCalculationWarningDialog,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Section view modes toggler buttons
  Widget _buildViewSwitcher() {
    if (_activeSection == 'movies') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewOptionButton('grid', Icons.grid_view, _movieViewMode, (val) => setState(() => _movieViewMode = val)),
          _buildViewOptionButton('list', Icons.view_list, _movieViewMode, (val) => setState(() => _movieViewMode = val)),
          _buildViewOptionButton('compact', Icons.grid_on_outlined, _movieViewMode, (val) => setState(() => _movieViewMode = val)),
        ],
      );
    } else if (_activeSection == 'shows') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewOptionButton('list', Icons.view_list, _showViewMode, (val) => setState(() => _showViewMode = val)),
          _buildViewOptionButton('grid', Icons.grid_view, _showViewMode, (val) => setState(() => _showViewMode = val)),
          _buildViewOptionButton('compact', Icons.grid_on_outlined, _showViewMode, (val) => setState(() => _showViewMode = val)),
        ],
      );
    } else {
      // Diary
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewOptionButton('timeline', Icons.timeline, _diaryViewMode, (val) => setState(() => _diaryViewMode = val)),
          _buildViewOptionButton('list', Icons.view_list, _diaryViewMode, (val) => setState(() => _diaryViewMode = val)),
          _buildViewOptionButton('grid', Icons.grid_view, _diaryViewMode, (val) => setState(() => _diaryViewMode = val)),
        ],
      );
    }
  }

  Widget _buildViewOptionButton(String mode, IconData icon, String currentMode, Function(String) onTap) {
    final isSelected = mode == currentMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: isSelected ? Theme.of(context).primaryColor : Colors.white54),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () => onTap(mode),
      ),
    );
  }

  // Switch content areas
  Widget _buildMainContent(String region) {
    if (_activeSection == 'movies') {
      return _buildMoviesContent(region);
    } else if (_activeSection == 'shows') {
      return _buildShowsContent(region);
    } else {
      return _buildDiaryContent(region);
    }
  }

  // MOVIES CONTENT LAYER
  Widget _buildMoviesContent(String region) {
    final String query = _movieQuery.trim().toLowerCase();
    final List<WatchHistoryItem> baseList = watchedMovies;
    final List<WatchHistoryItem> filtered = query.isEmpty
        ? baseList
        : baseList
            .where((m) => m.title.toLowerCase().contains(query))
            .toList();

    if (baseList.isEmpty && query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.movie_outlined,
        title: 'No watched movies yet',
        subtitle: 'Start watching movies to see them here!',
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_movieViewMode == 'grid') {
      return _buildMovieGrid(filtered, region, isCompact: false);
    } else if (_movieViewMode == 'compact') {
      return _buildMovieGrid(filtered, region, isCompact: true);
    } else {
      return _buildMovieListView(filtered, region);
    }
  }

  Widget _buildMovieGrid(List<WatchHistoryItem> items, String region, {required bool isCompact}) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 800 || AppPlatform.isDesktop;
    
    int crossAxisCount;
    if (isCompact) {
      crossAxisCount = isLarge ? 7 : 4;
    } else {
      crossAxisCount = isLarge ? 5 : 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: isCompact ? 8 : 12,
        mainAxisSpacing: isCompact ? 8 : 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final movie = items[index];
        if (isCompact) {
          return _buildCompactGridCard(movie, region);
        } else {
          return _buildDetailedGridCard(movie, region);
        }
      },
    );
  }

  Widget _buildMovieListView(List<WatchHistoryItem> items, String region) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final movie = items[index];
        return _buildDetailedListRow(movie, region);
      },
    );
  }

  // TV SHOWS CONTENT LAYER
  Widget _buildShowsContent(String region) {
    final String query = _showQuery.trim().toLowerCase();
    final List<WatchHistoryItem> baseList = watchedShows;
    final List<WatchHistoryItem> filtered = query.isEmpty
        ? baseList
        : baseList
            .where((s) => s.title.toLowerCase().contains(query))
            .toList();

    if (baseList.isEmpty && query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.tv_outlined,
        title: 'No watched shows yet',
        subtitle: 'Start watching shows to see them here!',
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_showViewMode == 'list') {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final show = filtered[index];
          return _buildDetailedListRow(show, region);
        },
      );
    } else if (_showViewMode == 'compact') {
      final grouped = _getGroupedShowsList(filtered);
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width >= 800 ? 7 : 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final showGroup = grouped[index];
          return _buildGroupedShowCompactCard(showGroup, region);
        },
      );
    } else {
      // Grid Grouped Shows
      final grouped = _getGroupedShowsList(filtered);
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width >= 800 ? 5 : 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final showGroup = grouped[index];
          return _buildGroupedShowDetailedCard(showGroup, region);
        },
      );
    }
  }

  List<Map<String, dynamic>> _getGroupedShowsList(List<WatchHistoryItem> sourceList) {
    final Map<int, List<WatchHistoryItem>> groups = {};
    for (final item in sourceList) {
      groups.putIfAbsent(item.tmdbId, () => []).add(item);
    }
    return groups.entries.map((e) {
      final episodes = e.value;
      episodes.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      final latest = episodes.first;
      return {
        'tmdbId': e.key,
        'title': latest.title,
        'posterPath': latest.posterPath,
        'count': episodes.length,
        'episodes': episodes,
        'latestWatchedAt': latest.watchedAt,
      };
    }).toList()..sort((a, b) => (b['latestWatchedAt'] as DateTime).compareTo(a['latestWatchedAt'] as DateTime));
  }

  // DIARY CONTENT LAYER
  Widget _buildDiaryContent(String region) {
    final String query = _diaryQuery.trim().toLowerCase();
    final List<WatchHistoryItem> baseList = diaryItems;
    final List<WatchHistoryItem> filtered = query.isEmpty
        ? baseList
        : baseList
            .where((d) => d.title.toLowerCase().contains(query))
            .toList();

    if (baseList.isEmpty && query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book_outlined,
        title: 'Your diary is empty',
        subtitle: 'Watch movies and shows to build your diary!',
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_diaryViewMode == 'grid') {
      return _buildMovieGrid(filtered, region, isCompact: false);
    } else if (_diaryViewMode == 'list') {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return _buildDetailedListRow(item, region);
        },
      );
    } else {
      // Timeline (default)
      return _buildTimelineDiaryView(filtered, region);
    }
  }

  // DIARY TIMELINE VIEW
  Widget _buildTimelineDiaryView(List<WatchHistoryItem> items, String region) {
    final Map<String, List<WatchHistoryItem>> grouped = {};
    for (final item in items) {
      final monthKey = DateFormat('MMMM yyyy').format(item.watchedAt);
      grouped.putIfAbsent(monthKey, () => []).add(item);
    }

    final keys = grouped.keys.toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final monthKey = keys[index];
          final monthItems = grouped[monthKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        monthKey,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(monthItems.length, (itemIndex) {
                final item = monthItems[itemIndex];
                final isLastItem = itemIndex == monthItems.length - 1 && index == keys.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 12,
                              color: Colors.white.withOpacity(0.12),
                            ),
                            TvFocusWrapper(
                              onTap: () async {
                                final confirm = await _showDeleteConfirmation(item);
                                if (confirm == true && item.id != null) {
                                  await _database.deleteWatchHistoryItem(item.id!);
                                  _loadWatchHistory();
                                }
                              },
                              borderRadius: 16.0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: item.type == 'movie'
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: item.type == 'movie' ? Colors.orange : Colors.blue,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (item.type == 'movie' ? Colors.orange : Colors.blue).withOpacity(0.2),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  item.type == 'movie' ? Icons.movie : Icons.tv,
                                  size: 14,
                                  color: item.type == 'movie' ? Colors.orange : Colors.blue,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isLastItem ? Colors.transparent : Colors.white.withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildTimelineItemCard(item, region),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineItemCard(WatchHistoryItem item, String region) {
    final isMovie = item.type == 'movie';
    return Dismissible(
      key: Key('timeline_item_${item.id ?? item.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(item),
      onDismissed: (direction) async {
        if (item.id != null) {
          await _database.deleteWatchHistoryItem(item.id!);
          _loadWatchHistory();
        }
      },
      child: TvFocusWrapper(
        onTap: () {
          if (isMovie) {
            _navigateToMovie(item.title, item.tmdbId);
          } else {
            _navigateToSerie(item.title, item.tmdbId);
          }
        },
        borderRadius: 16.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      image: item.posterPath != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                  '${getImageBaseUrl(region)}/t/p/w200${item.posterPath}',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.posterPath == null
                        ? Icon(isMovie ? Icons.movie : Icons.tv, color: Colors.grey[700])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: (isMovie ? getMovieTitleTextStyle(item.tmdbId) : getSeriesTitleTextStyle(item.tmdbId)).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isMovie ? Icons.movie_outlined : Icons.tv_outlined,
                                size: 10,
                                color: Colors.white30,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isMovie
                                    ? 'Movie'
                                    : ('TV Show' +
                                        (item.seasonNumber != null
                                            ? ' • S${item.seasonNumber} E${item.episodeNumber}'
                                            : '')),
                                style: const TextStyle(color: Colors.white30, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('hh:mm a • EEE, MMM dd').format(item.watchedAt),
                            style: const TextStyle(color: Colors.white24, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // DETAILED CARD/ROW RENDERERS
  Widget _buildDetailedGridCard(WatchHistoryItem item, String region) {
    final isMovie = item.type == 'movie';
    return GestureDetector(
      onLongPress: () async {
        final confirm = await _showDeleteConfirmation(item);
        if (confirm == true && item.id != null) {
          await _database.deleteWatchHistoryItem(item.id!);
          _loadWatchHistory();
        }
      },
      child: TvFocusWrapper(
        onTap: () {
          if (isMovie) {
            _navigateToMovie(item.title, item.tmdbId);
          } else {
            _navigateToSerie(item.title, item.tmdbId);
          }
        },
        borderRadius: 16.0,
        child: Card(
          elevation: 6,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withOpacity(0.03),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: item.posterPath != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              '${getImageBaseUrl(region)}/t/p/w500${item.posterPath}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.posterPath == null
                      ? Icon(isMovie ? Icons.movie : Icons.tv, size: 40, color: Colors.grey[700])
                      : null,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: (isMovie ? getMovieTitleTextStyle(item.tmdbId) : getSeriesTitleTextStyle(item.tmdbId)).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (item.seasonNumber != null && item.episodeNumber != null)
                        Text(
                          'S${item.seasonNumber} E${item.episodeNumber}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(item.watchedAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGridCard(WatchHistoryItem item, String region) {
    final isMovie = item.type == 'movie';
    return GestureDetector(
      onLongPress: () async {
        final confirm = await _showDeleteConfirmation(item);
        if (confirm == true && item.id != null) {
          await _database.deleteWatchHistoryItem(item.id!);
          _loadWatchHistory();
        }
      },
      child: TvFocusWrapper(
        onTap: () {
          if (isMovie) {
            _navigateToMovie(item.title, item.tmdbId);
          } else {
            _navigateToSerie(item.title, item.tmdbId);
          }
        },
        borderRadius: 8.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: item.posterPath != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          '${getImageBaseUrl(region)}/t/p/w200${item.posterPath}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.posterPath == null
                  ? Icon(isMovie ? Icons.movie : Icons.tv, size: 24, color: Colors.grey[700])
                  : null,
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isMovie ? Icons.movie : Icons.tv,
                  size: 8,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedListRow(WatchHistoryItem item, String region) {
    final isMovie = item.type == 'movie';
    return Dismissible(
      key: Key('detailed_list_item_${item.id ?? item.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(item),
      onDismissed: (direction) async {
        if (item.id != null) {
          await _database.deleteWatchHistoryItem(item.id!);
          _loadWatchHistory();
        }
      },
      child: TvFocusWrapper(
        onTap: () {
          if (isMovie) {
            _navigateToMovie(item.title, item.tmdbId);
          } else {
            _navigateToSerie(item.title, item.tmdbId);
          }
        },
        borderRadius: 16.0,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: item.posterPath != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              '${getImageBaseUrl(region)}/t/p/w200${item.posterPath}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.posterPath == null
                      ? Icon(isMovie ? Icons.movie : Icons.tv, color: Colors.grey[600], size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: (isMovie ? getMovieTitleTextStyle(item.tmdbId) : getSeriesTitleTextStyle(item.tmdbId)).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (item.seasonNumber != null && item.episodeNumber != null) ...[
                        Text(
                          'Season ${item.seasonNumber}, Episode ${item.episodeNumber}' +
                              (item.episodeTitle != null ? ' - "${item.episodeTitle}"' : ''),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 10, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            'Watched on ${DateFormat('MMM dd, yyyy').format(item.watchedAt)}',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
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
      ),
    );
  }

  // GROUPED SHOWS RENDERERS
  Widget _buildGroupedShowDetailedCard(Map<String, dynamic> showGroup, String region) {
    final tmdbId = showGroup['tmdbId'] as int;
    final title = showGroup['title'] as String;
    final posterPath = showGroup['posterPath'] as String?;
    final count = showGroup['count'] as int;
    final episodes = showGroup['episodes'] as List<WatchHistoryItem>;

    return TvFocusWrapper(
      onTap: () => _navigateToSerie(title, tmdbId),
      borderRadius: 16.0,
      child: Card(
        elevation: 6,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.03),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  image: posterPath != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            '${getImageBaseUrl(region)}/t/p/w500$posterPath',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: posterPath == null
                    ? Icon(Icons.tv, size: 40, color: Colors.grey[700])
                    : null,
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    '$count Ep${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: getSeriesTitleTextStyle(tmdbId).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last: ${DateFormat('MMM dd').format(showGroup['latestWatchedAt'] as DateTime)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () {
                    _showGroupedEpisodesBottomSheet(title, episodes, region);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54.withOpacity(0.75),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.list_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedShowCompactCard(Map<String, dynamic> showGroup, String region) {
    final tmdbId = showGroup['tmdbId'] as int;
    final title = showGroup['title'] as String;
    final posterPath = showGroup['posterPath'] as String?;
    final count = showGroup['count'] as int;
    final episodes = showGroup['episodes'] as List<WatchHistoryItem>;

    return TvFocusWrapper(
      onTap: () => _navigateToSerie(title, tmdbId),
      borderRadius: 8.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                image: posterPath != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          '${getImageBaseUrl(region)}/t/p/w200$posterPath',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: posterPath == null
                  ? const Icon(Icons.tv, size: 20, color: Colors.grey)
                  : null,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: InkWell(
                onTap: () => _showGroupedEpisodesBottomSheet(title, episodes, region),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.list_alt, size: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM SHEET & DIALOG LAYER
  void _showGroupedEpisodesBottomSheet(String showTitle, List<WatchHistoryItem> episodes, String region) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                showTitle,
                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Watched Episodes (Swipe left to delete)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final ep = episodes[index];
                    return ListTileTheme(
                      textColor: Colors.white,
                      child: Dismissible(
                        key: Key('grouped_ep_${ep.id ?? ep.hashCode}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.redAccent.withOpacity(0.2),
                          child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 24),
                        ),
                        confirmDismiss: (direction) => _showDeleteConfirmation(ep),
                        onDismissed: (direction) async {
                          if (ep.id != null) {
                            await _database.deleteWatchHistoryItem(ep.id!);
                            _loadWatchHistory();
                          }
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'S${ep.seasonNumber} E${ep.episodeNumber}' + (ep.episodeTitle != null ? ' - ${ep.episodeTitle}' : ''),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Watched: ${DateFormat('MMM dd, yyyy').format(ep.watchedAt)}',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(WatchHistoryItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Watch Log', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to remove "${item.title}" from your watch history?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
