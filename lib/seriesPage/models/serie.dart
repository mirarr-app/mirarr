class Serie {
  final String name;
  final String posterPath;
  final String? backdropPath;
  final String overView;
  final int id;
  final double? score;

  Serie(
      {required this.name,
      required this.posterPath,
      required this.overView,
      required this.id,
      this.backdropPath,
      required this.score});
}
