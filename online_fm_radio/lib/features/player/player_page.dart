import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';

class PlayerPage extends StatelessWidget {
  final Station station;

  const PlayerPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStationImage(context),
                    _buildStationInfo(context),
                    _buildBufferingIndicator(context),
                    _buildErrorState(context),
                    _buildPlaybackControls(context),
                    _buildVolumeControl(context),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Consumer<SleepTimerService>(
            builder: (context, timerService, child) {
              if (!timerService.isActive) return const SizedBox.shrink();
              return Text(
                _formatDuration(timerService.remaining!),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStationImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: station.logo,
          width: 280,
          height: 280,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: const Center(
              child: Icon(
                Icons.radio,
                size: 80,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            station.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                station.country,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.tag, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                station.category,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          if (station.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              station.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        if (!playerService.isBuffering) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                '缓冲中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        if (playerService.errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.red[100],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  '播放失败',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playerService.errorMessage!,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => playerService.play(station),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '重试',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 40),
                onPressed: () {},
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  if (playerService.currentStation == station) {
                    if (playerService.isPlaying) {
                      playerService.pause();
                    } else {
                      playerService.resume();
                    }
                  } else {
                    playerService.play(station);
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    playerService.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 40),
                onPressed: () {},
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volume_mute,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: playerService.volume,
                      onChanged: (value) => playerService.setVolume(value),
                      min: 0.0,
                      max: 1.0,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      thumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(playerService.volume * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            context,
            Icons.favorite,
            '收藏',
            () {
              Provider.of<FavoritesService>(context, listen: false)
                  .toggleFavorite(station);
            },
            isActive: Provider.of<FavoritesService>(context).isFavorite(station),
            activeColor: Colors.red,
          ),
          const SizedBox(width: 48),
          _buildActionButton(
            context,
            Icons.timer,
            '定时关闭',
            () => _showSleepTimerDialog(context),
            isActive: Provider.of<SleepTimerService>(context).isActive,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool isActive = false,
    Color? activeColor,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (activeColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: 28,
              color: isActive
                  ? (activeColor ?? Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final timerService = Provider.of<SleepTimerService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('定时关闭'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (timerService.isActive) ...[
                Text(
                  '剩余时间: ${_formatDuration(timerService.remaining!)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
              ],
              const Text('选择关闭时间:'),
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
              child: const Text('取消'),
            ),
            if (timerService.isActive)
              TextButton(
                onPressed: () {
                  timerService.cancel();
                  Navigator.pop(context);
                },
                child: const Text('关闭定时'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, int minutes, String label) {
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
      ),
      child: Text(label),
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