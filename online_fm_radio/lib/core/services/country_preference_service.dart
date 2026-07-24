import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 国家偏好服务类
///
/// 管理用户选择的国家偏好设置，用于推荐页面筛选电台。
/// 使用 SharedPreferences 持久化存储，支持加载和更新操作。
class CountryPreferenceService extends ChangeNotifier {
  /// SharedPreferences 存储键
  static const String _storageKey = 'selected_country';

  /// 当前选中的国家名称（英文）
  String? _selectedCountry;

  /// 获取当前选中的国家名称
  String? get selectedCountry => _selectedCountry;

  /// 从 SharedPreferences 加载已保存的国家偏好
  Future<void> loadCountry() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCountry = prefs.getString(_storageKey);
    notifyListeners();
  }

  /// 设置国家偏好
  ///
  /// [country] - 国家名称（英文），为空时清除偏好
  ///
  /// 将选择写入 SharedPreferences 并通知监听者
  Future<void> setCountry(String? country) async {
    _selectedCountry = country;
    final prefs = await SharedPreferences.getInstance();

    if (country == null || country.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, country);
    }

    notifyListeners();
  }
}