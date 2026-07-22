import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/services/station_cache_service.dart';
import '../models/country.dart';
import '../models/language.dart';
import '../models/station.dart';
import '../models/tag.dart';

class LocalStationDatasource {
  static const List<String> _apiServers = [
    'http://api.radio-browser.info/json',
    'http://nl1.api.radio-browser.info/json',
    'http://fr1.api.radio-browser.info/json',
    'http://de1.api.radio-browser.info/json',
  ];

  static const int _pageSize = 20;
  static const int _batchSize = 200;
  static const int _maxStations = 10000;

  final Dio _dio;
  final StationCacheService _cacheService;
  int _currentServerIndex = 0;

  LocalStationDatasource({
    Dio? dio,
    StationCacheService? cacheService,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _cacheService = cacheService ?? StationCacheService();

  Future<List<Station>> loadStations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final hasCache = await _cacheService.hasCache();
      if (hasCache) {
        return await _cacheService.getCachedStations();
      }
    }
    return await _loadFromApiAndCache();
  }

  Future<List<Station>> loadMoreStations(int offset) async {
    try {
      final response = await _request('stations', queryParameters: {
        'limit': _pageSize,
        'offset': offset,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      final stations = jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();

      await _cacheService.appendStations(stations);
      return stations;
    } catch (e) {
      debugPrint('Failed to load more stations: $e');
    }
    return [];
  }

  Future<int> fetchAllAndCache({void Function(int fetched, int total)? onProgress}) async {
    final allStations = <Station>[];
    int offset = 0;

    while (offset < _maxStations) {
      try {
        final response = await _request('stations', queryParameters: {
          'limit': _batchSize,
          'offset': offset,
          'order': 'votes',
          'reverse': 'true',
        });

        final List<dynamic> jsonData = response.data as List<dynamic>;
        if (jsonData.isEmpty) break;

        final batch = jsonData
            .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
            .where((station) => station.streamUrl.isNotEmpty)
            .toList();

        allStations.addAll(batch);
        onProgress?.call(allStations.length, _maxStations);

        if (jsonData.length < _batchSize) break;
        offset += _batchSize;
      } catch (e) {
        debugPrint('Failed to fetch batch at offset $offset: $e');
        break;
      }
    }

    if (allStations.isNotEmpty) {
      await _cacheService.cacheStations(allStations, 1);
    }
    return allStations.length;
  }

  Future<Response> _request(String path, {Map<String, dynamic>? queryParameters}) async {
    for (int i = 0; i < _apiServers.length; i++) {
      final url = '${_apiServers[_currentServerIndex]}/$path';
      try {
        final response = await _dio.get(url, queryParameters: queryParameters);
        if (response.statusCode == 200) {
          return response;
        }
      } catch (e) {
        debugPrint('Server ${_apiServers[_currentServerIndex]} failed: $e');
        _currentServerIndex = (_currentServerIndex + 1) % _apiServers.length;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('All servers failed');
  }

  Future<List<Station>> _loadFromApiAndCache() async {
    try {
      final response = await _request('stations', queryParameters: {
        'limit': _pageSize,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      final stations = jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();

      await _cacheService.cacheStations(stations, 1);
      return stations;
    } catch (e) {
      debugPrint('Failed to load from API: $e, falling back to local data');
      return await _loadFromLocalAsset();
    }
  }

  Future<List<Station>> loadByCountry(String countryCode) async {
    try {
      final response = await _request('stations/bycountrycodeexact/$countryCode', queryParameters: {
        'limit': 50,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to load by country: $e');
    }
    return [];
  }

  Future<List<Station>> loadByTag(String tag) async {
    try {
      final response = await _request('stations/bytag/$tag', queryParameters: {
        'limit': 50,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to load by tag: $e');
    }
    return [];
  }

  Future<List<Station>> searchStations(String query) async {
    try {
      final response = await _request('stations/byname/${Uri.encodeComponent(query)}', queryParameters: {
        'limit': 50,
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to search stations: $e');
    }
    return [];
  }

  Future<List<Station>> _loadFromLocalAsset() async {
    final jsonString = await rootBundle.loadString('assets/data/stations.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Country>> loadCountries() async {
    try {
      final response = await _request('countries', queryParameters: {
        'order': 'stationcount',
        'reverse': 'true',
        'hidebroken': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .where((country) => country.name.isNotEmpty && country.stationCount > 0)
          .toList();
    } catch (e) {
      debugPrint('Failed to load countries: $e');
    }
    return [];
  }

  Future<List<Tag>> loadTags() async {
    try {
      final response = await _request('tags', queryParameters: {
        'order': 'stationcount',
        'reverse': 'true',
        'hidebroken': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .where((tag) => tag.name.isNotEmpty && tag.stationCount > 0)
          .toList();
    } catch (e) {
      debugPrint('Failed to load tags: $e');
    }
    return [];
  }

  Future<List<Language>> loadLanguages() async {
    try {
      final response = await _request('languages', queryParameters: {
        'order': 'stationcount',
        'reverse': 'true',
        'hidebroken': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Language.fromJson(json as Map<String, dynamic>))
          .where((lang) => lang.name.isNotEmpty && lang.stationCount > 0)
          .toList();
    } catch (e) {
      debugPrint('Failed to load languages: $e');
    }
    return [];
  }

  Future<List<Station>> loadByLanguage(String language) async {
    try {
      final response = await _request('stations/bylanguage/$language', queryParameters: {
        'limit': 50,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to load by language: $e');
    }
    return [];
  }
}
