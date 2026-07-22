import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

class StationUpdateService extends ChangeNotifier {
  final StationRepository _repository;

  bool _isUpdating = false;
  int _fetchedCount = 0;
  int _totalCount = 0;
  String? _errorMessage;
  bool _updateComplete = false;

  bool get isUpdating => _isUpdating;
  int get fetchedCount => _fetchedCount;
  int get totalCount => _totalCount;
  String? get errorMessage => _errorMessage;
  bool get updateComplete => _updateComplete;
  double get progress => _totalCount > 0 ? _fetchedCount / _totalCount : 0;

  StationUpdateService({StationRepository? repository})
      : _repository = repository ?? StationRepository();

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

  void resetState() {
    _updateComplete = false;
    _errorMessage = null;
    notifyListeners();
  }
}
