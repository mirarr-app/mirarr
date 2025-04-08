import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
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

Color getColor(BuildContext context, int movieId) =>
    getMovieColor(context, movieId);

void showTorrentOptions(BuildContext context, int movieId, String movieTitle,
    String? releaseDate, String? imdbId) {
  final String movieYear =
      releaseDate != null ? releaseDate.substring(0, 4) : '';
  final String? movieImdbId = imdbId;

  Map<String, String> optionPublicTorrents = {
    '1337x': 'https://1337x.to/search/$movieTitle $movieYear/1/',
    'SolidTorrents': 'https://solidtorrents.to/search?q=$movieTitle $movieYear',
    'Ext':
        'https://ext.to/browse/?q=$movieTitle $movieYear',
    'Limetorrents':
        'https://www.limetorrents.lol/search/all/$movieTitle $movieYear',
    'DDL from vadapav': 'https://vadapav.mov/s/$movieTitle',
  };

  Map<String, String> optionPrivateTorrents = {
    'IPTorrents': 'https://www.iptorrents.com/t?q=$movieImdbId',
    'TorrentLeech':
        'https://www.torrentleech.org/torrents/browse/index/imdbID/$movieImdbId/categories/8,9,11,37,43,14,12,13,47,15,29,26,32,27,34,35,36,44',
  };

  List<String> _publicTorrents = optionPublicTorrents.keys.toList();
  List<String> _privateTorrents = optionPrivateTorrents.keys.toList();

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      Color mainColor = getColor(context, movieId);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Search for torrents',
              style: TextStyle(color: mainColor, fontSize: 16),
            ),
          ),
          Flexible(
            child: Column(
              children: [
                const CustomDivider(), // Custom divider
                Text(
                  'Public Trackers',
                  style: TextStyle(color: mainColor, fontSize: 12),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _publicTorrents.length,
                    itemBuilder: (BuildContext context, int index) {
                      String option = _publicTorrents[index];
                      String? url = optionPublicTorrents[option];
                      return ListTile(
                        leading: Icon(Icons.play_arrow, color: mainColor),
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
                const Divider(), // Custom divider
                Text(
                  'Private Trackers',
                  style: TextStyle(color: mainColor, fontSize: 12),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _privateTorrents.length,
                    itemBuilder: (BuildContext context, int index) {
                      String option = _privateTorrents[index];
                      String? url = optionPrivateTorrents[option];
                      return ListTile(
                        leading: Icon(Icons.play_arrow, color: mainColor),
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
