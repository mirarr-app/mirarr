import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

// Model class for series download items from Iran servers
class SeriesDownloadItem {
  final String fileName;
  final String url;
  final String? subtitleUrl;
  final String quality;
  final String server;

  SeriesDownloadItem({
    required this.fileName,
    required this.url,
    this.subtitleUrl,
    required this.quality,
    required this.server,
  });
}

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

Future<Map<String, Map<String, dynamic>>> fetchTvSources() async {
  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/mirarr-app/sources/refs/heads/main/tvsources.txt'));

    if (response.statusCode == 200) {
      return Map<String, Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load TV sources');
    }
  } catch (e) {
    log('Error fetching TV sources: $e');
    return {};
  }
}

Color getColor(BuildContext context, int serieId) =>
    getSeriesColor(context, serieId);

// Function to fetch and parse download links from Iran subtitle server
Future<List<SeriesDownloadItem>> fetchIranSeriesDownloadLinks(
    String imdbId, int seasonNumber, int episodeNumber, int quality) async {
  try {
    final url =
        'https://subtitle.saymyname.website/DL/filmgir/?i=$imdbId&f=$seasonNumber&q=$quality';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<SeriesDownloadItem> items = [];
      final body = response.body;

      // Extract quality info from the yellow div
      // Pattern: <div class="text-center mb-2" style="color:yellow;">QUALITY_INFO</div>
      final qualityRegex = RegExp(
        r'<div[^>]*style="color:yellow;"[^>]*>([^<]+)</div>',
        multiLine: true,
        dotAll: true,
      );
      final qualityMatch = qualityRegex.firstMatch(body);
      final qualityInfo = qualityMatch?.group(1)?.trim() ?? 'Unknown Quality';

      // Determine server name based on quality parameter
      String serverName;
      switch (quality) {
        case 1:
          serverName = 'Server 1';
          break;
        case 2:
          serverName = 'Server 2';
          break;
        case 3:
          serverName = 'Server 3';
          break;
        default:
          serverName = 'Server $quality';
      }

      // Extract episode links
      // Pattern: <a ... href="VIDEO_URL">دانلود قسمت X</a> | <a ... href="SUBTITLE_URL">دانلود زیرنویس قسمت X</a>
      // We need to find pairs of video and subtitle links for each episode
      
      // First, find all video download links with their episode numbers
      final videoRegex = RegExp(
        r'<a[^>]*href="([^"]+)"[^>]*>دانلود قسمت (\d+)</a>',
        multiLine: true,
      );
      
      // Find all subtitle download links with their episode numbers
      final subtitleRegex = RegExp(
        r'<a[^>]*href="([^"]+)"[^>]*>دانلود زیرنویس قسمت (\d+)</a>',
        multiLine: true,
      );

      // Build a map of episode number to video URL
      final Map<int, String> videoUrls = {};
      for (final match in videoRegex.allMatches(body)) {
        final videoUrl = match.group(1)!;
        final episodeNum = int.tryParse(match.group(2)!) ?? 0;
        videoUrls[episodeNum] = videoUrl;
      }

      // Build a map of episode number to subtitle URL
      final Map<int, String> subtitleUrls = {};
      for (final match in subtitleRegex.allMatches(body)) {
        final subtitleUrl = match.group(1)!;
        final episodeNum = int.tryParse(match.group(2)!) ?? 0;
        subtitleUrls[episodeNum] = subtitleUrl;
      }

      // Only get the current episode
      if (videoUrls.containsKey(episodeNumber)) {
        final videoUrl = videoUrls[episodeNumber]!;
        final subtitleUrl = subtitleUrls[episodeNumber];

        // Extract filename from URL
        final uri = Uri.tryParse(videoUrl);
        final fileName = uri?.pathSegments.isNotEmpty == true
            ? Uri.decodeComponent(uri!.pathSegments.last)
            : 'Episode $episodeNumber';

        items.add(SeriesDownloadItem(
          fileName: fileName,
          url: videoUrl,
          subtitleUrl: subtitleUrl,
          quality: qualityInfo,
          server: serverName,
        ));
      }

      return items;
    }
    return [];
  } catch (e) {
    log('Error fetching Iran series download links: $e');
    return [];
  }
}

// Function to fetch all Iran download links from all quality servers
Future<List<SeriesDownloadItem>> fetchAllIranSeriesDownloadLinks(
    String imdbId, int seasonNumber, int episodeNumber) async {
  final List<SeriesDownloadItem> allItems = [];

  // Fetch from all 3 quality servers in parallel
  final futures = [1, 2, 3].map((quality) async {
    final items = await fetchIranSeriesDownloadLinks(
        imdbId, seasonNumber, episodeNumber, quality);
    return items;
  });

  final results = await Future.wait(futures);
  for (final items in results) {
    allItems.addAll(items);
  }

  return allItems;
}

void showWatchOptions(BuildContext context, int serieId, int seasonNumber,
    int episodeNumber, String imdbId) async {
  Map<String, Map<String, dynamic>> optionUrls = await fetchTvSources();

  optionUrls = optionUrls.map((key, value) {
    final url = value['url']
        .toString()
        .replaceAll('{serieId}', serieId.toString())
        .replaceAll('{seasonNumber}', seasonNumber.toString())
        .replaceAll('{episodeNumber}', episodeNumber.toString());
    return MapEntry(key, {...value, 'url': url});
  });

  List<String> options = optionUrls.keys.toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext bottomSheetContext) {
      Color mainColor = getColor(context, serieId);
      final region = Provider.of<RegionProvider>(context).currentRegion;

      return _WatchOptionsContent(
        serieId: serieId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        imdbId: imdbId,
        mainColor: mainColor,
        region: region,
        options: options,
        optionUrls: optionUrls,
      );
    },
  );
}

class _WatchOptionsContent extends StatefulWidget {
  final int serieId;
  final int seasonNumber;
  final int episodeNumber;
  final String imdbId;
  final Color mainColor;
  final String region;
  final List<String> options;
  final Map<String, Map<String, dynamic>> optionUrls;

  const _WatchOptionsContent({
    required this.serieId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.imdbId,
    required this.mainColor,
    required this.region,
    required this.options,
    required this.optionUrls,
  });

  @override
  State<_WatchOptionsContent> createState() => _WatchOptionsContentState();
}

class _WatchOptionsContentState extends State<_WatchOptionsContent> {
  List<SeriesDownloadItem> iranDownloads = [];
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
      final downloads = await fetchAllIranSeriesDownloadLinks(
        widget.imdbId,
        widget.seasonNumber,
        widget.episodeNumber,
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
                    'Watch or Download - S${widget.seasonNumber}E${widget.episodeNumber}',
                    style: TextStyle(color: widget.mainColor, fontSize: 14),
                  ),
                  IconButton(
                    onPressed: () => _launchUrl(Uri.parse(
                        'https://dl.vidsrc.vip/tv/${widget.serieId}/${widget.seasonNumber}/${widget.episodeNumber}')),
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
                      onTap: () {
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
                          'No direct downloads available for this episode',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...iranDownloads
                        .map((item) => _buildDownloadItemTile(item)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadItemTile(SeriesDownloadItem item) {
    // Extract quality info from quality string
    String quality = '';
    if (item.quality.contains('1080p')) {
      quality = '1080p';
    } else if (item.quality.contains('720p')) {
      quality = '720p';
    } else if (item.quality.contains('480p')) {
      quality = '480p';
    } else if (item.quality.contains('2160p') || item.quality.contains('4K')) {
      quality = '4K';
    }

    // Extract codec info
    String codec = '';
    if (item.quality.contains('x265') || item.quality.contains('HEVC')) {
      codec = 'x265';
    } else if (item.quality.contains('x264')) {
      codec = 'x264';
    }

    // Extract size info (after the /)
    String size = '';
    if (item.quality.contains('/')) {
      size = item.quality.split('/').last.trim();
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
          Icons.tv,
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
            if (size.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.mainColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  size,
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
            if (item.subtitleUrl != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Subs',
                  style: TextStyle(
                    color: Colors.green,
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
          if (item.subtitleUrl != null)
            IconButton(
              icon: const Icon(
                Icons.subtitles,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () => _launchUrl(Uri.parse(item.subtitleUrl!)),
              tooltip: 'Download Subtitle',
            ),
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
