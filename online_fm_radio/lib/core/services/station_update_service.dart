import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

/// 电台数据更新服务类
///
/// 负责从服务器全量更新电台数据并缓存到本地。
/// 提供更新进度、状态和错误信息的监听。
class StationUpdateService extends ChangeNotifier {
  /// 电台数据仓库
  final StationRepository _repository;

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

  /// 创建更新服务实例
  ///
  /// [repository] - 数据仓库实例，可选，默认使用 StationRepository
  StationUpdateService({StationRepository? repository})
      : _repository = repository ?? StationRepository();

  /// 全量更新电台数据
  ///
  /// 从服务器批量获取电台数据并缓存到本地，最多获取 10000 条。
  /// 更新过程中会通过 [notifyListeners] 通知进度变化。
  /// 更新完成后 [updateComplete] 会被设为 true。
  Future<void> updateAllStations() async {
    if (_isUpdating) return;

    _isUpdating = true;
    _errorMessage = null;
    _updateComplete = false;
    _fetchedCount = 0;
    _totalCount = 10000;
    notifyListeners();

    try {
      final count = await _repository.fetchAllAndCache(
        onProgress: (fetched, total) {
          _fetchedCount = fetched;
          _totalCount = total;
          notifyListeners();
        },
      );

      _fetchedCount = count;
      _updateComplete = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
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
