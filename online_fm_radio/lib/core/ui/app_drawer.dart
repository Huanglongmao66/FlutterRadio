import 'package:flutter/material.dart';

/// 应用侧边抽屉组件
///
/// 包含应用标题、导航菜单和功能入口。
/// 部分功能（主题电台、录音、闹钟）尚未实现，点击时显示提示。
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// 抽屉头部：应用名称和副标题
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FMradio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '在线收音机',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          /// 主页导航
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('主页'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          /// 探索导航
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('探索'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          /// 收藏导航
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('收藏'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          /// 主题电台（开发中）
          ListTile(
            leading: const Icon(Icons.radio),
            title: const Text('主题电台'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题电台功能开发中')),
              );
            },
          ),
          /// 录音（开发中）
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('录音'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('录音功能开发中')),
              );
            },
          ),
          /// 闹钟（开发中）
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('闹钟'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('闹钟功能开发中')),
              );
            },
          ),
          const Divider(),
          /// 设置页面
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          /// 关于页面
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
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
    );
  }
}