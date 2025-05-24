class WatchHistoryItem {
  final int? id;
  final int tmdbId;
  final String title;
  final String type; // 'movie' or 'tv'
  final String? posterPath;
  final DateTime watchedAt;
  final int? seasonNumber; // For TV shows
  final int? episodeNumber; // For TV shows
  final String? episodeTitle; // For TV shows
  final double? userRating; // Optional user rating
  final String? notes; // Optional user notes

  WatchHistoryItem({
    this.id,
    required this.tmdbId,
    required this.title,
    required this.type,
    this.posterPath,
    required this.watchedAt,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.userRating,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'title': title,
      'type': type,
      'poster_path': posterPath,
      'watched_at': watchedAt.millisecondsSinceEpoch,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'episode_title': episodeTitle,
      'user_rating': userRating,
      'notes': notes,
    };
  }

  factory WatchHistoryItem.fromMap(Map<String, dynamic> map) {
    return WatchHistoryItem(
      id: map['id'],
      tmdbId: map['tmdb_id'],
      title: map['title'],
      type: map['type'],
      posterPath: map['poster_path'],
      watchedAt: DateTime.fromMillisecondsSinceEpoch(map['watched_at']),
      seasonNumber: map['season_number'],
      episodeNumber: map['episode_number'],
      episodeTitle: map['episode_title'],
      userRating: map['user_rating'],
      notes: map['notes'],
    );
  }

  WatchHistoryItem copyWith({
    int? id,
    int? tmdbId,
    String? title,
    String? type,
    String? posterPath,
    DateTime? watchedAt,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    double? userRating,
    String? notes,
  }) {
    return WatchHistoryItem(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      type: type ?? this.type,
      posterPath: posterPath ?? this.posterPath,
      watchedAt: watchedAt ?? this.watchedAt,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      userRating: userRating ?? this.userRating,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'WatchHistoryItem{id: $id, tmdbId: $tmdbId, title: $title, type: $type, watchedAt: $watchedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchHistoryItem &&
        other.id == id &&
        other.tmdbId == tmdbId &&
        other.type == type &&
        other.seasonNumber == seasonNumber &&
        other.episodeNumber == episodeNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tmdbId.hashCode ^
        type.hashCode ^
        seasonNumber.hashCode ^
        episodeNumber.hashCode;
  }
} 