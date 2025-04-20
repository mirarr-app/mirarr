import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> checkXprime(int movieId) async {
  try {
    final response = await http.get(Uri.parse(
        'https://xprime.tv/primebox?id=$movieId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}


Future<bool> checkXprimeSeries(int serieId, int seasonNumber, int episodeNumber) async {
  try {
    final response = await http.get(Uri.parse(
        'https://xprime.tv/primebox?id=$serieId&season=$seasonNumber&episode=$episodeNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}