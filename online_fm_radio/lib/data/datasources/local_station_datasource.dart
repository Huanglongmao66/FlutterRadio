import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/station.dart';

class LocalStationDatasource {
  static const String _apiBaseUrl = 'https://de1.api.radio-browser.info/json';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Station>> loadStations() async {
    try {
      return await _loadFromApi();
    } catch (e) {
      debugPrint('Failed to load from API: $e, falling back to local data');
      return await _loadFromLocalAsset();
    }
  }

  Future<List<Station>> _loadFromApi() async {
    final response = await _dio.get('$_apiBaseUrl/stations', queryParameters: {
      'limit': 100,
      'order': 'votes',
      'reverse': 'true',
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = response.data as List<dynamic>;
      return jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();
    } else {
      throw Exception('Failed to load stations: ${response.statusCode}');
    }
  }

  Future<List<Station>> loadByCountry(String countryCode) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/stations/bycountrycodeexact/$countryCode',
        queryParameters: {
          'limit': 50,
          'order': 'votes',
          'reverse': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        return jsonData
            .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
            .where((station) => station.streamUrl.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Failed to load by country: $e');
      return [];
    }
  }

  Future<List<Station>> searchStations(String query) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/stations/byname/${Uri.encodeComponent(query)}',
        queryParameters: {'limit': 50},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        return jsonData
            .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
            .where((station) => station.streamUrl.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Failed to search stations: $e');
      return [];
    }
  }

  Future<List<Station>> _loadFromLocalAsset() async {
    final jsonString = await rootBundle.loadString('assets/data/stations.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
  }
}