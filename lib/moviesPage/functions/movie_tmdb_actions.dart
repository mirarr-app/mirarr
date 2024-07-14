import 'dart:convert';
import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:hive/hive.dart';

final apiKey = dotenv.env['TMDB_API_KEY'];

Future<void> addWatchList(String accountId, String sessionId, int movieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/watchlist?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'movie',
    'media_id': movieId,
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
        print('Movie added to watchlist successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add movie to watchlist', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> addRating(String sessionId, int movieId, double userScore,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/movie/$movieId/rating?api_key=$apiKey&session_id=$sessionData';

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
        print('Rating added for $movieId successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add rating for $movieId', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeRating(
    String sessionId, int movieId, BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/movie/$movieId/rating?api_key=$apiKey&session_id=$sessionData';

  try {
    final http.Response response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json;charset=utf-8',
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Rating removed for $movieId successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to remove rating for $movieId', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> addFavorite(String accountId, String sessionId, int movieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/favorite?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'movie',
    'media_id': movieId,
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
        print('Movie added to favorites successfully!');
      }
    } else {
      showErrorDialog('Error', 'Failed to add movie to favorites', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeFromWatchList(String accountId, String sessionId,
    int movieId, BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/watchlist?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'movie',
    'media_id': movieId,
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
        print('Movie removed from watchlist successfully!');
      }
    } else {
      showErrorDialog(
          'Error', 'Failed to remove movie from watchlist', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}

Future<void> removeFromFavorite(String accountId, String sessionId, int movieId,
    BuildContext context) async {
  final openbox = await Hive.openBox('sessionBox');
  final String accountId = openbox.get('accountId');
  final String sessionData = openbox.get('sessionData');
  const String baseUrl = 'https://api.themoviedb.org/3';

  final String url =
      '$baseUrl/account/$accountId/favorite?api_key=$apiKey&session_id=$sessionData';

  Map<String, dynamic> requestBody = {
    'media_type': 'movie',
    'media_id': movieId,
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
        print('Movie removed from favorites successfully!');
      }
    } else {
      showErrorDialog(
          'Error', 'Failed to remove movie from favorites', context);
    }
  } catch (error) {
    showErrorDialog('Error', error.toString(), context);
  }
}
