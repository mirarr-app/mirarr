import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final apiKey = dotenv.env['TMDB_API_KEY'];

Future<Map<String, List<Map<String, dynamic>>>> fetchEpisodeCastAndCrew(
    int serieId, int seasonNumber, int episodeNumber) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/tv/$serieId/season/$seasonNumber/episode/$episodeNumber?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> castList = responseData['guest_stars'];
      final List<Map<String, dynamic>> allGuestsList =
          castList.cast<Map<String, dynamic>>().toList();

      // Fetch director details
      final List<dynamic> crewList = responseData['crew'];
      final List<Map<String, dynamic>> allCrewList =
          crewList.cast<Map<String, dynamic>>().toList();

      return {
        'guest_stars': allGuestsList,
        'crew': allCrewList,
      };
    } else {
      throw Exception('Failed to load guest stars and crew details');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
    return {
      'guest_stars': [],
      'crew': [],
    };
  }
}
