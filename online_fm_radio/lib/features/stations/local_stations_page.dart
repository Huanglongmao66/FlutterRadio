import 'package:flutter/material.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class LocalStationsPage extends StatefulWidget {
  const LocalStationsPage({super.key});

  @override
  State<LocalStationsPage> createState() => _LocalStationsPageState();
}

class _LocalStationsPageState extends State<LocalStationsPage> {
  final StationRepository _repository = StationRepository();
  List<Station> _stations = [];
  List<Station> _filteredStations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _stations = await _repository.loadStations();
      _filterStations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterStations() {
    if (_searchKeyword.isEmpty) {
      _filteredStations = _stations;
    } else {
      final keyword = _searchKeyword.toLowerCase();
      _filteredStations = _stations
          .where((s) =>
              s.name.toLowerCase().contains(keyword) ||
              s.country.toLowerCase().contains(keyword) ||
              s.language.toLowerCase().contains(keyword) ||
              s.category.toLowerCase().contains(keyword))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('本地电台 (${_stations.length})'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索电台...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                  _filterStations();
                });
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载本地电台...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStations,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredStations.isEmpty) {
      return const Center(child: Text('没有找到匹配的电台'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        return StationCard(
          station: _filteredStations[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: _filteredStations[index],
          ),
        );
      },
    );
  }
}
