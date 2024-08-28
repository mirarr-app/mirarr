import 'dart:convert';
import 'dart:io';

import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:Mirarr/widgets/hls_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

// Function to launch a URL
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
  }
}

// Function to get hls playlist
Future<Map<String, dynamic>> getHLSPlaylistAndSubtitles(int movieId) async {
  final String obfuscatedUrl = _deobfuscateUrl([
    114,
    100,
    112,
    46,
    118,
    105,
    100,
    108,
    105,
    110,
    107,
    46,
    112,
    114,
    111
  ]);
  final response = await http
      .get(Uri.parse('https://$obfuscatedUrl/api/movie/$movieId?multiLang=0'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final String fullUrl = data['stream']['playlist'];
    final String hlsUrl =
        fullUrl.split('&').first.split('=').last.split('?').last;
    Map<String, String> subtitles = {};
    if (data['stream']['captions'] != null) {
      for (var caption in data['stream']['captions']) {
        subtitles[caption['language']] = caption['url'];
      }
    }
    return {
      'hlsUrl': hlsUrl,
      'subtitles': subtitles,
    };
  } else {
    throw Exception('Failed to load hls playlist and subtitles');
  }
}

String _deobfuscateUrl(List<int> obfuscatedChars) {
  return String.fromCharCodes(obfuscatedChars);
}

// Function to show watch options in a modal bottom sheet
void showWatchOptions(BuildContext context, int movieId) {
  Map<String, Map<String, dynamic>> optionUrls = {
    if (Platform.isAndroid || Platform.isIOS)
      'Mirarr(Beta)': {
        'hasAds': false,
        'hasSubs': true,
      },
    'braflix': {
      'url': 'https://www.braflix.video/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'binged': {
      'url': 'https://binged.live/watch/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'lonelil': {
      'url': 'https://watch.lonelil.ru/watch/movie/$movieId',
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
                              Map<String, dynamic> videoInfo =
                                  await getHLSPlaylistAndSubtitles(movieId);

                              Navigator.of(bottomSheetContext).pop();

                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => HlsPlayerScreen(
                                        videoUrl: videoInfo['hlsUrl'],
                                        subtitleUrls: videoInfo['subtitles']),
                                  ),
                                );
                              });
                            } catch (e) {
                              Navigator.of(bottomSheetContext)
                                  .pop(); // Close the bottom sheet
                              showErrorDialog('Error',
                                  'Failed to get HLS playlist: $e', context);
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
