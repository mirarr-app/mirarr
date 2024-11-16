import 'dart:isolate';
import 'dart:convert';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

List<Serie> _parseSeriesInIsolate(String responseBody) {
  final List<Serie> series = [];
  final List<dynamic> results = json.decode(responseBody)['results'];

  for (var result in results) {
    final serie = Serie(
        name: result['name'],
        posterPath: result['poster_path'] ?? '',
        overView: result['overview'] ?? '',
        id: result['id'],
        score: result['vote_average'] ?? '');
    series.add(serie);
  }

  return series;
}

void _isolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final List<Serie> series = _parseSeriesInIsolate(responseBody);
  sendPort.send(series);
}

Future<List<Serie>> fetchTrendingSeries() async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/trending/tv/day?api_key=$apiKey',
    ),
  );

  if (response.statusCode == 200) {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateFunction,
      {
        'sendPort': receivePort.sendPort,
        'responseBody': response.body,
      },
    );

    final series = await receivePort.first as List<Serie>;
    return series;
  } else {
    throw Exception('Failed to load trending series data');
  }
}
