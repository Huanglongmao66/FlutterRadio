import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/models/tag.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_logo.dart';

/// 探索页：分三个板块展示电台内容。
/// 1. 新电台：按最近活跃时间排序的最新电台，横向滑动。
/// 2. 音乐电台：标签为 'music' 的电台，横向滑动。
/// 3. 音乐类型：标签云（网格），点击进入对应标签的电台列表。
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  /// 电台数据仓库。
  final StationRepository _repository = StationRepository();

  /// 新电台列表（最近活跃）。
  List<Station> _newestStations = [];

  /// 音乐电台列表（标签 music）。
  List<Station> _musicStations = [];

  /// 音乐类型 / 标签列表。
  List<Tag> _tags = [];

  /// 过滤后的标签列表（根据搜索关键词）。
  List<Tag> _filteredTags = [];

  /// 整体加载标志。
  bool _isLoading = true;

  /// 标签搜索关键词。
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// 并行加载新电台、音乐电台、标签三类数据。
  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.loadNewestStations(limit: 20),
        _repository.loadByTag('music'),
        _repository.loadTags(),
      ]);
      _newestStations = results[0] as List<Station>;
      _musicStations = results[1] as List<Station>;
      _tags = results[2] as List<Tag>;
      _filterTags();
    } catch (e) {
      debugPrint('Failed to load explore data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 根据搜索关键词过滤标签。
  void _filterTags() {
    if (_searchKeyword.isEmpty) {
      _filteredTags = _tags;
    } else {
      _filteredTags = _tags
          .where((t) => t.name.toLowerCase().contains(_searchKeyword.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppTopBar(title: '探索'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 三个板块均为空时提示。
    if (_newestStations.isEmpty &&
        _musicStations.isEmpty &&
        _filteredTags.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        children: [
          // 1. 新电台（横向）
          if (_newestStations.isNotEmpty) _buildSectionHeader('新电台'),
          if (_newestStations.isNotEmpty)
            _buildHorizontalStationList(_newestStations),

          // 2. 音乐电台（横向）
          if (_musicStations.isNotEmpty) _buildSectionHeader('音乐电台'),
          if (_musicStations.isNotEmpty)
            _buildHorizontalStationList(_musicStations),

          // 3. 音乐类型（搜索 + 网格）
          if (_tags.isNotEmpty) ...[
            _buildSectionHeader('音乐类型'),
            _buildTagSearch(),
            _buildTagGrid(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 板块标题：统一风格的小标题 + 装饰条。
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 横向电台列表：固定高度，横向滑动展示电台卡片。
  Widget _buildHorizontalStationList(List<Station> stations) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            _buildHorizontalStationCard(stations[index]),
      ),
    );
  }

  /// 横向电台卡片：logo + 名称 + 国家，点击进入播放页。
  Widget _buildHorizontalStationCard(Station station) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/player',
        arguments: station,
      ),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StationLogo(
                station: station,
                size: 100,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              station.country,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标签搜索框。
  Widget _buildTagSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索音乐类型...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
            _filterTags();
          });
        },
      ),
    );
  }

  /// 音乐类型网格：点击进入对应标签电台列表。
  Widget _buildTagGrid() {
    if (_filteredTags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('没有找到匹配的音乐类型')),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: _filteredTags.length,
      itemBuilder: (context, index) {
        final tag = _filteredTags[index];
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/tag_stations', arguments: tag),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tag.stationCount} 个电台',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
