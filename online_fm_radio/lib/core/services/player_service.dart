import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/core/services/audio_handler.dart';
import 'package:online_fm_radio/core/services/audio_player_singleton.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 播放器业务服务。
///
/// 关键设计：
/// - 使用全局单例 AudioPlayer（与 RadioAudioHandler 共享）
/// - 播放时通过 audioHandler 更新通知栏媒体信息
/// - 自身不创建/销毁 AudioPlayer，避免资源冲突
class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayerSingleton.instance;
  final HistoryService? _historyService;
  final RadioAudioHandler? _audioHandler;

  StreamSubscription<PlayerState>? _playerStateSub;

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

  PlayerService({
    HistoryService? historyService,
    RadioAudioHandler? audioHandler,
  })  : _historyService = historyService,
        _audioHandler = audioHandler {
    _init();
  }

  void _init() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        stop();
      }

      notifyListeners();
    });

    _player.setVolume(_volume);
  }

  Future<void> play(Station station) async {
    _errorMessage = null;
    _retryCount = 0;
    _currentStation = station;
    _isBuffering = true;
    notifyListeners();

    // 写入最近播放历史
    _historyService?.addToHistory(station);

    // 更新通知栏媒体信息
    _audioHandler?.setStationMediaItem(station);

    try {
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (e) {
      _handlePlaybackError(e.toString());
    }
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_isPlaying || _currentStation == null) return;
    await _player.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
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
    await _player.seek(position);
  }

  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    // 注意：不 dispose _player，因为单例共享
    super.dispose();
  }
}
