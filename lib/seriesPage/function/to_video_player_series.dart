import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';




Future<void> _openInVLC(String url) async {
  try {
    if (Platform.isLinux) {
      await Process.run('vlc', [url]);
    } else if (Platform.isWindows) {
      await Process.run(r'C:\Program Files\VideoLAN\VLC\vlc.exe', [url]);
    } else if (Platform.isMacOS) {
      await Process.run('/Applications/VLC.app/Contents/MacOS/VLC', [url]);
    } else if (Platform.isAndroid) {
      final cleanUrl = url.replaceFirst(RegExp(r'^https?://'), '');
      await launchUrlString('vlc://$cleanUrl');
    } else {
      throw Exception('Platform not supported for VLC');
    }
  } catch (e) {
    throw Exception('Failed to open VLC: $e');
  }
}

Color getColor(BuildContext context, int serieId) {
  return getSeriesColor(context, serieId);
}

Future<Map<String, dynamic>> fetchSourcesDirectTV(int serieId, int seasonNumber, int episodeNumber) async {
  try {
    final response = await http.get(Uri.parse(
        'https://xprime.tv/primebox?id=$serieId&season=$seasonNumber&episode=$episodeNumber'));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load sources');
    }
  } catch (e) {
    throw Exception('failed to load sources');
  }
}

void showWatchOptionsDirectTV(BuildContext context, int serieId, int seasonNumber, int episodeNumber) async {
  // Fetch sources dynamically
  Map<String, dynamic> response = await fetchSourcesDirectTV(serieId, seasonNumber, episodeNumber);

  // Get available qualities and streams
  List<String> availableQualities = List<String>.from(response['available_qualities'] ?? []);
  Map<String, String> streams = Map<String, String>.from(response['streams'] ?? {});

  showModalBottomSheet(
    context: context,
    builder: (BuildContext bottomSheetContext) {
      Color mainColor = getColor(context, serieId);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Quality',
                  style: TextStyle(color: mainColor, fontSize: 12),
                ),
                
              ],
            ),
          ),
          const CustomDivider(),
          Expanded(
            child: ListView.builder(
              itemCount: availableQualities.length,
              itemBuilder: (BuildContext context, int index) {
                String quality = availableQualities[index];
                String? streamUrl = streams[quality];
                return ListTile(
                  leading: Icon(Icons.play_arrow, color: mainColor),
                  title: Text(
                    quality,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    if (streamUrl != null) {
                      try {
                        await _openInVLC(streamUrl);
                        Navigator.of(context).pop();
                      } catch (e) {
                        showErrorDialog('Error',
                            'Failed to open VLC: ${e.toString()}', context);
                      }
                    } else {
                      showErrorDialog('Error',
                          'Stream not available for $quality', context);
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
