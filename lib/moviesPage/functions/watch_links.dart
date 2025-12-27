import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model class for download items from Iran servers
class DownloadItem {
  final String fileName;
  final String url;
  final String size;
  final String server;
  final bool mayCensorContent;

  DownloadItem({
    required this.fileName,
    required this.url,
    required this.size,
    required this.server,
    this.mayCensorContent = false,
  });
}

// Function to simplify movie title for API search
String _simplifyMovieTitle(String title) {
  // Convert to lowercase
  String simplified = title.toLowerCase();
  
  // Remove common symbols and punctuation
  // Keep only letters, numbers, and spaces
  simplified = simplified.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  
  // Replace multiple spaces with single space
  simplified = simplified.replaceAll(RegExp(r'\s+'), ' ');
  
  // Trim whitespace
  simplified = simplified.trim();
  
  return simplified;
}

// Function to launch a URL
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
  }
}

// Function to copy URL to clipboard
Future<void> _copyToClipboard(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Color getColor(BuildContext context, int movieId) {
  return getMovieColor(context, movieId);
}

Future<Map<String, Map<String, dynamic>>> fetchSources() async {
  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/mirarr-app/sources/refs/heads/main/moviesources.txt'));

    if (response.statusCode == 200) {
      return Map<String, Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load sources');
    }
  } catch (e) {
    throw Exception('failed to load sources');
  }
}

// Function to fetch and parse download links from an Iran server
Future<List<DownloadItem>> fetchIranDownloadLinks(
    String baseUrl, String server) async {
  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<DownloadItem> items = [];
      final body = response.body;

      // Parse the HTML to extract file links
      // Match table rows with file information
      final rowRegex = RegExp(
        r'<tr>\s*<td class="n">\s*<a href="([^"]+)"[^>]*>.*?</a>\s*</td>\s*<td class="m">.*?</td>\s*<td class="s">\s*(?:<code>)?([^<]+)(?:</code>)?\s*</td>\s*</tr>',
        multiLine: true,
        dotAll: true,
      );

      for (final match in rowRegex.allMatches(body)) {
        final href = match.group(1)!;
        final size = match.group(2)!.trim();

        // Skip parent directory and empty entries
        if (href == '../' || href.isEmpty || size == '-') continue;

        // Build full URL
        final fullUrl =
            baseUrl.endsWith('/') ? '$baseUrl$href' : '$baseUrl/$href';

        items.add(DownloadItem(
          fileName: Uri.decodeComponent(href),
          url: fullUrl,
          size: size,
          server: server,
        ));
      }

      return items;
    }
    return [];
  } catch (e) {
    return [];
  }
}

// Function to fetch download links from the GiftMond API
Future<List<DownloadItem>> fetchGiftMondDownloadLinks(
    String movieTitle, String year) async {
  try {
    // Simplify the movie title (lowercase, remove symbols)
    final simplifiedTitle = _simplifyMovieTitle(movieTitle);
    // URL encode the simplified movie title
    final encodedTitle = Uri.encodeComponent(simplifiedTitle);
    final apiUrl =
        'https://server-hi-speed-iran.info/api/search/$encodedTitle/4F5A9C3D9A86FA54EACEDDD635185/';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<DownloadItem> items = [];
      final Map<String, dynamic> data = json.decode(response.body);

      // Get the posters array
      final List<dynamic>? posters = data['posters'];
      if (posters == null) return [];

      // Filter by year (like jq's select(.year == 2019))
      final int targetYear = int.tryParse(year) ?? 0;
      final matchingPosters = posters.where((poster) {
        final posterYear = poster['year'];
        return posterYear == targetYear;
      }).toList();

      // Extract sources from matching posters
      for (final poster in matchingPosters) {
        final List<dynamic>? sources = poster['sources'];
        if (sources == null) continue;

        final String posterTitle = poster['title'] ?? 'Unknown';

        for (final source in sources) {
          final String? url = source['url'];
          final String quality = source['quality'] ?? '';

          if (url == null || url.isEmpty) continue;

          // Extract filename from URL
          final uri = Uri.tryParse(url);
          final fileName = uri?.pathSegments.isNotEmpty == true
              ? uri!.pathSegments.last
              : posterTitle;

          items.add(DownloadItem(
            fileName: fileName,
            url: url,
            size: quality, // Quality field contains size info like "1 GB زیرنویس 720"
            server: 'GiftMond',
            mayCensorContent: true,
          ));
        }
      }

      return items;
    }
    return [];
  } catch (e) {
    return [];
  }
}

// Function to fetch all Iran download links from all servers
Future<List<DownloadItem>> fetchAllIranDownloadLinks(
    String movieTitle, String year, String imdbIdWithoutTT) async {
  final servers = {
    'Berlin': 'https://berlin.saymyname.website/Movies/$year/$imdbIdWithoutTT',
    'Tokyo': 'https://tokyo.saymyname.website/Movies/$year/$imdbIdWithoutTT',
    'Nairobi':
        'https://nairobi.saymyname.website/Movies/$year/$imdbIdWithoutTT',
  };

  final List<DownloadItem> allItems = [];

  // Fetch from all servers in parallel (including GiftMond API)
  final futures = <Future<List<DownloadItem>>>[
    // HTML-based servers
    ...servers.entries.map((entry) async {
      final items = await fetchIranDownloadLinks(entry.value, entry.key);
      return items;
    }),
    // GiftMond API
    fetchGiftMondDownloadLinks(movieTitle, year),
  ];

  final results = await Future.wait(futures);
  for (final items in results) {
    allItems.addAll(items);
  }

  return allItems;
}

// Function to show watch options in a modal bottom sheet
void showWatchOptions(BuildContext context, int movieId, String movieTitle,
    String releaseDate, String imdbId) async {
  // Fetch sources dynamically
  Map<String, Map<String, dynamic>> optionUrls = await fetchSources();

  // Replace hardcoded URLs with dynamic ones
  optionUrls = optionUrls.map((key, value) {
    final url =
        value['url'].toString().replaceAll('{movieId}', movieId.toString());
    return MapEntry(key, {...value, 'url': url});
  });

  List<String> options = optionUrls.keys.toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext bottomSheetContext) {
      Color mainColor = getColor(context, movieId);
      final region = Provider.of<RegionProvider>(context).currentRegion;
      final year = releaseDate.split('-')[0];
      final imdbIdWithoutTT =
          imdbId.startsWith('tt') ? imdbId.substring(2) : imdbId;

      return _WatchOptionsContent(
        movieId: movieId,
        movieTitle: movieTitle,
        mainColor: mainColor,
        region: region,
        year: year,
        imdbIdWithoutTT: imdbIdWithoutTT,
        options: options,
        optionUrls: optionUrls,
      );
    },
  );
}

class _WatchOptionsContent extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final Color mainColor;
  final String region;
  final String year;
  final String imdbIdWithoutTT;
  final List<String> options;
  final Map<String, Map<String, dynamic>> optionUrls;

  const _WatchOptionsContent({
    required this.movieId,
    required this.movieTitle,
    required this.mainColor,
    required this.region,
    required this.year,
    required this.imdbIdWithoutTT,
    required this.options,
    required this.optionUrls,
  });

  @override
  State<_WatchOptionsContent> createState() => _WatchOptionsContentState();
}

class _WatchOptionsContentState extends State<_WatchOptionsContent> {
  List<DownloadItem> iranDownloads = [];
  bool isLoadingIranDownloads = false;
  bool iranDownloadsLoaded = false;
  String? iranDownloadsError;

  @override
  void initState() {
    super.initState();
    if (widget.region == 'iran') {
      _loadIranDownloads();
    }
  }

  Future<void> _loadIranDownloads() async {
    setState(() {
      isLoadingIranDownloads = true;
      iranDownloadsError = null;
    });

    try {
      final downloads = await fetchAllIranDownloadLinks(
        widget.movieTitle,
        widget.year,
        widget.imdbIdWithoutTT,
      );
      if (mounted) {
        setState(() {
          iranDownloads = downloads;
          isLoadingIranDownloads = false;
          iranDownloadsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          iranDownloadsError = 'Failed to load downloads';
          isLoadingIranDownloads = false;
          iranDownloadsLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Watch or Download',
                    style: TextStyle(color: widget.mainColor, fontSize: 14),
                  ),
                  IconButton(
                    onPressed: () => _launchUrl(Uri.parse(
                        'https://dl.vidsrc.vip/movie/${widget.movieId.toString()}')),
                    icon: Icon(Icons.download, color: widget.mainColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  const CustomDivider(),
                  // Regular streaming options
                  ...widget.options.map((option) {
                    Map<String, dynamic>? optionData = widget.optionUrls[option];
                    return ListTile(
                      leading: Icon(Icons.play_arrow, color: widget.mainColor),
                      title: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (optionData?['hasAds'] == true)
                            Text(
                              'Ads',
                              style: TextStyle(
                                  color: Theme.of(context).highlightColor),
                            ),
                          if (optionData?['hasSubs'] == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Subs',
                                style: TextStyle(color: widget.mainColor),
                              ),
                            ),
                        ],
                      ),
                      onTap: () async {
                        if (optionData != null && optionData['url'] != null) {
                          _launchUrl(Uri.parse(optionData['url']));
                        } else {
                          showErrorDialog('Error',
                              'URL not available for $option', context);
                        }
                        Navigator.of(context).pop();
                      },
                    );
                  }),

                  // Iran downloads section
                  if (widget.region == 'iran') ...[
                    const CustomDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                      child: Row(
                        children: [
                          const Text(
                            '🇮🇷',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Direct Downloads',
                            style: TextStyle(
                              color: widget.mainColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isLoadingIranDownloads)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: widget.mainColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (iranDownloadsError != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          iranDownloadsError!,
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ),
                    if (iranDownloadsLoaded && iranDownloads.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No direct downloads available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...iranDownloads.map((item) => _buildDownloadItemTile(item)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadItemTile(DownloadItem item) {
    // Extract quality info from filename
    String quality = '';
    if (item.fileName.contains('1080p')) {
      quality = '1080p';
    } else if (item.fileName.contains('720p')) {
      quality = '720p';
    } else if (item.fileName.contains('480p')) {
      quality = '480p';
    } else if (item.fileName.contains('2160p') || item.fileName.contains('4K')) {
      quality = '4K';
    }

    // Extract codec info
    String codec = '';
    if (item.fileName.contains('x265') || item.fileName.contains('HEVC')) {
      codec = 'x265';
    } else if (item.fileName.contains('x264')) {
      codec = 'x264';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.mainColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: widget.mainColor,
          size: 20,
        ),
      ),
      title: Text(
        item.fileName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.server,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.mainColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.size,
                style: TextStyle(
                  color: widget.mainColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (quality.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quality,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (codec.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  codec,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (item.mayCensorContent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠ May Contain Censors',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.copy,
              color: widget.mainColor,
              size: 20,
            ),
            onPressed: () => _copyToClipboard(context, item.url),
            tooltip: 'Copy URL',
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: widget.mainColor,
              size: 20,
            ),
            onPressed: () {
              _launchUrl(Uri.parse(item.url));
              Navigator.of(context).pop();
            },
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }
}
