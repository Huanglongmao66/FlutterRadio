import 'dart:async';
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
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  Timer? _searchDebounce;

  List<Station> get filteredStations => _filteredStations;
  List<String> get categories => _categories;
  List<String> get countries => _countries;
  String? get currentCategory => _currentCategory;
  String? get currentCountry => _currentCountry;
  String get searchKeyword => _searchKeyword;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String? get errorMessage => _errorMessage;

  HomePageViewModel({StationRepository? stationRepository})
      : _stationRepository = stationRepository ?? StationRepository() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allStations = await _stationRepository.loadStations();
      _filteredStations = _allStations;
      _categories = await _stationRepository.getCategories();
      _countries = await _stationRepository.getCountries();
      _currentOffset = _allStations.length;
      _hasMoreData = _allStations.length >= _pageSize;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load stations: $e';
      _filteredStations = [];
      _hasMoreData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMoreData || _searchKeyword.isNotEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newStations = await _stationRepository.loadMoreStations(_currentOffset);

      if (newStations.isEmpty) {
        _hasMoreData = false;
      } else {
        _allStations.addAll(newStations);
        _currentOffset += newStations.length;
        _hasMoreData = newStations.length >= _pageSize;
        _filterStations();
      }
    } catch (e) {
      debugPrint('Failed to load more: $e');
      _hasMoreData = false;
    } finally {
      _isLoadingMore = false;
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

    _searchDebounce?.cancel();

    if (keyword.length >= 2) {
      _isSearching = true;
      notifyListeners();

      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _performApiSearch();
      });
    } else {
      _filterStations();
    }
  }

  Future<void> _performApiSearch() async {
    if (_searchKeyword.length < 2) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    try {
      final results = await _stationRepository.search(_searchKeyword);
      _filteredStations = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Search failed: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
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

  void clearFilters() {
    _currentCategory = null;
    _currentCountry = null;
    _searchKeyword = '';
    _filteredStations = _allStations;
    notifyListeners();
  }

  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMoreData = true;
    await _init();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
