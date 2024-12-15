import 'dart:convert';
import 'dart:isolate';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/functions/get_base_url.dart';

final apiKey = dotenv.env['TMDB_API_KEY'];

List<Movie> _parseMoviesInIsolate(String responseBody) {
  final List<Movie> movies = [];
  final List<dynamic> results = json.decode(responseBody)['results'];

  for (var result in results) {
    final movie = Movie(
        title: result['title'],
        releaseDate: result['release_date'],
        posterPath: result['poster_path'] ?? '',
        overView: result['overview'] ?? '',
        id: result['id'] ?? '',
        score: result['vote_average'] ?? '');
    movies.add(movie);
  }
  return movies;
}

void _isolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final movies = _parseMoviesInIsolate(responseBody);
  sendPort.send(movies);
}

Future<List<Movie>> fetchPopularMovies(String region) async {
  final baseUrl = getBaseUrl(region);

  final response = await http.get(
    Uri.parse(
      '${baseUrl}movie/popular?api_key=$apiKey',
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
    final movies = await receivePort.first as List<Movie>;
    return movies;
  } else {
    throw Exception('Failed to load popular movie data');
  }
}
