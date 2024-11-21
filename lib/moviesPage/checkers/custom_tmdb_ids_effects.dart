import 'package:flutter/material.dart';
import 'package:Mirarr/moviesPage/checkers/const_tmdb_ids.dart';

bool isHarryPotter(int tmdbId) => harryPotterIds.contains(tmdbId);
bool isMatrix(int tmdbId) => matrixIds.contains(tmdbId);
bool isStarwars(int tmdbId) => starwarsIds.contains(tmdbId);
bool isSpiderman(int tmdbId) => spidermanIds.contains(tmdbId);
bool isAvengers(int tmdbId) => avengersIds.contains(tmdbId);
bool isBatman(int tmdbId) => batmanIds.contains(tmdbId);
bool isShrek(int tmdbId) => shrekIds.contains(tmdbId);
bool isDeadpool(int tmdbId) => deadpoolIds.contains(tmdbId);
bool isDune(int tmdbId) => duneIds.contains(tmdbId);
bool isMonsters(int tmdbId) => monstersIds.contains(tmdbId);
bool isLotr(int tmdbId) => lotrIds.contains(tmdbId);
bool isHobbit(int tmdbId) => hobbitIds.contains(tmdbId);

TextStyle getMovieTitleTextStyle(int tmdbId) => switch (tmdbId) {
      _ when isHarryPotter(tmdbId) => const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC39A1C),
          fontFamily: 'HarryPotter',
        ),
      _ when isMatrix(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF008F11),
          fontFamily: 'Matrix',
        ),
      _ when isStarwars(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFffe81f),
          fontFamily: 'Starwars',
        ),
      _ when isSpiderman(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFea1818),
          fontFamily: 'Spiderman',
        ),
      _ when isAvengers(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFF460061),
          fontFamily: 'Avengers',
        ),
      _ when isBatman(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFFe6f10c),
          fontFamily: 'Batman',
        ),
      _ when isShrek(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFFb0c400),
          fontFamily: 'Shrek',
        ),
      _ when isDeadpool(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8f2121),
          fontFamily: 'Deadpool',
        ),
      _ when isDune(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFFe79b07),
          fontFamily: 'Dune',
        ),
      _ when isMonsters(tmdbId) => const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: Color(0xFF50ceff),
          fontFamily: 'Monsters',
        ),
      _ when isLotr(tmdbId) => const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFe3b737),
          fontFamily: 'Lotr',
        ),
      _ when isHobbit(tmdbId) => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFfec908),
          fontFamily: 'Lotr',
        ),
      _ => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
    };

Color getMovieBackgroundColor(BuildContext context, int tmdbId) =>
    switch (tmdbId) {
      _ when isHarryPotter(tmdbId) => const Color(0xFF641E1E).withOpacity(0.8),
      _ when isMatrix(tmdbId) => const Color(0xFF0e1b0f).withOpacity(0.8),
      _ when isStarwars(tmdbId) => const Color(0xFF201652).withOpacity(0.8),
      _ when isSpiderman(tmdbId) => const Color(0xFFea1818).withOpacity(0.6),
      _ when isAvengers(tmdbId) => const Color(0xFF460061).withOpacity(0.8),
      _ when isBatman(tmdbId) => const Color(0xFF03084e).withOpacity(0.8),
      _ when isShrek(tmdbId) => const Color(0xFFb0c400).withOpacity(0.8),
      _ when isDeadpool(tmdbId) => const Color(0xFF8f2121).withOpacity(0.8),
      _ when isDune(tmdbId) => const Color(0xFF3d2d1c).withOpacity(0.8),
      _ when isMonsters(tmdbId) => const Color(0xFF5aff49).withOpacity(0.8),
      _ when isLotr(tmdbId) => const Color(0xFFb87316).withOpacity(0.8),
      _ when isHobbit(tmdbId) => const Color(0xFF201d05).withOpacity(0.8),
      _ => Colors.grey.withOpacity(0.2),
    };

TextStyle getMovieAboutTextStyle(BuildContext context, int tmdbId) =>
    switch (tmdbId) {
      _ when isHarryPotter(tmdbId) => const TextStyle(
          fontWeight: FontWeight.w300,
          color: Color(0xFFEFEEE9),
        ),
      _ when isMatrix(tmdbId) => const TextStyle(
          fontWeight: FontWeight.w300,
          fontFamily: 'Matrix',
          color: Colors.white,
          fontSize: 15,
        ),
      _ when isStarwars(tmdbId) => const TextStyle(
          fontWeight: FontWeight.w300,
          fontFamily: 'Starwars',
          color: Colors.white,
          fontSize: 15,
        ),
      _ when isAvengers(tmdbId) => const TextStyle(
          fontWeight: FontWeight.w300,
          fontFamily: 'Avengers',
          color: Colors.white,
          fontSize: 15,
        ),
      _ when isLotr(tmdbId) => const TextStyle(
          fontWeight: FontWeight.w300,
          fontFamily: 'Lotr',
          color: Colors.white,
          fontSize: 15,
        ),
      _ => const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w300,
        ),
    };

Color getMovieColor(BuildContext context, int tmdbId) => switch (tmdbId) {
      _ when isHarryPotter(tmdbId) => const Color(0xFF641E1E),
      _ when isMatrix(tmdbId) => const Color(0xFF0e1b0f),
      _ when isStarwars(tmdbId) => const Color(0xFF201652),
      _ when isSpiderman(tmdbId) => const Color(0xFFea1818),
      _ when isAvengers(tmdbId) => const Color(0xFF460061),
      _ when isBatman(tmdbId) => const Color(0xFFe6f10c),
      _ when isShrek(tmdbId) => const Color(0xFFb0c400),
      _ when isDeadpool(tmdbId) => const Color(0xFF8f2121),
      _ when isDune(tmdbId) => const Color(0xFFe79b07),
      _ when isMonsters(tmdbId) => const Color(0xFF5aff49),
      _ when isLotr(tmdbId) => const Color(0xFFb87316),
      _ when isHobbit(tmdbId) => const Color(0xFF201d05),
      _ => Theme.of(context).primaryColor,
    };

TextStyle getMovieButtonTextStyle(int tmdbId) => switch (tmdbId) {
      _ when isHarryPotter(tmdbId) => const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC39A1C),
          fontFamily: 'HarryPotter',
        ),
      _ when isMatrix(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF008F11),
          fontFamily: 'Matrix',
        ),
      _ when isStarwars(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFffe81f),
          fontFamily: 'Starwars',
        ),
      _ when isSpiderman(tmdbId) => const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Spiderman',
        ),
      _ when isAvengers(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00991f),
          fontFamily: 'Avengers',
        ),
      _ when isBatman(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF03084e),
          fontFamily: 'Batman',
        ),
      _ when isShrek(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF795a2d),
          fontFamily: 'Shrek',
        ),
      _ when isDeadpool(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF171717),
          fontFamily: 'Deadpool',
        ),
      _ when isDune(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3d2d1c),
          fontFamily: 'Dune',
        ),
      _ when isMonsters(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF50ceff),
          fontFamily: 'Monsters',
        ),
      _ when isLotr(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFe3b737),
          fontFamily: 'Lotr',
        ),
      _ when isHobbit(tmdbId) => const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFfec908),
          fontFamily: 'Lotr',
        ),
      _ => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
    };
