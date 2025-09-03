import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
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
    builder: (BuildContext context) {
      Color mainColor = getColor(context, serieId);
            final region = Provider.of<RegionProvider>(context).currentRegion;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Watch or Download',
                  style: TextStyle(color: mainColor, fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _launchUrl(Uri.parse(
                          'https://dl.vidsrc.vip/tv/${serieId.toString()}/${seasonNumber.toString()}/${episodeNumber.toString()}')),
                      icon: Icon(Icons.download, color: mainColor),
                    ),
                      if (region == 'iran')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _launchUrl(Uri.parse(
                                'https://subtitle.saymyname.website/DL/filmgir/?i=$imdbId&f=${seasonNumber.toString()}&q=1')
                            ),
                            icon: Icon(Icons.download, color: mainColor),
                          ),
                          Text(
                            '🇮🇷',
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 10,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchUrl(Uri.parse(
                                'https://subtitle.saymyname.website/DL/filmgir/?i=$imdbId&f=${seasonNumber.toString()}&q=2')
                            ),
                            icon: Icon(Icons.download, color: mainColor),
                          ),
                          Text(
                            '🇮🇷',
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 10,
                            ),
                          ),
                           IconButton(
                            onPressed: () => _launchUrl(Uri.parse(
                                'https://subtitle.saymyname.website/DL/filmgir/?i=$imdbId&f=${seasonNumber.toString()}&q=3')
                            ),
                            icon: Icon(Icons.download, color: mainColor),
                          ),
                          Text(
                            '🇮🇷',
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 10,
                            ),
                          ),],)
                  ],
                ),
              
              ],
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
                        leading: Icon(Icons.play_arrow, color: mainColor),
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
                                  style: TextStyle(color: mainColor),
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
