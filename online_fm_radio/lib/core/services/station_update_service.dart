import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 电台数据更新服务类
///
/// 负责从服务器全量更新电台数据并缓存到本地。
/// 提供更新进度、状态和错误信息的监听。
/// 支持屏幕常亮（更新期间防止锁屏）和断点续传（中断后下次从上次位置继续）。
class StationUpdateService extends ChangeNotifier {
  /// 电台数据仓库
  final StationRepository _repository;

  /// 断点续传：已保存的 offset
  static const String _resumeOffsetKey = 'update_resume_offset';

  /// 断点续传：已保存的已获取数量
  static const String _resumeFetchedKey = 'update_resume_fetched';

  /// 断点续传：已保存的总量
  static const String _resumeTotalKey = 'update_resume_total';

  /// 是否正在更新中
  bool _isUpdating = false;

  /// 已获取的电台数量
  int _fetchedCount = 0;

  /// 总数量（用于计算进度）
  int _totalCount = 0;

  /// 错误信息（更新失败时设置）
  String? _errorMessage;

  /// 更新是否完成（成功或失败）
  bool _updateComplete = false;

  /// 是否存在未完成的断点续传数据
  bool _hasResumeData = false;

  /// 获取是否正在更新
  bool get isUpdating => _isUpdating;

  /// 获取已获取的电台数量
  int get fetchedCount => _fetchedCount;

  /// 获取总数量
  int get totalCount => _totalCount;

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 获取更新是否完成
  bool get updateComplete => _updateComplete;

  /// 获取更新进度（0.0 ~ 1.0）
  double get progress => _totalCount > 0 ? _fetchedCount / _totalCount : 0;

  /// 是否存在未完成的断点续传数据
  bool get hasResumeData => _hasResumeData;

  /// 创建更新服务实例
  ///
  /// [repository] - 数据仓库实例，可选，默认使用 StationRepository
  StationUpdateService({StationRepository? repository})
      : _repository = repository ?? StationRepository() {
    _checkResumeData();
  }

  /// 检查是否存在未完成的断点续传数据
  Future<void> _checkResumeData() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getInt(_resumeOffsetKey) ?? 0;
    if (offset > 0) {
      _hasResumeData = true;
      _fetchedCount = prefs.getInt(_resumeFetchedKey) ?? 0;
      _totalCount = prefs.getInt(_resumeTotalKey) ?? 0;
      notifyListeners();
    }
  }

  /// 全量更新电台数据
  ///
  /// 从服务器批量获取电台数据并缓存到本地，最多获取 10000 条。
  /// 更新过程中会通过 [notifyListeners] 通知进度变化。
  /// 更新完成后 [updateComplete] 会被设为 true。
  /// 如果存在断点续传数据，会从上次中断的位置继续。
  Future<void> updateAllStations() async {
    if (_isUpdating) return;

    // 开启屏幕常亮，防止更新过程中锁屏
    await WakelockPlus.enable();

    _isUpdating = true;
    _errorMessage = null;
    _updateComplete = false;

    // 检查是否有断点续传数据
    final prefs = await SharedPreferences.getInstance();
    final savedOffset = prefs.getInt(_resumeOffsetKey) ?? 0;
    if (savedOffset > 0) {
      _fetchedCount = prefs.getInt(_resumeFetchedKey) ?? 0;
      _totalCount = prefs.getInt(_resumeTotalKey) ?? 10000;
    } else {
      _fetchedCount = 0;
      _totalCount = 10000;
    }
    notifyListeners();

    try {
      final count = await _repository.fetchAllAndCache(
        resumeOffset: savedOffset,
        resumeFetched: _fetchedCount,
        onProgress: (fetched, total) {
          _fetchedCount = fetched;
          _totalCount = total;
          notifyListeners();
        },
        onBatchSaved: (offset, fetched, total) async {
          // 保存断点位置，支持下次断点续传
          await prefs.setInt(_resumeOffsetKey, offset);
          await prefs.setInt(_resumeFetchedKey, fetched);
          await prefs.setInt(_resumeTotalKey, total);
        },
      );

      _fetchedCount = count;
      _updateComplete = true;
      _hasResumeData = false;
      // 清除断点续传数据
      await prefs.remove(_resumeOffsetKey);
      await prefs.remove(_resumeFetchedKey);
      await prefs.remove(_resumeTotalKey);
    } catch (e) {
      _errorMessage = e.toString();
      _hasResumeData = true;
    } finally {
      _isUpdating = false;
      // 关闭屏幕常亮
      await WakelockPlus.disable();
      notifyListeners();
    }
  }

  /// 清除断点续传数据
  Future<void> clearResumeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resumeOffsetKey);
    await prefs.remove(_resumeFetchedKey);
    await prefs.remove(_resumeTotalKey);
    _hasResumeData = false;
    _fetchedCount = 0;
    _totalCount = 0;
    notifyListeners();
  }

  /// 重置状态
  ///
  /// 清除更新完成标记和错误信息，用于准备下一次更新
  void resetState() {
    _updateComplete = false;
    _errorMessage = null;
    notifyListeners();
  }
}
