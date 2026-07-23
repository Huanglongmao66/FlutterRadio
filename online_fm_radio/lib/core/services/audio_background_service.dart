import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 后台播放服务：负责在应用后台时继续播放音频，并在系统通知栏显示播放控制。
/// 若初始化失败（如平台不支持），将降级为纯前台播放模式。
class AudioBackgroundService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  Station? _currentStation;

  AudioBackgroundService() {
    _initPlayer();
  }

  /// 初始化播放器，绑定状态流到 audio_service 通知。
  void _initPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;

      final playState = PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.play,
          MediaAction.pause,
        },
        processingState: _mapProcessingState(processingState),
        playing: isPlaying,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      );

      playbackState.add(playState);
    });
  }

  /// 将 just_audio 的 ProcessingState 映射到 audio_service 的 AudioProcessingState。
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// 创建 MediaItem 用于通知栏展示。
  MediaItem _createMediaItem(Station station) {
    return MediaItem(
      id: station.id,
      title: station.name,
      artist: station.country,
      album: 'FM Radio',
      artUri: station.logo.isNotEmpty ? Uri.parse(station.logo) : null,
      duration: const Duration(days: 1),
      extras: {
        'streamUrl': station.streamUrl,
        'country': station.country,
        'language': station.language,
      },
    );
  }

  /// 播放指定电台。
  Future<void> playStation(Station station) async {
    _currentStation = station;
    final item = _createMediaItem(station);
    mediaItem.add(item);

    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(station.streamUrl),
          tag: item,
        ),
      );
      await _player.play();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
    }
  }

  /// 暂停播放。
  Future<void> pausePlayback() async {
    await _player.pause();
  }

  /// 恢复播放。
  Future<void> resumePlayback() async {
    await _player.play();
  }

  /// 停止播放。
  Future<void> stopPlayback() async {
    await _player.stop();
    _currentStation = null;
    mediaItem.add(null);
  }

  /// 设置音量。
  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// 当前播放状态。
  bool get isPlaying => _player.playing;

  /// 当前电台。
  Station? get currentStation => _currentStation;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => stopPlayback();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  /// 清理资源。
  void cleanup() {
    _playerStateSubscription.cancel();
    _player.dispose();
  }
}

/// 全局后台音频处理实例。
/// 若后台服务初始化失败，此字段为 null，播放器将降级为纯前台播放。
AudioBackgroundService? audioBackgroundService;

/// 初始化后台音频服务，失败时返回 null，不阻塞应用启动。
Future<AudioBackgroundService?> initAudioBackgroundService({
  required String channelId,
  required String channelName,
}) async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: channelId,
      androidNotificationChannelName: channelName,
      androidNotificationOngoing: true,
    );

    final handler = await AudioService.init(
      builder: () => AudioBackgroundService(),
      config: AudioServiceConfig(
        androidNotificationChannelId: channelId,
        androidNotificationChannelName: channelName,
        androidNotificationOngoing: true,
      ),
    );

    return handler as AudioBackgroundService;
  } catch (e) {
    debugPrint('Failed to initialize audio background service: $e');
    return null;
  }
}
