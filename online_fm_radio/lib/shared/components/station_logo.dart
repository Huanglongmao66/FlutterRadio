import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/theme/app_theme.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 电台 Logo 组件：支持多级回退，解决 Web 端图片加载失败问题。
///
/// 加载顺序：
/// 1. station.safeLogo（HTTP→HTTPS 升级后的原始 URL）
/// 2. station.faviconFallback（Google Favicon 服务）
/// 3. 渐变背景 + 电台图标（最终兜底）
class StationLogo extends StatefulWidget {
  final Station station;
  final double size;
  final double borderRadius;

  const StationLogo({
    super.key,
    required this.station,
    this.size = 64,
    this.borderRadius = 10,
  });

  @override
  State<StationLogo> createState() => _StationLogoState();
}

class _StationLogoState extends State<StationLogo> {
  int _failCount = 0;

  /// 当前尝试加载的 URL，null 表示已用尽所有 URL，使用兜底 UI。
  String? get _currentUrl {
    if (_failCount == 0) return widget.station.safeLogo;
    if (_failCount == 1) {
      final fallback = widget.station.faviconFallback;
      return fallback.isNotEmpty ? fallback : null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    final sz = widget.size;
    final br = widget.borderRadius;

    // 无可用 URL，直接显示兜底 UI。
    if (url == null || url.isEmpty) {
      return _buildFallback(sz, br);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(br),
      child: CachedNetworkImage(
        imageUrl: url,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: sz,
          height: sz,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: SizedBox(
              width: sz * 0.3,
              height: sz * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          // 触发下一级回退
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failCount++);
          });
          return _buildFallback(sz, br);
        },
      ),
    );
  }

  /// 兜底 UI：渐变背景 + 电台图标。
  Widget _buildFallback(double sz, double br) {
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(br),
        gradient: AppTheme.primaryGradient,
      ),
      child: Icon(
        Icons.radio,
        size: sz * 0.4,
        color: Colors.white,
      ),
    );
  }
}
