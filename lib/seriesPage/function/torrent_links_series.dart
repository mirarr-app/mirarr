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

void showTorrentOptions(BuildContext context, String serieTitle, int serieId,
    int seasonNumber, int episodeNumber, String? imdbId) {
  final String seasonStr = seasonNumber.toString().padLeft(2, '0');
  final String episodeStr = episodeNumber.toString().padLeft(2, '0');

  final String? serieImdbId = imdbId;
  Map<String, String> optionPublicTorrents = {
    '1337x': 'https://1337x.to/search/$serieTitle s${seasonStr}e$episodeStr/1/',
    'SolidTorrents':
        'https://solidtorrents.to/search?q=$serieTitle s${seasonStr}e$episodeStr',
    'TorrentGalaxy':
        'https://torrentgalaxy.to/torrents.php?search=$serieTitle s${seasonStr}e$episodeStr#results'
  };
  Map<String, String> optionPrivateTorrents = {
    'IPTorrents': 'https://www.iptorrents.com/t?q=$serieImdbId',
    'TorrentLeech':
        'https://www.torrentleech.org/torrents/browse/index/query/$serieTitle s${seasonStr}e$episodeStr',
  };

  List<String> _publicTorrents = optionPublicTorrents.keys.toList();
  List<String> _privateTorrents = optionPrivateTorrents.keys.toList();

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Search for torrents',
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 16),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const CustomDivider(),
                Text(
                  'Public Trackers',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor, fontSize: 12),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _publicTorrents.length,
                    itemBuilder: (BuildContext context, int index) {
                      String option = _publicTorrents[index];
                      String? url = optionPublicTorrents[option];
                      return ListTile(
                        leading: Icon(Icons.play_arrow,
                            color: Theme.of(context).primaryColor),
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          if (url != null) {
                            _launchUrl(Uri.parse(url));
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
                const CustomDivider(),
                Text(
                  'Private Trackers',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor, fontSize: 12),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _privateTorrents.length,
                    itemBuilder: (BuildContext context, int index) {
                      String option = _privateTorrents[index];
                      String? url = optionPrivateTorrents[option];
                      return ListTile(
                        leading: Icon(Icons.play_arrow,
                            color: Theme.of(context).primaryColor),
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          if (url != null) {
                            _launchUrl(Uri.parse(url));
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
