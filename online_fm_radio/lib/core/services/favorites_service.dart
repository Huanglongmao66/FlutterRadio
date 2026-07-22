import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static const String _storageKey = 'favorites';
  final List<String> _favoriteIds = [];

  bool isFavorite(Station station) {
    return _favoriteIds.contains(station.id);
  }

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);

  Future<void> toggleFavorite(Station station) async {
    final prefs = await SharedPreferences.getInstance();

    if (_favoriteIds.contains(station.id)) {
      _favoriteIds.remove(station.id);
    } else {
      _favoriteIds.add(station.id);
    }

    await prefs.setStringList(_storageKey, _favoriteIds);
    notifyListeners();
  }

  Future<void> removeFavorite(Station station) async {
    if (_favoriteIds.contains(station.id)) {
      _favoriteIds.remove(station.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteIds);
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);

    if (stored != null) {
      _favoriteIds.clear();
      _favoriteIds.addAll(stored);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _favoriteIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}