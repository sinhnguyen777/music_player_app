import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final List<Track>? list;
  const TrackTile({super.key, required this.track, this.list});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final playing =
        player.current?.id == track.id && player.audioPlayer.playing;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: track.artworkUrl.isNotEmpty
              ? track.artworkUrl
              : 'https://via.placeholder.com/56',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
        onPressed: () async {
          await player.playTrack(track, queue: list);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        },
      ),
      onTap: () async {
        await player.playTrack(track, queue: list);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
    );
  }
}
