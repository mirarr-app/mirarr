import 'dart:isolate';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});
}

// Isolate parsing function for genres
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

// Isolate parsing function for movies
List<Movie> _parseMoviesInIsolate(String responseBody) {
  final List<Movie> movies = [];
  final List<dynamic> results = json.decode(responseBody)['results'];
  for (var result in results) {
    final movie = Movie(
      title: result['title'],
      releaseDate: result['release_date'],
      posterPath: result['poster_path'] ?? '',
      overView: result['overview'] ?? '',
      id: result['id'],
      score: result['vote_average'] ?? 0.0,
    );
    movies.add(movie);
  }
  return movies;
}

// Isolate handler functions
void _genreIsolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final genres = _parseGenresInIsolate(responseBody);
  sendPort.send(genres);
}

void _movieIsolateFunction(Map<String, dynamic> message) {
  final SendPort sendPort = message['sendPort'];
  final String responseBody = message['responseBody'];
  final movies = _parseMoviesInIsolate(responseBody);
  sendPort.send(movies);
}

Future<List<Genre>> fetchGenres() async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/genre/movie/list?api_key=$apiKey',
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

Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/discover/movie?api_key=$apiKey&with_genres=$genreId',
    ),
  );

  if (response.statusCode == 200) {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _movieIsolateFunction,
      {
        'sendPort': receivePort.sendPort,
        'responseBody': response.body,
      },
    );

    final movies = await receivePort.first as List<Movie>;
    return movies;
  } else {
    throw Exception('Failed to load movies by genre');
  }
}
