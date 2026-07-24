import 'package:flutter/foundation.dart';

/// 动效设置服务类
///
/// 管理音乐可视化动效的各项设置，包括：
/// - 动效开关（是否启用）
/// - 柱状图柱子宽度系数（0.3-0.7，默认0.5）
/// - 动效速度系数（0.5-2.0，默认1.0）
class VisualizerSettingsService extends ChangeNotifier {
  bool _isEnabled = false;
  double _barWidthFactor = 0.5;
  double _speedFactor = 1.0;

  bool get isEnabled => _isEnabled;
  double get barWidthFactor => _barWidthFactor;
  double get speedFactor => _speedFactor;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void setBarWidthFactor(double factor) {
    _barWidthFactor = factor.clamp(0.3, 0.7);
    notifyListeners();
  }

  void setSpeedFactor(double factor) {
    _speedFactor = factor.clamp(0.5, 2.0);
    notifyListeners();
  }
}
