import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

const Color accentColor = Color(0xFF6C5CE7);
const Color primaryColor = Color(0xFF1A1A1A);

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  void _openPlayerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, p, _) {
        final t = p.current;
        if (t == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _openPlayerScreen(context),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(1),
                  accentColor.withOpacity(0.9),
                  primaryColor,
                ],
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    t.artworkUrl.isNotEmpty
                        ? t.artworkUrl
                        : 'https://via.placeholder.com/56',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.artist,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Control buttons - prevent tap through to PlayerScreen
                GestureDetector(
                  onTap: () {}, // Absorb taps to prevent bubbling
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play/Pause button
                      StreamBuilder<PlayerState>(
                        stream: p.playerStateStream,
                        builder: (c, s) {
                          final state = s.data;
                          final playing = state?.playing ?? false;
                          final proc = state?.processingState;
                          if (proc == ProcessingState.loading ||
                              proc == ProcessingState.buffering) {
                            return const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(),
                            );
                          }
                          return IconButton(
                            key: const Key('mini_player_play_pause'),
                            onPressed: () => p.togglePlayPause(),
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 36,
                            ),
                          );
                        },
                      ),
                      // Next button
                      IconButton(
                        key: const Key('mini_player_next'),
                        onPressed: () => p.next(),
                        icon: const Icon(Icons.skip_next),
                      ),
                      // Queue button
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, child) {
                          final queueLength = playerProvider.queue.length;
                          if (queueLength <= 1) return const SizedBox.shrink();

                          return IconButton(
                            key: const Key('mini_player_queue'),
                            onPressed: () => _openPlayerScreen(context),
                            icon: Stack(
                              children: [
                                const Icon(Icons.queue_music, size: 20),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      '$queueLength',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
