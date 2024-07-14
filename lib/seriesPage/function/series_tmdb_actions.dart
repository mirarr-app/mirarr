import 'dart:convert';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:hive/hive.dart';

final apiKey = dotenv.env['TMDB_API_KEY'];
Future<void> addRating(String sessionId, int serieId, double userScore,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/tv/$serieId/rating?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'value': userScore,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      if (kDebugMode) {
        print('Rating added for $serieId successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add rating for $serieId', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeRating(
    String sessionId, int serieId, BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/tv/$serieId/rating?api_key=$apiKey&session_id=$sessionData';

  try {
    final http.Response response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Rating removed for $serieId successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to remove rating for $serieId', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> addWatchList(String accountId, String sessionId, int serieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/watchlist?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'tv',
    'media_id': serieId,
    'watchlist': true,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      if (kDebugMode) {
        print('Serie added to watchlist successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add serie to watchlist', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> addFavorite(String accountId, String sessionId, int serieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/favorite?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'tv',
    'media_id': serieId,
    'favorite': true,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      if (kDebugMode) {
        print('Serie added to favorites successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add serie to favorites', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeFromWatchList(String accountId, String sessionId,
    int serieId, BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/watchlist?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'tv',
    'media_id': serieId,
    'watchlist': false,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Serie removed from watchlist successfully!');
      }
    } else {
      showErrorDialog(
          'Error', 'Failed to remove serie from watchlist', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeFromFavorite(String accountId, String sessionId, int serieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/favorite?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'tv',
    'media_id': serieId,
    'favorite': false,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Serie removed from favorites successfully!');
      }
    } else {
      showErrorDialog(
          'Error', 'Failed to remove serie from favorites', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}
