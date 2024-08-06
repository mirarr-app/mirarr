import 'package:Mirarr/moviesPage/movieDetailPageDesktop.dart';
import 'package:flutter/material.dart';

void onTapMovieDesktop(String movieTitle, int movieId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          MovieDetailPageDesktop(movieTitle: movieTitle, movieId: movieId),
    ),
  );
}

void onTapMovieDesktop2(
    String movieTitle, int movieId, BuildContext context, Offset tapPosition) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 300),
      reverseTransitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MovieDetailPageDesktop(movieTitle: movieTitle, movieId: movieId);
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
