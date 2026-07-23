import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 电台列表项卡片。
/// 布局：左侧缩略图 | 中间竖向排列(名称/标签/国家) | 右侧播放按钮 + 收藏按钮。
/// - 点击播放按钮直接播放，不跳转播放页；
/// - 点击收藏按钮切换收藏状态；
/// - 点击卡片其它区域跳转到播放页。
class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;

  const StationCard({
    super.key,
    required this.station,
    this.onTap,
  });

  /// 判断 URL 是否有效（非空且以 http 开头）。
  bool _isValidUrl(String url) {
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final favoritesService = Provider.of<FavoritesService>(context);
    final playerService = Provider.of<PlayerService>(context);
    final isFavorite = favoritesService.isFavorite(station);

    // 当前正在播放的电台高亮显示。
    final isCurrentPlaying = playerService.currentStation?.id == station.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isCurrentPlaying ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlaying
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // 左侧：缩略图
              _buildThumbnail(context, isCurrentPlaying, playerService),
              const SizedBox(width: 12),
              // 中间：电台名称、标签、国家竖向排列
              Expanded(
                child: _buildInfo(context),
              ),
              // 右侧：播放按钮 + 收藏按钮
              _buildActions(context, playerService, favoritesService, isFavorite),
            ],
          ),
        ),
      ),
    );
  }

  /// 左侧缩略图：有效 URL 时加载网络图片，否则显示默认图标。
  Widget _buildThumbnail(
    BuildContext context,
    bool isCurrentPlaying,
    PlayerService playerService,
  ) {
    final hasValidLogo = _isValidUrl(station.logo);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hasValidLogo
                ? CachedNetworkImage(
                    imageUrl: station.logo,
                    fit: BoxFit.cover,
                    // 加载中显示默认背景 + 图标
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.radio,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    // 加载失败显示默认图标（不再显示 loading 转圈）
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.radio,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.radio,
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
        ),
        // 正在播放时在缩略图上叠加播放动画指示器
        if (isCurrentPlaying && playerService.isPlaying)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.equalizer,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  /// 中间信息区：电台名称、标签、国家竖向排列。
  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 电台名称
        Text(
          station.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // 标签（category）
        if (station.category.isNotEmpty && station.category != 'Other')
          _buildInfoRow(
            context,
            icon: Icons.tag,
            text: station.category,
          ),
        // 国家
        if (station.country.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _buildInfoRow(
              context,
              icon: Icons.location_on,
              text: station.country,
            ),
          ),
      ],
    );
  }

  /// 单行信息（图标 + 文本）。
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 右侧操作区：播放按钮 + 收藏按钮。
  Widget _buildActions(
    BuildContext context,
    PlayerService playerService,
    FavoritesService favoritesService,
    bool isFavorite,
  ) {
    final isCurrentPlaying = playerService.currentStation?.id == station.id;
    final isPlayingThis = isCurrentPlaying && playerService.isPlaying;
    final isBufferingThis = isCurrentPlaying && playerService.isBuffering;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 播放/暂停按钮：点击直接播放，不跳转页面
        IconButton(
          icon: isBufferingThis
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Icon(
                  isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 36,
                ),
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            if (isCurrentPlaying) {
              // 当前电台正在播放：切换播放/暂停
              if (playerService.isPlaying) {
                playerService.pause();
              } else {
                playerService.resume();
              }
            } else {
              // 点击直接播放该电台
              playerService.play(station);
            }
          },
        ),
        // 收藏按钮
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 22,
          ),
          color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () => favoritesService.toggleFavorite(station),
        ),
      ],
    );
  }
}
