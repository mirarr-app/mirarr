import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:Mirarr/functions/platform_helper.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/UI/cast_crew_row.dart';
import 'package:Mirarr/moviesPage/UI/movie_result.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/seriesPage/UI/serie_result.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/widgets/discover/discover_with_filters.dart';
import 'package:Mirarr/widgets/models/person.dart';
import 'package:Mirarr/widgets/person_result.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:provider/provider.dart';

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
  List<Person> personResults = [];

  final apiKey = dotenv.env['TMDB_API_KEY'];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late FocusNode _movieSearchFocusNode;
  late FocusNode _tvSearchFocusNode;
  late FocusNode _peopleSearchFocusNode;

  KeyEventResult _handleSearchFocusKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && TvFocusModeManager.isTvFocusMode.value) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        node.focusInDirection(TraversalDirection.down);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        node.focusInDirection(TraversalDirection.up);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _movieSearchFocusNode = FocusNode(onKeyEvent: _handleSearchFocusKey);
    _tvSearchFocusNode = FocusNode(onKeyEvent: _handleSearchFocusKey);
    _peopleSearchFocusNode = FocusNode(onKeyEvent: _handleSearchFocusKey);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      String query = _searchController.text.trim();
      if (query.isNotEmpty) {
        if (mounted) {
          searchMovies(query, context);
          searchSeries(query, context);
          searchPerson(query, context);
        }
      } else {
        setState(() {
          movieResults.clear();
          tvResults.clear();
          personResults.clear();
        });
      }
    });
  }

  Future<void> searchMovies(String query, BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}search/movie?api_key=$apiKey&query=$query',
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

  Future<void> searchSeries(String query, BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}search/tv?api_key=$apiKey&query=$query',
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

  Future<void> searchPerson(String query, BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final response = await http.get(
      Uri.parse(
        '${baseUrl}search/person?api_key=$apiKey&query=$query',
      ),
    );
    if (response.statusCode == 200) {
      final List<Person> persons = [];
      final List<dynamic> results = json.decode(response.body)['results'];

      for (var result in results) {
        final person = Person(
          name: result['name'],
          profilePath: result['profile_path'] ?? '',
          id: result['id'],
          department: result['known_for_department'],
        );
        persons.add(person);
      }

      setState(() {
        personResults = persons;
      });
    } else {
      throw Exception('Failed to load people data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
extendBody: true,
      appBar: TabBar(
        labelColor: Colors.black,
        padding: AppPlatform.isMobile
            ? const EdgeInsets.fromLTRB(0, 32, 0, 0)
            : const EdgeInsets.fromLTRB(0, 0, 0, 0),
        indicator: BoxDecoration(color: Theme.of(context).primaryColor),
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.movie),
          ),
          Tab(
            icon: Icon(Icons.local_movies),
          ),
          Tab(
            icon: Icon(Icons.people),
          ),
          Tab(
            icon: Icon(Icons.explore),
          )
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
                  focusNode: _movieSearchFocusNode,
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
                    fillColor: Theme.of(context).hintColor,
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
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
                            return TvFocusWrapper(
                              borderRadius: 12.0,
                              onTap: () => onTapMovie(movie.title, movie.id, context),
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
                  focusNode: _tvSearchFocusNode,
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
                    fillColor: Theme.of(context).hintColor,
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
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
                            return TvFocusWrapper(
                              borderRadius: 12.0,
                              onTap: () => onTapSerie(serie.name, serie.id, context),
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
                child: TextField(
                  focusNode: _peopleSearchFocusNode,
                  autocorrect: false,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Search for People',
                    labelStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    filled: false,
                    fillColor: Theme.of(context).hintColor,
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
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
                          personResults.clear();
                        });
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: personResults.isEmpty
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
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                AppPlatform.isMobile ? 2 : 6,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: personResults.length,
                          itemBuilder: (context, index) {
                            final person = personResults[index];
                            return TvFocusWrapper(
                              borderRadius: 12.0,
                              onTap: () => person.department == 'Acting'
                                  ? onTapCast(context, person.id)
                                  : onTapCrew(context, person.id),
                              child: PersonSearchResult(
                                person: person,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          DiscoverMoviesPage(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _movieSearchFocusNode.dispose();
    _tvSearchFocusNode.dispose();
    _peopleSearchFocusNode.dispose();
    super.dispose();
  }
}
