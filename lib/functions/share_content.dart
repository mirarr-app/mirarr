import 'package:share_plus/share_plus.dart';

class ShareContent {
  static void shareMovie(int movieId) {
    final url = 'https://www.themoviedb.org/movie/$movieId';
    Share.share(url);
  }

  static void shareTVShow(int serieId) {
    final url = 'https://www.themoviedb.org/tv/$serieId';
    Share.share(url);
  }
}
