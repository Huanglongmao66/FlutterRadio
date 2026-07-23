import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:provider/provider.dart';

/// 应用顶部导航栏组件
///
/// 提供统一的顶部导航栏样式，包含菜单按钮、标题和操作按钮（搜索、国家筛选、更新）。
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文本
  final String title;

  /// 是否显示搜索按钮
  final bool showSearch;

  /// 是否显示国家筛选按钮
  final bool showCountryFilter;

  /// 是否显示数据更新按钮
  final bool showDownload;

  /// 当前选中的国家名称
  final String? selectedCountry;

  /// 国家选择回调
  final void Function(String?)? onCountrySelected;

  /// 创建顶部导航栏
  ///
  /// [title] - 标题文本，为空时不显示
  /// [showSearch] - 是否显示搜索按钮，默认 true
  /// [showCountryFilter] - 是否显示国家筛选按钮，默认 true
  /// [showDownload] - 是否显示数据更新按钮，默认 true
  /// [selectedCountry] - 当前选中的国家名称（用于国家选择器高亮）
  /// [onCountrySelected] - 国家选择回调
  const AppTopBar({
    super.key,
    this.title = '',
    this.showSearch = true,
    this.showCountryFilter = true,
    this.showDownload = true,
    this.selectedCountry,
    this.onCountrySelected,
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
        /// 国家筛选按钮：打开国家选择器
        if (showCountryFilter)
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: () => _showCountryPicker(context),
          ),
        /// 数据更新按钮：触发电台数据全量更新
        if (showDownload)
          Consumer<StationUpdateService>(
            builder: (context, updateService, child) {
              return IconButton(
                icon: updateService.isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onPressed: updateService.isUpdating
                    ? null
                    : () => updateService.updateAllStations(),
              );
            },
          ),
      ],
    );
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
}