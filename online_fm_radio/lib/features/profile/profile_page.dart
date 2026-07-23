import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/features/home/home_page_view_model.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppTopBar(title: '我的'),
      body: Consumer<StationUpdateService>(
        builder: (context, updateService, child) {
          if (updateService.updateComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<HomePageViewModel>(context, listen: false).refresh();
              _showUpdateResult(context, updateService);
              updateService.resetState();
            });
          }

          return ListView(
            children: [
              _buildUserProfile(context),
              _buildSettingsSection(context),
              _buildUpdateStationSection(context, updateService),
              _buildFavoritesSection(context),
              _buildHistorySection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF6366F1),
            child: Icon(
              Icons.person,
              size: 48,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Fradoi 用户',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '在线收听电台',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('帮助与反馈'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('帮助与反馈功能开发中')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('关于'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Fradoi',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.radio, size: 48),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateStationSection(
      BuildContext context, StationUpdateService updateService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_download, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    '电台数据',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (updateService.isUpdating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => _startUpdate(context, updateService),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('更新电台列表'),
                    ),
                ],
              ),
              if (updateService.isUpdating) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: updateService.progress > 0
                      ? updateService.progress
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  '正在后台获取电台数据... (${updateService.fetchedCount} / ${updateService.totalCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ] else if (updateService.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  '更新失败: ${updateService.errorMessage}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  '点击更新从服务器获取最新电台列表',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startUpdate(BuildContext context, StationUpdateService service) {
    service.updateAllStations();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在后台更新电台列表...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUpdateResult(BuildContext context, StationUpdateService service) {
    if (service.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新失败: ${service.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新成功！共获取 ${service.fetchedCount} 个电台'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
        // 直接使用 FavoritesService 中保存的完整 Station 列表，
        // 不再依赖播放历史查找，确保收藏电台可正常播放。
        final favoriteStations = favoritesService.favorites;

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