import 'dart:isolate';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final apiKey = dotenv.env['TMDB_API_KEY'];

List<dynamic> _parseMoviesInIsolate(String responseBody) {
  final decoded = json.decode(responseBody);
  final List<dynamic> movies = decoded['crew'];

  Set<int> movieIds = {};

  List<dynamic> filteredMovies = [];

  for (var movie in movies) {
    // Check if the crew member's job is "Director"
    if (movie['job'] == 'Director') {
      // Add the movie only if it has a poster path and not already added
      if (movie['poster_path'] != null &&
          movie['poster_path'] != '' &&
          !movieIds.contains(movie['id'])) {
        filteredMovies.add(movie);
        movieIds.add(movie['id']);
      }
    }
  }
  return filteredMovies;
}

void _isolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final filteredMovies = _parseMoviesInIsolate(responseBody);
  sendPort.send(filteredMovies);
}

Future<List<dynamic>> fetchOtherMoviesByDirector(int castId) async {
  final response = await http.get(
    Uri.parse(
        'https://tmdb.maybeparsa.top/tmdb/person/$castId/movie_credits?api_key=$apiKey'),
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
    final filteredMovies = await receivePort.first as List<dynamic>;
    return filteredMovies;
  } else {
    throw Exception('Failed to load other movies');
  }
}
