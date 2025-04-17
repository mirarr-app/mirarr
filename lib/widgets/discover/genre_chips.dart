import 'package:flutter/material.dart';

import 'discover_with_filters.dart';

class GenreBottomSheet extends StatefulWidget {
  final List<Genre> allGenres;
  final Map<int, GenreSelection> genreSelections;
  final Function(Genre) onToggleGenre;
  final bool andGenreSearch;
  final Function(bool?) onToggleAndGenre;

  const GenreBottomSheet({
    Key? key,
    required this.allGenres,
    required this.genreSelections,
    required this.onToggleGenre,
    required this.andGenreSearch,
    required this.onToggleAndGenre,
  }) : super(key: key);

  @override
  _GenreBottomSheetState createState() => _GenreBottomSheetState();
}

class _GenreBottomSheetState extends State<GenreBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Select Genres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8.0,
          children:
              widget.allGenres.map((genre) => _buildGenreChip(genre)).toList(),
        ),
        _buildAndGenreCheckbox(),
      ],
    );
  }

  Widget _buildGenreChip(Genre genre) {
    final selection = widget.genreSelections[genre.id] ?? GenreSelection.none;
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
      onSelected: (_) {
        widget.onToggleGenre(genre);
        setState(() {}); // Trigger rebuild
      },
      backgroundColor: Colors.black45,
      selectedColor: chipColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selection != GenreSelection.none ? Colors.white : Colors.white70,
      ),
      avatar: avatar,
    );
  }

  Widget _buildAndGenreCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            activeColor: Colors.white,
            checkColor: Theme.of(context).primaryColor,
            side: const BorderSide(color: Colors.white),
            value: widget.andGenreSearch,
            onChanged: (bool? newValue) {
              widget.onToggleAndGenre(newValue);
              setState(() {}); // Trigger rebuild
            },
          ),
          const Text(
            'Must have all selected genres',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
