import 'dart:convert';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});
}

Future<List<Genre>> fetchGenres() async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/genre/tv/list?api_key=$apiKey',
    ),
  );

  if (response.statusCode == 200) {
    final List<Genre> genres = [];
    final List<dynamic> results = json.decode(response.body)['genres'];
    for (var result in results) {
      final genre = Genre(
        name: result['name'],
        id: result['id'],
      );
      genres.add(genre);
    }
    return genres;
  } else {
    throw Exception('Failed to load genres');
  }
}

Future<List<Serie>> fetchSeriesByGenre(int genreId) async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/discover/tv?api_key=$apiKey&with_genres=$genreId',
    ),
  );

  if (response.statusCode == 200) {
    final List<Serie> series = [];
    final List<dynamic> results = json.decode(response.body)['results'];
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
  } else {
    throw Exception('Failed to load movies by genre');
  }
}
