import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';
import '../models/track.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  String _format(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    final Track? t = p.current;
    if (t == null)
      return const Scaffold(body: Center(child: Text('No track playing')));

    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: Column(
        children: [
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              t.artworkUrl,
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(t.artist, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          StreamBuilder<Duration>(
            stream: p.positionStream,
            builder: (context, snapPos) {
              final pos = snapPos.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: p.durationStream,
                builder: (context, snapDur) {
                  final dur = snapDur.data ?? Duration.zero;
                  final max = dur.inMilliseconds > 0
                      ? dur.inMilliseconds.toDouble()
                      : 1.0;
                  final value = pos.inMilliseconds
                      .toDouble()
                      .clamp(0, max)
                      .toDouble(); // ✅ fix
                  return Column(
                    children: [
                      Slider(
                        value: value, // giờ ok
                        min: 0,
                        max: max,
                        onChanged: (v) => p.audioPlayer.seek(
                          Duration(milliseconds: v.toInt()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(_format(pos)), Text(_format(dur))],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 36,
                onPressed: () => p.previous(),
              ),
              StreamBuilder<PlayerState>(
                stream: p.playerStateStream,
                builder: (context, snap) {
                  final state = snap.data;
                  final playing = state?.playing ?? false;
                  final proc = state?.processingState;
                  if (proc == ProcessingState.loading ||
                      proc == ProcessingState.buffering) {
                    return const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(),
                    );
                  }
                  return IconButton(
                    icon: Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    iconSize: 64,
                    onPressed: () => p.togglePlayPause(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 36,
                onPressed: () => p.next(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
