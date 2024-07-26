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

Future<List<Genre>> fetchGenres() async {
  final response = await http.get(
    Uri.parse(
      'https://api.themoviedb.org/3/genre/movie/list?api_key=$apiKey',
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

Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
  final response = await http.get(
    Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$genreId',
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
        score: result['vote_average'] ?? 0.0,
      );
      movies.add(movie);
    }
    return movies;
  } else {
    throw Exception('Failed to load movies by genre');
  }
}
