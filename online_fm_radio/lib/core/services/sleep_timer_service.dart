import 'dart:async';

import 'package:flutter/foundation.dart';

/// 定时关闭服务类
///
/// 提供播放定时关闭功能，支持启动、取消和状态监听。
/// 定时结束时自动触发通知，上层可监听 [isCompleted] 判断是否需要停止播放。
class SleepTimerService extends ChangeNotifier {
  /// 定时器实例
  Timer? _timer;

  /// 剩余时间
  Duration? _remaining;

  /// 是否处于激活状态
  bool _isActive = false;

  /// 获取剩余时间
  Duration? get remaining => _remaining;

  /// 获取是否激活
  bool get isActive => _isActive;

  /// 启动定时关闭
  ///
  /// [duration] - 定时时长
  ///
  /// 启动前会先取消已存在的定时器，然后每秒更新剩余时间，
  /// 时间到达后调用 [_complete] 完成定时。
  void start(Duration duration) {
    cancel();

    _remaining = duration;
    _isActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining != null && _remaining! > Duration.zero) {
        _remaining = _remaining! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        _complete();
      }
    });
  }

  /// 取消定时关闭
  ///
  /// 清除定时器并重置状态
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _isActive = false;
    notifyListeners();
  }

  /// 定时完成处理
  ///
  /// 将剩余时间设为零，标记为未激活状态
  void _complete() {
    _timer?.cancel();
    _timer = null;
    _remaining = Duration.zero;
    _isActive = false;
    notifyListeners();
  }

  /// 判断定时是否已完成
  ///
  /// 返回 true 表示定时已结束（非激活状态且剩余时间为零）
  bool get isCompleted => !_isActive && _remaining == Duration.zero;

  @override
  void dispose() {
    /// 释放时取消定时器
    _timer?.cancel();
    super.dispose();
  }
}