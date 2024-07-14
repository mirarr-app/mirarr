class Movie {
  final String title;
  final String releaseDate;
  final String posterPath;
  final String overView;
  final int id;
  final double? score;
  final String? backdropPath;

  Movie(
      {required this.title,
      required this.releaseDate,
      required this.posterPath,
      required this.overView,
      required this.id,
      this.backdropPath,
      required this.score});
}
