import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:online_fm_radio/core/constants/app_constants.dart';
import 'package:online_fm_radio/core/services/audio_handler.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/local_station_service.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
import 'package:online_fm_radio/core/services/visualizer_settings_service.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/core/theme/app_theme.dart';
import 'package:online_fm_radio/core/ui/main_app.dart';
import 'package:online_fm_radio/features/home/home_page_view_model.dart';
import 'package:online_fm_radio/features/player/player_page.dart';
import 'package:online_fm_radio/features/search/search_page.dart';
import 'package:online_fm_radio/features/settings/settings_page.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/models/language.dart';
import 'package:online_fm_radio/data/models/tag.dart';
import 'package:online_fm_radio/features/countries/country_list_page.dart';
import 'package:online_fm_radio/features/countries/country_stations_page.dart';
import 'package:online_fm_radio/features/languages/language_list_page.dart';
import 'package:online_fm_radio/features/languages/language_stations_page.dart';
import 'package:online_fm_radio/features/stations/local_stations_page.dart';
import 'package:online_fm_radio/features/tags/tag_list_page.dart';
import 'package:online_fm_radio/features/tags/tag_stations_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RadioAudioHandler? audioHandler;
  try {
    // 初始化 audio_service：启动前台媒体播放服务。
    // RadioAudioHandler 使用全局单例 AudioPlayer，与 PlayerService 共享，
    // 避免重复创建导致的网络/资源冲突。
    audioHandler = await AudioService.init(
      builder: () => RadioAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.online_fm_radio.channel.audio',
        androidNotificationChannelName: 'Online FM Radio',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        notificationColor: Color(0xFF6366F1),
      ),
    );
  } catch (e) {
    debugPrint('audio_service init failed (fallback): $e');
  }

  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final RadioAudioHandler? audioHandler;

  const MyApp({super.key, this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CountryPreferenceService>(
          create: (_) => CountryPreferenceService()..loadCountry(),
        ),
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService()..loadFavorites(),
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService()..loadHistory(),
        ),
        ChangeNotifierProvider<LocalStationService>(
          create: (_) => LocalStationService()..loadStations(),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (context) => PlayerService(
            historyService: context.read<HistoryService>(),
            audioHandler: audioHandler,
          ),
        ),
        ChangeNotifierProvider<SleepTimerService>(
          create: (_) => SleepTimerService(),
        ),
        ChangeNotifierProvider<VisualizerSettingsService>(
          create: (_) => VisualizerSettingsService(),
        ),
        ChangeNotifierProvider<StationUpdateService>(
          create: (_) => StationUpdateService(),
        ),
        ChangeNotifierProvider<HomePageViewModel>(
          create: (_) => HomePageViewModel(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const MainApp(),
          '/player': (context) {
            final station = ModalRoute.of(context)?.settings.arguments as Station;
            return PlayerPage(station: station);
          },
          '/search': (context) => const SearchPage(),
          '/settings': (context) => const SettingsPage(),
          '/countries': (context) => const CountryListPage(),
          '/country_stations': (context) {
            final country = ModalRoute.of(context)?.settings.arguments as Country;
            return CountryStationsPage(country: country!);
          },
          '/languages': (context) => const LanguageListPage(),
          '/language_stations': (context) {
            final language = ModalRoute.of(context)?.settings.arguments as Language;
            return LanguageStationsPage(language: language!);
          },
          '/tags': (context) => const TagListPage(),
          '/tag_stations': (context) {
            final tag = ModalRoute.of(context)?.settings.arguments as Tag;
            return TagStationsPage(tag: tag!);
          },
          '/local_stations': (context) => const LocalStationsPage(),
        },
      ),
    );
  }
}