import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../providers/playlist_provider.dart';
import '../widgets/playlist_tile.dart';

class PlaylistTileWithTracks extends StatelessWidget {
  final Playlist playlist;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlaylistTileWithTracks({
    Key? key,
    required this.playlist,
    this.isGridView = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<Track>>(
      future: _loadPlaylistTracks(playlistProvider),
      builder: (context, snapshot) {
        // Show basic tile while loading or on error
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return PlaylistTile(
            playlist: playlist,
            isGridView: isGridView,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        }

        // Show tile with tracks for artwork generation
        return PlaylistTile(
          playlist: playlist,
          tracks: snapshot.data,
          isGridView: isGridView,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }

  Future<List<Track>> _loadPlaylistTracks(
    PlaylistProvider playlistProvider,
  ) async {
    try {
      // Only load first 4 tracks for artwork generation (performance optimization)
      final trackIds = playlist.trackIds.take(4).toList();
      if (trackIds.isEmpty) return [];

      // Get tracks from playlist provider
      return await playlistProvider.getTracksByIds(trackIds);
    } catch (e) {
      print('Error loading tracks for playlist artwork: $e');
      return [];
    }
  }
}
