import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:online_fm_radio/data/models/station.dart';

class AudioBackgroundService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  Station? _currentStation;

  AudioBackgroundService() {
    _initPlayer();
  }

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

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Future<void> resumePlayback() async {
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _currentStation = null;
    mediaItem.add(null);
  }

  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0.0, 1.0));
  }

  bool get isPlaying => _player.playing;

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

  void cleanup() {
    _playerStateSubscription.cancel();
    _player.dispose();
  }
}

late AudioBackgroundService audioBackgroundService;
