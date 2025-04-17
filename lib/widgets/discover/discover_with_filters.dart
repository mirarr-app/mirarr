import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:Mirarr/widgets/discover/genre_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class Human {
  final int id;
  final String name;

  Human({required this.id, required this.name});
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});
}

enum GenreSelection { include, exclude, none }

class DiscoverMoviesPage extends StatefulWidget {
  @override
  _DiscoverMoviesPageState createState() => _DiscoverMoviesPageState();
}

class _DiscoverMoviesPageState extends State<DiscoverMoviesPage> {
  RangeValues _yearRange = const RangeValues(1900, 2024);
  List<Movie> movies = [];
  int crossAxisCount = Platform.isAndroid || Platform.isIOS ? 2 : 4;
  bool isLoading = false;
  List<Human> andSelectedPeople = [];
  List<Genre> allGenres = [];
  Map<int, GenreSelection> genreSelections = {};
  Timer? _debounce;
  bool _andPersonSearch = false;
  bool _andGenreSearch = false;

  TextEditingController _peopleSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGenres(context);
  }

  Future<void> _fetchGenres(BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final url = Uri.parse('${baseUrl}genre/movie/list?api_key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> genreList = json.decode(response.body)['genres'];
        setState(() {
          allGenres = genreList
              .map((genre) => Genre(id: genre['id'], name: genre['name']))
              .toList();
          genreSelections = {
            for (var genre in allGenres) genre.id: GenreSelection.none
          };
        });
      } else {
        throw Exception('Failed to load genres');
      }
    } catch (e) {
      print('Error fetching genres: $e');
    }
  }

  Future<void> _fetchMovies(BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    setState(() {
      isLoading = true;
    });

    final apiKey = dotenv.env['TMDB_API_KEY'];

    String withPeople = andSelectedPeople
        .map((p) => p.id.toString())
        .join(_andPersonSearch ? ',' : '|');
    String withGenres = genreSelections.entries
        .where((entry) => entry.value == GenreSelection.include)
        .map((entry) => entry.key.toString())
        .join(_andGenreSearch ? ',' : '|');
    String withoutGenres = genreSelections.entries
        .where((entry) => entry.value == GenreSelection.exclude)
        .map((entry) => entry.key.toString())
        .join(',');

    final url = Uri.parse('${baseUrl}discover/movie?api_key=$apiKey'
        '&include_adult=true'
        '&primary_release_date.gte=${_yearRange.start.round()}-01-01'
        '&primary_release_date.lte=${_yearRange.end.round()}-12-31'
        '&with_people=$withPeople'
        '&with_genres=$withGenres'
        '&without_genres=$withoutGenres');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<Movie> fetchedMovies = [];
        final List<dynamic> results = json.decode(response.body)['results'];

        for (var result in results) {
          final movie = Movie(
            title: result['title'],
            releaseDate: result['release_date'],
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'],
            score: result['vote_average'],
          );
          fetchedMovies.add(movie);
        }

        setState(() {
          movies = fetchedMovies;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load movie data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching movies: $e');
    }
  }

  Future<List<Human>> _searchActors(String query, BuildContext context) async {
    if (query.isEmpty) return [];
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final url =
        Uri.parse('${baseUrl}search/person?api_key=$apiKey&query=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body)['results'];
        return results
            .where((result) => result['known_for_department'] == 'Acting')
            .map((result) => Human(
                  id: result['id'],
                  name: result['name'],
                ))
            .toList();
      } else {
        throw Exception('Failed to search people');
      }
    } catch (e) {
      print('Error searching people: $e');
      return [];
    }
  }

  void _toggleAndPerson(bool? value) {
    setState(() {
      _andPersonSearch = value ?? false;
    });
  }

  void _toggleAndGenre(bool? newValue) {
    setState(() {
      _andGenreSearch = newValue ?? false;
    });
  }

  void _addPerson(Human person) {
    if (!andSelectedPeople.contains(person)) {
      setState(() {
        andSelectedPeople.add(person);
        _peopleSearchController.clear();
      });
    }
  }

  void _removePerson(Human person) {
    setState(() {
      andSelectedPeople.remove(person);
    });
  }

  void _toggleGenre(Genre genre) {
    setState(() {
      final currentSelection = genreSelections[genre.id] ?? GenreSelection.none;
      switch (currentSelection) {
        case GenreSelection.none:
          genreSelections[genre.id] = GenreSelection.include;
          break;
        case GenreSelection.include:
          genreSelections[genre.id] = GenreSelection.exclude;
          break;
        case GenreSelection.exclude:
          genreSelections[genre.id] = GenreSelection.none;
          break;
      }
    });
  }

  Widget _buildGenreChip(Genre genre) {
    final selection = genreSelections[genre.id] ?? GenreSelection.none;
    Color chipColor;
    Widget? avatar;
    switch (selection) {
      case GenreSelection.include:
        chipColor = Colors.green;
        avatar = const Icon(Icons.add, color: Colors.white, size: 18);
        break;
      case GenreSelection.exclude:
        chipColor = Colors.red;
        avatar = const Icon(Icons.remove, color: Colors.white, size: 18);
        break;
      case GenreSelection.none:
      chipColor = Colors.grey;
        avatar = null;
    }

    return FilterChip(
      label: Text(genre.name),
      selected: selection != GenreSelection.none,
      onSelected: (_) => _toggleGenre(genre),
      backgroundColor: Colors.black45,
      selectedColor: chipColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selection != GenreSelection.none ? Colors.white : Colors.white70,
      ),
      avatar: avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<Human>(
                            displayStringForOption: (Human option) =>
                                option.name,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<Human>.empty();
                              }
                              if (_debounce?.isActive ?? false) {
                                _debounce!.cancel();
                              }
                              return _searchActors(
                                  textEditingValue.text, context);
                            },
                            onSelected: _addPerson,
                            fieldViewBuilder: (BuildContext context,
                                TextEditingController
                                    fieldTextEditingController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted) {
                              _peopleSearchController =
                                  fieldTextEditingController;
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                child: TextField(
                                  controller: fieldTextEditingController,
                                  focusNode: fieldFocusNode,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    hintText: 'Search for People',
                                    hintStyle:
                                        const TextStyle(color: Colors.black),
                                    filled: true,
                                    fillColor: Theme.of(context).primaryColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              );
                            },
                            optionsViewBuilder: (BuildContext context,
                                AutocompleteOnSelected<Human> onSelected,
                                Iterable<Human> options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  color: Colors.black87,
                                  child: SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final Human option =
                                            options.elementAt(index);
                                        return GestureDetector(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: ListTile(
                                            title: Text(
                                              option.name,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: Colors.white,
                                checkColor: Theme.of(context).primaryColor,
                                side: const BorderSide(
                                  color: Colors.white,
                                ),
                                value: _andPersonSearch,
                                onChanged: _toggleAndPerson,
                              ),
                              Text(
                                _andPersonSearch ? 'All' : 'Any',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Year Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const CustomDivider(),
                    RangeSlider(
                      values: _yearRange,
                      min: 1900,
                      max: 2024,
                      divisions: 124,
                      activeColor: Colors.white,
                      inactiveColor: Theme.of(context).primaryColor,
                      labels: RangeLabels(
                        _yearRange.start.round().toString(),
                        _yearRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _yearRange = values;
                        });
                      },
                    ),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Wrap(
                          spacing: 8.0,
                          children: andSelectedPeople
                              .map((person) => Chip(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    label: Text(person.name,
                                        style: const TextStyle(
                                            color: Colors.black)),
                                    onDeleted: () => _removePerson(person),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: Platform.isMacOS ||
                          Platform.isWindows ||
                          Platform.isLinux,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Text(
                          'Genres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const CustomDivider(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    children:
                                        allGenres.map(_buildGenreChip).toList(),
                                  ),
                                ),
                              ),
                              _buildAndGenreCheckbox(),
                            ],
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: ListTile(
                              title: Text('Genres',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor)),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  color: Theme.of(context).primaryColor),
                              onTap: () => _showGenreBottomSheet(context),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor),
                        onPressed: () => _fetchMovies(context),
                        child: const Text('Search Movies',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : movies.isEmpty
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Customize your search to get results',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ))
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: movies.length,
                              itemBuilder: (context, index) {
                                final movie = movies[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Platform.isAndroid || Platform.isIOS
                                          ? onTapMovie(
                                              movie.title, movie.id, context)
                                          : onTapMovieDesktop(
                                              movie.title, movie.id, context),
                                  child: CustomMovieWidget(movie: movie),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndGenreCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            activeColor: Colors.white,
            checkColor: Theme.of(context).primaryColor,
            side: const BorderSide(color: Colors.white),
            value: _andGenreSearch,
            onChanged: _toggleAndGenre,
          ),
          const Text(
            'Must have all selected genres',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showGenreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return GenreBottomSheet(
              allGenres: allGenres,
              genreSelections: genreSelections,
              onToggleGenre: (genre) {
                _toggleGenre(genre);
                setModalState(() {});
              },
              andGenreSearch: _andGenreSearch,
              onToggleAndGenre: (bool? newValue) {
                _toggleAndGenre(newValue);
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }
}
