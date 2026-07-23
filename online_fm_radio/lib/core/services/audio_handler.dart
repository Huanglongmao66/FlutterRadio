import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:online_fm_radio/core/services/audio_player_singleton.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 后台音频处理 Handler：桥接 just_audio 与 audio_service。
///
/// 完整支持：
/// - 后台播放（前台服务保活）
/// - 锁屏媒体控制（播放/暂停/停止）
/// - 线控耳机按键
/// - 蓝牙耳机媒体控制
/// - 通知栏媒体控制
class RadioAudioHandler extends BaseAudioHandler with QueueHandler {
  final AudioPlayer _player = AudioPlayerSingleton.instance;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

  final List<Station> _stationQueue = [];
  int _currentIndex = -1;
  final StreamController<int> _indexController = StreamController<int>.broadcast();

  Stream<int> get currentIndexStream => _indexController.stream;
  int get currentIndex => _currentIndex;

  Station? get currentStation =>
      _currentIndex >= 0 && _currentIndex < _stationQueue.length
          ? _stationQueue[_currentIndex]
          : null;

  List<Station> get stationQueue => List.unmodifiable(_stationQueue);

  RadioAudioHandler() {
    _init();
  }

  void _init() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 4],
        processingState: _mapProcessingState(state.processingState),
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });

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
    final item = _stationToMediaItem(station);
    mediaItem.add(item);
  }

  /// 设置播放队列，支持线控/蓝牙切台。
  void setPlayQueue(List<Station> stations, int startIndex) {
    _stationQueue.clear();
    _stationQueue.addAll(stations);
    _currentIndex = startIndex;
    _indexController.add(startIndex);

    final queueItems = stations.map(_stationToMediaItem).toList();
    queue.add(queueItems);

    if (startIndex >= 0 && startIndex < stations.length) {
      setStationMediaItem(stations[startIndex]);
    }
  }

  /// 追加到队列末尾。
  void appendToQueue(Station station) {
    _stationQueue.add(station);
    final newQueue = List<MediaItem>.from(queue.value)
      ..add(_stationToMediaItem(station));
    queue.add(newQueue);
  }

  /// 从队列中移除指定位置。
  void removeFromQueue(int index) {
    if (index < 0 || index >= _stationQueue.length) return;
    _stationQueue.removeAt(index);
    final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
    queue.add(newQueue);
    if (index < _currentIndex) {
      _currentIndex--;
      _indexController.add(_currentIndex);
    }
  }

  MediaItem _stationToMediaItem(Station station) {
    return MediaItem(
      id: station.id,
      album: station.country,
      title: station.name,
      artist: station.country,
      genre: station.category,
      artUri: station.safeLogo.isNotEmpty ? Uri.tryParse(station.safeLogo) : null,
      displayDescription: station.description,
      duration: Duration.zero,
      playable: true,
      extras: {
        'streamUrl': station.streamUrl,
        'countryCode': station.countryCode,
        'language': station.language,
        'votes': station.votes,
        'bitrate': station.bitrate,
        'codec': station.codec,
      },
    );
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
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> skipToNext() async {
    if (_stationQueue.isEmpty) return;
    final next = (_currentIndex + 1) % _stationQueue.length;
    _skipToIndex(next);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_stationQueue.isEmpty) return;
    final prev = (_currentIndex - 1 + _stationQueue.length) % _stationQueue.length;
    _skipToIndex(prev);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _stationQueue.length) return;
    _skipToIndex(index);
  }

  Future<void> _skipToIndex(int index) async {
    if (index < 0 || index >= _stationQueue.length) return;
    final station = _stationQueue[index];
    _currentIndex = index;
    _indexController.add(index);
    setStationMediaItem(station);
    try {
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (_) {
      // 错误由 PlayerService 处理
    }
  }

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
    await super.onNotificationDeleted();
  }

  @override
  Future<void> onClick(MediaButton button) async {
    switch (button) {
      case MediaButton.media:
        if (_player.playing) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> dispose() async {
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _indexController.close();
  }
}
