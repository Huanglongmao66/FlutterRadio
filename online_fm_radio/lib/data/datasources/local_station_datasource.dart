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

  static const int _pageSize = 30;
  static const int _batchSize = 1000;
  static const int _maxStations = 10000;

  /// 并行拉取的批次数（同时发起的请求数），避免给 API 服务器过大压力。
  static const int _parallelBatches = 3;

  final Dio _dio;
  final StationCacheService _cacheService;
  int _currentServerIndex = 0;

  LocalStationDatasource({
    Dio? dio,
    StationCacheService? cacheService,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 10),
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
    final totalBatches = (_maxStations / _batchSize).ceil();

    // 按组分批并行拉取：每组同时发起 _parallelBatches 个请求，组内并行、组间串行。
    // 相比纯串行可减少约 2/3 的总耗时，同时避免一次性发起过多请求压垮服务器。
    for (int groupStart = 0; groupStart < totalBatches; groupStart += _parallelBatches) {
      final groupEnd = (groupStart + _parallelBatches).clamp(0, totalBatches);
      final futures = <Future<List<Station>>>[];

      for (int i = groupStart; i < groupEnd; i++) {
        final offset = i * _batchSize;
        futures.add(_fetchBatch(offset));
      }

      final results = await Future.wait(futures);

      var groupEmpty = true;
      for (final batch in results) {
        if (batch.isNotEmpty) groupEmpty = false;
        allStations.addAll(batch);
        onProgress?.call(allStations.length, _maxStations);
      }

      // 组内全部为空表示已无更多数据，提前结束。
      if (groupEmpty) break;

      // 达到上限则停止。
      if (allStations.length >= _maxStations) {
        allStations.removeRange(_maxStations, allStations.length);
        break;
      }
    }

    if (allStations.isNotEmpty) {
      await _cacheService.cacheStations(allStations, 1);
    }
    return allStations.length;
  }

  /// 拉取单批电台数据（offset 起 _batchSize 条）。
  Future<List<Station>> _fetchBatch(int offset) async {
    try {
      final response = await _request('stations', queryParameters: {
        'limit': _batchSize,
        'offset': offset,
        'order': 'votes',
        'reverse': 'true',
        'hidebroken': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch batch at offset $offset: $e');
      return [];
    }
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
        // 缩短切换服务器等待时间，加快失败重试。
        await Future.delayed(const Duration(milliseconds: 200));
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
