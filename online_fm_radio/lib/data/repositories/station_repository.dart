import '../models/station.dart';
import '../datasources/local_station_datasource.dart';

class StationRepository {
  final LocalStationDatasource _datasource;
  List<Station>? _cachedStations;

  StationRepository({LocalStationDatasource? datasource})
      : _datasource = datasource ?? LocalStationDatasource();

  Future<List<Station>> loadStations() async {
    if (_cachedStations != null) {
      return _cachedStations!;
    }
    _cachedStations = await _datasource.loadStations();
    return _cachedStations!;
  }

  Future<List<Station>> loadByCountry(String countryCode) async {
    return await _datasource.loadByCountry(countryCode);
  }

  Future<List<Station>> search(String keyword) async {
    if (keyword.length >= 2) {
      return await _datasource.searchStations(keyword);
    }
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
    final categories = stations.map((station) => station.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<List<String>> getCountries() async {
    final stations = await loadStations();
    final countries = stations.map((station) => station.country).toSet().toList();
    countries.sort();
    return countries;
  }

  void clearCache() {
    _cachedStations = null;
  }
}