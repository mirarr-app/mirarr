import 'dart:convert';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<bool> checkAvailability(int movieId, String region) async {
  final baseUrl = getBaseUrl(region);
  final apiKey = dotenv.env['TMDB_API_KEY'];
  final response = await http.get(
    Uri.parse('${baseUrl}movie/$movieId/watch/providers?api_key=$apiKey'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final Map<String, dynamic> results = data['results'];

    return results.isNotEmpty;
  } else {
    return false;
  }
}
