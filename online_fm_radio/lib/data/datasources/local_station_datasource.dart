import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/station.dart';

class LocalStationDatasource {
  Future<String> _loadAsset() async {
    return await rootBundle.loadString('assets/data/stations.json');
  }

  Future<List<Station>> loadStations() async {
    final jsonString = await _loadAsset();
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((json) => Station.fromJson(json)).toList();
  }
}