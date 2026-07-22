import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StationRepository _repository = StationRepository();
  List<Station> _recommendedStations = [];
  List<Station> _countryStations = [];
  List<Station> _languageStations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      final allStations = await _repository.loadStations();
      _recommendedStations = allStations.take(20).toList();
      _countryStations = allStations
          .where((s) => s.country.isNotEmpty)
          .take(20)
          .toList();
      _languageStations = allStations
          .where((s) => s.language.isNotEmpty)
          .take(20)
          .toList();
    } catch (e) {
      debugPrint('Failed to load stations: $e');
    } finally {
      setState(() => _isLoading = false);
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
                _buildStationList(_countryStations),
                _buildStationList(_languageStations),
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
          isFavorite: Provider.of<FavoritesService>(context).isFavorite(station.id),
          onFavorite: () => Provider.of<FavoritesService>(context, listen: false)
              .toggleFavorite(station.id),
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: station,
          ),
        );
      },
    );
  }
}
