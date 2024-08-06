import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme;
  SharedPreferences? _prefs;

  ThemeProvider(this._currentTheme) {
    loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;

  void setTheme(ThemeData theme) async {
    _currentTheme = theme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    String? themeName = _prefs?.getString('theme');
    if (themeName != null) {
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
        // Add more cases for additional themes
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
    }
    await _prefs?.setString('theme', themeName);
  }
}

class AppThemes {
  static final ThemeData orangeTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromARGB(255, 255, 161, 20),
      onPrimary: Colors.orange,
      secondary: Colors.orangeAccent,
      onSecondary: Colors.deepOrange,
      error: Colors.red,
      onError: Colors.orange,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.deepOrange,
    secondaryHeaderColor: Colors.deepOrange,
    hintColor: Colors.orangeAccent[200],
    cardColor: Colors.orange,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData blueTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.blue,
      onPrimary: Colors.lightBlue,
      secondary: Colors.lightBlueAccent,
      onSecondary: Colors.blueAccent,
      error: Colors.red,
      onError: Colors.blue,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueAccent,
    secondaryHeaderColor: Colors.blueAccent,
    hintColor: Colors.lightBlue[200],
    cardColor: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData redTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.red,
      onPrimary: Colors.redAccent,
      secondary: Colors.pink,
      onSecondary: Colors.pinkAccent,
      error: Colors.deepOrange,
      onError: Colors.red,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.redAccent,
    secondaryHeaderColor: Colors.redAccent,
    hintColor: Colors.red[200],
    cardColor: Colors.red,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData greyTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.grey,
      onPrimary: Colors.blueGrey,
      secondary: Colors.blueGrey,
      onSecondary: Colors.grey,
      error: Colors.red,
      onError: Colors.grey,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueGrey,
    secondaryHeaderColor: Colors.blueGrey,
    hintColor: Colors.grey[400],
    cardColor: Colors.grey,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData yellowTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.yellow,
      onPrimary: Colors.amber,
      secondary: Colors.amber,
      onSecondary: Colors.yellowAccent,
      error: Colors.red,
      onError: Colors.yellow,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.amber,
    secondaryHeaderColor: Colors.amber,
    hintColor: Colors.yellow[200],
    cardColor: Colors.yellow,
    scaffoldBackgroundColor: Colors.black,
  );

  static final ThemeData brownTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.brown,
      onPrimary: Colors.amber,
      secondary: Colors.amber,
      onSecondary: Colors.brown,
      error: Colors.red,
      onError: Colors.brown,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.amber,
    secondaryHeaderColor: Colors.amber,
    hintColor: Colors.brown[200],
    cardColor: Colors.brown,
    scaffoldBackgroundColor: Colors.black,
  );
  static final ThemeData greenTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.green,
      onPrimary: Colors.lightGreen,
      secondary: Colors.lightGreenAccent,
      onSecondary: Colors.greenAccent,
      error: Colors.red,
      onError: Colors.green,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.greenAccent,
    secondaryHeaderColor: Colors.greenAccent,
    hintColor: Colors.lightGreen[200],
    cardColor: Colors.green,
    scaffoldBackgroundColor: Colors.black,
  );
  static final ThemeData monoFontTheme = ThemeData(
    fontFamily: 'RobotoMono',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Colors.grey,
      onPrimary: Colors.blueGrey,
      secondary: Colors.blueGrey,
      onSecondary: Colors.grey,
      error: Colors.red,
      onError: Colors.grey,
      background: Colors.black,
      onBackground: Colors.black,
      surface: Colors.black,
      onSurface: Colors.black,
    ),
    highlightColor: Colors.blueGrey,
    secondaryHeaderColor: Colors.blueGrey,
    hintColor: Colors.grey[400],
    cardColor: Colors.grey,
    scaffoldBackgroundColor: Colors.black,
  );
}
