import 'dart:ui';

import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
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
    final double width = MediaQuery.of(context).size.width;
    int crossAxisCount = (width / 200).round();
    if (crossAxisCount < 2) crossAxisCount = 2;
    return Scaffold(
      extendBody: true,
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
              onTap: () => onTapMovie(movie.title, movie.id, context),
              child: CustomMovieWidget(movie: movie),
            );
          },
        ),
      ),
    );
  }
}
