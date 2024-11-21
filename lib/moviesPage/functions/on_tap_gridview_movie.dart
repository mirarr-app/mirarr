import 'package:Mirarr/moviesPage/UI/gridview_forlists_movies.dart';
import 'package:flutter/material.dart';

void onTapGridMovie(List movieList, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ListGridViewMovies(movieList: movieList),
    ),
  );
}
