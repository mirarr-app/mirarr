import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/models/watch_history_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ShelfPage extends StatefulWidget {
  const ShelfPage({super.key});

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final WatchHistoryDatabase _database = WatchHistoryDatabase();
  
  List<WatchHistoryItem> watchedMovies = [];
  List<WatchHistoryItem> watchedShows = [];
  List<WatchHistoryItem> diaryItems = [];
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWatchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

      setState(() {
        watchedMovies = movies;
        watchedShows = shows;
        diaryItems = diary;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading watch history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
    
    return Scaffold(
      appBar: TabBar(
               labelColor: Colors.black,
        padding: Platform.isAndroid || Platform.isIOS
            ? const EdgeInsets.fromLTRB(0, 36, 0, 0)
            : const EdgeInsets.fromLTRB(0, 0, 0, 0),
        indicator: BoxDecoration(color: Theme.of(context).primaryColor),
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies', icon: Icon(Icons.movie)),
            Tab(text: 'Shows', icon: Icon(Icons.tv)),
            Tab(text: 'Diary', icon: Icon(Icons.book)),
          ],
        ),
      
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMoviesTab(region),
                _buildShowsTab(region),
                _buildDiaryTab(region),
              ],
            ),
      bottomNavigationBar: BottomBar(),
    );
  }

  Widget _buildMoviesTab(String region) {
    if (watchedMovies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No watched movies yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start watching movies to see them here!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWatchHistory,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Platform.isWindows || Platform.isLinux || Platform.isMacOS ? 5 : 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: watchedMovies.length,
          itemBuilder: (context, index) {
            final movie = watchedMovies[index];
            return _buildMovieCard(movie, region);
          },
        ),
      ),
    );
  }

  Widget _buildShowsTab(String region) {
    if (watchedShows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No watched shows yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start watching shows to see them here!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWatchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: watchedShows.length,
        itemBuilder: (context, index) {
          final show = watchedShows[index];
          return _buildShowCard(show, region);
        },
      ),
    );
  }

  Widget _buildDiaryTab(String region) {
    if (diaryItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your diary is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Watch movies and shows to build your diary!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWatchHistory,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: diaryItems.length,
          itemBuilder: (context, index) {
            final item = diaryItems[index];
            return _buildDiaryCard(item, region);
          },
        ),
      ),
    );
  }

  Widget _buildMovieCard(WatchHistoryItem movie, String region) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                image: movie.posterPath != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          '${getImageBaseUrl(region)}/t/p/w500${movie.posterPath}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: movie.posterPath == null
                  ? const Icon(Icons.movie, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: getMovieTitleTextStyle(movie.tmdbId).copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(movie.watchedAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowCard(WatchHistoryItem show, String region) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListTile(
          leading: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: show.posterPath != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        '${getImageBaseUrl(region)}/t/p/w200${show.posterPath}',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: show.posterPath == null
                ? const Icon(Icons.tv, color: Colors.grey)
                : null,
          ),
          title: Text(
            show.title,
            style: getSeriesTitleTextStyle(show.tmdbId).copyWith(fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (show.seasonNumber != null && show.episodeNumber != null)
                Text('S${show.seasonNumber} E${show.episodeNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                'Watched on ${DateFormat('MMM dd, yyyy').format(show.watchedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          isThreeLine: show.seasonNumber != null && show.episodeNumber != null,
        ),
      ),
    );
  }

  Widget _buildDiaryCard(WatchHistoryItem item, String region) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
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
              ? Icon(
                  item.type == 'movie' ? Icons.movie : Icons.tv,
                  color: Colors.grey,
                )
              : null,
        ),
        title: Text(
          item.title,
          style: item.type == 'movie' ? getMovieTitleTextStyle(item.tmdbId).copyWith(fontSize: 14) : getSeriesTitleTextStyle(item.tmdbId).copyWith(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.type == 'movie' ? Icons.movie : Icons.tv,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  item.type == 'movie' ? 'Movie' : 'TV Show',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (item.seasonNumber != null && item.episodeNumber != null) ...[
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Text(
                    'S${item.seasonNumber} E${item.episodeNumber}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(item.watchedAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
