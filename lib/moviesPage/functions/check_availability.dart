import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<bool> checkAvailability(int movieId) async {
  final apiKey = dotenv.env['TMDB_API_KEY']; // Replace with your TMDB API Key
  final response = await http.get(
    Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId/watch/providers?api_key=$apiKey',
    ),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final Map<String, dynamic> results = data['results'];

    return results.isNotEmpty;
  } else {
    // Handle error here
    return false;
  }
}
