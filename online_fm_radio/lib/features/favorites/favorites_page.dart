import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
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

  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        final favoriteIds = favoritesService.favoriteIds;
        
        if (favoriteIds.isEmpty) {
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
          itemCount: favoriteIds.length,
          itemBuilder: (context, index) {
            final stationId = favoriteIds[index];
            return _buildFavoriteStationCard(context, stationId);
          },
        );
      },
    );
  }

  Widget _buildFavoriteStationCard(BuildContext context, String stationId) {
    final historyService = Provider.of<HistoryService>(context, listen: false);
    final favoritesService = Provider.of<FavoritesService>(context);
    
    final station = historyService.history.firstWhere(
      (s) => s.id == stationId,
      orElse: () => Station(
        id: stationId,
        name: '未知电台',
        url: '',
        logo: '',
        country: '',
        language: '',
        category: '',
        description: '',
      ),
    );

    final isFavorite = favoritesService.isFavorite(stationId);

    return StationCard(
      station: station,
      onTap: () => Navigator.pushNamed(
        context,
        '/player',
        arguments: station,
      ),
    );
  }

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