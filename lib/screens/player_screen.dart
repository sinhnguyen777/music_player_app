import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../models/track.dart';
import '../main.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  String _format(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    final Track? t = p.current;
    if (t == null) {
      return Scaffold(
        backgroundColor: primaryColor,
        body: Center(
          child: Text(
            'No track playing',
            style: TextStyle(color: textPrimary, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, color: textPrimary, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accentColor, accentColor.withOpacity(0.8), primaryColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // Circular Album Art
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: t.artworkUrl.isNotEmpty
                          ? t.artworkUrl
                          : 'https://via.placeholder.com/280',
                      width: 280,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Track Info
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  t.artist,
                  style: TextStyle(fontSize: 16, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Progress Bar
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
                            .toDouble();
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: textPrimary,
                                inactiveTrackColor: textSecondary.withOpacity(
                                  0.3,
                                ),
                                thumbColor: textPrimary,
                                overlayColor: textPrimary.withOpacity(0.2),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                value: value,
                                min: 0,
                                max: max,
                                onChanged: (v) => p.audioPlayer.seek(
                                  Duration(milliseconds: v.toInt()),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _format(pos),
                                    style: TextStyle(color: textSecondary),
                                  ),
                                  Text(
                                    _format(dur),
                                    style: TextStyle(color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle, color: textSecondary),
                      iconSize: 28,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: textPrimary),
                      iconSize: 40,
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
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: textPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: textPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                            ),
                            iconSize: 36,
                            onPressed: () => p.togglePlayPause(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: textPrimary),
                      iconSize: 40,
                      onPressed: () => p.next(),
                    ),
                    IconButton(
                      icon: Icon(Icons.repeat, color: textSecondary),
                      iconSize: 28,
                      onPressed: () {},
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
