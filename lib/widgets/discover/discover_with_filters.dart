import 'dart:async';
import 'dart:ui';

import 'package:Mirarr/functions/get_base_url.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/moviesPage/UI/customMovieWidget.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:Mirarr/widgets/discover/genre_chips.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class Human {
  final int id;
  final String name;

  Human({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Human && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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
  RangeValues _yearRange = const RangeValues(1900, 2026);
  List<Movie> movies = [];
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
            releaseDate: result['release_date'] ?? '',
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
    IconData? iconData;
    switch (selection) {
      case GenreSelection.include:
        chipColor = Colors.green;
        iconData = Icons.add;
        break;
      case GenreSelection.exclude:
        chipColor = Colors.red;
        iconData = Icons.remove;
        break;
      case GenreSelection.none:
        chipColor = Colors.grey;
        iconData = null;
    }

    final isSelected = selection != GenreSelection.none;

    return FilterChip(
      label: Text(genre.name, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => _toggleGenre(genre),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: chipColor.withValues(alpha: 0.15),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.white.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: iconData != null
          ? Icon(
              iconData,
              color: chipColor,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildAndGenreCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          activeColor: Theme.of(context).primaryColor,
          checkColor: Colors.black,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          value: _andGenreSearch,
          onChanged: _toggleAndGenre,
        ),
        Text(
          'All selected',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
        ),
      ],
    );
  }

  void _showGenreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[950],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: GenreBottomSheet(
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeopleSearchSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actors & Crew',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: Theme.of(context).primaryColor,
                  checkColor: Colors.black,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  value: _andPersonSearch,
                  onChanged: _toggleAndPerson,
                ),
                Text(
                  _andPersonSearch ? 'All match' : 'Any match',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Autocomplete<Human>(
          displayStringForOption: (Human option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<Human>.empty();
            }
            if (_debounce?.isActive ?? false) {
              _debounce!.cancel();
            }

            final completer = Completer<Iterable<Human>>();
            _debounce = Timer(const Duration(milliseconds: 500), () async {
              if (!mounted) {
                completer.complete([]);
                return;
              }
              try {
                final results = await _searchActors(textEditingValue.text, context);
                completer.complete(results);
              } catch (e) {
                completer.complete([]);
              }
            });

            return completer.future;
          },
          onSelected: _addPerson,
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            _peopleSearchController = fieldTextEditingController;
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for people...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.grey[900]!.withValues(alpha: 0.8),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Human option = options.elementAt(index);
                      return ListTile(
                        onTap: () => onSelected(option),
                        title: Text(
                          option.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (andSelectedPeople.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            children: andSelectedPeople
                .map((person) => InputChip(
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      selectedColor: Theme.of(context).primaryColor,
                      label: Text(
                        person.name,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: Theme.of(context).primaryColor,
                      onDeleted: () => _removePerson(person),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildYearRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Year Range',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              '${_yearRange.start.round()} - ${_yearRange.end.round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _yearRange,
          min: 1900,
          max: 2026,
          divisions: 126,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Colors.white.withValues(alpha: 0.1),
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
      ],
    );
  }

  Widget _buildDesktopGenresSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Genres',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            _buildAndGenreCheckbox(),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: allGenres.map(_buildGenreChip).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileGenresSection(BuildContext context) {
    final selectedGenres = genreSelections.entries
        .where((e) => e.value != GenreSelection.none)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Genres',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedGenres.isNotEmpty)
                Text(
                  '${selectedGenres.length} selected',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor, size: 16),
            ],
          ),
          onTap: () => _showGenreBottomSheet(context),
        ),
        if (selectedGenres.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            children: selectedGenres.map((entry) {
              final genre = allGenres.firstWhere((g) => g.id == entry.key);
              final isInclude = entry.value == GenreSelection.include;
              return Chip(
                padding: EdgeInsets.zero,
                backgroundColor: isInclude ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                side: BorderSide(color: isInclude ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                label: Text(
                  genre.name,
                  style: TextStyle(
                    color: isInclude ? Colors.green : Colors.red,
                    fontSize: 11,
                  ),
                ),
                onDeleted: () => _toggleGenre(genre),
                deleteIcon: Icon(
                  Icons.close,
                  size: 12,
                  color: isInclude ? Colors.green : Colors.red,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search_rounded, color: Colors.black, size: 20),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: () => _fetchMovies(context),
        label: const Text(
          'Search Movies',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsGrid(BuildContext context, int columns) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_filter_outlined, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Customize your filters and press Search to discover movies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: TvFocusModeManager.isTvDevice ? 12 : BottomBar.getHeight(context),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return TvFocusWrapper(
          borderRadius: 16.0,
          onTap: () => onTapMovie(movie.title, movie.id, context),
          child: CustomMovieWidget(movie: movie),
        );
      },
    );
  }

  Widget _buildSplitPane(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey[950],
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPeopleSearchSection(context),
                  const SizedBox(height: 24),
                  _buildYearRangeSection(context),
                  const SizedBox(height: 24),
                  _buildDesktopGenresSection(context),
                  const SizedBox(height: 32),
                  _buildSearchButton(context),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth;
                final columns = gridWidth > 1200
                    ? 5
                    : gridWidth > 800
                        ? 4
                        : gridWidth > 500
                            ? 3
                            : 2;
                return _buildResultsGrid(context, columns);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Search Filters',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildPeopleSearchSection(context),
              const SizedBox(height: 16),
              _buildYearRangeSection(context),
              const SizedBox(height: 16),
              _buildMobileGenresSection(context),
              const SizedBox(height: 20),
              _buildSearchButton(context),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridWidth = constraints.maxWidth;
              final columns = gridWidth > 600 ? 3 : 2;
              return _buildResultsGrid(context, columns);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useSplitPane = screenWidth > 900;

    return Scaffold(
      extendBody: true,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: useSplitPane ? _buildSplitPane(context) : _buildMobileLayout(context),
      ),
    );
  }
}
