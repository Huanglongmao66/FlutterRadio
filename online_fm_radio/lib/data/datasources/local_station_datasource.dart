import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/services/station_cache_service.dart';
import '../models/country.dart';
import '../models/language.dart';
import '../models/radio_stats.dart';
import '../models/station.dart';
import '../models/tag.dart';

/// 电台数据数据源类
///
/// 负责从 radio-browser.info API 和本地资源文件加载电台数据，
/// 并提供数据缓存、搜索和分类查询功能。
///
/// 数据加载策略：
/// 1. 优先从本地缓存加载，减少网络请求
/// 2. 缓存不存在时从 API 加载并缓存
/// 3. API 请求失败时回退到本地 assets/data/stations.json
///
/// 性能优化：
/// - 并行请求：同时发起多个批次请求，大幅提升获取速度
/// - 增大批次：每次请求 500 条（API 最大支持 1000）
/// - 连接池：Dio 启用 HTTP/1.1 持久连接和连接池
/// - 分块缓存：每获取一定数量后立即缓存，避免内存占用过高
class LocalStationDatasource {
  /// radio-browser.info API 服务器地址
  static const String _apiServer = 'http://de1.api.radio-browser.info/json';

  /// 分页加载每页数量
  static const int _pageSize = 30;

  /// 批量加载每次数量（用于全量缓存更新）
  /// API 最大支持 1000，设置为 500 平衡速度与稳定性
  static const int _batchSize = 500;

  /// 并行请求数量（同时发起的批次请求数）
  static const int _parallelCount = 3;

  /// 分块缓存大小（每积累多少条数据后缓存一次）
  static const int _cacheChunkSize = 1000;

  /// 全量缓存默认最大电台数量（当无法从 stats API 获取真实数量时使用）
  static const int _defaultMaxStations = 10000;

  /// 缓存的统计数据（避免重复请求）
  RadioStats? _cachedStats;

  /// HTTP 请求客户端
  final Dio _dio;

  /// 电台缓存服务
  final StationCacheService _cacheService;

  /// 创建数据源实例
  ///
  /// [dio] - HTTP 请求客户端，可选，默认使用配置好的 Dio 实例
  /// [cacheService] - 缓存服务，可选，默认使用 StationCacheService 实例
  LocalStationDatasource({
    Dio? dio,
    StationCacheService? cacheService,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 10),
          followRedirects: true,
          maxRedirects: 5,
          persistentConnection: true,
        )),
        _cacheService = cacheService ?? StationCacheService() {
    _configureDio();
  }

  /// 配置 Dio 客户端，优化网络请求性能
  void _configureDio() {
    _dio.options.headers = {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
    };
    _dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: false,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));
  }

  /// 加载电台列表
  ///
  /// [forceRefresh] - 是否强制从 API 刷新，默认为 false
  ///
  /// 加载策略：
  /// 1. 如果 [forceRefresh] 为 false 且存在缓存，直接返回缓存数据
  /// 2. 否则从 API 加载并缓存，API 失败时回退到本地资源文件
  Future<List<Station>> loadStations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final hasCache = await _cacheService.hasCache();
      if (hasCache) {
        return await _cacheService.getCachedStations();
      }
    }
    return await _loadFromApiAndCache();
  }

  /// 分页加载更多电台
  ///
  /// [offset] - 偏移量，用于分页
  ///
  /// 从 API 加载指定偏移量的电台数据，加载后追加到缓存
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

  /// 全量获取电台数据并缓存（高性能版本）
  ///
  /// [onProgress] - 进度回调，参数为 (已获取数量, 总数量)
  /// [resumeOffset] - 断点续传起始偏移量，0 表示从头开始
  /// [resumeFetched] - 断点续传已获取数量，用于累计计数
  /// [onBatchSaved] - 每批次保存后的回调，参数为 (当前 offset, 已获取数量, 总数量)
  /// [isPaused] - 返回 true 时暂停获取，等待 [onWaitForResume] 完成
  /// [onWaitForResume] - 暂停时调用的 Future，完成后继续获取
  /// [shouldStop] - 返回 true 时停止获取（用于取消）
  ///
  /// 性能优化策略：
  /// - 并行请求：同时发起 [_parallelCount] 个批次请求，大幅提升获取速度
  /// - 批量解析：将 JSON 解析放在后台进行
  /// - 分块缓存：每积累 [_cacheChunkSize] 条数据后立即缓存，避免内存占用过高
  /// - 增量更新：断点续传时只获取缺失部分，不重复获取已缓存数据
  Future<int> fetchAllAndCache({
    void Function(int fetched, int total)? onProgress,
    int resumeOffset = 0,
    int resumeFetched = 0,
    void Function(int offset, int fetched, int total)? onBatchSaved,
    bool Function()? isPaused,
    Future<void> Function()? onWaitForResume,
    bool Function()? shouldStop,
  }) async {
    final totalStations = await _getMaxStations();
    final allStations = <Station>[];
    int offset = resumeOffset;
    int fetchedCount = resumeFetched;
    int cachedCount = 0;

    // 如果是断点续传，先加载已缓存的数据（用于后续合并覆盖）
    if (resumeOffset > 0) {
      final existing = await _cacheService.getCachedStations();
      allStations.addAll(existing);
      cachedCount = existing.length;
    }

    // 预计算所有需要请求的 offset 列表
    final offsets = <int>[];
    for (int i = offset; i < totalStations; i += _batchSize) {
      offsets.add(i);
    }

    int offsetIndex = 0;
    final pendingFutures = <Future<({int offset, List<Station> stations})>>{};

    while (offsetIndex < offsets.length || pendingFutures.isNotEmpty) {
      // 取消检查
      if (shouldStop != null && shouldStop()) {
        if (allStations.isNotEmpty) {
          await _cacheService.cacheStations(allStations, 1);
        }
        return fetchedCount;
      }

      // 暂停检查：等待恢复信号
      while (isPaused != null && isPaused()) {
        if (shouldStop != null && shouldStop()) {
          return fetchedCount;
        }
        if (onWaitForResume != null) {
          await onWaitForResume();
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 填充并行请求队列
      while (pendingFutures.length < _parallelCount && offsetIndex < offsets.length) {
        final currentOffset = offsets[offsetIndex];
        pendingFutures.add(_fetchBatchParallel(currentOffset));
        offsetIndex++;
      }

      // 等待至少一个请求完成
      if (pendingFutures.isNotEmpty) {
        final completed = await Future.any(pendingFutures);
        pendingFutures.remove(completed);

        // 处理完成的批次
        allStations.addAll(completed.stations);
        fetchedCount += completed.stations.length;
        onProgress?.call(fetchedCount, totalStations);

        // 保存断点位置
        final nextOffset = completed.offset + _batchSize;
        onBatchSaved?.call(nextOffset, fetchedCount, totalStations);

        // 分块缓存：每积累一定数量后立即缓存
        if (allStations.length - cachedCount >= _cacheChunkSize) {
          await _cacheService.cacheStations(allStations, 1);
          cachedCount = allStations.length;
        }
      }
    }

    // 最终缓存
    if (allStations.isNotEmpty && cachedCount != allStations.length) {
      await _cacheService.cacheStations(allStations, 1);
    }

    return fetchedCount;
  }

  /// 并行获取单个批次的数据
  ///
  /// [offset] - 请求偏移量
  ///
  /// 返回包含偏移量和电台列表的记录
  Future<({int offset, List<Station> stations})> _fetchBatchParallel(int offset) async {
    try {
      final response = await _request('stations', queryParameters: {
        'limit': _batchSize,
        'offset': offset,
        'order': 'votes',
        'reverse': 'true',
      });

      final List<dynamic> jsonData = response.data as List<dynamic>;
      if (jsonData.isEmpty) {
        return (offset: offset, stations: <Station>[]);
      }

      // 批量解析 JSON，跳过无效数据
      final batch = jsonData
          .map((json) => _parseStation(json as Map<String, dynamic>))
          .where((station) => station != null)
          .toList()
          .cast<Station>();

      return (offset: offset, stations: batch);
    } catch (e) {
      debugPrint('Failed to fetch batch at offset $offset: $e');
      return (offset: offset, stations: <Station>[]);
    }
  }

  /// 解析单个电台数据，返回 null 如果数据无效
  ///
  /// 优化解析逻辑：减少不必要的字符串处理，提前返回无效数据
  Station? _parseStation(Map<String, dynamic> json) {
    final stationUuid = json['stationuuid'] as String?;
    if (stationUuid == null || stationUuid.isEmpty) {
      return null;
    }

    final streamUrl = json['url_resolved'] as String? ?? json['url'] as String?;
    if (streamUrl == null || streamUrl.isEmpty) {
      return null;
    }

    final name = (json['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }

    final tags = (json['tags'] as String?)?.split(',') ?? [];
    final category = tags.isNotEmpty ? tags.first.trim() : 'Other';

    return Station(
      id: stationUuid,
      name: name,
      streamUrl: streamUrl,
      country: json['country'] as String? ?? 'Unknown',
      countryCode: json['countrycode'] as String? ?? '',
      language: (json['language'] as String?)?.trim() ?? '',
      category: category,
      logo: json['favicon'] as String? ?? '',
      description: tags.join(', '),
      votes: json['votes'] as int? ?? 0,
      bitrate: json['bitrate'] as int? ?? 0,
      codec: json['codec'] as String? ?? '',
    );
  }

  /// 获取电台总数
  ///
  /// 优先从 stats API 获取真实电台总数，失败时使用默认值
  Future<int> _getMaxStations() async {
    try {
      final stats = await loadStats();
      if (stats.stations > 0) {
        return stats.stations;
      }
    } catch (e) {
      debugPrint('Failed to get stats, using default max stations: $e');
    }
    return _defaultMaxStations;
  }

  /// 从本地缓存统计电台数据
  ///
  /// 不发起网络请求，直接从本地缓存（或回退到 stations.json）中统计
  /// 电台数量、国家数、语言数、标签数。
  Future<RadioStats> loadLocalStats() async {
    final stations = await loadStations();

    final countries = <String>{};
    final languages = <String>{};
    final tags = <String>{};

    for (final s in stations) {
      if (s.country.isNotEmpty) countries.add(s.country);
      if (s.language.isNotEmpty) languages.add(s.language);
      if (s.category.isNotEmpty) tags.add(s.category);
    }

    return RadioStats(
      stations: stations.length,
      clicks: 0,
      countries: countries.length,
      languages: languages.length,
      tags: tags.length,
      clicksLastHour: 0,
      stationsBroken: 0,
    );
  }

  /// 加载电台统计数据
  ///
  /// [forceRefresh] - 是否强制刷新，默认为 false 使用缓存
  ///
  /// 从 /json/stats API 获取平台统计数据，包括电台总数、国家数、语言数等。
  /// 结果会被缓存，后续调用直接返回缓存数据。
  Future<RadioStats> loadStats({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStats != null) {
      return _cachedStats!;
    }

    final response = await _request('stats');
    final jsonData = response.data as Map<String, dynamic>;
    final stats = RadioStats.fromJson(jsonData);
    _cachedStats = stats;
    return stats;
  }

  /// 发起 HTTP GET 请求
  ///
  /// [path] - API 路径（不包含服务器地址）
  /// [queryParameters] - 查询参数
  ///
  /// 返回 Response 对象，状态码非 200 时抛出异常
  Future<Response> _request(String path, {Map<String, dynamic>? queryParameters}) async {
    final url = '$_apiServer/$path';
    final response = await _dio.get(url, queryParameters: queryParameters);
    if (response.statusCode == 200) {
      return response;
    }
    throw Exception('Server returned status ${response.statusCode}');
  }

  /// 从 API 加载电台数据并缓存
  ///
  /// 从 API 获取投票最多的电台数据，缓存后返回。
  /// API 请求失败时回退到本地资源文件 [_loadFromLocalAsset]
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

  /// 检查是否存在本地缓存
  Future<bool> hasCache() async {
    return await _cacheService.hasCache();
  }

  /// 获取本地缓存的电台列表
  Future<List<Station>> getCachedStations() async {
    return await _cacheService.getCachedStations();
  }

  /// 获取本地缓存电台数量（高效版本）
  ///
  /// 直接调用缓存服务的 getCachedCount，避免解析完整数据。
  Future<int> getCachedStationCount() async {
    return await _cacheService.getCachedCount();
  }

  /// 清空本地电台缓存
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// 根据国家代码加载电台
  ///
  /// [countryCode] - ISO 3166-1 alpha-2 国家代码（如 CN、US）
  ///
  /// 使用 stations/bycountrycodeexact API 接口
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

  /// 根据国家名称精确匹配加载电台
  ///
  /// [countryName] - 国家名称（英文）
  ///
  /// 用于推荐页面，当用户在设置中选择国家后加载该国家的电台。
  /// 使用 stations/bycountryexact API 接口
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

  /// 加载最新活跃的电台
  ///
  /// [limit] - 返回数量，默认 20
  ///
  /// 使用 lastchecktime 排序，返回最近检查过的电台（最新的优先）
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

  /// 根据标签加载电台
  ///
  /// [tag] - 标签名称
  ///
  /// 使用 stations/bytag API 接口
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

  /// 通过 API 搜索电台
  ///
  /// [query] - 搜索关键词
  ///
  /// 使用 stations/byname API 接口，按名称搜索
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

  /// 从本地缓存的所有电台中搜索
  ///
  /// [keyword] - 搜索关键词
  ///
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

  /// 从本地资源文件加载电台数据
  ///
  /// 加载 assets/data/stations.json 文件，作为 API 失败时的回退方案
  Future<List<Station>> _loadFromLocalAsset() async {
    final jsonString = await rootBundle.loadString('assets/data/stations.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 从本地缓存的电台数据中提取国家列表
  ///
  /// 根据电台数据统计每个国家的电台数量，并按数量降序排序。
  /// 使用两个 Map 分别存储国家计数和国家码，确保 Country 对象包含正确的 countryCode。
  Future<List<Country>> loadCountries() async {
    try {
      final stations = await loadStations();
      if (stations.isNotEmpty) {
        final Map<String, int> countryCounts = {};
        final Map<String, String> countryCodes = {};
        for (final s in stations) {
          if (s.country.isNotEmpty) {
            countryCounts[s.country] = (countryCounts[s.country] ?? 0) + 1;
            if (s.countryCode.isNotEmpty && !countryCodes.containsKey(s.country)) {
              countryCodes[s.country] = s.countryCode;
            }
          }
        }
        final entries = countryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries
            .map((e) => Country(name: e.key, countryCode: countryCodes[e.key] ?? '', stationCount: e.value))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to extract countries from local data: $e');
    }
    return [];
  }

  /// 从本地缓存的电台数据中提取标签列表
  ///
  /// 根据电台数据统计每个标签的电台数量，并按数量降序排序。
  /// 使用电台的 category 字段作为标签。
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

  /// 从本地缓存的电台数据中提取语言列表
  ///
  /// 根据电台数据统计每种语言的电台数量，并按数量降序排序。
  /// 使用电台的 language 字段作为语言标识。
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

  /// 根据语言加载电台
  ///
  /// [language] - 语言名称
  ///
  /// 使用 stations/bylanguage API 接口
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