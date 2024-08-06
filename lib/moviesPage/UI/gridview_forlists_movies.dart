import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:flutter/material.dart';

class ListGridViewMovies extends StatefulWidget {
  final List movieList;

  ListGridViewMovies({Key? key, required this.movieList}) : super(key: key);

  @override
  _ListGridViewMoviesState createState() => _ListGridViewMoviesState();
}

class _ListGridViewMoviesState extends State<ListGridViewMovies> {
  @override
  Widget build(BuildContext context) {
    int crossAxisCount = Platform.isAndroid || Platform.isIOS ? 2 : 4;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Movie List'),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7,
          ),
          itemCount: widget.movieList.length,
          itemBuilder: (context, index) {
            final movie = widget.movieList[index];
            return GestureDetector(
              onTap: () => Platform.isAndroid || Platform.isIOS
                  ? onTapMovie(movie.title, movie.id, context)
                  : onTapMovieDesktop(movie.title, movie.id, context),
              child: CustomMovieWidget(movie: movie),
            );
          },
        ),
      ),
    );
  }
}
