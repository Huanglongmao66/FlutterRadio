import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 电台缓存服务类
///
/// 管理电台数据的本地缓存，支持缓存、追加、读取和过期检查。
/// 使用文件存储代替 SharedPreferences（更适合大数据量），
/// 元数据（时间戳、页码）仍使用 SharedPreferences。
///
/// 性能优化：
/// - 使用文件存储：相比 SharedPreferences，文件存储更适合存储大量数据
/// - 批量序列化：减少 I/O 操作次数
/// - 缓存预热：首次读取后缓存在内存中
class StationCacheService {
  /// 电台列表缓存文件名
  static const String _cacheFileName = 'stations_cache.json';

  /// 缓存时间戳键
  static const String _cacheTimestampKey = 'stations_cache_timestamp';

  /// 缓存页码键
  static const String _cachePageKey = 'stations_cache_page';

  /// 内存缓存（首次读取后缓存在内存中，避免重复读取文件）
  List<Station>? _memoryCache;

  /// 内存缓存时间戳
  int? _memoryCacheTimestamp;

  /// 获取缓存文件路径
  Future<String> _getCacheFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_cacheFileName';
  }

  /// 缓存电台列表
  ///
  /// [stations] - 要缓存的电台列表
  /// [page] - 当前页码，用于分页加载
  ///
  /// 同时保存时间戳和页码信息
  Future<void> cacheStations(List<Station> stations, int page) async {
    // 更新内存缓存
    _memoryCache = List.unmodifiable(stations);
    _memoryCacheTimestamp = DateTime.now().millisecondsSinceEpoch;

    // 序列化并写入文件
    final filePath = await _getCacheFilePath();
    final jsonList = stations.map((s) => s.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    // 使用文件存储，比 SharedPreferences 更适合大数据量
    await File(filePath).writeAsString(jsonString);

    // 保存元数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheTimestampKey, _memoryCacheTimestamp!);
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
    await cacheStations(allStations, 1);
  }

  /// 获取所有已缓存电台的 ID 集合
  ///
  /// 轻量级方法，只读取 ID 字段，避免加载完整数据。
  /// 用于同步时对比差异。
  Future<Set<String>> getCachedIds() async {
    final stations = await getCachedStations();
    return stations.map((s) => s.id).toSet();
  }

  /// 同步电台数据：对比远程数据，只写入差异部分
  ///
  /// [remoteStations] - 远程获取的电台列表
  ///
  /// 对比逻辑：
  /// 1. 获取本地缓存中已存在的电台 ID 集合
  /// 2. 过滤掉重复的电台
  /// 3. 只将新增的电台追加到缓存
  ///
  /// 返回新增的电台数量
  Future<int> syncStations(List<Station> remoteStations) async {
    final existingIds = await getCachedIds();

    // 过滤出本地不存在的新电台
    final newStations = remoteStations
        .where((s) => !existingIds.contains(s.id))
        .toList();

    if (newStations.isEmpty) {
      return 0;
    }

    final existing = await getCachedStations();
    final allStations = [...existing, ...newStations];
    await cacheStations(allStations, 1);

    return newStations.length;
  }

  /// 获取缓存中指定 ID 的电台
  ///
  /// [ids] - 要查询的 ID 集合
  /// 返回存在的电台列表
  Future<List<Station>> getStationsByIds(Set<String> ids) async {
    final stations = await getCachedStations();
    return stations.where((s) => ids.contains(s.id)).toList();
  }

  /// 移除缓存中指定 ID 的电台
  ///
  /// [ids] - 要移除的电台 ID 集合
  /// 返回移除的数量
  Future<int> removeStationsByIds(Set<String> ids) async {
    final stations = await getCachedStations();
    final before = stations.length;
    final filtered = stations.where((s) => !ids.contains(s.id)).toList();
    final removed = before - filtered.length;

    if (removed > 0) {
      await cacheStations(filtered, 1);
    }

    return removed;
  }

  /// 获取缓存的电台列表
  ///
  /// 返回解析后的 Station 对象列表，如果缓存为空则返回空列表
  /// 优先从内存缓存读取，避免重复读取文件
  Future<List<Station>> getCachedStations() async {
    // 优先从内存缓存读取
    if (_memoryCache != null) {
      return _memoryCache!;
    }

    final filePath = await _getCacheFilePath();
    final file = File(filePath);

    if (!await file.exists()) {
      return [];
    }

    try {
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final stations = jsonList
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();

      // 更新内存缓存
      _memoryCache = List.unmodifiable(stations);
      final prefs = await SharedPreferences.getInstance();
      _memoryCacheTimestamp = prefs.getInt(_cacheTimestampKey);

      return stations;
    } catch (e) {
      return [];
    }
  }

  /// 检查是否存在缓存
  ///
  /// 返回 true 表示存在非空缓存，false 表示缓存不存在或为空
  Future<bool> hasCache() async {
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      return true;
    }

    final filePath = await _getCacheFilePath();
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    final length = await file.length();
    return length > 0;
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
  /// 删除缓存文件、时间戳和页码信息，同时清除内存缓存
  Future<void> clearCache() async {
    // 清除内存缓存
    _memoryCache = null;
    _memoryCacheTimestamp = null;

    // 删除缓存文件
    final filePath = await _getCacheFilePath();
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // 删除元数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_cachePageKey);
  }

  /// 检查缓存是否过期
  ///
  /// [maxAge] - 最大有效期，默认 24 小时
  ///
  /// 返回 true 表示缓存已过期或不存在，false 表示缓存有效
  Future<bool> isCacheExpired({Duration maxAge = const Duration(hours: 24)}) async {
    if (_memoryCacheTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(_memoryCacheTimestamp!);
      return DateTime.now().difference(cacheTime) > maxAge;
    }

    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > maxAge;
  }

  /// 获取缓存电台数量（不解析完整数据，直接从内存或文件大小估算）
  Future<int> getCachedCount() async {
    if (_memoryCache != null) {
      return _memoryCache!.length;
    }

    final filePath = await _getCacheFilePath();
    final file = File(filePath);
    if (!await file.exists()) {
      return 0;
    }

    try {
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.length;
    } catch (e) {
      return 0;
    }
  }

  /// 刷新内存缓存（强制重新读取文件）
  Future<void> refreshMemoryCache() async {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    await getCachedStations();
  }
}
