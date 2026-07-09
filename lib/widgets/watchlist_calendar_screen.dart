import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:Mirarr/functions/fetchers/fetch_serie_details.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:Mirarr/seriesPage/serieDetailPage.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';

class WatchlistCalendarScreen extends StatefulWidget {
  const WatchlistCalendarScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistCalendarScreen> createState() => _WatchlistCalendarScreenState();
}

class _WatchlistCalendarScreenState extends State<WatchlistCalendarScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Serie> _watchlistSeries = [];

  @override
  void initState() {
    super.initState();
    _fetchWatchlistAndDetails();
  }

  Future<void> _fetchWatchlistAndDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final openbox = Hive.box('sessionBox');
      final String? accountId = openbox.get('accountId');
      final String? sessionData = openbox.get('sessionData');
      final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final apiKey = dotenv.env['TMDB_API_KEY'];
      final baseUrl = getBaseUrl(region);

      if (accountId == null || sessionData == null || apiKey == null) {
        throw Exception('User session or API Key not found');
      }

      // Fetch all pages of TV watchlist
      int page = 1;
      int totalPages = 1;
      List<Serie> basicSeries = [];

      while (page <= totalPages) {
        final response = await http.get(
          Uri.parse('${baseUrl}account/$accountId/watchlist/tv?api_key=$apiKey&session_id=$sessionData&page=$page'),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> decoded = json.decode(response.body);
          totalPages = decoded['total_pages'] ?? 1;
          final List<dynamic> results = decoded['results'] ?? [];
          for (var result in results) {
            basicSeries.add(Serie(
              name: result['name'],
              posterPath: result['poster_path'] ?? '',
              overView: result['overview'] ?? '',
              id: result['id'],
              score: (result['vote_average'] as num?)?.toDouble() ?? 0.0,
            ));
          }
          page++;
        } else {
          throw Exception('Failed to load watchlist series');
        }
      }

      if (!mounted) return;

      // Fetch details for all series in parallel (fault tolerant)
      final List<Future<Map<String, dynamic>>> detailFutures = basicSeries.map((serie) async {
        try {
          return await fetchSerieDetails(serie.id, region);
        } catch (e) {
          // If details fetch fails for one show, return empty map to prevent breaking the whole screen
          return <String, dynamic>{};
        }
      }).toList();

      final List<Map<String, dynamic>> allSerieDetails = await Future.wait(detailFutures);

      final List<Serie> detailedSeries = [];
      for (var i = 0; i < basicSeries.length; i++) {
        final serie = basicSeries[i];
        final serieDetails = allSerieDetails[i];

        if (serieDetails.isEmpty) {
          // Keep basic serie if details failed
          detailedSeries.add(serie);
          continue;
        }

        final nextEpisode = serieDetails['next_episode_to_air'];
        final String? nextAirDate = nextEpisode?['air_date'];
        final int? nextEpisodeSeasonNumber = nextEpisode?['season_number'];
        final int? nextEpisodeEpisodeNumber = nextEpisode?['episode_number'];
        final String? nextEpisodeName = nextEpisode?['name'];

        final serieLatestAir = serieDetails['last_air_date'];
        final serieLastEpisodeSeasonNumber = serieDetails['last_episode_to_air']?['season_number'];
        final serieLastEpisodeEpisodeNumber = serieDetails['last_episode_to_air']?['episode_number'];

        detailedSeries.add(Serie(
          name: serie.name,
          posterPath: serie.posterPath,
          overView: serie.overView,
          id: serie.id,
          score: serie.score,
          backdropPath: serieDetails['backdrop_path'] ?? serie.backdropPath,
          lastAirDate: serieLatestAir,
          lastEpisodeSeasonNumber: serieLastEpisodeSeasonNumber,
          lastEpisodeEpisodeNumber: serieLastEpisodeEpisodeNumber,
          nextAirDate: nextAirDate,
          nextEpisodeSeasonNumber: nextEpisodeSeasonNumber,
          nextEpisodeEpisodeNumber: nextEpisodeEpisodeNumber,
          nextEpisodeName: nextEpisodeName,
        ));
      }

      if (!mounted) return;

      setState(() {
        _watchlistSeries = detailedSeries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String friendlyMessage = 'Something went wrong. Please try again.';
      final errStr = e.toString();
      if (errStr.contains('ClientException') ||
          errStr.contains('SocketException') ||
          errStr.contains('Connection failed')) {
        friendlyMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errStr.contains('User session') || errStr.contains('API Key')) {
        friendlyMessage = 'Authentication or session error. Please log in again.';
      } else {
        friendlyMessage = errStr.replaceAll('Exception: ', '');
      }
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  DateTime? _parseAirDate(String? airDateStr) {
    if (airDateStr == null || airDateStr.isEmpty) return null;
    try {
      final parts = airDateStr.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  Widget _buildUpcomingListView(BuildContext context, String region) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Filter and sort future episodes
    final upcomingSeries = _watchlistSeries.where((s) {
      final airDate = _parseAirDate(s.nextAirDate);
      if (airDate == null) return false;
      return !airDate.isBefore(today);
    }).toList();

    // Sort ascending
    upcomingSeries.sort((a, b) {
      final dateA = _parseAirDate(a.nextAirDate)!;
      final dateB = _parseAirDate(b.nextAirDate)!;
      return dateA.compareTo(dateB);
    });

    if (upcomingSeries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tv_off, color: Theme.of(context).primaryColor.withValues(alpha: 0.4), size: 48),
              const SizedBox(height: 12),
              const Text(
                'No future episodes scheduled in your watchlist.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    // Group shows by air date
    final Map<String, List<Serie>> grouped = {};
    for (var s in upcomingSeries) {
      final dateStr = s.nextAirDate!;
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(s);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: TvFocusModeManager.isTvDevice ? 16.0 : BottomBar.getHeight(context),
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateStr = sortedDates[dateIndex];
        final date = _parseAirDate(dateStr)!;
        final list = grouped[dateStr]!;

        final String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);
        final int difference = date.difference(today).inDays;
        final bool isDateToday = difference == 0;

        // Calculate remaining days text next to the date
        String remainingText = '';
        if (difference == 0) {
          remainingText = 'Today';
        } else if (difference == 1) {
          remainingText = 'Tomorrow (1 day remaining)';
        } else {
          remainingText = '$difference days remaining';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: isDateToday ? Theme.of(context).highlightColor : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($remainingText)',
                    style: TextStyle(
                      color: isDateToday ? Theme.of(context).highlightColor.withValues(alpha: 0.8) : Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            ...list.map((serie) => _buildEpisodeTile(context, serie, region)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Serie serie, String region) {
    final displayEpisodeCode = serie.nextEpisodeSeasonNumber != null && serie.nextEpisodeEpisodeNumber != null
        ? 'S${serie.nextEpisodeSeasonNumber.toString().padLeft(2, '0')}E${serie.nextEpisodeEpisodeNumber.toString().padLeft(2, '0')}'
        : '';
    final episodeName = serie.nextEpisodeName != null && serie.nextEpisodeName!.isNotEmpty
        ? ' - "${serie.nextEpisodeName}"'
        : '';

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: serie.posterPath.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: '${getImageBaseUrl(region)}/t/p/w185${serie.posterPath}',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.tv, color: Colors.white30, size: 20),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  width: 50,
                  height: 75,
                  child: const Icon(Icons.tv, color: Colors.white30, size: 20),
                ),
        ),
        title: Text(
          serie.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$displayEpisodeCode$episodeName',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SerieDetailPage(serieName: serie.name, serieId: serie.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTv = TvFocusModeManager.isTvDevice;
    final region = Provider.of<RegionProvider>(context).currentRegion;

    Widget body;
    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _fetchWatchlistAndDetails,
              ),
            ],
          ),
        ),
      );
    } else {
      body = _buildUpcomingListView(context, region);
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Upcoming Episodes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isTv
          ? Column(
              children: [
                const BottomBar(),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isTv ? null : const BottomBar(),
    );
  }
}
