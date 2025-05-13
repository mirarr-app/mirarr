import 'package:http/http.dart' as http;
import 'dart:convert';

const String _encodedBaseUrl = 'aHR0cHM6Ly94cHJpbWUudHYvcHJpbWVib3g/bmFtZT0=';

String get baseStreamUrl => utf8.decode(base64.decode(_encodedBaseUrl));

Future<bool> checkXprime(int movieId, String movieName) async {
  try {
    final response = await http.get(Uri.parse(
        '$baseStreamUrl$movieName'));

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


Future<bool> checkXprimeSeries(int serieId, int seasonNumber, int episodeNumber, String serieName) async {
  try {
    final response = await http.get(Uri.parse(
        '$baseStreamUrl$serieName&season=$seasonNumber&episode=$episodeNumber'));

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