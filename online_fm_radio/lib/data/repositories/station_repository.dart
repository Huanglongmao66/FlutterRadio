import '../models/station.dart';
import '../datasources/local_station_datasource.dart';

class StationRepository {
  final LocalStationDatasource _localDatasource;
  List<Station>? _cachedStations;

  StationRepository({LocalStationDatasource? localDatasource})
      : _localDatasource = localDatasource ?? LocalStationDatasource();

  Future<List<Station>> loadStations() async {
    if (_cachedStations != null) {
      return _cachedStations!;
    }
    _cachedStations = await _localDatasource.loadStations();
    return _cachedStations!;
  }

  Future<List<Station>> filterByCategory(String category) async {
    final stations = await loadStations();
    return stations.where((station) => station.category == category).toList();
  }

  Future<List<Station>> filterByCountry(String country) async {
    final stations = await loadStations();
    return stations.where((station) => station.country == country).toList();
  }

  Future<List<Station>> search(String keyword) async {
    final stations = await loadStations();
    final lowerKeyword = keyword.toLowerCase();
    return stations.where((station) {
      return station.name.toLowerCase().contains(lowerKeyword) ||
          station.description.toLowerCase().contains(lowerKeyword) ||
          station.country.toLowerCase().contains(lowerKeyword) ||
          station.category.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  Future<List<String>> getCategories() async {
    final stations = await loadStations();
    return stations.map((station) => station.category).toSet().toList();
  }

  Future<List<String>> getCountries() async {
    final stations = await loadStations();
    return stations.map((station) => station.country).toSet().toList();
  }

  Future<List<Station>> loadFromApi() async {
    return [];
  }
}