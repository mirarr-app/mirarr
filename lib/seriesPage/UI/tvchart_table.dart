import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/functions/platform_helper.dart';
import 'package:Mirarr/functions/get_imdb_score.dart';

class TvChartTable extends StatefulWidget {
  final String imdbId;

  const TvChartTable({Key? key, required this.imdbId}) : super(key: key);

  @override
  State<TvChartTable> createState() => _TvChartTableState();
}

class _TvChartTableState extends State<TvChartTable> {
  bool _isLoading = true;
  String? _error;
  String _showTitle = 'Episode Ratings';
  Map<int, List<Episode>> _seasonEpisodes = {};

  @override
  void initState() {
    super.initState();
    _fetchRatingsData();
  }

  Future<void> _fetchRatingsData() async {
    try {
      final omdbApiKey = dotenv.env['OMDB_API_KEY'];
      if (omdbApiKey == null) {
        throw Exception('OMDB API key not found in .env file');
      }

      // 1. Fetch main series metadata to get show title and total seasons
      final metadataResponse = await http.get(
        Uri.parse('http://www.omdbapi.com/?i=${widget.imdbId}&apikey=$omdbApiKey'),
      ).timeout(const Duration(seconds: 5));

      if (metadataResponse.statusCode != 200) {
        throw Exception('Failed to fetch metadata: ${metadataResponse.statusCode}');
      }

      final metadata = json.decode(metadataResponse.body);
      if (metadata['Response'] == 'False') {
        throw Exception(metadata['Error'] ?? 'Series not found');
      }

      final totalSeasons = int.tryParse(metadata['totalSeasons'] ?? '') ?? 0;
      final title = metadata['Title'] ?? 'Episode Ratings';

      setState(() {
        _showTitle = title;
      });

      if (totalSeasons == 0) {
        throw Exception('No seasons found for this show.');
      }

      // 2. Fetch all seasons concurrently
      final List<Future<http.Response>> seasonFutures = [];
      for (int season = 1; season <= totalSeasons; season++) {
        seasonFutures.add(
          http.get(
            Uri.parse('http://www.omdbapi.com/?i=${widget.imdbId}&Season=$season&apikey=$omdbApiKey'),
          ).timeout(const Duration(seconds: 5)),
        );
      }

      final seasonResponses = await Future.wait(seasonFutures);

      final Map<int, List<Episode>> fetchedSeasonEpisodes = {};
      final List<Map<String, dynamic>> pendingRatings = [];

      for (int i = 0; i < seasonResponses.length; i++) {
        final seasonNumber = i + 1;
        final response = seasonResponses[i];

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['Episodes'] != null) {
            final List<Episode> episodes = [];
            final episodesList = data['Episodes'] as List;

            for (var e in episodesList) {
              final epNum = int.tryParse(e['Episode']?.toString() ?? '') ?? 0;
              final epTitle = e['Title'] ?? '';
              final ratingVal = e['imdbRating'] != 'N/A' && e['imdbRating'] != null
                  ? double.tryParse(e['imdbRating'].toString())
                  : null;
              final epImdbId = e['imdbID'] as String?;
              final release = e['Released'] ?? '';

              if (ratingVal != null) {
                episodes.add(Episode(
                  number: epNum,
                  title: epTitle,
                  rating: ratingVal,
                  releaseDate: release,
                ));
              } else if (epImdbId != null && epImdbId.isNotEmpty) {
                // Queue for batch lookup from our API
                pendingRatings.add({
                  'season': seasonNumber,
                  'number': epNum,
                  'title': epTitle,
                  'imdbID': epImdbId,
                  'releaseDate': release,
                });
              } else {
                episodes.add(Episode(
                  number: epNum,
                  title: epTitle,
                  rating: null,
                  releaseDate: release,
                ));
              }
            }
            fetchedSeasonEpisodes[seasonNumber] = episodes;
          }
        }
      }

      // 3. Perform batch API fetch for missing ratings
      if (pendingRatings.isNotEmpty) {
        try {
          final List<String> imdbIds = pendingRatings.map((e) => e['imdbID'] as String).toList();
          final scoresMap = await getImdbScoresBatch(imdbIds);

          for (var p in pendingRatings) {
            final season = p['season'] as int;
            final epNum = p['number'] as int;
            final epTitle = p['title'] as String;
            final imdbId = p['imdbID'] as String;
            final release = p['releaseDate'] as String;
            final rating = scoresMap[imdbId];

            fetchedSeasonEpisodes[season]?.add(Episode(
              number: epNum,
              title: epTitle,
              rating: rating,
              releaseDate: release,
            ));
          }
        } catch (_) {
          // If batch fallback fails, add them with null ratings
          for (var p in pendingRatings) {
            final season = p['season'] as int;
            final epNum = p['number'] as int;
            final epTitle = p['title'] as String;
            final release = p['releaseDate'] as String;

            fetchedSeasonEpisodes[season]?.add(Episode(
              number: epNum,
              title: epTitle,
              rating: null,
              releaseDate: release,
            ));
          }
        }
      }

      // Sort episodes inside each season by number
      for (var season in fetchedSeasonEpisodes.keys) {
        fetchedSeasonEpisodes[season]?.sort((a, b) => a.number.compareTo(b.number));
      }

      setState(() {
        _seasonEpisodes = fetchedSeasonEpisodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getRatingColor(double? rating) {
    if (rating == null) {
      return Colors.grey[850]!;
    }
    if (rating >= 9.0) return const Color(0xFF1E5631).withOpacity(0.85); // Excellent
    if (rating >= 8.0) return const Color(0xFF4C9A2A).withOpacity(0.85); // Good
    if (rating >= 7.0) return const Color(0xFFD4AF37).withOpacity(0.85); // Average
    if (rating >= 6.0) return const Color(0xFFE97451).withOpacity(0.85); // Mediocre
    return const Color(0xFFC21807).withOpacity(0.85); // Poor
  }

  void _showEpisodeDetails(BuildContext context, int seasonNumber, Episode episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1.5),
        ),
        title: Text(
          'Season $seasonNumber, Episode ${episode.number}',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 22),
                const SizedBox(width: 6),
                Text(
                  episode.rating != null ? '${episode.rating!.toStringAsFixed(1)} / 10' : 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (episode.releaseDate.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Released: ${episode.releaseDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _showTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.amber,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchRatingsData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_seasonEpisodes.isEmpty) {
      return const Center(
        child: Text(
          'No episode ratings found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final sortedSeasons = _seasonEpisodes.keys.toList()..sort();
    final maxEpisodes = _seasonEpisodes.values
        .map((episodes) => episodes.length)
        .reduce((max, length) => length > max ? length : max);

    final Map<int, TableColumnWidth> columnWidths = {
      0: const FixedColumnWidth(35),
    };
    for (int i = 0; i < sortedSeasons.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(55);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
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
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Table(
                        columnWidths: columnWidths,
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          // Header row
                          TableRow(
                            children: [
                              const TableCell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Ep',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              ...sortedSeasons.map((season) => TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'S$season',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                          // Episode rows
                          for (int episodeIndex = 0; episodeIndex < maxEpisodes; episodeIndex++)
                            TableRow(
                              children: [
                                // Episode number label
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      '${episodeIndex + 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Episode cells for each season
                                ...sortedSeasons.map((seasonNumber) {
                                  final episodes = _seasonEpisodes[seasonNumber]!;
                                  if (episodeIndex < episodes.length) {
                                    final episode = episodes[episodeIndex];
                                    final ratingText = episode.rating != null
                                        ? episode.rating!.toStringAsFixed(1)
                                        : 'N/A';
                                    return TableCell(
                                      child: GestureDetector(
                                        onTap: () => _showEpisodeDetails(context, seasonNumber, episode),
                                        child: Container(
                                          margin: const EdgeInsets.all(2.0),
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          decoration: BoxDecoration(
                                            color: _getRatingColor(episode.rating),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.05),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            ratingText,
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
                                      child: SizedBox(height: 32),
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
          ),
          _buildLegend(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'IMDb Ratings Color Scale (Tap cell to view details)',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('≥ 9.0', const Color(0xFF1E5631)),
              _buildLegendItem('8.0 - 8.9', const Color(0xFF4C9A2A)),
              _buildLegendItem('7.0 - 7.9', const Color(0xFFD4AF37)),
              _buildLegendItem('6.0 - 6.9', const Color(0xFFE97451)),
              _buildLegendItem('< 6.0', const Color(0xFFC21807)),
              _buildLegendItem('N/A', Colors.grey[850]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}

class Episode {
  final int number;
  final String title;
  final double? rating;
  final String releaseDate;

  Episode({
    required this.number,
    required this.title,
    this.rating,
    required this.releaseDate,
  });
}
