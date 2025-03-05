import 'dart:io';

import 'package:Mirarr/functions/fetchers/fetch_movie_details.dart';
import 'package:Mirarr/functions/fetchers/fetch_serie_details.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:provider/provider.dart';

class TMDBUrlParser {
  static bool isTMDBMovieUrl(String url) {
    return url.startsWith('https://www.themoviedb.org/movie/') ||
        url.startsWith('themoviedb://movie/');
  }

  static bool isTMDBTVUrl(String url) {
    return url.startsWith('https://www.themoviedb.org/tv/') ||
        url.startsWith('themoviedb://tv/');
  }

  static Future<String> _getMovieTitle(
      int movieId, BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final responseData = await fetchMovieDetails(movieId, region);
    return responseData['title'];
  }

  static int? parseMovieId(String url) {
    try {
      // Remove the base URL part
      String path = url.replaceAll('https://www.themoviedb.org/movie/', '');
      path = path.replaceAll('themoviedb://movie/', '');

      // Split by dash to separate ID and title
      List<String> parts = path.split('-');

      // First part is the ID
      return int.parse(parts[0]);
    } catch (e) {
      debugPrint('Error parsing TMDB movie ID: $e');
      return null;
    }
  }

  static Future<String> _getSerieTitle(
      int serieId, BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final responseData = await fetchSerieDetails(serieId, region);
    return responseData['name'];
  }

  static int? parseSerieId(String url) {
    try {
      // Remove the base URL part
      String path = url.replaceAll('https://www.themoviedb.org/tv/', '');
      path = path.replaceAll('themoviedb://tv/', '');

      // Split by dash to separate ID and title
      List<String> parts = path.split('-');

      // First part is the ID
      int serieId = int.parse(parts[0]);

      return serieId;
    } catch (e) {
      debugPrint('Error parsing TMDB TV URL: $e');
      return null;
    }
  }

  static Future<void> handleUrl(String url, BuildContext context) async {
    // Ensure we're on the main thread and the context is valid
    if (!context.mounted) return;

    if (isTMDBMovieUrl(url)) {
      final movieId = parseMovieId(url);
      if (movieId != null) {
        try {
          final movieTitle = await _getMovieTitle(movieId, context);
          if (context.mounted) {
            if (Platform.isAndroid || Platform.isIOS) {
              onTapMovie(movieTitle, movieId, context);
            } else {
              onTapMovieDesktop(movieTitle, movieId, context);
            }
          }
        } catch (e) {
          debugPrint('Error fetching movie title: $e');
        }
      }
    } else if (isTMDBTVUrl(url)) {
      final serieId = parseSerieId(url);
      if (serieId != null) {
        final serieTitle = await _getSerieTitle(serieId, context);
        if (context.mounted) {
          if (Platform.isAndroid || Platform.isIOS) {
            onTapSerie(serieTitle, serieId, context);
          } else {
            onTapSerieDesktop(serieTitle, serieId, context);
          }
        }
      }
    }
  }
}
