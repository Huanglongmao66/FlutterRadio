import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/player_service.dart';

/// A persistent mini player bar shown above the bottom navigation.
/// Displays the currently playing station with a play/pause control and
/// navigates to the full player page when tapped.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        final station = playerService.currentStation;
        // Nothing to show when no station is loaded.
        if (station == null) return const SizedBox.shrink();

        return Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/player',
              arguments: station,
            ),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Station logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: (station.logo.isNotEmpty &&
                              (station.logo.startsWith('http://') ||
                                  station.logo.startsWith('https://')))
                          ? CachedNetworkImage(
                              imageUrl: station.logo,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.radio,
                                  size: 22,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.radio,
                                  size: 22,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.radio,
                                size: 22,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Station name + country
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                station.country,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Error indicator
                  if (playerService.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                    ),
                  // Play / pause control
                  IconButton(
                    icon: playerService.isBuffering
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Icon(
                            playerService.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                          ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      if (playerService.isBuffering) return;
                      if (playerService.isPlaying) {
                        playerService.pause();
                      } else {
                        playerService.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: () => playerService.stop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
