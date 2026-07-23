import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/core/services/audio_handler.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 播放器业务服务：包装 RadioAudioHandler，向上层 UI 提供状态与控制接口。
///
/// 职责：
/// - 监听 RadioAudioHandler（即 audio_service + just_audio 桥接层）的状态变化，
///   转换为 UI 层易用的字段（currentStation / isPlaying / isBuffering 等）
/// - 维护错误信息、重试逻辑、音量等业务状态
/// - 播放电台时自动写入最近播放历史
/// - 通过 notifyListeners 驱动 UI 刷新
class PlayerService extends ChangeNotifier {
  final RadioAudioHandler _audioHandler;
  final HistoryService _historyService;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  Station? _currentStation;
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _errorMessage;
  int _retryCount = 0;
  double _volume = 0.5;
  static const int _maxRetryCount = 3;

  Station? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  double get volume => _volume;

  RadioAudioHandler get audioHandler => _audioHandler;

  PlayerService({
    required RadioAudioHandler audioHandler,
    required HistoryService historyService,
  })  : _audioHandler = audioHandler,
        _historyService = historyService {
    _init();
  }

  void _init() {
    // 订阅底层播放器状态，转发到 ChangeNotifier 通知 UI。
    _playerStateSubscription =
        _audioHandler.audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        stop();
      }

      if (wasPlaying != _isPlaying || _isBuffering) {
        notifyListeners();
      }
    });

    _audioHandler.audioPlayer.setVolume(_volume);
  }

  /// 播放指定电台。
  /// 会自动写入最近播放历史，并通过 audio_service 启动前台服务。
  Future<void> play(Station station) async {
    _errorMessage = null;
    _retryCount = 0;
    _currentStation = station;
    _isBuffering = true;
    notifyListeners();

    // 写入最近播放历史
    _historyService.addToHistory(station);

    try {
      await _audioHandler.playStation(station);
    } catch (e) {
      _handlePlaybackError(e.toString());
    }
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    if (_isPlaying || _currentStation == null) return;
    await _audioHandler.play();
  }

  Future<void> stop() async {
    await _audioHandler.stop();
    _currentStation = null;
    _isPlaying = false;
    _isBuffering = false;
    _errorMessage = null;
    _retryCount = 0;
    notifyListeners();
  }

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

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  Stream<Duration?> get positionStream =>
      _audioHandler.audioPlayer.positionStream;

  Stream<Duration?> get durationStream =>
      _audioHandler.audioPlayer.durationStream;

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioHandler.audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioHandler.dispose();
    super.dispose();
  }
}
