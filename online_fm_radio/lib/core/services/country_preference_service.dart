import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountryPreferenceService extends ChangeNotifier {
  static const String _storageKey = 'selected_country';

  String? _selectedCountry;

  String? get selectedCountry => _selectedCountry;

  /// 加载已持久化的国家偏好。如果用户从未设置过，默认使用 "China"。
  Future<void> loadCountry() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCountry = prefs.getString(_storageKey);
    // 首次使用默认中国，让用户打开推荐页即可看到国内电台。
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      _selectedCountry = 'China';
      await prefs.setString(_storageKey, 'China');
    }
    notifyListeners();
  }

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