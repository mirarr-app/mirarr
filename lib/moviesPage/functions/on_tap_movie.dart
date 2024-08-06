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

void onTapMovie2(
    String movieTitle, int movieId, BuildContext context, Offset tapPosition) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 300),
      reverseTransitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MovieDetailPage(movieTitle: movieTitle, movieId: movieId);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 0.7),
        );

        return Transform(
          transform: Matrix4.identity()
            ..translate(tapPosition.dx, tapPosition.dy)
            ..scale(curvedAnimation.value)
            ..translate(-tapPosition.dx, -tapPosition.dy),
          child: child,
        );
      },
    ),
  );
}
