import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
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

void showWatchOptions(BuildContext context, int serieId, int seasonNumber,
    int episodeNumber) async {
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
