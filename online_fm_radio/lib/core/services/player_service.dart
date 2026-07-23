import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/core/services/audio_background_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 播放器服务：统一管理音频播放状态。
/// - 后台服务可用时（`audioBackgroundService != null`）：通过后台服务播放，支持通知栏控制和后台播放；
/// - 后台服务不可用时：降级为直接使用 just_audio 前台播放，不影响应用启动。
class PlayerService extends ChangeNotifier {
  /// 后台服务实例（可能为 null，表示降级为前台播放模式）。
  AudioBackgroundService? get _backgroundService => audioBackgroundService;

  /// 降级模式下直接使用的播放器（后台服务不可用时启用）。
  AudioPlayer? _fallbackPlayer;

  /// 降级模式下的播放状态订阅。
  StreamSubscription<PlayerState>? _fallbackStateSubscription;

  Station? _currentStation;
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _errorMessage;
  int _retryCount = 0;
  double _volume = 0.5;
  static const int _maxRetryCount = 3;

  final HistoryService? _historyService;

  /// 后台服务播放状态订阅（后台模式）。
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  Station? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  double get volume => _volume;

  /// 是否启用了后台播放模式。
  bool get hasBackgroundService => _backgroundService != null;

  PlayerService({HistoryService? historyService})
      : _historyService = historyService {
    _initPlayer();
  }

  /// 初始化播放器：根据后台服务是否可用选择模式。
  void _initPlayer() {
    if (hasBackgroundService) {
      // 后台模式：监听 audio_service 状态流。
      _playbackStateSubscription = AudioService.playbackStateStream.listen((state) {
        _isPlaying = state.playing;
        _isBuffering =
            state.processingState == AudioProcessingState.buffering ||
                state.processingState == AudioProcessingState.loading;
        notifyListeners();
      });
    } else {
      // 降级模式：直接使用 just_audio。
      _fallbackPlayer = AudioPlayer();
      _fallbackStateSubscription = _fallbackPlayer!.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _isBuffering = state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;

        if (state.processingState == ProcessingState.completed) {
          stop();
        }

        notifyListeners();
      });
      _fallbackPlayer!.setVolume(_volume);
    }
  }

  /// 播放指定电台。
  Future<void> play(Station station) async {
    _errorMessage = null;
    _retryCount = 0;
    _currentStation = station;
    _isBuffering = true;
    notifyListeners();

    // 记录到播放历史。
    _historyService?.addToHistory(station);

    try {
      if (hasBackgroundService) {
        await _backgroundService!.playStation(station);
      } else if (_fallbackPlayer != null) {
        await _fallbackPlayer!.setUrl(station.streamUrl);
        await _fallbackPlayer!.play();
      }
    } catch (e) {
      _handlePlaybackError(e.toString());
    }
  }

  /// 暂停播放。
  Future<void> pause() async {
    if (!_isPlaying) return;

    if (hasBackgroundService) {
      await _backgroundService!.pausePlayback();
    } else {
      await _fallbackPlayer?.pause();
    }
    _isPlaying = false;
    notifyListeners();
  }

  /// 恢复播放。
  Future<void> resume() async {
    if (_isPlaying || _currentStation == null) return;

    if (hasBackgroundService) {
      await _backgroundService!.resumePlayback();
    } else {
      await _fallbackPlayer?.play();
    }
    _isPlaying = true;
    notifyListeners();
  }

  /// 停止播放。
  Future<void> stop() async {
    if (hasBackgroundService) {
      await _backgroundService!.stopPlayback();
    } else {
      await _fallbackPlayer?.stop();
    }
    _currentStation = null;
    _isPlaying = false;
    _isBuffering = false;
    _errorMessage = null;
    _retryCount = 0;
    notifyListeners();
  }

  /// 处理播放错误，自动重试。
  void _handlePlaybackError(String message) {
    _errorMessage = message;
    _isBuffering = false;

    if (_retryCount < _maxRetryCount && _currentStation != null) {
      _retryCount++;
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentStation != null) {
          play(_currentStation!);
        }
      });
    } else {
      _isPlaying = false;
    }

    notifyListeners();
  }

  /// 跳转播放位置（电台流通常不支持）。
  Future<void> seek(Duration position) async {
    if (hasBackgroundService) {
      await _backgroundService!.seek(position);
    } else {
      await _fallbackPlayer?.seek(position);
    }
  }

  /// 播放位置流。
  Stream<Duration?> get positionStream {
    if (hasBackgroundService) {
      return AudioService.positionStream;
    }
    return _fallbackPlayer?.positionStream ?? Stream.value(null);
  }

  /// 播放时长流（电台直播流返回 null）。
  Stream<Duration?> get durationStream => Stream.value(null);

  /// 设置音量。
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (hasBackgroundService) {
      _backgroundService!.setVolume(_volume);
    } else {
      _fallbackPlayer?.setVolume(_volume);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _fallbackStateSubscription?.cancel();
    _fallbackPlayer?.dispose();
    super.dispose();
  }
}
