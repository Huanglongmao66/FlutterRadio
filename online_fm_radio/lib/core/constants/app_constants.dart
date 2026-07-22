class AppConstants {
  static const String appName = 'Online FM Radio';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  static const String packageName = 'com.example.online_fm_radio';

  static const String audioNotificationChannelId = '$packageName.channel.audio';
  static const String audioNotificationChannelName = 'Online FM Radio';

  static const String storageKeyFavorites = 'favorites';
  static const String storageKeyPlayHistory = 'play_history';
  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyVolume = 'volume';
  static const String storageKeySleepTimer = 'sleep_timer';

  static const int maxHistoryLength = 10;
  static const int maxFavoriteStations = 50;

  static const int defaultSleepTimerDuration = 30;

  static const double defaultVolume = 0.5;

  static const String urlPrivacyPolicy = 'https://example.com/privacy';
  static const String urlTermsOfService = 'https://example.com/terms';

  static const String apiBaseUrl = 'https://api.example.com';

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