import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

Future<List<Movie>> fetchTrendingMovies() async {
  final response = await http.get(
    Uri.parse(
      'https://tmdb.maybeparsa.top/tmdb/trending/movie/week?api_key=$apiKey',
    ),
  );

  if (response.statusCode == 200) {
    final List<Movie> movies = [];
    final List<dynamic> results = json.decode(response.body)['results'];

    for (var result in results) {
      final movie = Movie(
          title: result['title'],
          releaseDate: result['release_date'],
          posterPath: result['poster_path'] ?? '',
          overView: result['overview'] ?? '',
          id: result['id'],
          score: result['vote_average'] ?? '');
      movies.add(movie);
    }

    return movies;
  } else {
    throw Exception('Failed to load trending movie data');
  }
}
