import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider extends ChangeNotifier {
  String? _supabaseUrl;
  String? _supabaseAnonKey;
  bool _isConfigured = false;
  SharedPreferences? _prefs;

  SupabaseProvider() {
    loadSupabaseConfig();
  }

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  bool get isConfigured => _isConfigured;

  Future<void> setSupabaseConfig(String? url, String? anonKey) async {
    _supabaseUrl = url;
    _supabaseAnonKey = anonKey;
    _isConfigured = url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty;
    notifyListeners();
    await _saveSupabaseConfig();
    
    // Initialize Supabase if both URL and key are provided
    if (_isConfigured) {
      await _initializeSupabase();
    }
  }

  Future<void> loadSupabaseConfig() async {
    _prefs = await SharedPreferences.getInstance();
    _supabaseUrl = _prefs?.getString('supabase_url');
    _supabaseAnonKey = _prefs?.getString('supabase_anon_key');
    _isConfigured = _supabaseUrl != null && 
                   _supabaseUrl!.isNotEmpty && 
                   _supabaseAnonKey != null && 
                   _supabaseAnonKey!.isNotEmpty;
    
    // Initialize Supabase if configuration exists
    if (_isConfigured) {
      await _initializeSupabase();
    }
    
    notifyListeners();
  }

  Future<void> _saveSupabaseConfig() async {
    if (_supabaseUrl != null && _supabaseUrl!.isNotEmpty) {
      await _prefs?.setString('supabase_url', _supabaseUrl!);
    } else {
      await _prefs?.remove('supabase_url');
    }
    
    if (_supabaseAnonKey != null && _supabaseAnonKey!.isNotEmpty) {
      await _prefs?.setString('supabase_anon_key', _supabaseAnonKey!);
    } else {
      await _prefs?.remove('supabase_anon_key');
    }
  }

  Future<void> _initializeSupabase() async {
    try {
      if (_supabaseUrl != null && _supabaseAnonKey != null) {
        await Supabase.initialize(
          url: _supabaseUrl!,
          anonKey: _supabaseAnonKey!,
        );
      }
    } catch (e) {
      // Supabase might already be initialized, which is fine
      debugPrint('Supabase initialization: $e');
    }
  }

  Future<void> clearSupabaseConfig() async {
    _supabaseUrl = null;
    _supabaseAnonKey = null;
    _isConfigured = false;
    notifyListeners();
    await _prefs?.remove('supabase_url');
    await _prefs?.remove('supabase_anon_key');
  }

  // Helper method to get Supabase client if configured
  SupabaseClient? get client {
    if (_isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (e) {
        debugPrint('Error getting Supabase client: $e');
        return null;
      }
    }
    return null;
  }
} 