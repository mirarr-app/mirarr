import 'package:Mirarr/seriesPage/serieDetailPage.dart';
import 'package:flutter/material.dart';

void onTapSerie(String movieTitle, int movieId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          SerieDetailPage(serieName: movieTitle, serieId: movieId),
    ),
  );
}
