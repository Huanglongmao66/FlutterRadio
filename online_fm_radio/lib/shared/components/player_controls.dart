import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/data/models/station.dart';

class PlayerControls extends StatelessWidget {
  final Station station;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PlayerControls({
    super.key,
    required this.station,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 40),
                onPressed: onPrevious,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  if (playerService.currentStation == station) {
                    if (playerService.isPlaying) {
                      playerService.pause();
                    } else {
                      playerService.resume();
                    }
                  } else {
                    playerService.play(station);
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    playerService.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 40),
                onPressed: onNext,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        );
      },
    );
  }
}