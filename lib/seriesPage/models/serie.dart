class Serie {
  final String name;
  final String posterPath;
  final String? backdropPath;
  final String overView;
  final int id;
  final double? score;
  final String? lastAirDate;
  final int? lastEpisodeSeasonNumber;
  final int? lastEpisodeEpisodeNumber;

  Serie(
      {required this.name,
      required this.posterPath,
      required this.overView,
      required this.id,
      this.backdropPath,
      required this.score,
      this.lastAirDate,
      this.lastEpisodeSeasonNumber,
      this.lastEpisodeEpisodeNumber});
}
