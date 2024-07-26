import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:Mirarr/moviesPage/UI/movie_result.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:Mirarr/seriesPage/UI/serie_result.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Movie> movieResults = [];
  List<Serie> tvResults = [];
  final apiKey = dotenv.env['TMDB_API_KEY'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      searchMovies(query);
      searchSeries(query);
    } else {
      setState(() {
        movieResults.clear();
        tvResults.clear();
      });
    }
  }

  Future<void> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query',
      ),
    );
    if (response.statusCode == 200) {
      final List<Movie> movies = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final movie = Movie(
            title: result['title'],
            releaseDate: result['release_date'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] ?? '',
            backdropPath: result['backdrop_path'] ?? '',
            score: result['vote_average'] ?? '');
        movies.add(movie);
      }

      setState(() {
        movieResults = movies;
      });
    } else {
      throw Exception('Failed to load movie data');
    }
  }

  Future<void> searchSeries(String query) async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/search/tv?api_key=$apiKey&query=$query',
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
          backdropPath: result['backdrop_path'] ?? '',
          score: result['vote_average'] ?? '',
        );
        series.add(serie);
      }

      setState(() {
        tvResults = series;
      });
    } else {
      throw Exception('Failed to load serie data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        labelColor: Colors.black,
        padding: Platform.isAndroid || Platform.isIOS
            ? const EdgeInsets.fromLTRB(0, 32, 0, 0)
            : const EdgeInsets.fromLTRB(0, 0, 0, 0),
        indicator: const BoxDecoration(color: Colors.orange),
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        controller: _tabController,
        tabs: const [
          Tab(
            text: 'Movies',
          ),
          Tab(text: 'TV'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
                child: TextField(
                  autocorrect: false,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Search for a movie',
                    labelStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    filled: false,
                    fillColor: Colors.orangeAccent[200],
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    suffixIcon: IconButton(
                      icon: Visibility(
                        visible: _searchController.text.isNotEmpty,
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          movieResults.clear();
                          tvResults.clear();
                        });
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: movieResults.isEmpty
                    ? Container()
                    : ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          physics: const BouncingScrollPhysics(),
                          scrollbars: true,
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.builder(
                          itemCount: movieResults.length,
                          itemBuilder: (context, index) {
                            final movie = movieResults[index];
                            return GestureDetector(
                              onTap: () => Platform.isAndroid || Platform.isIOS
                                  ? onTapMovie(movie.title, movie.id, context)
                                  : onTapMovieDesktop(
                                      movie.title, movie.id, context),
                              child: MovieSearchResult(
                                movie: movie,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
                child: TextField(
                  autocorrect: false,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Search for a TV show',
                    labelStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    filled: false,
                    fillColor: Colors.orangeAccent[200],
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    suffixIcon: IconButton(
                      icon: Visibility(
                        visible: _searchController.text.isNotEmpty,
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          movieResults.clear();
                          tvResults.clear();
                        });
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: tvResults.isEmpty
                    ? Container()
                    : ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          physics: const BouncingScrollPhysics(),
                          scrollbars: true,
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.builder(
                          itemCount: tvResults.length,
                          itemBuilder: (context, index) {
                            final serie = tvResults[index];
                            return GestureDetector(
                              onTap: () => Platform.isAndroid || Platform.isIOS
                                  ? onTapSerie(serie.name, serie.id, context)
                                  : onTapSerieDesktop(
                                      serie.name, serie.id, context),
                              child: SerieSearchResult(
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
      bottomNavigationBar: BottomBar(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
