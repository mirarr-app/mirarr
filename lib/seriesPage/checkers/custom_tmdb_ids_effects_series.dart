import 'package:flutter/material.dart';
import 'package:Mirarr/seriesPage/checkers/const_tmdb_ids_series.dart';

bool isBreakingBad(int tmdbId) => breakingbadId.contains(tmdbId);

TextStyle getSeriesTitleTextStyle(int tmdbId) => switch (tmdbId) {
      _ when isBreakingBad(tmdbId) => const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFFc19557),
        ),
      _ => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
    };

Color getSeriesBackgroundColor(BuildContext context, int tmdbId) =>
    switch (tmdbId) {
      _ when isBreakingBad(tmdbId) => const Color(0xFF583724).withOpacity(0.8),
      _ => Colors.grey.withOpacity(0.2),
    };

TextStyle getSeriesAboutTextStyle(BuildContext context, int tmdbId) =>
    switch (tmdbId) {
      _ => const TextStyle(
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
    };

Color getSeriesColor(BuildContext context, int tmdbId) => switch (tmdbId) {
      _ when isBreakingBad(tmdbId) => const Color(0xFF583724),
      _ => Theme.of(context).primaryColor,
    };

TextStyle getSeriesButtonTextStyle(int tmdbId) => switch (tmdbId) {
      _ when isBreakingBad(tmdbId) => const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFc19557),
        ),
      _ => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
    };
