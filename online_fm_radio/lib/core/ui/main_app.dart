import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/ui/app_bottom_navigation.dart';
import 'package:online_fm_radio/features/home/home_page.dart';
import 'package:online_fm_radio/features/explore/explore_page.dart';
import 'package:online_fm_radio/features/favorites/favorites_page.dart';
import 'package:online_fm_radio/features/profile/profile_page.dart';
import 'package:online_fm_radio/shared/components/mini_player_bar.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ExplorePage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Persistent mini player; only renders when a station is playing.
          const MiniPlayerBar(),
          AppBottomNavigation(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}