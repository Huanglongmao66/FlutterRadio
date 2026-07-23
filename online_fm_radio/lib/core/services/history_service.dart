import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'play_history';
  static const int _maxHistoryLength = 10;
  final List<Station> _history = [];

  List<Station> get history => List.unmodifiable(_history);

  Future<void> addToHistory(Station station) async {
    _history.removeWhere((s) => s.id == station.id);
    _history.insert(0, station);

    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }

    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeFromHistory(Station station) async {
    _history.removeWhere((s) => s.id == station.id);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);

    if (stored != null) {
      _history.clear();
      for (final jsonString in stored) {
        try {
          final map = jsonDecode(jsonString) as Map<String, dynamic>;
          _history.add(Station.fromJson(map));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}