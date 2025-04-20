import 'package:http/http.dart' as http;
import 'dart:convert';

const String _encodedBaseUrl = 'aHR0cHM6Ly94cHJpbWUudHYvcHJpbWVib3g/aWQ9';

String get baseStreamUrl => utf8.decode(base64.decode(_encodedBaseUrl));

Future<bool> checkXprime(int movieId) async {
  try {
    final response = await http.get(Uri.parse(
        '$baseStreamUrl$movieId'));

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
        '$baseStreamUrl$serieId&season=$seasonNumber&episode=$episodeNumber'));

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