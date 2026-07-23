import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/constants/app_constants.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
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
import 'package:online_fm_radio/features/languages/language_stations_page.dart';
import 'package:online_fm_radio/features/tags/tag_list_page.dart';
import 'package:online_fm_radio/features/tags/tag_stations_page.dart';

Future<void> main() async {
  // 必须先初始化 Flutter 绑定，才能在 runApp 之前调用平台插件。
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化后台播放通知栏服务（Android 媒体通知 / iOS 控制中心）。
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.online_fm_radio.channel.audio',
    androidNotificationChannelName: 'Online FM Radio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: false,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        ChangeNotifierProvider<PlayerService>(
          create: (context) => PlayerService(
            historyService: context.read<HistoryService>(),
          ),
        ),
        ChangeNotifierProvider<SleepTimerService>(
          create: (_) => SleepTimerService(),
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
          '/tags': (context) => const TagListPage(),
          '/tag_stations': (context) {
            final tag = ModalRoute.of(context)?.settings.arguments as Tag;
            return TagStationsPage(tag: tag!);
          },
          '/language_stations': (context) {
            final language = ModalRoute.of(context)?.settings.arguments as Language;
            return LanguageStationsPage(language: language!);
          },
        },
      ),
    );
  }
}