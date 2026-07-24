import '../models/country.dart';
import '../models/language.dart';
import '../models/radio_stats.dart';
import '../models/station.dart';
import '../models/tag.dart';
import '../datasources/local_station_datasource.dart';

/// 电台数据仓库类：作为数据访问层的统一入口。
///
/// 封装数据源操作，为上层提供简洁的 API 接口。
/// 所有数据请求都通过此类中转，便于统一管理和测试。
class StationRepository {
  /// 本地数据源
  final LocalStationDatasource _datasource;

  /// 创建仓库实例
  ///
  /// [datasource] - 数据源实例，可选，默认使用 LocalStationDatasource
  StationRepository({LocalStationDatasource? datasource})
      : _datasource = datasource ?? LocalStationDatasource();

  /// 加载电台列表
  ///
  /// [forceRefresh] - 是否强制从 API 刷新，默认为 false
  Future<List<Station>> loadStations({bool forceRefresh = false}) async {
    return await _datasource.loadStations(forceRefresh: forceRefresh);
  }

  /// 分页加载更多电台
  ///
  /// [offset] - 偏移量，用于分页
  Future<List<Station>> loadMoreStations(int offset) async {
    return await _datasource.loadMoreStations(offset);
  }

  /// 全量获取电台数据并缓存
  ///
  /// [onProgress] - 进度回调，参数为 (已获取数量, 总数量)
  /// [resumeOffset] - 断点续传起始偏移量
  /// [resumeFetched] - 断点续传已获取数量
  /// [onBatchSaved] - 每批次保存后的回调
  /// [isPaused] - 返回 true 时暂停获取
  /// [onWaitForResume] - 暂停时等待恢复的 Future
  /// [shouldStop] - 返回 true 时停止获取
  Future<int> fetchAllAndCache({
    void Function(int fetched, int total)? onProgress,
    int resumeOffset = 0,
    int resumeFetched = 0,
    void Function(int offset, int fetched, int total)? onBatchSaved,
    bool Function()? isPaused,
    Future<void> Function()? onWaitForResume,
    bool Function()? shouldStop,
  }) async {
    return await _datasource.fetchAllAndCache(
      onProgress: onProgress,
      resumeOffset: resumeOffset,
      resumeFetched: resumeFetched,
      onBatchSaved: onBatchSaved,
      isPaused: isPaused,
      onWaitForResume: onWaitForResume,
      shouldStop: shouldStop,
    );
  }

  /// 获取本地缓存电台数量
  ///
  /// 不发起网络请求，直接返回本地缓存中的电台数量。
  /// 优先使用缓存服务的 getCachedCount 方法（更高效）。
  Future<int> getCachedStationCount() async {
    return await _datasource.getCachedStationCount();
  }

  /// 获取本地缓存的电台列表
  ///
  /// 不发起网络请求，直接返回本地缓存中的电台列表。
  Future<List<Station>> getCachedStations() async {
    return await _datasource.getCachedStations();
  }

  /// 清空本地电台缓存
  Future<void> clearCache() async {
    await _datasource.clearCache();
  }

  /// 加载远程统计数据（强制刷新，不走缓存）
  ///
  /// 返回服务器最新的电台总数、国家数、语言数等统计信息。
  Future<RadioStats> loadRemoteStats() async {
    return await _datasource.loadStats(forceRefresh: true);
  }

  /// 同步远程数据：对比缓存差异，只写入新增数据
  ///
  /// [onProgress] - 进度回调，参数为 (已对比数量, 总数量)
  /// [shouldStop] - 返回 true 时停止同步
  ///
  /// 返回新增的电台数量
  Future<int> syncRemoteStations({
    void Function(int compared, int total)? onProgress,
    bool Function()? shouldStop,
  }) async {
    return await _datasource.syncRemoteStations(
      onProgress: onProgress,
      shouldStop: shouldStop,
    );
  }

  /// 根据国家代码加载电台
  ///
  /// [countryCode] - ISO 3166-1 alpha-2 国家代码
  Future<List<Station>> loadByCountry(String countryCode) async {
    return await _datasource.loadByCountry(countryCode);
  }

  /// 根据国家名称加载电台
  ///
  /// [countryName] - 国家名称（英文）
  Future<List<Station>> loadByCountryName(String countryName) async {
    return await _datasource.loadByCountryName(countryName);
  }

  /// 加载最新活跃的电台
  ///
  /// [limit] - 返回数量，默认 20
  Future<List<Station>> loadNewestStations({int limit = 20}) async {
    return await _datasource.loadNewestStations(limit: limit);
  }

  /// 通过 API 搜索电台（关键词长度需 >= 2）
  ///
  /// [keyword] - 搜索关键词
  Future<List<Station>> search(String keyword) async {
    if (keyword.length >= 2) {
      return await _datasource.searchStations(keyword);
    }
    return [];
  }

  /// 从本地缓存中搜索电台
  ///
  /// [keyword] - 搜索关键词
  Future<List<Station>> searchCached(String keyword) async {
    return await _datasource.searchCachedStations(keyword);
  }

  /// 加载电台统计数据
  ///
  /// [forceRefresh] - 是否强制刷新，默认为 false
  ///
  /// 返回平台统计信息，包括电台总数、国家数、语言数等。
  Future<RadioStats> loadStats({bool forceRefresh = false}) async {
    return await _datasource.loadStats(forceRefresh: forceRefresh);
  }

  /// 从本地缓存统计电台数据
  ///
  /// 不发起网络请求，直接从本地缓存中统计电台数量、国家数、语言数、标签数。
  Future<RadioStats> loadLocalStats() async {
    return await _datasource.loadLocalStats();
  }

  /// 获取所有分类列表（字符串格式）
  Future<List<String>> getCategories() async {
    final stations = await loadStations();
    final categories = stations.map((station) => station.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// 获取所有国家列表（字符串格式）
  Future<List<String>> getCountries() async {
    final stations = await loadStations();
    final countries = stations.map((station) => station.country).toSet().toList();
    countries.sort();
    return countries;
  }

  /// 加载国家列表（对象格式，包含国家码和电台数量）
  Future<List<Country>> loadCountries() async {
    return await _datasource.loadCountries();
  }

  /// 加载标签列表（包含电台数量）
  Future<List<Tag>> loadTags() async {
    return await _datasource.loadTags();
  }

  /// 根据标签加载电台
  ///
  /// [tag] - 标签名称
  Future<List<Station>> loadByTag(String tag) async {
    return await _datasource.loadByTag(tag);
  }

  /// 加载语言列表（包含电台数量）
  Future<List<Language>> loadLanguages() async {
    return await _datasource.loadLanguages();
  }

  /// 根据语言加载电台
  ///
  /// [language] - 语言名称
  Future<List<Station>> loadByLanguage(String language) async {
    return await _datasource.loadByLanguage(language);
  }
}
