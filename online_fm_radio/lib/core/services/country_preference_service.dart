import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountryPreferenceService extends ChangeNotifier {
  static const String _storageKey = 'selected_country';

  String? _selectedCountry;

  String? get selectedCountry => _selectedCountry;

  Future<void> loadCountry() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCountry = prefs.getString(_storageKey);
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