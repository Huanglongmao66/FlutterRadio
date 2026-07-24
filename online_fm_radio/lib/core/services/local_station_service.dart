import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地电台服务
///
/// 管理通过导入功能（m3u/m3u8/json）添加的本地电台列表。
/// 与远程 API 更新的电台数据相互独立，不随远程更新而变化。
class LocalStationService extends ChangeNotifier {
  static const String _storageKey = 'local_stations';

  final List<Station> _stations = [];

  List<Station> get stations => List.unmodifiable(_stations);

  /// 从 SharedPreferences 加载本地电台
  Future<void> loadStations() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    _stations.clear();
    if (stored != null) {
      for (final jsonString in stored) {
        try {
          final map = jsonDecode(jsonString) as Map<String, dynamic>;
          _stations.add(Station.fromJson(map));
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// 导入电台列表（自动去重）
  ///
  /// 返回新增的电台数量
  Future<int> importStations(List<Station> stations) async {
    int added = 0;
    for (final station in stations) {
      final exists = _stations.any((s) => s.id == station.id);
      if (!exists) {
        _stations.add(station);
        added++;
      }
    }
    await _save();
    notifyListeners();
    return added;
  }

  /// 移除单个本地电台
  Future<void> removeStation(Station station) async {
    _stations.removeWhere((s) => s.id == station.id);
    await _save();
    notifyListeners();
  }

  /// 清空所有本地电台
  Future<void> clearAll() async {
    _stations.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _stations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}
