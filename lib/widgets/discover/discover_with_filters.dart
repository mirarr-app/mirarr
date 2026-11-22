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
import 'package:Mirarr/services/api_client.dart';
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

class _ActiveDiscoverFilters {
  final RangeValues yearRange;
  final RangeValues ratingRange;
  final String withPeople;
  final String withGenres;
  final String withoutGenres;

  const _ActiveDiscoverFilters({
    required this.yearRange,
    required this.ratingRange,
    required this.withPeople,
    required this.withGenres,
    required this.withoutGenres,
  });
}

class DiscoverMoviesPage extends StatefulWidget {
  final ApiClient? client;

  const DiscoverMoviesPage({Key? key, this.client}) : super(key: key);

  @override
  _DiscoverMoviesPageState createState() => _DiscoverMoviesPageState();
}

class _DiscoverMoviesPageState extends State<DiscoverMoviesPage>
    with AutomaticKeepAliveClientMixin {
  RangeValues _yearRange = const RangeValues(1900, 2026);
  RangeValues _ratingRange = const RangeValues(0.0, 10.0);
  List<Movie> movies = [];
  bool isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  bool _loadMoreError = false;
  String? _fetchError;
  int _currentPage = 1;
  int _totalPages = 1;
  int _discoverFetchId = 0;
  _ActiveDiscoverFilters? _activeFilters;

  @override
  bool get wantKeepAlive => true;

  List<Human> andSelectedPeople = [];
  List<Genre> allGenres = [];
  Map<int, GenreSelection> genreSelections = {};
  Timer? _debounce;
  bool _andPersonSearch = false;
  bool _andGenreSearch = false;

  TextEditingController _peopleSearchController = TextEditingController();

  ApiClient get _apiClient => widget.client ?? apiClient;

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
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> genreList = json.decode(response.body)['genres'];
        if (!mounted) return;
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

  Uri _buildDiscoverUrl(
    String baseUrl,
    String apiKey,
    _ActiveDiscoverFilters filters,
    int page,
  ) {
    final StringBuffer buffer = StringBuffer(
      '${baseUrl}discover/movie?api_key=$apiKey&include_adult=true&page=$page',
    );
    buffer.write(
      '&primary_release_date.gte=${filters.yearRange.start.round()}-01-01',
    );
    buffer.write(
      '&primary_release_date.lte=${filters.yearRange.end.round()}-12-31',
    );

    if (filters.ratingRange.start > 0.0) {
      buffer.write(
        '&vote_average.gte=${filters.ratingRange.start.toStringAsFixed(1)}',
      );
    }
    if (filters.ratingRange.end < 10.0) {
      buffer.write(
        '&vote_average.lte=${filters.ratingRange.end.toStringAsFixed(1)}',
      );
    }

    if (filters.withPeople.isNotEmpty) {
      buffer.write('&with_people=${filters.withPeople}');
    }
    if (filters.withGenres.isNotEmpty) {
      buffer.write('&with_genres=${filters.withGenres}');
    }
    if (filters.withoutGenres.isNotEmpty) {
      buffer.write('&without_genres=${filters.withoutGenres}');
    }

    return Uri.parse(buffer.toString());
  }

  Future<void> _fetchMovies(BuildContext context) async {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final currentFetchId = ++_discoverFetchId;

    final String withPeople = andSelectedPeople
        .map((p) => p.id.toString())
        .join(_andPersonSearch ? ',' : '|');
    final String withGenres = genreSelections.entries
        .where((entry) => entry.value == GenreSelection.include)
        .map((entry) => entry.key.toString())
        .join(_andGenreSearch ? ',' : '|');
    final String withoutGenres = genreSelections.entries
        .where((entry) => entry.value == GenreSelection.exclude)
        .map((entry) => entry.key.toString())
        .join(',');

    final filters = _ActiveDiscoverFilters(
      yearRange: _yearRange,
      ratingRange: _ratingRange,
      withPeople: withPeople,
      withGenres: withGenres,
      withoutGenres: withoutGenres,
    );

    setState(() {
      isLoading = true;
      _isLoadingMore = false;
      _hasSearched = true;
      _fetchError = null;
      _loadMoreError = false;
      _activeFilters = filters;
      _currentPage = 1;
    });

    final url = _buildDiscoverUrl(baseUrl, apiKey ?? '', filters, 1);

    try {
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        if (!mounted || currentFetchId != _discoverFetchId) return;

        final Map<String, dynamic> decoded = json.decode(response.body);
        final List<dynamic> results = decoded['results'] ?? [];
        final List<Movie> fetchedMovies = [];

        for (var result in results) {
          final movie = Movie(
            title: result['title'] ?? '',
            releaseDate: result['release_date'] ?? '',
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] is int
                ? result['id']
                : int.tryParse(result['id']?.toString() ?? '') ?? 0,
            backdropPath: result['backdrop_path'] ?? '',
            score: (result['vote_average'] as num?)?.toDouble(),
          );
          fetchedMovies.add(movie);
        }

        final int totalPages =
            (decoded['total_pages'] as int? ?? 1).clamp(1, 500);

        setState(() {
          movies = fetchedMovies;
          _totalPages = totalPages;
          _currentPage = 1;
          isLoading = false;
          _fetchError = null;
        });
      } else {
        throw Exception('Failed to load movie data (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted || currentFetchId != _discoverFetchId) return;
      setState(() {
        isLoading = false;
        _fetchError = e.toString();
      });
      print('Error fetching movies: $e');
    }
  }

  Future<void> _loadMoreMovies(BuildContext context) async {
    if (isLoading || _isLoadingMore || _activeFilters == null) return;
    if (_currentPage >= _totalPages) return;

    final filters = _activeFilters!;
    final nextPage = _currentPage + 1;
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    final baseUrl = getBaseUrl(region);
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final currentFetchId = _discoverFetchId;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    final url = _buildDiscoverUrl(baseUrl, apiKey ?? '', filters, nextPage);

    try {
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        if (!mounted || currentFetchId != _discoverFetchId) return;

        final Map<String, dynamic> decoded = json.decode(response.body);
        final List<dynamic> results = decoded['results'] ?? [];
        final List<Movie> fetchedMovies = [];

        for (var result in results) {
          final movie = Movie(
            title: result['title'] ?? '',
            releaseDate: result['release_date'] ?? '',
            posterPath: result['poster_path'] ?? '',
            overView: result['overview'] ?? '',
            id: result['id'] is int
                ? result['id']
                : int.tryParse(result['id']?.toString() ?? '') ?? 0,
            backdropPath: result['backdrop_path'] ?? '',
            score: (result['vote_average'] as num?)?.toDouble(),
          );
          fetchedMovies.add(movie);
        }

        final int totalPages =
            (decoded['total_pages'] as int? ?? _totalPages).clamp(1, 500);

        final existingIds = movies.map((m) => m.id).toSet();
        final uniqueNewMovies = fetchedMovies
            .where((m) => !existingIds.contains(m.id))
            .toList();

        setState(() {
          movies.addAll(uniqueNewMovies);
          _currentPage = nextPage;
          _totalPages = totalPages;
          _isLoadingMore = false;
          _loadMoreError = false;
        });
      } else {
        throw Exception('Failed to load more movie data (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted || currentFetchId != _discoverFetchId) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = true;
      });
      print('Error loading more movies: $e');
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
      final response = await _apiClient.get(url);
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          activeColor: colorScheme.primary,
          checkColor: colorScheme.onPrimary,
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
          value: _andGenreSearch,
          onChanged: _toggleAndGenre,
        ),
        const SizedBox(width: 4),
        Text(
          'All selected',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }

  void _showGenreBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Actors & Crew',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  value: _andPersonSearch,
                  onChanged: _toggleAndPerson,
                ),
                const SizedBox(width: 4),
                Text(
                  _andPersonSearch ? 'All match' : 'Any match',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search for people...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                color: colorScheme.surfaceContainerHigh,
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
                          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
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
                      backgroundColor: colorScheme.primaryContainer,
                      selectedColor: colorScheme.primary,
                      label: Text(
                        person.name,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: colorScheme.onPrimaryContainer,
                      onDeleted: () => _removePerson(person),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildYearRangeSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Year Range',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${_yearRange.start.round()} - ${_yearRange.end.round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
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
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
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

  Widget _buildRatingPresetChip(String label, RangeValues range) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = (_ratingRange.start - range.start).abs() < 0.05 &&
        (_ratingRange.end - range.end).abs() < 0.05;

    return TvFocusWrapper(
      borderRadius: 14.0,
      onTap: () {
        setState(() {
          _ratingRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRangeSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'TMDB Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_ratingRange.start.toStringAsFixed(1)} - ${_ratingRange.end.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _ratingRange,
          min: 0.0,
          max: 10.0,
          divisions: 20,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
          labels: RangeLabels(
            _ratingRange.start.toStringAsFixed(1),
            _ratingRange.end.toStringAsFixed(1),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _ratingRange = values;
            });
          },
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: [
            _buildRatingPresetChip('All', const RangeValues(0.0, 10.0)),
            _buildRatingPresetChip('6.0+', const RangeValues(6.0, 10.0)),
            _buildRatingPresetChip('7.0+', const RangeValues(7.0, 10.0)),
            _buildRatingPresetChip('8.0+', const RangeValues(8.0, 10.0)),
            _buildRatingPresetChip('8.5+', const RangeValues(8.5, 10.0)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopGenresSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Genres',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.onSurface,
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
                    color: colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: colorScheme.primary, size: 16),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: Icon(Icons.search_rounded, color: colorScheme.onPrimary, size: 20),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: () => _fetchMovies(context),
        label: Text(
          'Search Movies',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsGrid(BuildContext context, int columns) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    if (_fetchError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load movies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TvFocusWrapper(
                borderRadius: 16.0,
                onTap: () => _fetchMovies(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: colorScheme.onPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Retry',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (movies.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _hasSearched
                    ? Icons.search_off_rounded
                    : Icons.movie_filter_outlined,
                size: 64,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                _hasSearched
                    ? 'No movies found matching your filters'
                    : 'Customize your filters and press Search to discover movies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.axis != Axis.vertical) return false;
        final maxExtent = scrollInfo.metrics.maxScrollExtent;
        final pixels = scrollInfo.metrics.pixels;

        // Ensure list is scrollable and user has scrolled down past threshold
        if (maxExtent > 0 && pixels > 0) {
          final threshold =
              (maxExtent - 300).clamp(maxExtent * 0.7, maxExtent);
          final bool isScrollingDown = scrollInfo is ScrollUpdateNotification
              ? (scrollInfo.scrollDelta ?? 0) > 0
              : true;

          if (isScrollingDown && pixels >= threshold) {
            if (!isLoading &&
                !_isLoadingMore &&
                !_loadMoreError &&
                _currentPage < _totalPages &&
                _activeFilters != null) {
              _loadMoreMovies(context);
            }
          }
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final movie = movies[index];
                  return TvFocusWrapper(
                    borderRadius: 16.0,
                    onTap: () => onTapMovie(movie.title, movie.id, context),
                    child: CustomMovieWidget(movie: movie),
                  );
                },
                childCount: movies.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 24,
                bottom: (TvFocusModeManager.isTvDevice
                        ? 24
                        : BottomBar.getHeight(context)) +
                    24,
              ),
              child: _buildPaginationFooter(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TvFocusWrapper(
            borderRadius: 20.0,
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading more movies...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_currentPage < _totalPages) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TvFocusWrapper(
            borderRadius: 20.0,
            onTap: () => _loadMoreMovies(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Load More (Page ${_currentPage + 1} of $_totalPages)',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'All ${movies.length} movies loaded',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSplitPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              right: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPeopleSearchSection(context),
                  const SizedBox(height: 24),
                  _buildYearRangeSection(context),
                  const SizedBox(height: 24),
                  _buildRatingRangeSection(context),
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
            color: colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Search Filters',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeopleSearchSection(context),
                      const SizedBox(height: 16),
                      _buildYearRangeSection(context),
                      const SizedBox(height: 16),
                      _buildRatingRangeSection(context),
                      const SizedBox(height: 16),
                      _buildMobileGenresSection(context),
                      const SizedBox(height: 20),
                      _buildSearchButton(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
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
    super.build(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
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
