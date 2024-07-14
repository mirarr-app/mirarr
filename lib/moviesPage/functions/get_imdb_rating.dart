import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiOmdbKey = dotenv.env['OMDB_API_KEY'];
Future<void> getImdbRating(
    String? imdbId, Function(String) updateRating) async {
  try {
    final response = await http.get(
      Uri.parse('http://www.omdbapi.com/?i=$imdbId&apikey=$apiOmdbKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String rating = responseData['imdbRating'];
      updateRating(rating);
    } else {
      throw Exception('Failed to load IMDB rating');
    }
  } catch (error) {
    // Handle error, e.g., by showing an error dialog
    if (kDebugMode) {
      print('Error: $error');
    }
  }
}
