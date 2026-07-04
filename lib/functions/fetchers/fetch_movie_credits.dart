import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:Mirarr/functions/get_base_url.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final apiKey = dotenv.env['TMDB_API_KEY'];

Map<String, List<Map<String, dynamic>>> _parseCreditsInIsolate(String responseBody) {
  final Map<String, dynamic> responseData = json.decode(responseBody);
  final List<dynamic> castList = responseData['cast'] ?? [];
  final List<dynamic> crewList = responseData['crew'] ?? [];

  return {
    'cast': castList.cast<Map<String, dynamic>>().toList(),
    'crew': crewList.cast<Map<String, dynamic>>().toList(),
  };
}

void _isolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];

  final parsedData = _parseCreditsInIsolate(responseBody);
  sendPort.send(parsedData);
}

Future<Map<String, List<Map<String, dynamic>>>> fetchCredits(
    int movieId, String region) async {
  final baseUrl = getBaseUrl(region);
  try {
    final response = await http.get(
      Uri.parse(
        '${baseUrl}movie/$movieId/credits?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      if (kIsWeb) {
        return _parseCreditsInIsolate(response.body);
      }
      final receivePort = ReceivePort();

      try {
        await Isolate.spawn(
          _isolateFunction,
          {
            'sendPort': receivePort.sendPort,
            'responseBody': response.body,
          },
        );

        final result = await receivePort.first;
        return result as Map<String, List<Map<String, dynamic>>>;
      } finally {
        receivePort.close();
      }
    } else {
      throw Exception('Failed to load cast and crew details');
    }
  } catch (e) {
    throw Exception('Failed to load cast and crew details');
  }
}

