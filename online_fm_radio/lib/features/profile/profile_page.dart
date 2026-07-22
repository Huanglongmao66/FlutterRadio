import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildUserProfile(context),
          _buildFavoritesSection(context),
          _buildHistorySection(context),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey,
            child: Icon(
              Icons.person,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'FM Radio 用户',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在线收听电台',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '收藏频道',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (favoritesService.favoriteIds.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearFavorites(context),
                      child: const Text(
                        '清空',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              _buildFavoritesList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        final historyService = Provider.of<HistoryService>(context, listen: false);
        final favoriteIds = favoritesService.favoriteIds;
        final favoriteStations = historyService.history
            .where((station) => favoriteIds.contains(station.id))
            .toList();

        if (favoriteStations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('暂无收藏频道'),
            ),
          );
        }

        return Column(
          children: favoriteStations
              .map((station) => StationCard(
                    station: station,
                    onTap: () => _navigateToPlayer(context, station),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, historyService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近播放',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (historyService.history.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearHistory(context),
                      child: const Text(
                        '清空',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              _buildHistoryList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, historyService, child) {
        if (historyService.history.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('暂无播放记录'),
            ),
          );
        }

        return Column(
          children: historyService.history
              .map((station) => StationCard(
                    station: station,
                    onTap: () => _navigateToPlayer(context, station),
                  ))
              .toList(),
        );
      },
    );
  }

  void _navigateToPlayer(BuildContext context, Station station) {
    Navigator.pushNamed(
      context,
      '/player',
      arguments: station,
    );
  }

  void _confirmClearFavorites(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有收藏频道吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<FavoritesService>(context, listen: false).clearAll();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有播放记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HistoryService>(context, listen: false).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}