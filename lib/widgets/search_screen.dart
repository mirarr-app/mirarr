import 'dart:convert';
import 'dart:async';
import 'dart:ui';
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

  late FocusNode _searchFocusNode;

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
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode = FocusNode(onKeyEvent: _handleSearchFocusKey);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
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
            releaseDate: result['release_date'] ?? '',
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] ?? '',
            backdropPath: result['backdrop_path'] ?? '',
            score: result['vote_average'] ?? 0.0);
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
          score: result['vote_average'] ?? 0.0,
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
          department: result['known_for_department'] ?? '',
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

  String _getSearchLabelText() {
    switch (_tabController.index) {
      case 0:
        return 'Search for movies...';
      case 1:
        return 'Search for TV shows...';
      case 2:
        return 'Search for people...';
      default:
        return 'Search...';
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            "No results found for '$query'",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieTab() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _buildEmptyState('Type to search for movies', Icons.movie_outlined);
    }
    if (movieResults.isEmpty) {
      return _buildNoResultsState(query);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 5
            : width > 800
                ? 4
                : width > 600
                    ? 3
                    : 2;

        return ScrollConfiguration(
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
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.77,
            ),
            itemCount: movieResults.length,
            itemBuilder: (context, index) {
              final movie = movieResults[index];
              return TvFocusWrapper(
                borderRadius: 16.0,
                onTap: () => onTapMovie(movie.title, movie.id, context),
                child: MovieSearchResult(
                  movie: movie,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTvTab() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _buildEmptyState('Type to search for TV shows', Icons.tv_outlined);
    }
    if (tvResults.isEmpty) {
      return _buildNoResultsState(query);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 5
            : width > 800
                ? 4
                : width > 600
                    ? 3
                    : 2;

        return ScrollConfiguration(
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
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.77,
            ),
            itemCount: tvResults.length,
            itemBuilder: (context, index) {
              final serie = tvResults[index];
              return TvFocusWrapper(
                borderRadius: 16.0,
                onTap: () => onTapSerie(serie.name, serie.id, context),
                child: SerieSearchResult(
                  serie: serie,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _buildEmptyState('Type to search for people', Icons.people_outline);
    }
    if (personResults.isEmpty) {
      return _buildNoResultsState(query);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 6
            : width > 800
                ? 4
                : width > 600
                    ? 3
                    : 2;

        return ScrollConfiguration(
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
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: personResults.length,
            itemBuilder: (context, index) {
              final person = personResults[index];
              return TvFocusWrapper(
                borderRadius: 16.0,
                onTap: () => person.department == 'Acting'
                    ? onTapCast(context, person.id)
                    : onTapCrew(context, person.id),
                child: PersonSearchResult(
                  person: person,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDiscoverTab = _tabController.index == 3;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Unified search bar at the top, only shown if not on the Discover tab
            if (!isDiscoverTab)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: TextField(
                      focusNode: _searchFocusNode,
                      autocorrect: false,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      cursorColor: Theme.of(context).primaryColor,
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: _getSearchLabelText(),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900]!.withValues(alpha: 0.6),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
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
                ),
              ),

            // Premium pill-shaped TabBar
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = MediaQuery.of(context).size.width;
                final bool isMobileWidth = width < 600;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: !isMobileWidth,
                    tabAlignment: isMobileWidth ? null : TabAlignment.center,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).primaryColor,
                    ),
                    tabs: [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobileWidth ? 4.0 : 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMobileWidth) ...const [
                                Icon(Icons.movie_outlined, size: 18),
                                SizedBox(width: 8),
                              ],
                              const Text('Movies'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobileWidth ? 4.0 : 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMobileWidth) ...const [
                                Icon(Icons.tv_outlined, size: 18),
                                SizedBox(width: 8),
                              ],
                              const Text('TV Shows'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobileWidth ? 4.0 : 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMobileWidth) ...const [
                                Icon(Icons.people_outline, size: 18),
                                SizedBox(width: 8),
                              ],
                              const Text('People'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobileWidth ? 4.0 : 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMobileWidth) ...const [
                                Icon(Icons.explore_outlined, size: 18),
                                SizedBox(width: 8),
                              ],
                              const Text('Discover'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Main result content area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMovieTab(),
                  _buildTvTab(),
                  _buildPeopleTab(),
                  DiscoverMoviesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
