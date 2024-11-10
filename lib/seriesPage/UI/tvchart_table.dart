import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/seriesPage/UI/omdb_table.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TvChartTable extends StatefulWidget {
  final String imdbId;

  const TvChartTable({Key? key, required this.imdbId}) : super(key: key);

  @override
  State<TvChartTable> createState() => _TvChartTableState();
}

class _TvChartTableState extends State<TvChartTable> {
  bool _isLoading = true;
  String? _error;
  Map<int, List<Episode>> _seasonEpisodes = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://tvcharts.co/api/seasons/${widget.imdbId}?ended=true'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'referer': 'https://tvcharts.co/show/${widget.imdbId}',
          'Host': 'tvcharts.co',
          'Cache-Control': 'no-cache',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Site': 'same-origin',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final seasons = data['seasons'] as Map<String, dynamic>;

        setState(() {
          _seasonEpisodes = Map.fromEntries(
            seasons.entries.map((entry) {
              final seasonNumber = int.parse(entry.key);
              final episodes = (entry.value as List)
                  .map((e) => Episode.fromJson(e as Map<String, dynamic>))
                  .toList();
              return MapEntry(seasonNumber, episodes);
            }),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load episodes: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getRatingColor(String rating) {
    if (rating == '-' || rating == 'N/A' || rating.isEmpty) {
      return Colors.grey;
    }

    try {
      final ratingNum = double.parse(rating);
      if (ratingNum >= 9.0) return Colors.green.shade900.withOpacity(0.5);
      if (ratingNum >= 8.5) return Colors.green.withOpacity(0.5);
      if (ratingNum >= 8.0) return Colors.lightGreen.withOpacity(0.5);
      if (ratingNum >= 7.0) return Colors.yellow.withOpacity(0.5);
      if (ratingNum >= 6.0) return Colors.orange.withOpacity(0.5);
      return Colors.red.withOpacity(0.5);
    } catch (e) {
      // Return grey if rating can't be parsed to double
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            labelColor: Colors.black,
            padding: Platform.isAndroid || Platform.isIOS
                ? const EdgeInsets.fromLTRB(0, 32, 0, 0)
                : const EdgeInsets.fromLTRB(0, 0, 0, 0),
            indicator: BoxDecoration(color: Theme.of(context).primaryColor),
            unselectedLabelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                text: 'Compact',
              ),
              Tab(
                text: 'Expanded',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // First tab - Compact View
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildCompactTable(),
            ),
            // Second tab - Expanded View
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: _buildExpandedTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // Show error message briefly before navigation
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OmdbTable(
              imdbId: widget.imdbId,
              title: 'Episode Ratings', // Or pass a title if you have it stored
            ),
          ),
        );
      });

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'There was an error loading the data from tvcharts.co, calculating ratings from IMDB',
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }

    if (_seasonEpisodes.isEmpty) {
      return const Center(child: Text('No episodes found'));
    }

    // Find the maximum number of episodes across all seasons
    final maxEpisodes = _seasonEpisodes.values
        .map((episodes) => episodes.length)
        .reduce((max, length) => length > max ? length : max);

    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate column widths
    final Map<int, TableColumnWidth> columnWidths = {
      0: const FixedColumnWidth(30),
    };
    for (var i = 0; i < _seasonEpisodes.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(45);
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: Platform.isAndroid || Platform.isIOS ? null : screenWidth,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Table(
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text('Ep',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.white)),
                          ),
                        ),
                        ..._seasonEpisodes.keys.map((season) => TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text('S$season',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.white)),
                              ),
                            )),
                      ],
                    ),
                    // Episode rows
                    for (var episodeIndex = 0;
                        episodeIndex < maxEpisodes;
                        episodeIndex++)
                      TableRow(
                        children: [
                          // Episode number
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                '${episodeIndex + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                          // Ratings for each season
                          ..._seasonEpisodes.values.map((episodes) {
                            if (episodeIndex < episodes.length) {
                              final episode = episodes[episodeIndex];
                              return TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: _getRatingColor(episode.rating),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      episode.rating,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const TableCell(
                                child: SizedBox(height: 25),
                              );
                            }
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error, Either this series is not available or the API is down',
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
        ),
      );
    }

    if (_seasonEpisodes.isEmpty) {
      return const Center(child: Text('No episodes found'));
    }

    final maxEpisodes = _seasonEpisodes.values
        .map((episodes) => episodes.length)
        .reduce((max, length) => length > max ? length : max);

    final Map<int, TableColumnWidth> columnWidths = {
      0: const FixedColumnWidth(40),
    };
    for (var i = 0; i < _seasonEpisodes.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(150);
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                columnWidths: columnWidths,
                border:
                    TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    children: [
                      const TableCell(
                        child: Center(
                          child: Text('Ep',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white)),
                        ),
                      ),
                      ..._seasonEpisodes.keys.map((season) => TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text('Season $season',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white)),
                            ),
                          )),
                    ],
                  ),
                  for (var episodeIndex = 0;
                      episodeIndex < maxEpisodes;
                      episodeIndex++)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Center(
                              child: Text(
                                '${episodeIndex + 1}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        ..._seasonEpisodes.values.map((episodes) {
                          if (episodeIndex < episodes.length) {
                            final episode = episodes[episodeIndex];
                            return TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(episode.rating),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        episode.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        episode.rating,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        episode.releaseDate,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return const TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: SizedBox(height: 50),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Episode {
  final String episodeNumber;
  final String title;
  final String rating;
  final String releaseDate;
  final String plot;

  Episode({
    required this.episodeNumber,
    required this.title,
    required this.rating,
    required this.releaseDate,
    required this.plot,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episodeNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      rating: json['imDbRating']?.toString() ?? 'N/A',
      releaseDate: json['released']?.toString() ?? '',
      plot: json['plot']?.toString() ?? '',
    );
  }
}
