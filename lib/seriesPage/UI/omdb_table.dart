import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OmdbTable extends StatefulWidget {
  final String imdbId;
  final String title;

  const OmdbTable({super.key, required this.imdbId, required this.title});

  @override
  State<OmdbTable> createState() => _OmdbTableState();
}

class _OmdbTableState extends State<OmdbTable> {
  final Map<int, List<Episode>> _seasonEpisodes = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllSeasonData();
  }

  Future<void> _fetchAllSeasonData() async {
    try {
      final omdbApiKey = dotenv.env['OMDB_API_KEY'];

      if (omdbApiKey == null) {
        throw Exception('OMDB API key not found in .env file');
      }

      print('Fetching data for series: ${widget.imdbId}');

      final seasonResponse = await http.get(
        Uri.parse(
            'http://www.omdbapi.com/?i=${widget.imdbId}&apikey=$omdbApiKey'),
      );

      print('Season response status: ${seasonResponse.statusCode}');
      print('Season response body: ${seasonResponse.body}');

      if (seasonResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch series data: ${seasonResponse.statusCode}');
      }

      final seriesData = json.decode(seasonResponse.body);

      if (seriesData['Response'] == 'False') {
        throw Exception(seriesData['Error'] ?? 'Failed to fetch series data');
      }

      if (!seriesData.containsKey('totalSeasons')) {
        throw Exception('No season data available for this series');
      }

      final totalSeasons = int.parse(seriesData['totalSeasons']);
      print('Total seasons: $totalSeasons');

      for (int season = 1; season <= totalSeasons; season++) {
        print('Fetching season $season');

        final response = await http.get(
          Uri.parse(
              'http://www.omdbapi.com/?i=${widget.imdbId}&Season=$season&apikey=$omdbApiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['Episodes'] != null) {
            final episodes = (data['Episodes'] as List)
                .map((e) => Episode(
                      number: int.parse(e['Episode']),
                      title: e['Title'],
                      rating: e['imdbRating'] != 'N/A'
                          ? double.parse(e['imdbRating'])
                          : null,
                    ))
                .toList();

            print('Season $season: ${episodes.length} episodes');

            setState(() {
              _seasonEpisodes[season] = episodes;
            });
          }
        } else {
          print('Failed to fetch season $season: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRatingColor(String ratingText) {
    if (ratingText == '-' || ratingText == 'N/A') {
      return Colors.grey;
    }

    final rating = double.parse(ratingText);
    if (rating >= 8.5) return Colors.green;
    if (rating >= 7.5) return Colors.lightGreen;
    if (rating >= 6.5) return Colors.yellow;
    if (rating >= 5.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_seasonEpisodes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
              SizedBox(height: 16),
              Text('No episode data available'),
            ],
          ),
        ),
      );
    }

    final maxEpisodes = _seasonEpisodes.values
        .map((episodes) => episodes.length)
        .reduce((max, length) => length > max ? length : max);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingTextStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            dividerThickness: 0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DataTable(
                            columnSpacing: 20,
                            horizontalMargin: 12,
                            columns: [
                              DataColumn(
                                label: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Episode'),
                                ),
                              ),
                              for (var season
                                  in _seasonEpisodes.keys.toList()..sort())
                                DataColumn(
                                  label: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('S$season'),
                                  ),
                                ),
                            ],
                            rows: [
                              for (var episodeNum = 1;
                                  episodeNum <= maxEpisodes;
                                  episodeNum++)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'E$episodeNum',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (var season
                                        in _seasonEpisodes.keys.toList()
                                          ..sort())
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: _getRatingColor(
                                              _seasonEpisodes[season]!
                                                      .where((e) =>
                                                          e.number ==
                                                          episodeNum)
                                                      .map((e) =>
                                                          e.rating
                                                              ?.toString() ??
                                                          'N/A')
                                                      .firstOrNull ??
                                                  '-',
                                            ).withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _seasonEpisodes[season]!
                                                    .where((e) =>
                                                        e.number == episodeNum)
                                                    .map((e) =>
                                                        e.rating?.toString() ??
                                                        'N/A')
                                                    .firstOrNull ??
                                                '-',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Episode {
  final int number;
  final String title;
  final double? rating;

  Episode({
    required this.number,
    required this.title,
    this.rating,
  });
}
