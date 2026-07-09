import 'package:Mirarr/moviesPage/movieDetailPage.dart';
import 'package:flutter/material.dart';

Future<void> onTapMovie(String movieTitle, int movieId, BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          MovieDetailPage(movieTitle: movieTitle, movieId: movieId),
    ),
  );
}
