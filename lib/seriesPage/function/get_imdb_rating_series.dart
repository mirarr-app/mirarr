import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/functions/get_imdb_score.dart';

final apiOmdbKey = dotenv.env['OMDB_API_KEY_FOR_SERIES'];
Future<void> getSerieRatings(String? imdbId, Function(String) updateImdbRating,
    Function(String) updateRottenTomatoesRating) async {
  try {
    final response = await http.get(
      Uri.parse('http://www.omdbapi.com/?i=$imdbId&apikey=$apiOmdbKey'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final rawImdbRating = responseData['imdbRating'];
      
      if (rawImdbRating != null &&
          rawImdbRating != 'N/A' &&
          rawImdbRating.toString().trim().isNotEmpty) {
        updateImdbRating(rawImdbRating.toString());
      } else if (imdbId != null && imdbId.isNotEmpty) {
        final score = await getImdbScore(imdbId);
        if (score != null) {
          updateImdbRating(score.toStringAsFixed(1));
        } else {
          updateImdbRating(rawImdbRating?.toString() ?? 'N/A');
        }
      } else {
        updateImdbRating(rawImdbRating?.toString() ?? 'N/A');
      }

      final List<dynamic>? ratings = responseData['Ratings'];
      if (ratings != null) {
        final rottenTomatoesRating = ratings.firstWhere(
          (rating) => rating['Source'] == 'Rotten Tomatoes',
          orElse: () => {'Value': 'N/A'},
        )['Value'];
        updateRottenTomatoesRating(rottenTomatoesRating.toString());
      } else {
        updateRottenTomatoesRating('N/A');
      }
    } else {
      throw Exception('Failed to load movie ratings');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error: $error');
    }
    updateRottenTomatoesRating('N/A');
    if (imdbId != null && imdbId.isNotEmpty) {
      try {
        final score = await getImdbScore(imdbId);
        if (score != null) {
          updateImdbRating(score.toStringAsFixed(1));
        }
      } catch (_) {}
    }
  }
}
