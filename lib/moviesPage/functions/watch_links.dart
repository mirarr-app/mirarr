import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Function to launch a URL
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
  }
}

// Function to show watch options in a modal bottom sheet
void showWatchOptions(BuildContext context, int movieId) {
  Map<String, Map<String, dynamic>> optionUrls = {
    'braflix': {
      'url': 'https://www.braflix.video/movie/$movieId',
      'hasAds': true,
      'hasSubs': true,
    },
    'streamflix': {
      'url': 'https://watch.streamflix.one/movie/$movieId',
      'hasAds': false,
      'hasSubs': true,
    },
    'binged': {
      'url': 'https://binged.live/watch/movie/$movieId',
      'hasAds': false,
      'hasSubs': true,
    },
    'lonelil': {
      'url': 'https://watch.lonelil.ru/watch/movie/$movieId',
      'hasAds': false,
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
    builder: (BuildContext context) {
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
                const CustomDivider(), // Custom divider
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

// Function to show an error dialog
