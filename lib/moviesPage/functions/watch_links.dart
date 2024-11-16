import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/moviesPage/checkers/custom_tmdb_ids_effects.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Function to launch a URL
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrlString(url.toString())) {
    await launchUrlString(url.toString());
  } else {
    throw Exception('Could not launch url');
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
    builder: (BuildContext bottomSheetContext) {
      Color mainColor = getColor(context, movieId);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Watch from below sources or download the movie.',
                  style: TextStyle(color: mainColor, fontSize: 12),
                ),
                IconButton(
                  onPressed: () => _launchUrl(Uri.parse(
                      'https://dl.vidsrc.vip/movie/${movieId.toString()}')),
                  icon: Icon(Icons.download, color: mainColor),
                ),
              ],
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
