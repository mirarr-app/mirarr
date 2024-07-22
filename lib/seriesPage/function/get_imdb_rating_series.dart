import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiOmdbKey = dotenv.env['OMDB_API_KEY_FOR_SERIES'];
Future<void> getSerieRatings(String? imdbId, Function(String) updateImdbRating,
    Function(String) updateRottenTomatoesRating) async {
  try {
    final response = await http.get(
      Uri.parse('http://www.omdbapi.com/?i=$imdbId&apikey=$apiOmdbKey'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String imdbRating = responseData['imdbRating'];
      updateImdbRating(imdbRating);

      final List<dynamic> ratings = responseData['Ratings'];
      final rottenTomatoesRating = ratings.firstWhere(
        (rating) => rating['Source'] == 'Rotten Tomatoes',
        orElse: () => {'Value': 'N/A'},
      )['Value'];
      updateRottenTomatoesRating(rottenTomatoesRating);
    } else {
      throw Exception('Failed to load movie ratings');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error: $error');
    }
  }
}
