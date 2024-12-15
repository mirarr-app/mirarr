String getBaseUrl(String region) {
  if (region == 'iran') {
    return 'https://tmdb.relayer.ir/tmdb/';
  } else {
    return 'https://tmdb.maybeparsa.top/tmdb/';
  }
}

String getImageBaseUrl(String region) {
  if (region == 'iran') {
    return 'https://tmdbpics.relayer.ir';
  } else {
    return 'https://tmdbpics.maybeparsa.top';
  }
}
