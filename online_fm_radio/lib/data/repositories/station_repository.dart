import '../models/country.dart';
import '../models/language.dart';
import '../models/station.dart';
import '../models/tag.dart';
import '../datasources/local_station_datasource.dart';

class StationRepository {
  final LocalStationDatasource _datasource;

  StationRepository({LocalStationDatasource? datasource})
      : _datasource = datasource ?? LocalStationDatasource();

  Future<List<Station>> loadStations({bool forceRefresh = false}) async {
    return await _datasource.loadStations(forceRefresh: forceRefresh);
  }

  Future<List<Station>> loadMoreStations(int offset) async {
    return await _datasource.loadMoreStations(offset);
  }

  Future<int> fetchAllAndCache({void Function(int fetched, int total)? onProgress}) async {
    return await _datasource.fetchAllAndCache(onProgress: onProgress);
  }

  Future<List<Station>> loadByCountry(String countryCode) async {
    return await _datasource.loadByCountry(countryCode);
  }

  Future<List<Station>> loadByCountryName(String countryName) async {
    return await _datasource.loadByCountryName(countryName);
  }

  Future<List<Station>> loadNewestStations({int limit = 20}) async {
    return await _datasource.loadNewestStations(limit: limit);
  }

  Future<List<Station>> search(String keyword) async {
    if (keyword.length >= 2) {
      return await _datasource.searchStations(keyword);
    }
    return [];
  }

  Future<List<Station>> searchCached(String keyword) async {
    return await _datasource.searchCachedStations(keyword);
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

  Future<List<Country>> loadCountries() async {
    return await _datasource.loadCountries();
  }

  Future<List<Tag>> loadTags() async {
    return await _datasource.loadTags();
  }

  Future<List<Station>> loadByTag(String tag) async {
    return await _datasource.loadByTag(tag);
  }

  Future<List<Language>> loadLanguages() async {
    return await _datasource.loadLanguages();
  }

  Future<List<Station>> loadByLanguage(String language) async {
    return await _datasource.loadByLanguage(language);
  }
}
