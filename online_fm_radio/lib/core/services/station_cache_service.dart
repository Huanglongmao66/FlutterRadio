import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 电台缓存服务类
///
/// 管理电台数据的本地缓存，支持缓存、追加、读取和过期检查。
/// 使用 SharedPreferences 作为持久化存储，数据格式为 JSON 字符串列表。
class StationCacheService {
  /// 电台列表缓存键
  static const String _cacheKey = 'cached_stations';

  /// 缓存时间戳键
  static const String _cacheTimestampKey = 'stations_cache_timestamp';

  /// 缓存页码键
  static const String _cachePageKey = 'stations_cache_page';

  /// 缓存电台列表
  ///
  /// [stations] - 要缓存的电台列表
  /// [page] - 当前页码，用于分页加载
  ///
  /// 同时保存时间戳和页码信息
  Future<void> cacheStations(List<Station> stations, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = stations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_cachePageKey, page);
  }

  /// 追加电台到缓存
  ///
  /// [stations] - 要追加的电台列表
  ///
  /// 去重逻辑：先获取已缓存的电台 ID，过滤掉重复的电台后再追加
  Future<void> appendStations(List<Station> stations) async {
    final existing = await getCachedStations();
    final existingIds = existing.map((s) => s.id).toSet();
    final newStations = stations.where((s) => !existingIds.contains(s.id)).toList();
    final allStations = [...existing, ...newStations];
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
  }

  /// 获取缓存的电台列表
  ///
  /// 返回解析后的 Station 对象列表，如果缓存为空则返回空列表
  Future<List<Station>> getCachedStations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Station.fromJson(map);
    }).toList();
  }

  /// 检查是否存在缓存
  ///
  /// 返回 true 表示存在非空缓存，false 表示缓存不存在或为空
  Future<bool> hasCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    return jsonList != null && jsonList.isNotEmpty;
  }

  /// 获取缓存的页码
  ///
  /// 返回缓存的页码，默认为 0
  Future<int> getCachedPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cachePageKey) ?? 0;
  }

  /// 清除所有缓存数据
  ///
  /// 删除缓存列表、时间戳和页码信息
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_cachePageKey);
  }

  /// 检查缓存是否过期
  ///
  /// [maxAge] - 最大有效期，默认 24 小时
  ///
  /// 返回 true 表示缓存已过期或不存在，false 表示缓存有效
  Future<bool> isCacheExpired({Duration maxAge = const Duration(hours: 24)}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > maxAge;
  }
}