import 'package:flutter/material.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class CachedStationsPage extends StatefulWidget {
  const CachedStationsPage({super.key});

  @override
  State<CachedStationsPage> createState() => _CachedStationsPageState();
}

class _CachedStationsPageState extends State<CachedStationsPage> {
  String _searchKeyword = '';
  List<Station> _stations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = StationRepository();
      _stations = await repository.getCachedStations();
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _loading = false;
    });
  }

  List<Station> get _filteredStations {
    if (_searchKeyword.isEmpty) return _stations;
    final keyword = _searchKeyword.toLowerCase();
    return _stations
        .where((s) =>
            s.name.toLowerCase().contains(keyword) ||
            s.country.toLowerCase().contains(keyword) ||
            s.language.toLowerCase().contains(keyword) ||
            s.category.toLowerCase().contains(keyword))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('缓存电台 (${_stations.length})'),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            TextButton(onPressed: _loadStations, child: const Text('重试')),
          ],
        ),
      );
    }

    final stations = _filteredStations;

    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchKeyword.isEmpty
                  ? '暂无缓存电台'
                  : '没有找到匹配的电台',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_searchKeyword.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '请在个人中心更新电台数据',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        return StationCard(
          station: stations[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: stations[index],
          ),
        );
      },
    );
  }
}
