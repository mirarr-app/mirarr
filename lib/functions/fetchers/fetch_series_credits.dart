import 'dart:isolate';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final apiKey = dotenv.env['TMDB_API_KEY'];

List<Map<String, dynamic>> _parseCastInIsolate(String responseBody) {
  final Map<String, dynamic> responseData = json.decode(responseBody);
  final List<dynamic> castList = responseData['cast'];
  final List<dynamic> crewList = responseData['crew'];
  return [
    ...castList.cast<Map<String, dynamic>>(),
    ...crewList.cast<Map<String, dynamic>>(),
  ];
}

void _isolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];

  final parsedData = _parseCastInIsolate(responseBody);
  sendPort.send(parsedData);
}

Future<Map<String, List<Map<String, dynamic>>>> fetchCredits(
    int serieId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://tmdb.maybeparsa.top/tmdb/tv/$serieId/credits?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final receivePort = ReceivePort();
      await Isolate.spawn(_isolateFunction, {
        'sendPort': receivePort.sendPort,
        'responseBody': response.body,
      });

      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> castList = responseData['cast'];
      final List<dynamic> crewList = responseData['crew'];
      return {
        'cast': castList.cast<Map<String, dynamic>>().toList(),
        'crew': crewList.cast<Map<String, dynamic>>().toList(),
      };
    } else {
      throw Exception('Failed to load cast and crew details');
    }
  } catch (e) {
    throw Exception('Failed to load cast and crew details');
  }
}
