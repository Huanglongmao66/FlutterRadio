import 'package:just_audio/just_audio.dart';

/// 全局 AudioPlayer 单例。
///
/// PlayerService 和 RadioAudioHandler 共享同一个实例，
/// 避免重复创建导致的资源冲突（之前 audio_service 接入失败的根本原因）。
class AudioPlayerSingleton {
  static AudioPlayer? _instance;

  static AudioPlayer get instance {
    _instance ??= AudioPlayer();
    return _instance!;
  }

  /// 仅在应用彻底退出时调用，平时不要 dispose。
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
