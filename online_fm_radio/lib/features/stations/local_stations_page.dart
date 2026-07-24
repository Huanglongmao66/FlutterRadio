import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/local_station_service.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class LocalStationsPage extends StatefulWidget {
  const LocalStationsPage({super.key});

  @override
  State<LocalStationsPage> createState() => _LocalStationsPageState();
}

class _LocalStationsPageState extends State<LocalStationsPage> {
  String _searchKeyword = '';

  List<Station> get _filteredStations {
    final stations = context.watch<LocalStationService>().stations;
    if (_searchKeyword.isEmpty) return stations;
    final keyword = _searchKeyword.toLowerCase();
    return stations
        .where((s) =>
            s.name.toLowerCase().contains(keyword) ||
            s.country.toLowerCase().contains(keyword) ||
            s.language.toLowerCase().contains(keyword) ||
            s.category.toLowerCase().contains(keyword))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final stationCount = context.watch<LocalStationService>().stations.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('本地电台 ($stationCount)'),
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
    final stations = _filteredStations;

    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchKeyword.isEmpty
                  ? '暂无本地电台'
                  : '没有找到匹配的电台',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_searchKeyword.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '请在设置中导入 M3U/M3U8/JSON 文件',
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
