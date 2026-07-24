import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 电池优化白名单工具类
///
/// MIUI/HyperOS 等国产 ROM 需要用户手动关闭电池优化，
/// 否则应用切到后台后网络会被断开导致播放停止。
class BatteryOptimizationUtils {
  /// 检查是否已忽略电池优化
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  /// 请求忽略电池优化
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// 检查通知权限
  static Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 请求通知权限
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 检查并请求所有必要的权限
  ///
  /// 返回 true 表示所有权限已授予
  static Future<bool> checkAndRequestAllPermissions() async {
    final hasNotification = await requestNotificationPermission();
    final hasBattery = await requestIgnoreBatteryOptimizations();
    return hasNotification && hasBattery;
  }

  /// 显示权限引导对话框
  ///
  /// 在用户首次播放或遇到后台播放问题时调用，
  /// 引导用户关闭电池优化和开启通知权限。
  static Future<void> showPermissionDialog(BuildContext context) async {
    final hasNotification = await hasNotificationPermission();
    final hasBattery = await isIgnoringBatteryOptimizations();

    // 如果权限都已授予，不再提示
    if (hasNotification && hasBattery) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 8),
            Text('后台播放保障'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '为了确保应用切到后台后电台正常播放，需要开启以下权限：',
            ),
            const SizedBox(height: 12),
            if (!hasNotification) ...[
              _PermissionItem(
                icon: Icons.notifications_active,
                title: '通知权限',
                description: '显示播放控制通知栏，防止系统杀后台',
                granted: false,
              ),
              const SizedBox(height: 8),
            ],
            if (!hasBattery) ...[
              _PermissionItem(
                icon: Icons.battery_saver,
                title: '关闭电池优化',
                description: '防止系统在后台断开网络连接',
                granted: false,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '部分手机还需在系统设置中将应用设为"自启动"和"无限制"',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await checkAndRequestAllPermissions();
            },
            child: const Text('立即开启'),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: granted ? Colors.green : Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: granted ? Colors.green : Colors.grey,
        ),
      ],
    );
  }
}
