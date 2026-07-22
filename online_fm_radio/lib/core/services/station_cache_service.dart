import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:online_fm_radio/data/models/station.dart';

class StationCacheService {
  static const String _cacheKey = 'cached_stations';
  static const String _cacheTimestampKey = 'stations_cache_timestamp';
  static const String _cachePageKey = 'stations_cache_page';

  Future<void> cacheStations(List<Station> stations, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = stations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_cachePageKey, page);
  }

  Future<void> appendStations(List<Station> stations) async {
    final existing = await getCachedStations();
    final allStations = [...existing, ...stations];
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
  }

  Future<List<Station>> getCachedStations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Station.fromJson(map);
    }).toList();
  }

  Future<bool> hasCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    return jsonList != null && jsonList.isNotEmpty;
  }

  Future<int> getCachedPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cachePageKey) ?? 0;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_cachePageKey);
  }

  Future<bool> isCacheExpired({Duration maxAge = const Duration(hours: 24)}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > maxAge;
  }
}
