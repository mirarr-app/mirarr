import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'dart:async';
import 'package:Mirarr/seriesPage/UI/customSeriesWidget.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';

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

  // Fetch trending Series
  Future<void> fetchTrendingSeries() async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/trending/tv/day?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final List<Serie> series = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final serie = Serie(
            name: result['name'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'] ?? '');
        series.add(serie);
      }

      setState(() {
        trendingSeries = series;
      });
    } else {
      throw Exception('Failed to load trending series data');
    }
  }

// Fetch popular series
  Future<void> fetchPopularSeries() async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/tv/popular?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final List<Serie> series = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final serie = Serie(
            name: result['name'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'] ?? '');
        series.add(serie);
      }

      setState(() {
        popularSeries = series;
      });
    } else {
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
            titleTextStyle:
                const TextStyle(color: Colors.orangeAccent, fontSize: 20),
            contentTextStyle:
                const TextStyle(color: Colors.orange, fontSize: 16),
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
  }

  Future<void> checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      handleNetworkError(ClientException('No internet connection'));
    } else {
      // Internet connection available, fetch data
      fetchTrendingSeries();
      fetchPopularSeries();
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
                    )
                  ],
                ),
              ),
            )),
          ],
        ),
        bottomNavigationBar: const BottomBar());
  }
}
