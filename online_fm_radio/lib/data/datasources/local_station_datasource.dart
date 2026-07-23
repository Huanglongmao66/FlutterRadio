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
  static const String _apiServer = 'http://de1.api.radio-browser.info/json';

  static const int _pageSize = 30;
  static const int _batchSize = 200;
  static const int _maxStations = 10000;

  final Dio _dio;
  final StationCacheService _cacheService;

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
    final url = '$_apiServer/$path';
    final response = await _dio.get(url, queryParameters: queryParameters);
    if (response.statusCode == 200) {
      return response;
    }
    throw Exception('Server returned status ${response.statusCode}');
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

  /// Load stations whose country name exactly matches [countryName].
  /// Used by the recommendation page when a country is selected in Settings.
  Future<List<Station>> loadByCountryName(String countryName) async {
    try {
      final response = await _request(
        'stations/bycountryexact/${Uri.encodeComponent(countryName)}',
        queryParameters: {
          'limit': 50,
          'order': 'votes',
          'reverse': 'true',
          'hidebroken': 'true',
        },
      );

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to load by country name: $e');
    }
    return [];
  }

  /// Load the most recently active/added stations (newest first).
  Future<List<Station>> loadNewestStations({int limit = 20}) async {
    try {
      final response = await _request('stations', queryParameters: {
        'limit': limit,
        'order': 'lastchecktime',
        'reverse': 'true',
        'hidebroken': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to load newest stations: $e');
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

  /// 从本地缓存的所有电台中搜索。
  /// 搜索范围：名称、国家、语言、分类、标签描述。
  /// 优先从缓存搜索；缓存为空时回退到本地资源文件。
  Future<List<Station>> searchCachedStations(String keyword) async {
    final trimmed = keyword.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    List<Station> allStations;
    final hasCache = await _cacheService.hasCache();
    if (hasCache) {
      allStations = await _cacheService.getCachedStations();
    } else {
      allStations = await _loadFromLocalAsset();
    }

    return allStations.where((s) {
      return s.name.toLowerCase().contains(trimmed) ||
          s.country.toLowerCase().contains(trimmed) ||
          s.language.toLowerCase().contains(trimmed) ||
          s.category.toLowerCase().contains(trimmed) ||
          s.description.toLowerCase().contains(trimmed);
    }).toList();
  }

  Future<List<Station>> _loadFromLocalAsset() async {
    final jsonString = await rootBundle.loadString('assets/data/stations.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Country>> loadCountries() async {
    try {
      final stations = await loadStations();
      if (stations.isNotEmpty) {
        final Map<String, int> countryMap = {};
        for (final s in stations) {
          if (s.country.isNotEmpty) {
            countryMap[s.country] = (countryMap[s.country] ?? 0) + 1;
          }
        }
        final entries = countryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries
            .map((e) => Country(name: e.key, countryCode: '', stationCount: e.value))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to extract countries from local data: $e');
    }
    return [];
  }

  Future<List<Tag>> loadTags() async {
    try {
      final stations = await loadStations();
      if (stations.isNotEmpty) {
        final Map<String, int> tagMap = {};
        for (final s in stations) {
          if (s.category.isNotEmpty) {
            tagMap[s.category] = (tagMap[s.category] ?? 0) + 1;
          }
        }
        final entries = tagMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries
            .map((e) => Tag(name: e.key, stationCount: e.value))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to extract tags from local data: $e');
    }
    return [];
  }

  Future<List<Language>> loadLanguages() async {
    try {
      final stations = await loadStations();
      if (stations.isNotEmpty) {
        final Map<String, int> langMap = {};
        for (final s in stations) {
          if (s.language.isNotEmpty) {
            langMap[s.language] = (langMap[s.language] ?? 0) + 1;
          }
        }
        final entries = langMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries
            .map((e) => Language(name: e.key, stationCount: e.value))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to extract languages from local data: $e');
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
