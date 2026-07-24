import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:provider/provider.dart';

/// 排序方式枚举
enum StationSortMode {
  /// 按投票数降序（热门优先）
  votes('votes', '热门度', Icons.trending_up),
  /// 按名称字母升序
  name('name', '名称', Icons.sort_by_alpha),
  /// 按国家
  country('country', '国家', Icons.public),
  /// 按最新检查时间
  newest('lastchecktime', '最新', Icons.access_time);

  final String apiKey;
  final String displayName;
  final IconData icon;

  const StationSortMode(this.apiKey, this.displayName, this.icon);
}

/// 应用顶部导航栏组件
///
/// 提供统一的顶部导航栏样式，包含菜单按钮、标题和操作按钮（搜索、更多菜单）。
/// 更多菜单包含国家选择、排序方式、同步数据等功能。
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文本
  final String title;

  /// 是否显示搜索按钮
  final bool showSearch;

  /// 是否显示更多菜单按钮
  final bool showMoreMenu;

  /// 当前选中的国家名称
  final String? selectedCountry;

  /// 国家选择回调
  final void Function(String?)? onCountrySelected;

  /// 排序方式变化回调
  final void Function(StationSortMode)? onSortModeChanged;

  /// 当前排序方式
  final StationSortMode? sortMode;

  /// 创建顶部导航栏
  ///
  /// [title] - 标题文本，为空时不显示
  /// [showSearch] - 是否显示搜索按钮，默认 true
  /// [showMoreMenu] - 是否显示更多菜单按钮，默认 true
  /// [selectedCountry] - 当前选中的国家名称（用于国家选择器高亮）
  /// [onCountrySelected] - 国家选择回调
  /// [sortMode] - 当前排序方式
  /// [onSortModeChanged] - 排序方式变化回调
  const AppTopBar({
    super.key,
    this.title = '',
    this.showSearch = true,
    this.showMoreMenu = true,
    this.selectedCountry,
    this.onCountrySelected,
    this.sortMode,
    this.onSortModeChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          /// 菜单按钮：打开侧边抽屉
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: title.isNotEmpty ? Text(title) : null,
      centerTitle: true,
      actions: [
        /// 搜索按钮：跳转到搜索页面
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        /// 更多菜单按钮：显示国家、排序方式、同步数据
        if (showMoreMenu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'country',
                child: ListTile(
                  leading: Icon(Icons.public),
                  title: Text('国家'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('排序方式'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sync',
                child: _buildSyncMenuItem(context),
              ),
            ],
          ),
      ],
    );
  }

  /// 构建同步数据菜单项
  ///
  /// 显示同步状态和进度
  Widget _buildSyncMenuItem(BuildContext context) {
    final updateService = context.watch<StationUpdateService>();
    return ListTile(
      leading: updateService.isUpdating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      title: Text(updateService.isUpdating ? '同步中...' : '同步数据'),
      subtitle: updateService.isUpdating
          ? Text(
              '${updateService.fetchedCount}/${updateService.totalCount}',
              style: const TextStyle(fontSize: 12),
            )
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 处理菜单项点击事件
  ///
  /// [context] - 构建上下文
  /// [value] - 菜单项标识
  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'country':
        _showCountryPicker(context);
        break;
      case 'sort':
        _showSortModePicker(context);
        break;
      case 'sync':
        _handleSync(context);
        break;
    }
  }

  /// 处理同步数据
  ///
  /// 调用 StationUpdateService.syncData 对比远程数据差异并写入新增数据
  void _handleSync(BuildContext context) {
    final updateService =
        Provider.of<StationUpdateService>(context, listen: false);
    if (updateService.isUpdating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在同步中，请稍候...')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开始同步数据，对比缓存与远程差异...'),
        duration: Duration(seconds: 2),
      ),
    );

    updateService.syncData().then((newCount) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newCount > 0
                ? '同步完成，新增 $newCount 个电台'
                : '同步完成，无新增数据'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    });
  }

  /// 显示国家选择对话框
  ///
  /// 从本地缓存加载国家列表，支持搜索筛选，选择后通过回调通知上层
  void _showCountryPicker(BuildContext context) async {
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
                    /// 全部国家选项
                    if (selectedCountry != null || onCountrySelected != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context, '__all__');
                        },
                        icon: const Icon(Icons.public),
                        label: const Text('全部国家'),
                      ),
                    /// 搜索输入框
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
                    /// 国家列表
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = selectedCountry == country.name;
                          /// 国旗 emoji：由 ISO 国家码转换，无码时回退到文字占位
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
                            onTap: () {
                              Navigator.pop(context, country.name);
                            },
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

    if (result != null && onCountrySelected != null) {
      if (result == '__all__') {
        onCountrySelected!(null);
      } else {
        onCountrySelected!(result);
      }
    }
  }

  /// 显示排序方式选择对话框
  ///
  /// 提供多种排序选项，选择后通过回调通知上层
  void _showSortModePicker(BuildContext context) {
    if (onSortModeChanged == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前页面不支持排序')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StationSortMode.values.map((mode) {
            final isSelected = sortMode == mode;
            return ListTile(
              leading: Icon(
                mode.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                mode.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                onSortModeChanged!(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
