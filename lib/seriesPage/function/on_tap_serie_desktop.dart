import 'package:Mirarr/seriesPage/serieDetailPageDesktop.dart';
import 'package:flutter/material.dart';

void onTapSerieDesktop(String movieTitle, int movieId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          SerieDetailPageDesktop(serieName: movieTitle, serieId: movieId),
    ),
  );
}
