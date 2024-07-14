import 'package:Mirarr/moviesPage/movieDetailPage.dart';
import 'package:flutter/material.dart';

void onTapMovie(String movieTitle, int movieId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          MovieDetailPage(movieTitle: movieTitle, movieId: movieId),
    ),
  );
}
