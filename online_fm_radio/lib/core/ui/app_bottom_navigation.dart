import 'package:flutter/material.dart';

/// 应用底部导航栏组件
///
/// 包含四个导航标签：主页、探索、收藏、我的
class AppBottomNavigation extends StatelessWidget {
  /// 当前选中的页面索引
  final int currentIndex;

  /// 点击导航项时的回调
  final void Function(int) onTap;

  /// 创建底部导航栏
  ///
  /// [currentIndex] - 当前选中的页面索引
  /// [onTap] - 点击导航项时的回调，参数为选中的索引
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '主页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: '探索',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: '收藏',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }
}
