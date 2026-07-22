import 'package:flutter/material.dart';
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
  List<Station> _recommendedStations = [];
  List<Country> _countries = [];
  List<Language> _languages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
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
      final allStations = await _repository.loadStations();
      _recommendedStations = allStations.take(20).toList();
    } catch (e) {
      debugPrint('Failed to load recommended stations: $e');
    }
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppTopBar(title: 'Fradoi'),
      body: Column(
        children: [
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
      return const Center(child: Text('暂无电台'));
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
            style: const TextStyle(fontSize: 18),
          ),
          trailing: Text(
            '${country.stationCount}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
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
          trailing: Text(
            '${language.stationCount}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
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