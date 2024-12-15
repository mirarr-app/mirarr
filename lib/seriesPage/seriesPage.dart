import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/functions/fetchers/fetch_popular_series.dart';
import 'package:Mirarr/functions/fetchers/fetch_trending_series.dart';
import 'package:Mirarr/functions/fetchers/fetch_series_by_genre.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/seriesPage/function/on_tap_gridview_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'dart:async';
import 'package:Mirarr/seriesPage/UI/customSeriesWidget.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:provider/provider.dart';

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

  Future<void> _fetchGenresAndSeries() async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    try {
      genres = await fetchGenres(region);
      for (var genre in genres) {
        final series = await fetchSeriesByGenre(genre.id, region);
        setState(() {
          seriesByGenre[genre.id] = series;
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
      popularSeries = await fetchPopularSeries(region);
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

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();

    // Add listener for region changes
    Provider.of<RegionProvider>(context, listen: false).addListener(() {
      checkInternetAndFetchData();
    });
  }

  @override
  void dispose() {
    // Remove listener when disposing
    Provider.of<RegionProvider>(context, listen: false).removeListener(() {
      checkInternetAndFetchData();
    });
    super.dispose();
  }

  Future<void> checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      handleNetworkError(ClientException('No internet connection'));
    } else {
      // Internet connection available, fetch data
      _fetchTrendingSeries();
      _fetchPopularSeries();
      await _fetchGenresAndSeries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trendingSeries.length,
                          itemBuilder: (context, index) {
                            final serie = trendingSeries[index];
                            return GestureDetector(
                              onTap: () => Platform.isAndroid || Platform.isIOS
                                  ? onTapSerie(serie.name, serie.id, context)
                                  : onTapSerieDesktop(
                                      serie.name, serie.id, context),
                              child: CustomSeriesWidget(
                                serie: serie,
                              ),
                            );
                          },
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
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: popularSeries.length,
                          itemBuilder: (context, index) {
                            final serie = popularSeries[index];
                            return GestureDetector(
                              onTap: () => Platform.isAndroid || Platform.isIOS
                                  ? onTapSerie(serie.name, serie.id, context)
                                  : onTapSerieDesktop(
                                      serie.name, serie.id, context),
                              child: CustomSeriesWidget(
                                serie: serie,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    for (var genre in genres)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 0, 0),
                            child: GestureDetector(
                              onTap: () => onTapGridSerie(
                                  seriesByGenre[genre.id]!, context),
                              child: Row(
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
                                itemCount: seriesByGenre[genre.id]?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final serie = seriesByGenre[genre.id]![index];
                                  return GestureDetector(
                                    onTap: () =>
                                        Platform.isAndroid || Platform.isIOS
                                            ? onTapSerie(
                                                serie.name, serie.id, context)
                                            : onTapSerieDesktop(
                                                serie.name, serie.id, context),
                                    child: CustomSeriesWidget(
                                      serie: serie,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            )),
          ],
        ),
        bottomNavigationBar: const BottomBar());
  }
}
