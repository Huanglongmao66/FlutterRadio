import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final StationRepository _repository = StationRepository();
  List<Station> _stations = [];
  List<Station> _filteredStations = [];
  bool _isLoading = false;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      _stations = await _repository.loadStations();
      _filteredStations = _stations;
    } catch (e) {
      debugPrint('Failed to load stations for search: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterStations() {
    _searchKeyword = _searchController.text.trim().toLowerCase();
    setState(() {
      if (_searchKeyword.isEmpty) {
        _filteredStations = _stations;
      } else {
        _filteredStations = _stations.where((station) {
          return station.name.toLowerCase().contains(_searchKeyword) ||
              station.country.toLowerCase().contains(_searchKeyword) ||
              station.language.toLowerCase().contains(_searchKeyword) ||
              station.category.toLowerCase().contains(_searchKeyword);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '',
        showSearch: false,
        showCountryFilter: false,
        showDownload: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _filterStations(),
          decoration: const InputDecoration(
            hintText: '搜索电台、国家、语言...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredStations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchKeyword.isEmpty ? '暂无电台数据' : '未找到相关电台',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        final station = _filteredStations[index];
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
}