import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/models/language.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StationRepository _repository = StationRepository();
  List<Station> _allStations = [];
  List<Station> _recommendedStations = [];
  List<Country> _countries = [];
  List<Language> _languages = [];
  String? _selectedCountry;
  bool _isLoading = true;
  CountryPreferenceService? _countryService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countryService = context.read<CountryPreferenceService>();
      _countryService!.addListener(_onCountryPreferenceChanged);
      // Apply the persisted preference once available.
      _applyCountryFilter(_countryService!.selectedCountry);
    });
  }

  void _onCountryPreferenceChanged() {
    _applyCountryFilter(_countryService?.selectedCountry);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadRecommendedStations(),
        _loadCountries(),
        _loadLanguages(),
      ]);
    } catch (e) {
      debugPrint('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendedStations() async {
    try {
      _allStations = await _repository.loadStations();
      _applyCountryFilter(_countryService?.selectedCountry);
    } catch (e) {
      debugPrint('Failed to load recommended stations: $e');
    }
  }

  void _applyCountryFilter(String? country) {
    setState(() {
      _selectedCountry = country;
      if (country == null || country.isEmpty) {
        _recommendedStations = _allStations.take(50).toList();
      } else {
        _recommendedStations = _allStations
            .where((s) => s.country == country)
            .take(50)
            .toList();
      }
    });
  }

  void _onCountrySelected(String? country) async {
    // Persist the choice via the service; the listener re-applies the filter.
    final service = context.read<CountryPreferenceService>();
    await service.setCountry(country);
  }

  Future<void> _loadCountries() async {
    try {
      _countries = await _repository.loadCountries();
    } catch (e) {
      debugPrint('Failed to load countries: $e');
    }
  }

  Future<void> _loadLanguages() async {
    try {
      _languages = await _repository.loadLanguages();
    } catch (e) {
      debugPrint('Failed to load languages: $e');
    }
  }

  @override
  void dispose() {
    _countryService?.removeListener(_onCountryPreferenceChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppTopBar(
        title: 'Fradoi',
        selectedCountry: _selectedCountry,
        onCountrySelected: _onCountrySelected,
      ),
      body: Column(
        children: [
          if (_selectedCountry != null)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '当前筛选: $_selectedCountry',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _onCountrySelected(null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '推荐'),
              Tab(text: '国家'),
              Tab(text: '语言'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStationList(_recommendedStations),
                _buildCountryList(),
                _buildLanguageList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationList(List<Station> stations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_selectedCountry != null
                ? '$_selectedCountry 暂无电台'
                : '暂无电台'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return StationCard(
          station: station,
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: station,
          ),
        );
      },
    );
  }

  Widget _buildCountryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_countries.isEmpty) {
      return const Center(child: Text('暂无国家数据'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _countries.length,
      itemBuilder: (context, index) {
        final country = _countries[index];
        final isSelected = _selectedCountry == country.name;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            radius: 24,
            child: Text(
              country.countryCode.isNotEmpty
                  ? country.countryCode.substring(0, 2).toUpperCase()
                  : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            country.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${country.stationCount}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/country_stations',
              arguments: country,
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_languages.isEmpty) {
      return const Center(child: Text('暂无语言数据'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _languages.length,
      itemBuilder: (context, index) {
        final language = _languages[index];
        return ListTile(
          title: Text(
            _capitalize(language.name),
            style: const TextStyle(fontSize: 20),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${language.stationCount}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/language_stations',
              arguments: language,
            );
          },
        );
      },
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}