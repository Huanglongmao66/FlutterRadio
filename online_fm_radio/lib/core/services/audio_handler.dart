import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 统一管理后台音频播放与通知栏控制。
///
/// 职责：
/// - 将 just_audio 的播放器状态同步到 audio_service 的 MediaItem / PlaybackState
/// - 接收通知栏 / 锁屏 / 蓝牙媒体按钮的控制指令（播放、暂停、停止）
/// - 启动前台服务，防止 App 进入后台后被系统杀掉
class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  /// 当前播放的电台元数据（通知栏展示用）。
  MediaItem? _currentMediaItem;

  /// 对外暴露的 just_audio 原始播放器，供 PlayerService 读取底层状态。
  AudioPlayer get audioPlayer => _player;

  /// 当前播放的电台（Station 对象，业务层使用）。
  Station? get currentStation {
    if (_currentMediaItem == null) return null;
    return Station(
      id: _currentMediaItem!.id,
      name: _currentMediaItem!.title,
      streamUrl: _currentMediaItem!.extras?['streamUrl'] as String? ?? '',
      country: _currentMediaItem!.artist ?? '',
      language: _currentMediaItem!.extras?['language'] as String? ?? '',
      category: _currentMediaItem!.genre ?? '',
      logo: _currentMediaItem!.artUri?.toString() ?? '',
      description: _currentMediaItem!.displayDescription ?? '',
      votes: _currentMediaItem!.extras?['votes'] as int? ?? 0,
      bitrate: _currentMediaItem!.extras?['bitrate'] as int? ?? 0,
      codec: _currentMediaItem!.extras?['codec'] as String? ?? '',
    );
  }

  RadioAudioHandler() {
    _init();
  }

  void _init() {
    // 将 just_audio 的播放状态广播到 audio_service（通知栏/锁屏据此刷新）。
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.play,
          MediaControl.pause,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.playPause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ));
    });

    // 播放完成时停止（直播流一般不会触发，保险起见）。
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// 将 Station 转换为 audio_service 的 MediaItem（通知栏展示信息）。
  MediaItem _stationToMediaItem(Station station) {
    return MediaItem(
      id: station.id,
      album: station.country,
      title: station.name,
      artist: station.country,
      genre: station.category,
      artUri: station.logo.isNotEmpty ? Uri.tryParse(station.logo) : null,
      displayDescription: station.description,
      duration: Duration.zero,
      extras: {
        'streamUrl': station.streamUrl,
        'language': station.language,
        'votes': station.votes,
        'bitrate': station.bitrate,
        'codec': station.codec,
      },
    );
  }

  /// just_audio 的 ProcessingState → audio_service 的 AudioProcessingState。
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

  /// 播放指定电台（由业务层调用）。
  Future<void> playStation(Station station) async {
    final mediaItem = _stationToMediaItem(station);
    _currentMediaItem = mediaItem;
    this.mediaItem.add(mediaItem);

    try {
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (_) {
      // 错误由 PlayerService 的监听器统一处理。
    }
  }

  // ===== 以下是 audio_service 控制接口（通知栏/锁屏/蓝牙按钮会调用）=====

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentMediaItem = null;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  @override
  Future<void> onActionCancel() => stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// 释放 just_audio 播放器资源。
  Future<void> dispose() async {
    await _player.dispose();
  }
}
