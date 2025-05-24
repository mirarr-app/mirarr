import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/seriesPage/checkers/custom_tmdb_ids_effects_series.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const String _encodedBaseUrl = 'aHR0cHM6Ly94cHJpbWUudHYvcHJpbWVib3g/bmFtZT0=';

String get baseStreamUrl => utf8.decode(base64.decode(_encodedBaseUrl));

const String _riveEncodedBaseUrl = 'aHR0cHM6Ly9yaXZlLnBhcnNhb28uaXIvYXBpL3N0cmVhbXM/';

String get riveBaseStreamUrl => utf8.decode(base64.decode(_riveEncodedBaseUrl));

Future<void> _openInVLC(String url) async {
  try {
    if (Platform.isLinux) {
      await Process.run('vlc', [url]);
    } else if (Platform.isWindows) {
      await Process.run(r'C:\Program Files\VideoLAN\VLC\vlc.exe', [url]);
    } else if (Platform.isMacOS) {
      await Process.run('/Applications/VLC.app/Contents/MacOS/VLC', [url]);
    } else if (Platform.isAndroid) {
      await launchUrlString('vlc://$url');
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
  Map<String, dynamic> combinedSources = {
    'available_qualities': <String>[],
    'streams': <String, String>{},
  };

  // Fetch Xprime sources
  try {
    final xprimeResponse = await http.get(Uri.parse(
        '$baseStreamUrl$serieId&season=$seasonNumber&episode=$episodeNumber'));

    if (xprimeResponse.statusCode == 200) {
      final xprimeData = Map<String, dynamic>.from(json.decode(xprimeResponse.body));
      List<String> xprimeQualities = List<String>.from(xprimeData['available_qualities'] ?? []);
      Map<String, String> xprimeStreams = Map<String, String>.from(xprimeData['streams'] ?? {});
      
      // Add Xprime sources with prefix
      for (String quality in xprimeQualities) {
        String prefixedQuality = 'Xprime-$quality';
        combinedSources['available_qualities'].add(prefixedQuality);
        combinedSources['streams'][prefixedQuality] = xprimeStreams[quality] ?? '';
      }
    }
  } catch (e) {
    print('Failed to fetch Xprime sources: $e');
  }

  // Fetch Rive sources
  try {
    final riveResponse = await http.get(Uri.parse(
        '${riveBaseStreamUrl}tmdId=$serieId&season=$seasonNumber&episode=$episodeNumber&type=series'));

    if (riveResponse.statusCode == 200) {
      final riveData = Map<String, dynamic>.from(json.decode(riveResponse.body));
      if (riveData['success'] == true && riveData['data'] != null) {
        List<dynamic> riveStreams = riveData['data']['streams'] ?? [];
        
        // Add Rive sources
        for (var stream in riveStreams) {
          String server = stream['server'] ?? 'unknown';
          String quality = stream['quality'] ?? 'unknown';
          String link = stream['link'] ?? '';
          
          if (link.isNotEmpty) {
            String prefixedQuality = 'Rive-$server-$quality';
            combinedSources['available_qualities'].add(prefixedQuality);
            combinedSources['streams'][prefixedQuality] = link;
          }
        }
      }
    }
  } catch (e) {
    print('Failed to fetch Rive sources: $e');
  }

  return combinedSources;
}

void showWatchOptionsDirectTV(BuildContext context, int serieId, int seasonNumber, int episodeNumber) async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    // Fetch sources dynamically
    Map<String, dynamic> response = await fetchSourcesDirectTV(serieId, seasonNumber, episodeNumber);

    // Close loading indicator
    Navigator.of(context).pop();

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
                    'Select Quality (${availableQualities.length} sources)',
                    style: TextStyle(color: mainColor, fontSize: 12),
                  ),
                  
                ],
              ),
            ),
            const CustomDivider(),
            if (availableQualities.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No streams available from any source', style: TextStyle(color: Colors.redAccent),),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableQualities.length,
                itemBuilder: (BuildContext context, int index) {
                  String quality = availableQualities[index];
                  String? streamUrl = streams[quality];
                  
                  // Extract source and quality info for better display
                  List<String> parts = quality.split('-');
                  String displayQuality = parts.length > 1 ? parts.sublist(1).join('-') : quality;
                  
                  return ListTile(
                    leading: Icon(Icons.play_arrow, color: mainColor),
                    title: Text(
                      displayQuality,
                      style: const TextStyle(color: Colors.white),
                    ),

                    onTap: () async {
                      if (streamUrl != null && streamUrl.isNotEmpty) {
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
  } catch (e) {
    // Close loading indicator if still open
    Navigator.of(context).pop();
    showErrorDialog('Error', 'Failed to fetch sources: ${e.toString()}', context);
  }
}
