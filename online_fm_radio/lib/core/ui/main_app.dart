import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/ui/app_bottom_navigation.dart';
import 'package:online_fm_radio/features/home/home_page.dart';
import 'package:online_fm_radio/features/explore/explore_page.dart';
import 'package:online_fm_radio/features/favorites/favorites_page.dart';
import 'package:online_fm_radio/features/profile/profile_page.dart';
import 'package:online_fm_radio/shared/components/mini_player_bar.dart';

/// 应用主页面容器
///
/// 包含底部导航栏和四个主要页面（主页、探索、收藏、我的）。
/// 底部导航栏上方包含迷你播放器，方便用户在切换页面时控制播放。
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  /// 当前选中的页面索引
  int _currentIndex = 0;

  /// 页面列表，按顺序对应底部导航栏的四个标签
  final List<Widget> _pages = const [
    HomePage(),
    ExplorePage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  /// 处理底部导航栏点击事件
  ///
  /// [index] - 被点击的页面索引
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 持久化迷你播放器，仅在播放时显示
          const MiniPlayerBar(),
          AppBottomNavigation(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}