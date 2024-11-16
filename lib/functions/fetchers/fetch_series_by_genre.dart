import 'dart:convert';
import 'dart:isolate';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});
}

List<Genre> _parseGenresInIsolate(String responseBody) {
  final List<Genre> genres = [];
  final List<dynamic> results = json.decode(responseBody)['genres'];
  for (var result in results) {
    final genre = Genre(
      name: result['name'],
      id: result['id'],
    );
    genres.add(genre);
  }
  return genres;
}

void _genreIsolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final List<Genre> genres = _parseGenresInIsolate(responseBody);
  sendPort.send(genres);
}

Future<List<Genre>> fetchGenres() async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/genre/tv/list?api_key=$apiKey',
    ),
  );

  if (response.statusCode == 200) {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _genreIsolateFunction,
      {
        'sendPort': receivePort.sendPort,
        'responseBody': response.body,
      },
    );

    final genres = await receivePort.first as List<Genre>;
    return genres;
  } else {
    throw Exception('Failed to load genres');
  }
}

List<Serie> _parseSeriesInIsolate(String responseBody) {
  final List<Serie> series = [];
  final List<dynamic> results = json.decode(responseBody)['results'];
  for (var result in results) {
    final serie = Serie(
      name: result['name'],
      posterPath: result['poster_path'] ?? '',
      overView: result['overview'] ?? '',
      id: result['id'],
      score: result['vote_average'] ?? 0.0,
    );
    series.add(serie);
  }
  return series;
}

void _seriesIsolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final List<Serie> series = _parseSeriesInIsolate(responseBody);
  sendPort.send(series);
}

Future<List<Serie>> fetchSeriesByGenre(int genreId) async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/discover/tv?api_key=$apiKey&with_genres=$genreId',
    ),
  );

  if (response.statusCode == 200) {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _seriesIsolateFunction,
      {
        'sendPort': receivePort.sendPort,
        'responseBody': response.body,
      },
    );

    final series = await receivePort.first as List<Serie>;
    return series;
  } else {
    throw Exception('Failed to load movies by genre');
  }
}
