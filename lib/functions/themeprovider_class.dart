import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme;
  SharedPreferences? _prefs;

  bool _isOmarchyLinux = false;
  bool get isOmarchyLinux => _isOmarchyLinux;

  ThemeData? _omarchyTheme;
  ThemeData? get omarchyTheme => _omarchyTheme;

  StreamSubscription<io.FileSystemEvent>? _fileSubscription;

  ThemeProvider(this._currentTheme) {
    loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;

  void setTheme(ThemeData theme) async {
    _currentTheme = theme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setOmarchyTheme() async {
    if (_isOmarchyLinux) {
      final colors = await _loadOmarchyColors();
      _omarchyTheme = _buildOmarchyThemeFromColors(colors);
      setTheme(_omarchyTheme!);
    }
  }

  Future<bool> _checkOmarchyLinux() async {
    if (kIsWeb) return false;
    if (!io.Platform.isLinux) return false;
    try {
      final result = await io.Process.run('omarchy', ['version']);
      if (result.exitCode == 0) {
        final stdout = result.stdout.toString().trim();
        return stdout.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, Color>> _loadOmarchyColors() async {
    final Map<String, Color> colors = {};
    try {
      final home = io.Platform.environment['HOME'];
      if (home == null) return colors;
      final file = io.File('$home/.config/omarchy/current/theme/colors.toml');
      if (!await file.exists()) return colors;

      final lines = await file.readAsLines();
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final eqIndex = line.indexOf('=');
        if (eqIndex == -1) continue;

        final key = line.substring(0, eqIndex).trim();
        var val = line.substring(eqIndex + 1).trim();

        // Strip quotes
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }

        if (val.startsWith('#')) {
          final color = _parseHexColor(val);
          if (color != null) {
            colors[key] = color;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing Omarchy colors: $e');
    }
    return colors;
  }

  Color? _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
      }
      if (hexString.length == 6) {
        buffer.write('ff');
        buffer.write(hexString);
      } else if (hexString.length == 8) {
        buffer.write(hexString);
      } else {
        return null;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  ThemeData _buildOmarchyThemeFromColors(Map<String, Color> colors) {
    final accent = colors['accent'] ?? Colors.blueGrey;
    final bg = colors['background'] ?? Colors.black;
    final fg = colors['foreground'] ?? Colors.white;
    final error = colors['color1'] ?? Colors.red;
    final hint = colors['color8'] ?? colors['color7'] ?? Colors.grey[400]!;

    return ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
          TargetPlatform.values,
          value: (_) => const FadeForwardsPageTransitionsBuilder(),
        ),
      ),
      fontFamily: 'RobotoMono',
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: accent,
        onPrimary: fg,
        secondary: accent,
        onSecondary: fg,
        error: error,
        onError: fg,
        surface: bg,
        onSurface: fg,
      ),
      highlightColor: accent,
      secondaryHeaderColor: accent,
      hintColor: hint,
      cardColor: accent,
      scaffoldBackgroundColor: bg,
      focusColor: accent.withValues(alpha: 0.3),
      hoverColor: accent.withValues(alpha: 0.15),
      listTileTheme: ListTileThemeData(
        selectedColor: accent,
      ),
    );
  }

  void _startWatchingColorsFile() {
    _fileSubscription?.cancel();
    try {
      final home = io.Platform.environment['HOME'];
      if (home == null) return;
      final dir = io.Directory('$home/.config/omarchy/current/theme');
      if (!dir.existsSync()) return;

      _fileSubscription = dir.watch().listen((event) async {
        if (event.path.endsWith('colors.toml')) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (_prefs?.getString('theme') == 'omarchy') {
            await _reloadOmarchyThemeColors();
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting file watch: $e');
    }
  }

  Future<void> _reloadOmarchyThemeColors() async {
    final colors = await _loadOmarchyColors();
    _omarchyTheme = _buildOmarchyThemeFromColors(colors);
    _currentTheme = _omarchyTheme!;
    notifyListeners();
  }

  Future<void> loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isOmarchyLinux = await _checkOmarchyLinux();

    if (_isOmarchyLinux) {
      _startWatchingColorsFile();
    }

    String? themeName = _prefs?.getString('theme');
    if (themeName != null) {
      if (themeName == 'omarchy' && _isOmarchyLinux) {
        final colors = await _loadOmarchyColors();
        _omarchyTheme = _buildOmarchyThemeFromColors(colors);
        _currentTheme = _omarchyTheme!;
      } else {
        switch (themeName) {
          case 'orange':
            _currentTheme = AppThemes.orangeTheme;
            break;
          case 'blue':
            _currentTheme = AppThemes.blueTheme;
            break;
          case 'red':
            _currentTheme = AppThemes.redTheme;
            break;
          case 'brown':
            _currentTheme = AppThemes.brownTheme;
            break;
          case 'grey':
            _currentTheme = AppThemes.greyTheme;
            break;
          case 'yellow':
            _currentTheme = AppThemes.yellowTheme;
            break;
          case 'green':
            _currentTheme = AppThemes.greenTheme;
            break;
          case 'mono':
            _currentTheme = AppThemes.monoFontTheme;
            break;
          case 'nothing':
            _currentTheme = AppThemes.nothingFontTheme;
            break;
          // Add more cases for additional themes
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    String themeName = 'orange'; // Default
    if (_currentTheme == AppThemes.blueTheme) {
      themeName = 'blue';
    } else if (_currentTheme == AppThemes.redTheme) {
      themeName = 'red';
    } else if (_currentTheme == AppThemes.brownTheme) {
      themeName = 'brown';
    } else if (_currentTheme == AppThemes.greyTheme) {
      themeName = 'grey';
    } else if (_currentTheme == AppThemes.yellowTheme) {
      themeName = 'yellow';
    } else if (_currentTheme == AppThemes.greenTheme) {
      themeName = 'green';
    } else if (_currentTheme == AppThemes.monoFontTheme) {
      themeName = 'mono';
    } else if (_currentTheme == AppThemes.nothingFontTheme) {
      themeName = 'nothing';
    } else if (_currentTheme == _omarchyTheme) {
      themeName = 'omarchy';
    }
    await _prefs?.setString('theme', themeName);
  }

  @override
  void dispose() {
    _fileSubscription?.cancel();
    super.dispose();
  }
}

class AppThemes {
  static final ThemeData orangeTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromARGB(255, 255, 161, 20),
      onPrimary: Colors.orange,
      secondary: Colors.orangeAccent,
      onSecondary: Colors.deepOrange,
      error: Colors.red,
      onError: Colors.orange,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.deepOrange,
    secondaryHeaderColor: Colors.deepOrange,
    hintColor: Colors.orangeAccent[200],
    cardColor: Colors.orange,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.deepOrange.withValues(alpha: 0.3),
    hoverColor: Colors.deepOrange.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.deepOrange,
    ),
  );

  static final ThemeData blueTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.blue,
      onPrimary: Colors.lightBlue,
      secondary: Colors.lightBlueAccent,
      onSecondary: Colors.blueAccent,
      error: Colors.red,
      onError: Colors.blue,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueAccent,
    secondaryHeaderColor: Colors.blueAccent,
    hintColor: Colors.lightBlue[200],
    cardColor: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.blueAccent.withValues(alpha: 0.3),
    hoverColor: Colors.blueAccent.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.blueAccent,
    ),
  );

  static final ThemeData redTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.red,
      onPrimary: Colors.redAccent,
      secondary: Colors.pink,
      onSecondary: Colors.pinkAccent,
      error: Colors.deepOrange,
      onError: Colors.red,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.redAccent,
    secondaryHeaderColor: Colors.redAccent,
    hintColor: Colors.red[200],
    cardColor: Colors.red,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.redAccent.withValues(alpha: 0.3),
    hoverColor: Colors.redAccent.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.redAccent,
    ),
  );

  static final ThemeData greyTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.grey,
      onPrimary: Colors.blueGrey,
      secondary: Colors.blueGrey,
      onSecondary: Colors.grey,
      error: Colors.red,
      onError: Colors.grey,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueGrey,
    secondaryHeaderColor: Colors.blueGrey,
    hintColor: Colors.grey[400],
    cardColor: Colors.grey,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.blueGrey.withValues(alpha: 0.3),
    hoverColor: Colors.blueGrey.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.blueGrey,
    ),
  );

  static final ThemeData yellowTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.yellow,
      onPrimary: Colors.amber,
      secondary: Colors.amber,
      onSecondary: Colors.yellowAccent,
      error: Colors.red,
      onError: Colors.yellow,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.amber,
    secondaryHeaderColor: Colors.amber,
    hintColor: Colors.yellow[200],
    cardColor: Colors.yellow,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.amber.withValues(alpha: 0.3),
    hoverColor: Colors.amber.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.amber,
    ),
  );

  static final ThemeData brownTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.brown,
      onPrimary: Colors.amber,
      secondary: Colors.amber,
      onSecondary: Colors.brown,
      error: Colors.red,
      onError: Colors.brown,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.amber,
    secondaryHeaderColor: Colors.amber,
    hintColor: Colors.brown[200],
    cardColor: Colors.brown,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.amber.withValues(alpha: 0.3),
    hoverColor: Colors.amber.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.amber,
    ),
  );
  static final ThemeData greenTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.green,
      onPrimary: Colors.lightGreen,
      secondary: Colors.lightGreenAccent,
      onSecondary: Colors.greenAccent,
      error: Colors.red,
      onError: Colors.green,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.greenAccent,
    secondaryHeaderColor: Colors.greenAccent,
    hintColor: Colors.lightGreen[200],
    cardColor: Colors.green,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.greenAccent.withValues(alpha: 0.3),
    hoverColor: Colors.greenAccent.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.greenAccent,
    ),
  );
  static final ThemeData monoFontTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'RobotoMono',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.grey,
      onPrimary: Colors.blueGrey,
      secondary: Colors.blueGrey,
      onSecondary: Colors.grey,
      error: Colors.red,
      onError: Colors.grey,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueGrey,
    secondaryHeaderColor: Colors.blueGrey,
    hintColor: Colors.grey[400],
    cardColor: Colors.grey,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.blueGrey.withValues(alpha: 0.3),
    hoverColor: Colors.blueGrey.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.blueGrey,
    ),
  );

  static final ThemeData nothingFontTheme = ThemeData(
    progressIndicatorTheme: const ProgressIndicatorThemeData(),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    fontFamily: 'Nothing',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.grey,
      onPrimary: Colors.blueGrey,
      secondary: Colors.blueGrey,
      onSecondary: Colors.grey,
      error: Colors.red,
      onError: Colors.grey,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueGrey,
    secondaryHeaderColor: Colors.blueGrey,
    hintColor: Colors.grey[400],
    cardColor: Colors.grey,
    scaffoldBackgroundColor: Colors.black,
    focusColor: Colors.blueGrey.withValues(alpha: 0.3),
    hoverColor: Colors.blueGrey.withValues(alpha: 0.15),
    listTileTheme: const ListTileThemeData(
      selectedColor: Colors.blueGrey,
    ),
  );
}
