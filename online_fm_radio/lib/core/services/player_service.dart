import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:online_fm_radio/data/models/station.dart';

class PlayerService extends ChangeNotifier {
  AudioHandler? _audioHandler;
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

  void setAudioHandler(AudioHandler handler) {
    _audioHandler = handler;
    _setupAudioHandlerListeners();
  }

  void _setupAudioHandlerListeners() {
    if (_audioHandler == null) return;

    _audioHandler!.playbackState.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == AudioProcessingState.buffering;

      if (state.processingState == AudioProcessingState.completed) {
        stop();
      }

      notifyListeners();
    });

    _audioHandler!.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        notifyListeners();
      }
    });
  }

  Future<void> play(Station station) async {
    if (_audioHandler == null) {
      _errorMessage = 'Audio service not initialized';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _retryCount = 0;
    _currentStation = station;
    _isBuffering = true;
    notifyListeners();

    try {
      final mediaItem = MediaItem(
        id: station.id,
        title: station.name,
        artist: station.country,
        album: station.category,
        artUri: station.logo.isNotEmpty ? Uri.parse(station.logo) : null,
        duration: const Duration(days: 1),
      );

      await _audioHandler!.addMediaItem(mediaItem);
      await _audioHandler!.setUrl(station.streamUrl);
      await _audioHandler!.play();
    } catch (e) {
      _handlePlaybackError(e.toString());
    }
  }

  Future<void> pause() async {
    if (_audioHandler == null || !_isPlaying) return;

    await _audioHandler!.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_audioHandler == null || _isPlaying || _currentStation == null) return;

    await _audioHandler!.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    if (_audioHandler == null) return;

    await _audioHandler!.stop();
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
    if (_audioHandler != null) {
      await _audioHandler!.seek(position);
    }
  }

  Stream<Duration?> get positionStream => _audioHandler?.playbackState
      .map((state) => state.updatePosition) ?? Stream.value(null);

  Stream<Duration?> get durationStream => _audioHandler?.mediaItem
      .map((item) => item?.duration) ?? Stream.value(null);

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioHandler?.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    AudioService.stop();
    super.dispose();
  }
}