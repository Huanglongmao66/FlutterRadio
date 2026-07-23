import 'dart:async';
import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/station_cache_service.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';

/// 搜索页面：支持从本地缓存中搜索电台数据。
///
/// 核心功能：
/// - 防抖搜索（300ms），避免频繁请求
/// - 搜索范围：电台名称、国家、语言、分类、标签描述
/// - 显示搜索结果数量和缓存总量
/// - 支持清空搜索关键词
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// 搜索输入控制器
  final TextEditingController _searchController = TextEditingController();

  /// 电台数据仓库
  final StationRepository _repository = StationRepository();

  /// 电台缓存服务
  final StationCacheService _cacheService = StationCacheService();

  /// 搜索结果列表
  List<Station> _results = [];

  /// 是否正在搜索中
  bool _isSearching = false;

  /// 是否已执行过搜索
  bool _hasSearched = false;

  /// 本地缓存的电台总数
  int _totalCached = 0;

  /// 防抖定时器
  Timer? _debounce;

  /// 防抖延迟时间（300ms）
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    /// 初始化时加载本地缓存数量
    _loadCacheCount();
  }

  @override
  void dispose() {
    /// 取消防抖定时器
    _debounce?.cancel();
    /// 释放搜索输入控制器
    _searchController.dispose();
    super.dispose();
  }

  /// 加载本地缓存的电台总数
  Future<void> _loadCacheCount() async {
    final hasCache = await _cacheService.hasCache();
    if (hasCache) {
      final stations = await _cacheService.getCachedStations();
      if (mounted) {
        setState(() {
          _totalCached = stations.length;
        });
      }
    }
  }

  /// 搜索关键词变化时的处理（防抖）
  ///
  /// - 清空关键词时重置搜索状态
  /// - 设置防抖定时器，延迟执行搜索
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    setState(() {});
    _debounce = Timer(_debounceDuration, () => _performSearch(value));
  }

  /// 执行搜索操作
  ///
  /// 从本地缓存中搜索电台，搜索范围包括：
  /// - 电台名称
  /// - 国家
  /// - 语言
  /// - 分类
  /// - 标签描述
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final results = await _repository.searchCached(keyword);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search failed: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '',
        showSearch: false,
        showCountryFilter: false,
        showDownload: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildResultCount(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏组件
  ///
  /// 包含搜索输入框和清空按钮，自动聚焦
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '搜索电台、国家、语言、标签...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果数量显示
  ///
  /// 仅在搜索完成后显示结果数量
  Widget _buildResultCount() {
    if (!_hasSearched || _isSearching) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '找到 ${_results.length} 个结果',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果列表
  ///
  /// 根据搜索状态显示不同内容：
  /// - 搜索中：显示加载指示器
  /// - 未搜索：显示搜索提示和缓存数量
  /// - 无结果：显示未找到提示
  /// - 有结果：显示电台卡片列表
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _totalCached > 0
                  ? '在 $_totalCached 个缓存电台中搜索'
                  : '输入关键词开始搜索',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '支持电台名、国家、语言、标签',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('未找到相关电台'),
            const SizedBox(height: 8),
            Text(
              '试试其他关键词',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final station = _results[index];
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
  }
}