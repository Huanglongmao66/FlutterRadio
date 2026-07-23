import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/core/services/audio_player_singleton.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 后台音频处理 Handler：桥接 just_audio 与 audio_service。
///
/// 关键设计：使用全局单例 AudioPlayer，避免与 PlayerService 重复创建实例。
/// 职责：
/// - 将播放器状态同步到 audio_service（通知栏/锁屏/蓝牙）
/// - 接收系统媒体控制指令（播放、暂停、停止）
/// - 不负责创建/销毁 AudioPlayer（由单例管理）
class RadioAudioHandler extends BaseAudioHandler {
  /// 使用全局单例，与 PlayerService 共享同一个播放器实例。
  final AudioPlayer _player = AudioPlayerSingleton.instance;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

  RadioAudioHandler() {
    _init();
  }

  void _init() {
    // 同步 just_audio 状态到 audio_service
    _playerStateSub = _player.playerStateStream.listen((state) {
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
        processingState: _mapProcessingState(state.processingState),
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    // 播放完成处理
    _playbackEventSub = _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  static AudioProcessingState _mapProcessingState(ProcessingState state) {
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

  /// 更新通知栏展示的媒体信息。
  void setStationMediaItem(Station station) {
    final mediaItem = MediaItem(
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
        'countryCode': station.countryCode,
        'language': station.language,
        'votes': station.votes,
        'bitrate': station.bitrate,
        'codec': station.codec,
      },
    );
    this.mediaItem.add(mediaItem);
  }

  // ===== audio_service 控制接口 =====

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    // 注意：不 dispose _player，因为单例共享
    await super.dispose();
  }
}
