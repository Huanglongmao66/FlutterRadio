import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放历史服务类
///
/// 管理用户最近播放的电台列表，支持添加、移除、加载和持久化存储。
/// 使用 SharedPreferences 作为持久化存储，数据格式为 JSON 字符串列表。
/// 历史记录最多保存 [_maxHistoryLength] 条。
class HistoryService extends ChangeNotifier {
  /// SharedPreferences 存储键
  static const String _storageKey = 'play_history';

  /// 最大历史记录条数
  static const int _maxHistoryLength = 10;

  /// 播放历史列表（内存缓存）
  final List<Station> _history = [];

  /// 获取不可修改的历史列表
  List<Station> get history => List.unmodifiable(_history);

  /// 添加电台到播放历史
  ///
  /// [station] - 要添加的电台
  ///
  /// 逻辑：
  /// 1. 如果电台已在历史中，先移除旧记录
  /// 2. 将电台添加到列表开头
  /// 3. 如果超过最大长度限制，移除最旧的记录
  Future<void> addToHistory(Station station) async {
    _history.removeWhere((s) => s.id == station.id);
    _history.insert(0, station);

    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }

    await _saveHistory();
    notifyListeners();
  }

  /// 从播放历史中移除指定电台
  ///
  /// [station] - 要移除的电台
  Future<void> removeFromHistory(Station station) async {
    _history.removeWhere((s) => s.id == station.id);
    await _saveHistory();
    notifyListeners();
  }

  /// 清空所有播放历史
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  /// 从 SharedPreferences 加载播放历史
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

  /// 将播放历史保存到 SharedPreferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}