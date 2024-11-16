import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final apiKey = dotenv.env['TMDB_API_KEY'];
Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
  try {
    // Make an HTTP GET request to fetch movie details from the first API
    final response = await http.get(
      Uri.parse(
        'https://tmdb.maybeparsa.top/tmdb/movie/$movieId?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to load movie details');
    }
  } catch (e) {
    throw Exception('Failed to load movie details');
  }
}
