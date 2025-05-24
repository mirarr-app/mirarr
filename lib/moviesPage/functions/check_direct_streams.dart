import 'package:http/http.dart' as http;
import 'dart:convert';

const String _xprimeEncodedBaseUrl = 'aHR0cHM6Ly94cHJpbWUudHYvcHJpbWVib3g/bmFtZT0=';

String get xprimeBaseStreamUrl => utf8.decode(base64.decode(_xprimeEncodedBaseUrl));

const String _riveEncodedBaseUrl = 'aHR0cHM6Ly9yaXZlLnBhcnNhb28uaXIvYXBpL3N0cmVhbXM/';

String get riveBaseStreamUrl => utf8.decode(base64.decode(_riveEncodedBaseUrl));

Future<bool> checkXprime(int movieId, String movieName) async {
  try {
    final response = await http.get(Uri.parse(
        '$xprimeBaseStreamUrl$movieName'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok' && data['streams'].isNotEmpty) {
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
        '$xprimeBaseStreamUrl$serieName&season=$seasonNumber&episode=$episodeNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok' && data['streams'].isNotEmpty) {
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

Future<bool> checkRive(int movieId, String movieName) async {
  try {
    final response = await http.get(Uri.parse(
        '${riveBaseStreamUrl}tmdId=$movieId&type=movie'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data']['streams'].isNotEmpty) {
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

Future<bool> checkRiveSeries(int serieId, int seasonNumber, int episodeNumber, String serieName) async {
  try {
    final response = await http.get(Uri.parse(
        '${riveBaseStreamUrl}tmdId=$serieId&season=$seasonNumber&episode=$episodeNumber&type=series'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data']['streams'].isNotEmpty) {
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