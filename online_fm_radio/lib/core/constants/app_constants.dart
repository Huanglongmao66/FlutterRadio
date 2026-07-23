/// 应用全局常量配置类
///
/// 集中管理应用中使用的常量值，包括应用信息、存储键、默认值、URL 等。
class AppConstants {
  /// 应用名称
  static const String appName = 'FMradio';

  /// 应用版本号
  static const String appVersion = '1.0.0';

  /// 应用构建号
  static const String appBuildNumber = '1';

  /// 应用包名
  static const String packageName = 'com.example.online_fm_radio';

  /// 音频通知渠道 ID
  static const String audioNotificationChannelId = '$packageName.channel.audio';

  /// 音频通知渠道名称
  static const String audioNotificationChannelName = 'Online FM Radio';

  /// 收藏列表存储键
  static const String storageKeyFavorites = 'favorites';

  /// 播放历史存储键
  static const String storageKeyPlayHistory = 'play_history';

  /// 主题模式存储键
  static const String storageKeyThemeMode = 'theme_mode';

  /// 音量设置存储键
  static const String storageKeyVolume = 'volume';

  /// 定时关闭存储键
  static const String storageKeySleepTimer = 'sleep_timer';

  /// 播放历史最大长度
  static const int maxHistoryLength = 10;

  /// 收藏电台最大数量
  static const int maxFavoriteStations = 50;

  /// 默认定时关闭时长（分钟）
  static const int defaultSleepTimerDuration = 30;

  /// 默认音量（0.0 ~ 1.0）
  static const double defaultVolume = 0.5;

  /// 隐私政策 URL
  static const String urlPrivacyPolicy = 'https://example.com/privacy';

  /// 服务条款 URL
  static const String urlTermsOfService = 'https://example.com/terms';

  /// API 基础 URL
  static const String apiBaseUrl = 'https://api.example.com';

  /// 支持的音乐分类列表
  static const List<String> supportedCategories = [
    'Pop',
    'Rock',
    'Jazz',
    'Classical',
    'Electronic',
    'Hip Hop',
    'Country',
    'Reggae',
    'Blues',
    'R&B',
    'Latin',
    'World',
  ];

  /// 支持的国家列表
  static const List<String> supportedCountries = [
    'USA',
    'UK',
    'Germany',
    'France',
    'Japan',
    'China',
    'India',
    'Brazil',
    'Mexico',
    'Canada',
    'Australia',
    'Russia',
    'Spain',
    'Italy',
    'South Korea',
  ];
}