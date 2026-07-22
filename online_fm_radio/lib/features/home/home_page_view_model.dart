import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

class HomePageViewModel extends ChangeNotifier {
  final StationRepository _stationRepository;

  List<Station> _allStations = [];
  List<Station> _filteredStations = [];
  List<String> _categories = [];
  List<String> _countries = [];

  String? _currentCategory;
  String? _currentCountry;
  String _searchKeyword = '';
  bool _isLoading = true;

  List<Station> get filteredStations => _filteredStations;
  List<String> get categories => _categories;
  List<String> get countries => _countries;
  String? get currentCategory => _currentCategory;
  String? get currentCountry => _currentCountry;
  String get searchKeyword => _searchKeyword;
  bool get isLoading => _isLoading;

  HomePageViewModel({StationRepository? stationRepository})
      : _stationRepository = stationRepository ?? StationRepository() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allStations = await _stationRepository.loadStations();
      _filteredStations = _allStations;
      _categories = await _stationRepository.getCategories();
      _countries = await _stationRepository.getCountries();
    } catch (e) {
      _filteredStations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _currentCategory = category;
    _filterStations();
  }

  void setCountry(String? country) {
    _currentCountry = country;
    _filterStations();
  }

  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    _filterStations();
  }

  void clearFilters() {
    _currentCategory = null;
    _currentCountry = null;
    _searchKeyword = '';
    _filterStations();
  }

  void _filterStations() {
    List<Station> result = _allStations;

    if (_currentCategory != null && _currentCategory!.isNotEmpty) {
      result = result.where((s) => s.category == _currentCategory).toList();
    }

    if (_currentCountry != null && _currentCountry!.isNotEmpty) {
      result = result.where((s) => s.country == _currentCountry).toList();
    }

    if (_searchKeyword.isNotEmpty) {
      final lowerKeyword = _searchKeyword.toLowerCase();
      result = result.where((s) {
        return s.name.toLowerCase().contains(lowerKeyword) ||
            s.description.toLowerCase().contains(lowerKeyword) ||
            s.country.toLowerCase().contains(lowerKeyword) ||
            s.category.toLowerCase().contains(lowerKeyword);
      }).toList();
    }

    _filteredStations = result;
    notifyListeners();
  }

  void refresh() {
    _init();
  }
}