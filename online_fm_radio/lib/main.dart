import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/constants/app_constants.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/core/services/sleep_timer_service.dart';
import 'package:online_fm_radio/core/services/audio_player_task.dart';
import 'package:online_fm_radio/core/theme/app_theme.dart';
import 'package:online_fm_radio/core/ui/main_app.dart';
import 'package:online_fm_radio/features/home/home_page_view_model.dart';
import 'package:online_fm_radio/features/player/player_page.dart';
import 'package:online_fm_radio/data/models/station.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerTask(),
    config: AudioServiceConfig(
      androidNotificationChannelId: AppConstants.audioNotificationChannelId,
      androidNotificationChannelName: AppConstants.audioNotificationChannelName,
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final AudioHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService()..loadFavorites(),
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService()..loadHistory(),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (_) => PlayerService()..setAudioHandler(audioHandler),
        ),
        ChangeNotifierProvider<SleepTimerService>(
          create: (_) => SleepTimerService(),
        ),
        ChangeNotifierProvider<HomePageViewModel>(
          create: (_) => HomePageViewModel(),
        ),
        Provider<AudioHandler>.value(value: audioHandler),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const MainApp(),
          '/player': (context) {
            final station = ModalRoute.of(context)?.settings.arguments as Station;
            return PlayerPage(station: station);
          },
        },
      ),
    );
  }
}