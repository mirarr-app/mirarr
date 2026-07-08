import 'dart:ui';

import 'package:Mirarr/functions/fetchers/fetch_popular_series.dart';
import 'package:Mirarr/functions/fetchers/fetch_trending_series.dart';
import 'package:Mirarr/functions/fetchers/fetch_series_by_genre.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/seriesPage/function/on_tap_gridview_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'dart:async';
import 'package:Mirarr/seriesPage/UI/customSeriesWidget.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SerieSearchScreen extends StatefulWidget {
  static final GlobalKey<_SerieSearchScreenState> movieSearchKey =
      GlobalKey<_SerieSearchScreenState>();

  const SerieSearchScreen({super.key});
  @override
  _SerieSearchScreenState createState() => _SerieSearchScreenState();
}

class _SerieSearchScreenState extends State<SerieSearchScreen> {
  final apiKey = dotenv.env['TMDB_API_KEY'];

  List<Serie> trendingSeries = [];
  List<Serie> popularSeries = [];
  List<Genre> genres = [];
  Map<int, List<Serie>> seriesByGenre = {};
  late RegionProvider _regionProvider;

  final List<Serie> _dummySeries = List.generate(
    5,
    (index) => Serie(
      name: 'TV Show Title Placeholder',
      posterPath: '',
      overView: 'This is a description placeholder for the tv show loading state.',
      id: -1 - index,
      score: 8.5,
    ),
  );

  final List<Genre> _dummyGenres = [
    Genre(id: -100, name: 'Genre Placeholder 1'),
    Genre(id: -101, name: 'Genre Placeholder 2'),
  ];

  late final Map<int, List<Serie>> _dummySeriesByGenre = {
    -100: List.generate(
      5,
      (index) => Serie(
        name: 'TV Show Title Placeholder',
        posterPath: '',
        overView: 'This is a description placeholder for the tv show loading state.',
        id: -200 - index,
        score: 8.5,
      ),
    ),
    -101: List.generate(
      5,
      (index) => Serie(
        name: 'TV Show Title Placeholder',
        posterPath: '',
        overView: 'This is a description placeholder for the tv show loading state.',
        id: -300 - index,
        score: 8.5,
      ),
    ),
  };

  Future<void> _fetchGenresAndSeries() async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    try {
      final fetchedGenres = await fetchGenres(region);
      final tasks = fetchedGenres.map((genre) async {
        final series = await fetchSeriesByGenre(genre.id, region);
        return MapEntry(genre.id, series);
      });
      final results = await Future.wait(tasks);

      if (mounted) {
        setState(() {
          genres = fetchedGenres;
          seriesByGenre = Map.fromEntries(results);
        });
      }
    } catch (e) {
      throw Exception('Failed to load series by genre');
    }
  }

  Future<void> _fetchTrendingSeries() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      trendingSeries = await fetchTrendingSeries(region);
      setState(() {
        trendingSeries = trendingSeries;
      });
    } catch (e) {
      throw Exception('Failed to load trending series data');
    }
  }

  Future<void> _fetchPopularSeries() async {
    try {
      final region =
          Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final series = await fetchPopularSeries(region);
      setState(() {
        popularSeries = series;
      });
    } catch (e) {
      throw Exception('Failed to load popular series data');
    }
  }

  void handleNetworkError(ClientException e) {
    if (e.message.contains('No address associated with hostname')) {
      // Handle case where there's no internet connection
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content:
                const Text('Please connect to the internet and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle other network-related errors
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titleTextStyle: TextStyle(
                color: Theme.of(context).secondaryHeaderColor, fontSize: 20),
            contentTextStyle: TextStyle(
                color: Theme.of(context).secondaryHeaderColor, fontSize: 16),
            title: const Text('Network Error'),
            content: const Text(
                'An error occurred while fetching data. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  checkInternetAndFetchData();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _onRegionChanged() {
    checkInternetAndFetchData();
  }

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();

    // Add listener for region changes
    _regionProvider = Provider.of<RegionProvider>(context, listen: false);
    _regionProvider.addListener(_onRegionChanged);
  }

  @override
  void dispose() {
    // Remove listener when disposing
    _regionProvider.removeListener(_onRegionChanged);
    super.dispose();
  }

  Future<void> checkInternetAndFetchData() async {
    setState(() {
      trendingSeries = [];
      popularSeries = [];
      genres = [];
      seriesByGenre = {};
    });
    _fetchTrendingSeries();
    _fetchPopularSeries();
    await _fetchGenresAndSeries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
extendBody: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            'Series',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Expanded(
                child: Card(
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
                          child: Text(
                            textAlign: TextAlign.left,
                            'Trending TV Shows',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 320, // Set the height for the movie cards
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: Skeletonizer(
                          enabled: trendingSeries.isEmpty,
                          containersColor: Colors.white.withOpacity(0.05),
                          effect: ShimmerEffect(
                            baseColor: Colors.white.withOpacity(0.05),
                            highlightColor: Colors.white.withOpacity(0.15),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingSeries.isEmpty
                                ? _dummySeries.length
                                : trendingSeries.length,
                            itemBuilder: (context, index) {
                              final serie = trendingSeries.isEmpty
                                  ? _dummySeries[index]
                                  : trendingSeries[index];
                              final widget = TvFocusWrapper(
                                autoFocus: index == 0 && trendingSeries.isNotEmpty,
                                onTap: trendingSeries.isEmpty
                                    ? () {}
                                    : () => onTapSerie(serie.name, serie.id, context),
                                child: CustomSeriesWidget(
                                  serie: serie,
                                ),
                              );
                              if (trendingSeries.isEmpty) {
                                final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                return Opacity(
                                  opacity: opacity,
                                  child: widget,
                                );
                              }
                              return widget;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 15, 0, 0),
                          child: Text(
                            'Popular TV Shows',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300, // Set the height for the movie cards
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: Skeletonizer(
                          enabled: popularSeries.isEmpty,
                          containersColor: Colors.white.withOpacity(0.05),
                          effect: ShimmerEffect(
                            baseColor: Colors.white.withOpacity(0.05),
                            highlightColor: Colors.white.withOpacity(0.15),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popularSeries.isEmpty
                                ? _dummySeries.length
                                : popularSeries.length,
                            itemBuilder: (context, index) {
                              final serie = popularSeries.isEmpty
                                  ? _dummySeries[index]
                                  : popularSeries[index];
                              final widget = TvFocusWrapper(
                                onTap: popularSeries.isEmpty
                                    ? () {}
                                    : () => onTapSerie(serie.name, serie.id, context),
                                child: CustomSeriesWidget(
                                  serie: serie,
                                ),
                              );
                              if (popularSeries.isEmpty) {
                                final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                return Opacity(
                                  opacity: opacity,
                                  child: widget,
                                );
                              }
                              return widget;
                            },
                          ),
                        ),
                      ),
                    ),
                    for (var genre in (genres.isEmpty ? _dummyGenres : genres))
                      Skeletonizer(
                        enabled: genres.isEmpty,
                        containersColor: Colors.white.withOpacity(0.05),
                        effect: ShimmerEffect(
                          baseColor: Colors.white.withOpacity(0.05),
                          highlightColor: Colors.white.withOpacity(0.15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 15, 0, 0),
                              child: TvFocusWrapper(
                                borderRadius: 8.0,
                                onTap: genres.isEmpty
                                    ? () {}
                                    : () => onTapGridSerie(
                                        seriesByGenre[genre.id]!, context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        genre.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Theme.of(context).primaryColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 320,
                              child: ScrollConfiguration(
                                behavior:
                                    ScrollConfiguration.of(context).copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                  },
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: genres.isEmpty
                                      ? (_dummySeriesByGenre[genre.id]?.length ?? 0)
                                      : (seriesByGenre[genre.id]?.length ?? 0),
                                  itemBuilder: (context, index) {
                                    final serie = genres.isEmpty
                                        ? _dummySeriesByGenre[genre.id]![index]
                                        : seriesByGenre[genre.id]![index];
                                     final widget = TvFocusWrapper(
                                       onTap: genres.isEmpty
                                           ? () {}
                                           : () => onTapSerie(serie.name, serie.id, context),
                                       child: CustomSeriesWidget(
                                         serie: serie,
                                       ),
                                    );
                                     if (genres.isEmpty) {
                                       final double opacity = (1.0 - (index * 0.18)).clamp(0.1, 1.0);
                                       return Opacity(
                                         opacity: opacity,
                                         child: widget,
                                       );
                                     }
                                     return widget;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            )),
          ],
        ));
  }
}
