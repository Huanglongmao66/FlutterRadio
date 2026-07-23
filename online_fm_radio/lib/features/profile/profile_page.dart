import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/features/home/home_page_view_model.dart';
import 'package:online_fm_radio/data/models/radio_stats.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

/// "我的"页面
///
/// 包含用户信息、设置入口、电台数据更新、收藏列表和播放历史。
/// 监听 StationUpdateService 以显示更新进度和结果。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final StationRepository _repository = StationRepository();
  RadioStats? _stats;
  bool _loadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final stats = await _repository.loadLocalStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString();
          _loadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppTopBar(title: '我的'),
      body: Consumer<StationUpdateService>(
        builder: (context, updateService, child) {
          /// 更新完成后刷新主页数据并显示结果
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

  /// 构建用户信息区域
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
            'FMradio 用户',
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

  /// 构建设置区域
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
                  applicationName: 'FMradio',
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

  /// 构建电台数据更新区域
  ///
  /// [updateService] - 电台更新服务
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
              const SizedBox(height: 12),
              _buildStatsGrid(),
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计数据网格
  Widget _buildStatsGrid() {
    if (_loadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_statsError != null) {
      return Center(
        child: Column(
          children: [
            Text(
              '数据加载失败',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            TextButton(
              onPressed: _loadStats,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_stats == null) return const SizedBox.shrink();

    final items = [
      _StatItem(Icons.radio, '本地电台', '${_stats!.stations}'),
      _StatItem(Icons.public, '国家', '${_stats!.countries}'),
      _StatItem(Icons.language, '语言', '${_stats!.languages}'),
      _StatItem(Icons.label, '标签', '${_stats!.tags}'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 启动电台数据更新
  ///
  /// [service] - 电台更新服务
  void _startUpdate(BuildContext context, StationUpdateService service) {
    service.updateAllStations();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在后台更新电台列表...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示更新结果提示
  ///
  /// [service] - 电台更新服务
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

  /// 构建收藏频道区域
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

  /// 构建收藏列表
  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        /// 直接使用 FavoritesService 中保存的完整 Station 列表，
        /// 不再依赖播放历史查找，确保收藏电台可正常播放。
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

  /// 构建播放历史区域
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

  /// 构建播放历史列表
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

  /// 导航到播放页面
  ///
  /// [station] - 要播放的电台
  void _navigateToPlayer(BuildContext context, Station station) {
    Navigator.pushNamed(
      context,
      '/player',
      arguments: station,
    );
  }

  /// 确认清空收藏
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

  /// 确认清空播放历史
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

/// 统计数据项
class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  _StatItem(this.icon, this.label, this.value);
}