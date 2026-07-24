import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/tag.dart';

/// 探索页面：分类浏览电台内容。
///
/// 布局结构：
/// 1. 发现新电台 - 4个正方形图标（年代、访谈、体育、新闻）
/// 2. 音乐电台 - 长方形卡片网格（2列），图片在上文字在左下角
/// 3. 音乐类型 - 长方形卡片网格（2列），包含多个音乐分类
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  /// 发现新电台分类
  final List<_ExploreCategory> _discoverCategories = const [
    _ExploreCategory(
      name: '年代',
      tagName: 'decades',
      icon: Icons.schedule,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _ExploreCategory(
      name: '访谈',
      tagName: 'talk',
      icon: Icons.mic,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    _ExploreCategory(
      name: '体育',
      tagName: 'sports',
      icon: Icons.sports_soccer,
      gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ),
    _ExploreCategory(
      name: '新闻',
      tagName: 'news',
      icon: Icons.newspaper,
      gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
    ),
  ];

  /// 音乐电台分类
  final List<_ImageCategory> _musicCategories = const [
    _ImageCategory(
      name: '流行',
      tagName: 'pop',
      icon: Icons.music_note,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _ImageCategory(
      name: '摇滚',
      tagName: 'rock',
      icon: Icons.electric_bolt,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    _ImageCategory(
      name: '音乐',
      tagName: 'music',
      icon: Icons.queue_music,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    _ImageCategory(
      name: '电音',
      tagName: 'electronic',
      icon: Icons.equalizer,
      gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ),
  ];

  /// 音乐类型分类
  final List<_ImageCategory> _genreCategories = const [
    _ImageCategory(
      name: '舞曲',
      tagName: 'dance',
      icon: Icons.directions_run,
      gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
    ),
    _ImageCategory(
      name: '古典',
      tagName: 'classical',
      icon: Icons.piano,
      gradient: [Color(0xFFa8edea), Color(0xFFfed6e3)],
    ),
    _ImageCategory(
      name: 'Top 40',
      tagName: 'top40',
      icon: Icons.emoji_events,
      gradient: [Color(0xFFff9a9e), Color(0xFFfecfef)],
    ),
    _ImageCategory(
      name: '基督教',
      tagName: 'christian',
      icon: Icons.church,
      gradient: [Color(0xFFffecd2), Color(0xFFfcb69f)],
    ),
    _ImageCategory(
      name: '爵士乐',
      tagName: 'jazz',
      icon: Icons.music_note,
      gradient: [Color(0xFFff6e7f), Color(0xFFbfe9ff)],
    ),
    _ImageCategory(
      name: '社区广播',
      tagName: 'community',
      icon: Icons.people,
      gradient: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
    ),
    _ImageCategory(
      name: '怀旧',
      tagName: 'oldies',
      icon: Icons.auto_awesome,
      gradient: [Color(0xFFd299c2), Color(0xFFfef9d7)],
    ),
    _ImageCategory(
      name: '成人当代',
      tagName: 'adult contemporary',
      icon: Icons.headphones,
      gradient: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
    ),
    _ImageCategory(
      name: '经典金曲',
      tagName: 'classic hits',
      icon: Icons.star,
      gradient: [Color(0xFFfddb92), Color(0xFFd1fdff)],
    ),
    _ImageCategory(
      name: '非主流音乐',
      tagName: 'alternative',
      icon: Icons.amp_stories,
      gradient: [Color(0xFFf6d365), Color(0xFFfda085)],
    ),
    _ImageCategory(
      name: '乡村音乐',
      tagName: 'country',
      icon: Icons.nature_people,
      gradient: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
    ),
    _ImageCategory(
      name: 'House',
      tagName: 'house',
      icon: Icons.nightlight_round,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppTopBar(title: '探索'),
      body: ListView(
        children: [
          _buildSectionTitle('发现新电台'),
          _buildDiscoverGrid(),
          _buildSectionTitle('音乐电台'),
          _buildImageGrid(_musicCategories),
          _buildSectionTitle('音乐类型'),
          _buildImageGrid(_genreCategories),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 板块标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 发现新电台 - 4个正方形图标网格
  Widget _buildDiscoverGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _discoverCategories.length,
        itemBuilder: (context, index) {
          final category = _discoverCategories[index];
          return _buildDiscoverItem(category);
        },
      ),
    );
  }

  /// 单个发现分类图标
  Widget _buildDiscoverItem(_ExploreCategory category) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category.name, category.tagName),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: category.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: category.gradient.first.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -8,
              child: Icon(
                category.icon,
                size: 56,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 长方形图片卡片网格（2列）
  Widget _buildImageGrid(List<_ImageCategory> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildImageCard(category);
        },
      ),
    );
  }

  /// 单个长方形分类卡片（渐变背景 + 大图标装饰 + 左下角文字）
  Widget _buildImageCard(_ImageCategory category) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category.name, category.tagName),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: category.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: category.gradient.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                category.icon,
                size: 90,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分类点击处理 - 跳转到对应标签的电台列表
  void _onCategoryTap(String categoryName, String tagName) {
    final tag = Tag(
      name: tagName,
      stationCount: 0,
    );
    Navigator.pushNamed(
      context,
      '/tag_stations',
      arguments: tag,
    );
  }
}

/// 探索分类（正方形卡片）
class _ExploreCategory {
  final String name;
  final String tagName;
  final IconData icon;
  final List<Color> gradient;

  const _ExploreCategory({
    required this.name,
    required this.tagName,
    required this.icon,
    required this.gradient,
  });
}

/// 图片分类（长方形渐变卡片）
class _ImageCategory {
  final String name;
  final String tagName;
  final IconData icon;
  final List<Color> gradient;

  const _ImageCategory({
    required this.name,
    required this.tagName,
    required this.icon,
    required this.gradient,
  });
}
