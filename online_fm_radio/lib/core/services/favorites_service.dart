import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 收藏服务类
///
/// 管理用户收藏的电台列表，支持添加、移除、加载和持久化存储。
/// 使用 SharedPreferences 作为持久化存储，数据格式为 JSON 字符串列表。
class FavoritesService extends ChangeNotifier {
  /// SharedPreferences 存储键
  static const String _storageKey = 'favorites';

  /// 收藏列表（内存缓存）
  final List<Station> _favorites = [];

  /// 获取不可修改的收藏列表
  List<Station> get favorites => List.unmodifiable(_favorites);

  /// 获取所有收藏电台的 ID 列表（向后兼容）
  List<String> get favoriteIds =>
      _favorites.map((s) => s.id).toList(growable: false);

  /// 检查电台是否已收藏
  ///
  /// [station] - 要检查的电台
  /// 返回 true 表示已收藏，false 表示未收藏
  bool isFavorite(Station station) {
    return _favorites.any((s) => s.id == station.id);
  }

  /// 切换电台收藏状态
  ///
  /// [station] - 要切换状态的电台
  /// 如果已收藏则移除，未收藏则添加到列表开头
  Future<void> toggleFavorite(Station station) async {
    final existing = _favorites.indexWhere((s) => s.id == station.id);
    if (existing >= 0) {
      _favorites.removeAt(existing);
    } else {
      _favorites.insert(0, station);
    }
    await _save();
    notifyListeners();
  }

  /// 移除指定电台的收藏
  ///
  /// [station] - 要移除的电台
  Future<void> removeFavorite(Station station) async {
    final existed = _favorites.any((s) => s.id == station.id);
    if (existed) {
      _favorites.removeWhere((s) => s.id == station.id);
      await _save();
      notifyListeners();
    }
  }

  /// 从 SharedPreferences 加载收藏列表
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      _favorites.clear();
      for (final jsonString in stored) {
        try {
          final map = jsonDecode(jsonString) as Map<String, dynamic>;
          _favorites.add(Station.fromJson(map));
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  /// 清空所有收藏
  Future<void> clearAll() async {
    _favorites.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  /// 将收藏列表保存到 SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _favorites.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}