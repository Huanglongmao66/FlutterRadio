import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
import 'package:online_fm_radio/core/services/visualizer_settings_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/theme/app_theme.dart';
import 'package:online_fm_radio/shared/components/music_visualizer.dart';
import 'package:online_fm_radio/shared/components/station_logo.dart';

/// 播放页：全屏沉浸式设计
///
/// 布局结构（从上到下）：
/// 1. 顶部栏：返回 + 电台名称 + 更多
/// 2. 国旗 + 国家名
/// 3. 电台大封面
/// 4. 音乐动效（可切换柱状/线条/粒子）
/// 5. 功能图标行：音量、闹钟、定时、录音、收藏
/// 6. 播放控制组件
/// 7. 上滑半屏最近播放列表（通过底部 handle 拉起）
class PlayerPage extends StatefulWidget {
  final Station station;

  const PlayerPage({super.key, required this.station});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VisualizerStyle _visualizerStyle = VisualizerStyle.bars;

  @override
  void initState() {
    super.initState();
    // 进入播放页时自动播放对应电台
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerService = context.read<PlayerService>();
      final current = playerService.currentStation;
      // 如果当前没有播放或播放的不是这个电台，则自动播放
      if (current?.id != widget.station.id) {
        playerService.play(widget.station);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.playerGradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(flex: 2, child: _buildCountryRow()),
                    Expanded(flex: 5, child: _buildStationImage()),
                    Expanded(flex: 3, child: _buildVisualizer()),
                    Expanded(flex: 4, child: _buildActionIcons()),
                    Expanded(flex: 4, child: _buildPlaybackControls()),
                    Expanded(flex: 2, child: _buildHistoryHandle()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== 顶部栏 ==========
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 22, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Consumer<PlayerService>(
              builder: (context, playerService, child) {
                final s = playerService.currentStation ?? widget.station;
                return Text(
                  s.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24, color: Colors.white),
            onPressed: () => _showMoreMenu(context),
          ),
        ],
      ),
    );
  }

  // ========== 国旗 + 国家 ==========
  Widget _buildCountryRow() {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        final s = playerService.currentStation ?? widget.station;
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.flagEmoji.isNotEmpty) ...[
                Text(
                  s.flagEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                s.country,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== 电台大封面 ==========
  Widget _buildStationImage() {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        final s = playerService.currentStation ?? widget.station;
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: StationLogo(
                station: s,
                size: 180,
                borderRadius: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== 音乐动效（可切换样式） ==========
  Widget _buildVisualizer() {
    return Consumer2<PlayerService, VisualizerSettingsService>(
      builder: (context, playerService, visualizerService, child) {
        // 动效开关关闭时隐藏整个组件
        if (!visualizerService.isEnabled) {
          return const SizedBox.shrink();
        }
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: GestureDetector(
              onTap: _cycleVisualizerStyle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MusicVisualizer(
                    isPlaying: playerService.isPlaying,
                    style: _visualizerStyle,
                    color: Colors.white,
                    height: 70,
                    width: 240,
                    isEnabled: visualizerService.isEnabled,
                    barWidthFactor: visualizerService.barWidthFactor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _styleLabel(_visualizerStyle),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _styleLabel(VisualizerStyle style) {
    switch (style) {
      case VisualizerStyle.bars:
        return '柱状 点击切换';
      case VisualizerStyle.lines:
        return '线条 点击切换';
      case VisualizerStyle.particles:
        return '粒子 点击切换';
    }
  }

  void _cycleVisualizerStyle() {
    setState(() {
      switch (_visualizerStyle) {
        case VisualizerStyle.bars:
          _visualizerStyle = VisualizerStyle.lines;
          break;
        case VisualizerStyle.lines:
          _visualizerStyle = VisualizerStyle.particles;
          break;
        case VisualizerStyle.particles:
          _visualizerStyle = VisualizerStyle.bars;
          break;
      }
    });
  }

  // ========== 功能图标行 ==========
  Widget _buildActionIcons() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Consumer<FavoritesService>(
          builder: (context, favoritesService, child) {
            final playerService =
                Provider.of<PlayerService>(context, listen: false);
            final s = playerService.currentStation ?? widget.station;
            final isFav = favoritesService.isFavorite(s);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionIcon(
                  icon: Icons.volume_up,
                  label: '音量',
                  onTap: () => _showVolumeDialog(context),
                ),
                _buildActionIcon(
                  icon: Icons.alarm,
                  label: '闹钟',
                  onTap: () => _showSnack('闹钟功能开发中'),
                ),
                _buildActionIcon(
                  icon: Icons.timer_outlined,
                  label: '定时',
                  onTap: () => _showSleepTimerDialog(context),
                ),
                _buildActionIcon(
                  icon: Icons.mic_none,
                  label: '录音',
                  onTap: () => _showSnack('录音功能开发中'),
                ),
                _buildActionIcon(
                  icon: isFav ? Icons.favorite : Icons.favorite_border,
                  label: '收藏',
                  color: isFav ? Colors.red : null,
                  onTap: () => favoritesService.toggleFavorite(s),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 播放控制 ==========
  Widget _buildPlaybackControls() {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        final s = playerService.currentStation ?? widget.station;
        final isCurrent = playerService.currentStation?.id == s.id;
        final isPlaying = isCurrent && playerService.isPlaying;
        final isBuffering = isCurrent && playerService.isBuffering;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 上一首
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        size: 40, color: Colors.white70),
                    onPressed: () => _playPrevious(),
                  ),
                  const SizedBox(width: 32),
                  // 播放/暂停大按钮
                  GestureDetector(
                    onTap: isBuffering
                        ? null
                        : () {
                            if (isCurrent) {
                              if (isPlaying) {
                                playerService.pause();
                              } else {
                                playerService.resume();
                              }
                            } else {
                              playerService.play(s);
                            }
                          },
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withOpacity(0.45),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: isBuffering
                          ? const Padding(
                              padding: EdgeInsets.all(26),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // 下一首
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        size: 40, color: Colors.white70),
                    onPressed: () => _playNext(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== 上滑提示 handle ==========
  Widget _buildHistoryHandle() {
    return Center(
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -3) {
            _showHistoryBottomSheet();
          }
        },
        onTap: _showHistoryBottomSheet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '上滑查看最近播放',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 最近播放底部弹窗 ==========
  void _showHistoryBottomSheet() {
    final historyService =
        Provider.of<HistoryService>(context, listen: false);
    final playerService =
        Provider.of<PlayerService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 顶部 handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '最近播放',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: Consumer<HistoryService>(
                      builder: (context, service, child) {
                        final history = service.history;
                        if (history.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无播放记录',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final station = history[index];
                            final isPlaying = playerService
                                    .currentStation?.id ==
                                station.id;
                            return ListTile(
                              leading: StationLogo(
                                station: station,
                                size: 44,
                                borderRadius: 8,
                              ),
                              title: Text(
                                station.name,
                                style: TextStyle(
                                  color: isPlaying
                                      ? const Color(0xFF6366F1)
                                      : Colors.white,
                                  fontWeight: isPlaying
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                station.country,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isPlaying
                                  ? const Icon(
                                      Icons.play_arrow,
                                      color: Color(0xFF6366F1),
                                    )
                                  : null,
                              onTap: () {
                                playerService.play(station);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ========== 音量弹窗 ==========
  void _showVolumeDialog(BuildContext context) {
    final playerService =
        Provider.of<PlayerService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('音量',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<PlayerService>(
                    builder: (context, ps, child) {
                      return Row(
                        children: [
                          const Icon(Icons.volume_mute,
                              color: Colors.white70),
                          Expanded(
                            child: Slider(
                              value: ps.volume,
                              onChanged: (v) {
                                ps.setVolume(v);
                              },
                              activeColor: const Color(0xFF6366F1),
                              inactiveColor: Colors.white12,
                            ),
                          ),
                          const Icon(Icons.volume_up,
                              color: Colors.white70),
                        ],
                      );
                    },
                  ),
                  Text(
                    '${(playerService.volume * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定',
                      style: TextStyle(color: Color(0xFF6366F1))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========== 定时关闭弹窗 ==========
  void _showSleepTimerDialog(BuildContext context) {
    final timerService =
        Provider.of<SleepTimerService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('定时关闭',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (timerService.isActive) ...[
                Text(
                  '剩余时间: ${_formatDuration(timerService.remaining!)}',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
              ],
              const Text('选择关闭时间:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTimerOption(context, 10, '10分钟'),
                  _buildTimerOption(context, 20, '20分钟'),
                  _buildTimerOption(context, 30, '30分钟'),
                  _buildTimerOption(context, 60, '1小时'),
                  _buildTimerOption(context, 120, '2小时'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消',
                  style: TextStyle(color: Colors.white70)),
            ),
            if (timerService.isActive)
              TextButton(
                onPressed: () {
                  timerService.cancel();
                  Navigator.pop(context);
                },
                child: const Text('关闭定时',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimerOption(
      BuildContext context, int minutes, String label) {
    return ElevatedButton(
      onPressed: () {
        Provider.of<SleepTimerService>(context, listen: false)
            .start(Duration(minutes: minutes));
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF6366F1),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  // ========== 更多菜单 ==========
  void _showMoreMenu(BuildContext context) {
    final playerService =
        Provider.of<PlayerService>(context, listen: false);
    final s = playerService.currentStation ?? widget.station;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.share, color: Colors.white70),
                title: const Text('分享电台',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSnack('分享功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline,
                    color: Colors.white70),
                title: const Text('电台信息',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showStationInfo(s);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined,
                    color: Colors.white70),
                title: const Text('举报电台',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSnack('举报功能开发中');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStationInfo(Station s) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(s.name,
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('国家', s.country),
              _infoRow('语言', s.language.isEmpty ? '-' : s.language),
              _infoRow('分类', s.category),
              _infoRow('码率', '${s.bitrate} kbps'),
              _infoRow('编码', s.codec.isEmpty ? '-' : s.codec),
              _infoRow('投票', '${s.votes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭',
                style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      );
    },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playPrevious() {
    final historyService =
        Provider.of<HistoryService>(context, listen: false);
    final playerService =
        Provider.of<PlayerService>(context, listen: false);
    final history = historyService.history;
    if (history.isEmpty) return;
    final currentId = playerService.currentStation?.id;
    final currentIndex =
        history.indexWhere((s) => s.id == currentId);
    if (currentIndex < 0 || currentIndex >= history.length - 1) {
      if (history.isNotEmpty) playerService.play(history.first);
    } else {
      playerService.play(history[currentIndex + 1]);
    }
  }

  void _playNext() {
    final historyService =
        Provider.of<HistoryService>(context, listen: false);
    final playerService =
        Provider.of<PlayerService>(context, listen: false);
    final history = historyService.history;
    if (history.isEmpty) return;
    final currentId = playerService.currentStation?.id;
    final currentIndex =
        history.indexWhere((s) => s.id == currentId);
    if (currentIndex <= 0) {
      if (history.isNotEmpty) playerService.play(history.last);
    } else {
      playerService.play(history[currentIndex - 1]);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
