import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

/// 收藏页：包含「收藏列表」与「最近播放」两个 Tab。
/// - 收藏列表：直接使用 FavoritesService 中保存的完整 Station 对象，
///   因此即使未在播放记录中也能正常播放（修复历史收藏无法播放的 bug）。
/// - 最近播放：来自 HistoryService（播放时自动写入）。
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: const AppTopBar(title: '收藏'),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '收藏列表'),
              Tab(text: '最近播放'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesList(context),
                _buildHistoryList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 收藏列表：直接消费 FavoritesService.favorites（完整 Station 列表）。
  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        // 使用完整 Station 列表，确保 streamUrl 等播放信息完整可用。
        final favorites = favoritesService.favorites;

        if (favorites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无收藏电台'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final station = favorites[index];
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
      },
    );
  }

  /// 最近播放列表：消费 HistoryService.history。
  Widget _buildHistoryList(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, historyService, child) {
        if (historyService.history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无播放记录'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: historyService.history.length,
          itemBuilder: (context, index) {
            final station = historyService.history[index];
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
      },
    );
  }
}
