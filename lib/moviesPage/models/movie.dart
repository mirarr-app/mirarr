class Movie {
  final String title;
  final String releaseDate;
  final String posterPath;
  final String overView;
  final int id;
  final double? score;
  final String? backdropPath;
  List<CrewMember>? crew;

  Movie(
      {required this.title,
      required this.releaseDate,
      required this.posterPath,
      required this.overView,
      required this.id,
      this.backdropPath,
      this.crew = const [],
      required this.score});
}

class CrewMember {
  final int id;
  final String name;
  final String job;

  CrewMember({required this.id, required this.name, required this.job});
}
