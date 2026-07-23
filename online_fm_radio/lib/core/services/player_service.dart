import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/core/services/audio_background_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 播放器服务：统一管理音频播放状态，集成后台播放能力。
/// 内部通过 AudioBackgroundService 实现后台播放，同时保持 ChangeNotifier 供 UI 监听。
class PlayerService extends ChangeNotifier {
  /// 后台音频服务（全局单例）。
  AudioBackgroundService get _backgroundService => audioBackgroundService;

  /// 当前播放电台。
  Station? _currentStation;

  /// 是否正在播放。
  bool _isPlaying = false;

  /// 是否正在缓冲。
  bool _isBuffering = false;

  /// 错误信息。
  String? _errorMessage;

  /// 重试次数。
  int _retryCount = 0;

  /// 当前音量。
  double _volume = 0.5;

  /// 最大重试次数。
  static const int _maxRetryCount = 3;

  /// 可选的历史服务，用于记录播放历史。
  final HistoryService? _historyService;

  /// 播放状态订阅（监听后台服务状态变化）。
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  /// 当前播放电台。
  Station? get currentStation => _currentStation;

  /// 是否正在播放。
  bool get isPlaying => _isPlaying;

  /// 是否正在缓冲。
  bool get isBuffering => _isBuffering;

  /// 错误信息。
  String? get errorMessage => _errorMessage;

  /// 当前音量。
  double get volume => _volume;

  PlayerService({HistoryService? historyService})
      : _historyService = historyService {
    _initPlayer();
  }

  /// 初始化播放器，绑定后台服务状态监听。
  void _initPlayer() {
    // 监听后台服务的播放状态变化，同步到本地状态。
    _playbackStateSubscription = AudioService.playbackStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering =
          state.processingState == AudioProcessingState.buffering ||
              state.processingState == AudioProcessingState.loading;
      notifyListeners();
    });

    // 监听后台服务的媒体项变化。
    AudioService.currentMediaItemStream.listen((mediaItem) {
      if (mediaItem != null && _currentStation != null) {
        // 更新当前电台信息。
        notifyListeners();
      }
    });
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
      // 通过后台服务播放，确保后台时也能继续播放。
      await _backgroundService.playStation(station);
    } catch (e) {
      _handlePlaybackError(e.toString());
    }
  }

  /// 暂停播放。
  Future<void> pause() async {
    if (!_isPlaying) return;

    await _backgroundService.pausePlayback();
    _isPlaying = false;
    notifyListeners();
  }

  /// 恢复播放。
  Future<void> resume() async {
    if (_isPlaying || _currentStation == null) return;

    await _backgroundService.resumePlayback();
    _isPlaying = true;
    notifyListeners();
  }

  /// 停止播放。
  Future<void> stop() async {
    await _backgroundService.stopPlayback();
    _currentStation = null;
    _isPlaying = false;
    _isBuffering = false;
    _errorMessage = null;
    _retryCount = 0;
    notifyListeners();
  }

  /// 处理播放错误。
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

  /// 跳转播放位置（电台流通常不支持跳转）。
  Future<void> seek(Duration position) async {
    await _backgroundService.seek(position);
  }

  /// 获取播放位置流。
  Stream<Duration?> get positionStream => AudioService.positionStream;

  /// 获取播放时长流。
  Stream<Duration?> get durationStream => Stream.value(null);

  /// 设置音量。
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _backgroundService.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    super.dispose();
  }
}
