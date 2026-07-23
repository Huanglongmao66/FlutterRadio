import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static const String _storageKey = 'favorites';
  final List<Station> _favorites = [];

  List<Station> get favorites => List.unmodifiable(_favorites);

  /// Backwards-compatible list of favorite station ids.
  List<String> get favoriteIds =>
      _favorites.map((s) => s.id).toList(growable: false);

  bool isFavorite(Station station) {
    return _favorites.any((s) => s.id == station.id);
  }

  Future<void> toggleFavorite(Station station) async {
    final existing = _favorites.indexWhere((s) => s.id == station.id);
    if (existing >= 0) {
      _favorites.removeAt(existing);
    } else {
      _favorites.insert(0, station);
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeFavorite(Station station) async {
    final existed = _favorites.removeWhere((s) => s.id == station.id);
    if (existed) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      _favorites.clear();
      for (final jsonString in stored) {
        try {
          final map = jsonDecode(jsonString) as Map<String, dynamic>;
          _favorites.add(Station.fromJson(map));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _favorites.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _favorites.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}
