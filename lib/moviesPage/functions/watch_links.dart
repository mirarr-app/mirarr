import 'dart:io';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:Mirarr/widgets/hls_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:developer';
import 'whvx_api.dart';

// Function to launch a URL
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
  }
}

Future<Map<String, dynamic>?> testWhvxStream(BuildContext context,
    String movieTitle, String releaseDate, String tmdbId, String imdbId) async {
  final whvxService = WhvxService();

  try {
    log('Starting WHVX stream test...');
    final sourcererOutput = await whvxService.search(
      title: movieTitle,
      releaseYear: releaseDate.substring(0, 4),
      tmdbId: tmdbId,
      imdbId: imdbId,
      type: 'movie',
    );

    if (sourcererOutput.embeds.isNotEmpty) {
      for (final embed in sourcererOutput.embeds) {
        try {
          final streamData = await whvxService.getStreams(embed);
          if (streamData.qualities.isNotEmpty) {
            // Show quality selection dialog
            final selectedQuality = await showDialog<StreamQuality>(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                  title: Text(
                    'Select Quality',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  children: streamData.qualities.map((quality) {
                    return SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, quality);
                      },
                      child: Text(
                        quality.quality,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                );
              },
            );

            if (selectedQuality != null) {
              log('Selected quality: ${selectedQuality.quality}, URL: ${selectedQuality.url}');
              final subtitleUrls = Map.fromEntries(streamData.subtitles.map(
                  (subtitle) => MapEntry(subtitle.language, subtitle.url)));
              log('Subtitle URLs: $subtitleUrls');

              return {
                'videoUrl': selectedQuality.url,
                'subtitleUrls': subtitleUrls,
              };
            } else {
              log('No quality selected');
            }
          } else {
            log('No qualities available for this embed');
          }
        } catch (e) {
          log('Error getting streams for embed ${embed.embedId}: $e');
          // Continue to the next embed if this one fails
        }
      }
      throw Exception('No valid streams found from any provider');
    } else {
      throw Exception('No embeds found');
    }
  } catch (e) {
    log('WHVX API Error: $e');
    if (context.mounted) {
      showErrorDialog('Error', 'Failed to get stream: $e', context);
    }
  } finally {
    whvxService.dispose();
  }
  return null;
}

// Function to show watch options in a modal bottom sheet
void showWatchOptions(BuildContext context, int movieId, String movieTitle,
    String releaseDate, String imdbId) {
  Map<String, Map<String, dynamic>> optionUrls = {
    if (Platform.isAndroid || Platform.isIOS)
      // 'Mirarr(Beta)': {
      //   'hasAds': false,
      //   'hasSubs': true,
      //   'isCustom': true,
      // },
      'movie-web': {
        'url': 'https://www.movie-web.me/media/tmdb-movie-$movieId',
        'hasAds': false,
        'hasSubs': true,
      },
    'braflix': {
      'url': 'https://www.braflix.video/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'freek': {
      'url': 'https://freek.to/watch/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'rive': {
      'url': 'https://rivestream.live/watch?type=movie&id=$movieId',
      'hasAds': false,
      'hasSubs': true,
    },
    'vidsrc': {
      'url': 'https://vidsrc.to/embed/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'primeflix': {
      'url': 'https://www.primeflix.lol/movie/$movieId/stream',
      'hasAds': true,
      'hasSubs': true,
    }
  };

  List<String> options = optionUrls.keys.toList();

  showModalBottomSheet(
    context: context,
    builder: (BuildContext bottomSheetContext) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'These are providers for the movie, choose one of them to play from that source',
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 16),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const CustomDivider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      String option = options[index];
                      Map<String, dynamic>? optionData = optionUrls[option];
                      return ListTile(
                        leading: Icon(Icons.play_arrow,
                            color: Theme.of(context).primaryColor),
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
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          if (option == 'Mirarr(Beta)') {
                            try {
                              Map<String, dynamic>? streamData =
                                  await testWhvxStream(context, movieTitle,
                                      releaseDate, movieId.toString(), imdbId);
                              Navigator.of(bottomSheetContext).pop();
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                if (streamData != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => HlsPlayerScreen(
                                          videoUrl: streamData['videoUrl'],
                                          subtitleUrls:
                                              streamData['subtitleUrls']),
                                    ),
                                  );
                                } else {
                                  showErrorDialog(
                                      'Error', 'Failed to get stream', context);
                                }
                              });
                            } catch (e) {
                              Navigator.of(bottomSheetContext)
                                  .pop(); // Close the bottom sheet
                              showErrorDialog(
                                  'Error', 'Failed to get stream: $e', context);
                            }
                          } else if (optionData != null &&
                              optionData['url'] != null) {
                            _launchUrl(Uri.parse(optionData['url']));
                          } else {
                            showErrorDialog('Error',
                                'URL not available for $option', context);
                          }
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
