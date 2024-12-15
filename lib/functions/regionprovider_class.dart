import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RegionProvider extends ChangeNotifier {
  String _currentRegion = 'worldwide';
  SharedPreferences? _prefs;

  RegionProvider(this._currentRegion) {
    loadRegion();
  }

  String get currentRegion => _currentRegion;

  void setRegion(String region) async {
    _currentRegion = region;
    notifyListeners();
    await _saveRegion();
  }

  Future<void> loadRegion() async {
    _prefs = await SharedPreferences.getInstance();
    String? region = _prefs?.getString('region');
    if (region != null) {
      switch (region) {
        case 'iran':
          _currentRegion = 'iran';
          break;
        case 'worldwide':
          _currentRegion = 'worldwide';
          break;
      }
    }
  }

  Future<void> _saveRegion() async {
    String regionName = 'worldwide';
    switch (_currentRegion) {
      case 'iran':
        regionName = 'iran';
        break;
      case 'worldwide':
        regionName = 'worldwide';
        break;
    }
    await _prefs?.setString('region', regionName);
  }
}

class Region {
  static const String iran = 'iran';
  static const String worldwide = 'worldwide';
}
