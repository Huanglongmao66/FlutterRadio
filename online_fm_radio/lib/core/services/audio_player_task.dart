import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/data/models/station.dart';

class AudioPlayerTask extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Station? _currentStation;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  AudioPlayerTask() {
    _init();
  }

  void _init() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      if (processingState == ProcessingState.completed) {
        stop();
      } else if (processingState == ProcessingState.buffering) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.buffering,
          playing: playing,
        ));
      } else if (processingState == ProcessingState.ready) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
          playing: playing,
        ));
      } else {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
        ));
      }
    });

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        playbackState.add(playbackState.value.copyWith(
          updatePosition: _player.position,
        ));
      }
    });
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.stopped,
      playing: false,
    ));
  }

  @override
  Future<void> skipToNext() async {
  }

  @override
  Future<void> skipToPrevious() async {
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  Future<void> playStation(Station station) async {
    _currentStation = station;

    final mediaItem = MediaItem(
      id: station.id,
      title: station.name,
      artist: station.country,
      album: station.category,
      artUri: station.logo.isNotEmpty ? Uri.parse(station.logo) : null,
      duration: const Duration(days: 1),
    );

    addMediaItem(mediaItem);

    try {
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play station: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _playerStateSubscription.cancel();
    await _player.dispose();
    super.dispose();
  }
}