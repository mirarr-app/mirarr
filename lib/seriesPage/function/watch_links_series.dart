import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
  }
}

void showWatchOptions(
    BuildContext context, int serieId, int seasonNumber, int episodeNumber) {
  Map<String, Map<String, dynamic>> optionUrls = {
    'braflix': {
      'url':
          'https://www.braflix.video/movie/$serieId/$seasonNumber/$episodeNumber?play=true',
      'hasAds': true,
      'hasSubs': true,
    },
    'freek': {
      'url':
          'https://freek.to/watch/tv/$serieId?season=$seasonNumber&ep=$episodeNumber',
      'hasAds': false,
      'hasSubs': true,
    },
    'rive': {
      'url':
          'https://rivestream.live/watch?type=tv&id=$serieId&season=$seasonNumber&episode=$episodeNumber',
      'hasAds': false,
      'hasSubs': true
    },
    'primeflix': {
      'url':
          'https://www.primeflix.lol/tv/$serieId/season/$seasonNumber/stream/$episodeNumber',
      'hasAds': true,
      'hasSubs': true
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
