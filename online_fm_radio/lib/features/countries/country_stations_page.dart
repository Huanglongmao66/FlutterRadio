import 'package:flutter/material.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class CountryStationsPage extends StatefulWidget {
  final Country country;

  const CountryStationsPage({super.key, required this.country});

  @override
  State<CountryStationsPage> createState() => _CountryStationsPageState();
}

class _CountryStationsPageState extends State<CountryStationsPage> {
  final StationRepository _repository = StationRepository();
  List<Station> _stations = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      // 第一步：先从全量缓存中按国家名查找该国家的电台。
      final allStations = await _repository.loadStations();
      final cached = allStations
          .where((s) => s.country == widget.country.name)
          .toList();

      if (cached.isNotEmpty) {
        _stations = cached;
      } else {
        // 第二步：缓存中没有，优先按国家名从 API 精确拉取（更可靠）。
        _stations = await _repository.loadByCountryName(widget.country.name);

        // 第三步：按国家名仍无结果且有国家码时，回退到按国家码拉取。
        if (_stations.isEmpty && widget.country.countryCode.isNotEmpty) {
          _stations = await _repository.loadByCountry(widget.country.countryCode);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.country.name),
        centerTitle: true,
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
            Text('正在加载电台...'),
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

    if (_stations.isEmpty) {
      return const Center(child: Text('该国家暂无可用电台'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _stations.length,
      itemBuilder: (context, index) {
        return StationCard(
          station: _stations[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: _stations[index],
          ),
        );
      },
    );
  }
}
