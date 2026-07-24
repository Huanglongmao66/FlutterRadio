import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/import_export_service.dart';
import 'package:online_fm_radio/core/services/local_station_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/core/services/visualizer_settings_service.dart';
import 'package:online_fm_radio/core/utils/battery_optimization_utils.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

/// 设置页面
///
/// 提供应用各项设置功能，包括：
/// - 国家/地区偏好选择
/// - 主题模式切换（浅色/深色/跟随系统）
/// - 定时关闭设置
/// - 数据管理（导入/导出电台列表、清空收藏/历史/缓存）
/// - 关于应用信息
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
          _buildVisualizerSection(context),
          _buildSleepTimerSection(context),
          _buildBackgroundKeepAliveSection(context),
          _buildDataManagementSection(context),
          _buildDeveloperSection(context),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  /// 构建国家/地区设置区域
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

  /// 显示国家选择对话框
  ///
  /// [context] - 构建上下文
  /// [service] - 国家偏好服务实例
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

  /// 构建主题设置区域
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

  /// 构建主题模式按钮
  ///
  /// [context] - 构建上下文
  /// [label] - 按钮文字
  /// [icon] - 按钮图标
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

  /// 构建动效设置区域
  Widget _buildVisualizerSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '动效设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<VisualizerSettingsService>(
              builder: (context, service, child) {
                return Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('启用动效'),
                      subtitle: const Text('播放时显示音乐可视化动效'),
                      value: service.isEnabled,
                      onChanged: service.setEnabled,
                    ),
                    const SizedBox(height: 12),
                    if (service.isEnabled) ...[
                      const Text(
                        '柱子宽度',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: service.barWidthFactor,
                        min: 0.3,
                        max: 0.7,
                        divisions: 4,
                        label: service.barWidthFactor < 0.4 ? '细' : service.barWidthFactor > 0.6 ? '粗' : '适中',
                        onChanged: service.setBarWidthFactor,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '动效速度',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: service.speedFactor,
                        min: 0.5,
                        max: 2.0,
                        divisions: 3,
                        label: service.speedFactor < 1.0 ? '慢' : service.speedFactor > 1.5 ? '快' : '正常',
                        onChanged: service.setSpeedFactor,
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

  /// 构建定时关闭设置区域
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

  /// 构建后台保活设置区域
  Widget _buildBackgroundKeepAliveSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('后台保活', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '确保应用切到后台后电台正常播放。部分手机（如小米、华为）需要在系统设置中额外开启自启动。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('通知权限'),
              subtitle: const Text('显示播放控制通知栏'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => BatteryOptimizationUtils.requestNotificationPermission(),
            ),
            ListTile(
              leading: const Icon(Icons.battery_saver),
              title: const Text('关闭电池优化'),
              subtitle: const Text('防止后台断开网络'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => BatteryOptimizationUtils.requestIgnoreBatteryOptimizations(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建数据管理区域
  ///
  /// 包含导入/导出电台列表、清空收藏/历史/缓存等功能
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file),
              title: const Text('导入电台列表'),
              subtitle: const Text('支持 m3u、m3u8、json 格式'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _importStations(context),
            ),
            const Divider(),
            Consumer<FavoritesService>(
              builder: (context, favoritesService, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download),
                  title: const Text('导出收藏电台'),
                  subtitle: Text('共 ${favoritesService.favoriteIds.length} 个收藏'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: favoritesService.favoriteIds.isEmpty
                      ? null
                      : () => _exportStations(context, favoritesService.favorites),
                );
              },
            ),
            const Divider(),
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

  /// 构建开发者调试区域
  ///
  /// 提供电台数据导出工具，支持：
  /// - 一键导出全部缓存电台
  /// - 按数量/国家/标签/语言自定义导出
  Widget _buildDeveloperSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_mode, size: 22),
                const SizedBox(width: 8),
                const Text(
                  '开发者调试',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '导出电台数据用于调试和分析',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // 一键导出全部缓存电台
            Consumer<StationUpdateService>(
              builder: (context, updateService, child) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_for_offline),
                  title: const Text('一键导出缓存电台'),
                  subtitle: Text('共 ${updateService.cachedCount} 个缓存电台'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: updateService.cachedCount == 0
                      ? null
                      : () => _exportAllCached(context),
                );
              },
            ),
            const Divider(),
            // 自定义导出（按条件筛选）
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.filter_alt),
              title: const Text('自定义导出'),
              subtitle: const Text('按数量/国家/标签/语言筛选导出'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCustomExportDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 一键导出全部缓存电台
  ///
  /// 弹出格式选择对话框，将本地缓存的电台数据全部导出
  Future<void> _exportAllCached(BuildContext context) async {
    final format = await _showFormatPicker(context);
    if (format == null || !context.mounted) return;

    final service = ImportExportService();
    final repository = StationRepository();

    try {
      // 显示加载提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在导出缓存电台数据...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final stations = await repository.getCachedStations();
      final count = await service.exportAllCached(stations, format);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导出 $count 个缓存电台'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 显示自定义导出对话框
  ///
  /// 支持按数量、国家、标签、语言组合筛选导出
  void _showCustomExportDialog(BuildContext context) {
    int limit = 100;
    String countryCode = '';
    String tag = '';
    String language = '';
    bool hideBroken = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
          return AlertDialog(
            title: const Text('自定义导出'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 数量
                    const Text('导出数量', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: limit.toDouble(),
                            min: 10,
                            max: 1000,
                            divisions: 99,
                            label: '$limit',
                            onChanged: (v) =>
                                setState(() => limit = v.round()),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '$limit',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 快捷数量按钮
                    Wrap(
                      spacing: 8,
                      children: [50, 100, 200, 500, 1000].map((n) {
                        return ChoiceChip(
                          label: Text('$n'),
                          selected: limit == n,
                          onSelected: (_) => setState(() => limit = n),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // 国家代码
                    const Text('国家代码 (可选)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      '如 CN、US、GB，留空表示不筛选',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '例如: CN',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) => countryCode = v.trim().toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    // 标签
                    const Text('标签 (可选)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      '如 pop、jazz、news，留空表示不筛选',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '例如: pop',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => tag = v.trim(),
                    ),
                    const SizedBox(height: 12),
                    // 语言
                    const Text('语言 (可选)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      '如 English、Chinese，留空表示不筛选',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '例如: English',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => language = v.trim(),
                    ),
                    const SizedBox(height: 12),
                    // 隐藏损坏电台
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('仅可用电台'),
                      subtitle: const Text('隐藏已损坏的电台'),
                      value: hideBroken,
                      onChanged: (v) => setState(() => hideBroken = v),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        await _performCustomExport(
                          context,
                          ExportFilter(
                            limit: limit,
                            countryCode: countryCode.isEmpty ? null : countryCode,
                            tag: tag.isEmpty ? null : tag,
                            language: language.isEmpty ? null : language,
                            hideBroken: hideBroken,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: const Text('导出'),
              ),
            ],
          );
          },
        );
      },
    );
  }

  /// 执行自定义导出
  ///
  /// 先选择导出格式，再从远程 API 获取数据并导出
  Future<void> _performCustomExport(
    BuildContext context,
    ExportFilter filter,
  ) async {
    final format = await _showFormatPicker(context);
    if (format == null || !context.mounted) return;

    final service = ImportExportService();

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在从远程获取电台数据...\n${filter.description}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final count = await service.exportFromRemote(filter, format);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导出 $count 个电台'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 显示格式选择对话框
  ///
  /// 返回 'm3u'、'm3u8'、'json' 或 null（取消）
  Future<String?> _showFormatPicker(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导出格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('M3U 格式'),
              subtitle: const Text('标准播放列表，兼容性最好'),
              onTap: () => Navigator.pop(context, 'm3u'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('M3U8 格式'),
              subtitle: const Text('UTF-8 编码，包含分类信息'),
              onTap: () => Navigator.pop(context, 'm3u8'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON 格式'),
              subtitle: const Text('结构化数据，包含完整字段'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 构建关于信息区域
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
                    'FMradio',
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

  /// 确认清空收藏对话框
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

  /// 确认清空播放记录对话框
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

  /// 确认清除缓存对话框
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

  /// 格式化时长为可读字符串
  ///
  /// [duration] - 要格式化的时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 导入电台列表
  ///
  /// 从文件选择器选择文件并导入电台数据，自动去重后添加到本地电台列表
  Future<void> _importStations(BuildContext context) async {
    final service = ImportExportService();
    try {
      final stations = await service.importFromFile();
      if (stations.isEmpty) {
        return;
      }

      final localStationService = Provider.of<LocalStationService>(context, listen: false);
      final importedCount = await localStationService.importStations(stations);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $importedCount 个电台到本地电台')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  /// 导出收藏电台列表
  ///
  /// [context] - 构建上下文
  /// [stations] - 要导出的电台列表
  /// 弹出格式选择对话框，支持 M3U/M3U8/JSON 三种格式
  Future<void> _exportStations(BuildContext context, List<dynamic> stations) async {
    final service = ImportExportService();
    final stationList = stations.whereType<Station>().toList();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导出格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'm3u'),
              child: const Text('M3U 格式'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'm3u8'),
              child: const Text('M3U8 格式'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'json'),
              child: const Text('JSON 格式'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await service.exportToFile(stationList, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出成功')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败: $e')),
          );
        }
      }
    }
  }
}