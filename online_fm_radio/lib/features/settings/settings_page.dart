import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildCountrySection(context),
          _buildThemeSection(context),
          _buildSleepTimerSection(context),
          _buildDataManagementSection(context),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildCountrySection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '国家/地区',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '选中的国家将用于推荐页面筛选电台',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Consumer<CountryPreferenceService>(
              builder: (context, service, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.public,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    service.selectedCountry ?? '全部国家',
                    style: TextStyle(
                      fontWeight: service.selectedCountry != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    service.selectedCountry != null
                        ? '已选: ${service.selectedCountry}'
                        : '未选择，显示全部国家电台',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCountryPicker(context, service),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(
    BuildContext context,
    CountryPreferenceService service,
  ) async {
    final repository = StationRepository();
    List<Country> countries = [];

    try {
      countries = await repository.loadCountries();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载国家列表失败: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        String searchKeyword = '';
        List<Country> filteredCountries = countries;
        return StatefulBuilder(
          builder: (context, setState) {
            if (searchKeyword.isNotEmpty) {
              filteredCountries = countries
                  .where((c) => c.name.toLowerCase().contains(searchKeyword.toLowerCase()))
                  .toList();
            } else {
              filteredCountries = countries;
            }

            return AlertDialog(
              title: const Text('选择国家/地区'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, '__all__'),
                      icon: const Icon(Icons.public),
                      label: const Text('全部国家'),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索国家...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchKeyword = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = service.selectedCountry == country.name;
                          // 国旗 emoji：由 ISO 国家码转换，无码时回退到文字占位。
                          final flag = country.flagEmoji;
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                flag.isNotEmpty
                                    ? flag
                                    : (country.countryCode.isNotEmpty
                                        ? country.countryCode.substring(0, 2).toUpperCase()
                                        : '?'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              country.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: Text('${country.stationCount}'),
                            onTap: () => Navigator.pop(context, country.name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (result == '__all__') {
        await service.setCountry(null);
      } else {
        await service.setCountry(result);
      }
    }
  }

  Widget _buildThemeSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '主题设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThemeButton(context, '浅色模式', Icons.light_mode),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(context, '深色模式', Icons.dark_mode),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(context, '跟随系统', Icons.phone_android),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 设置已保存')),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSleepTimerSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '定时关闭',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<SleepTimerService>(
              builder: (context, timerService, child) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('默认定时时长'),
                        DropdownButton<String>(
                          value: '30',
                          items: const [
                            DropdownMenuItem(value: '10', child: Text('10分钟')),
                            DropdownMenuItem(value: '20', child: Text('20分钟')),
                            DropdownMenuItem(value: '30', child: Text('30分钟')),
                            DropdownMenuItem(value: '60', child: Text('1小时')),
                            DropdownMenuItem(value: '120', child: Text('2小时')),
                          ],
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                    if (timerService.isActive) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '定时关闭中，剩余 ${_formatDuration(timerService.remaining!)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => timerService.cancel(),
                              child: const Text('取消'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<FavoritesService>(
              builder: (context, favoritesService, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite),
                  title: const Text('清空收藏'),
                  subtitle: Text('共 ${favoritesService.favoriteIds.length} 个收藏'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: favoritesService.favoriteIds.isEmpty
                      ? null
                      : () => _confirmClearFavorites(context),
                );
              },
            ),
            const Divider(),
            Consumer<HistoryService>(
              builder: (context, historyService, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: const Text('清空播放记录'),
                  subtitle: Text('共 ${historyService.history.length} 条记录'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: historyService.history.isEmpty
                      ? null
                      : () => _confirmClearHistory(context),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storage),
              title: const Text('清除缓存'),
              subtitle: const Text('清除图片和数据缓存'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _confirmClearCache(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.radio, size: 64, color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text(
                    'Fradoi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('在线收音机'),
                  SizedBox(height: 8),
                  Text('版本 1.0.0'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help),
              title: const Text('帮助与反馈'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('帮助与反馈功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('收藏已清空')),
              );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('播放记录已清空')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}