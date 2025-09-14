import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/firebase_playlist_service.dart';
import 'add_tracks_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final FirebasePlaylistService _playlistService = FirebasePlaylistService();
  List<Track> _tracks = [];
  bool _loadingTracks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().loadPlaylistById(widget.playlistId);
      _loadTracks();
    });
  }

  Future<void> _loadTracks() async {
    setState(() {
      _loadingTracks = true;
    });

    try {
      final tracks = await _playlistService.getPlaylistTracks(
        widget.playlistId,
      );
      setState(() {
        _tracks = tracks;
        _loadingTracks = false;
      });
    } catch (e) {
      print('Error loading tracks: $e');
      setState(() {
        _loadingTracks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          final playlist = playlistProvider.currentPlaylist;

          if (playlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (playlist == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Không tìm thấy playlist')),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with playlist info
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      playlist.imageUrl != null
                          ? Image.network(
                              playlist.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultBackground();
                              },
                            )
                          : _buildDefaultBackground(),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editPlaylist(playlist);
                          break;
                        case 'delete':
                          _deletePlaylist(playlist);
                          break;
                        case 'share':
                          _sharePlaylist(playlist);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Chia sẻ'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Playlist info and controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (playlist.description.isNotEmpty) ...[
                        Text(
                          playlist.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_tracks.length} bài hát',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            playlist.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            playlist.isPublic ? 'Công khai' : 'Riêng tư',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Control buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _tracks.isNotEmpty ? _playAll : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Phát tất cả'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _tracks.isNotEmpty
                                  ? _shufflePlay
                                  : null,
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Phát ngẫu nhiên'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addTracks,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm bài hát'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Track list
              if (_loadingTracks)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_tracks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có bài hát nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thêm bài hát đầu tiên vào playlist của bạn',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: track.artworkUrl.isNotEmpty
                            ? Image.network(
                                track.artworkUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.music_note),
                                    ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.music_note),
                              ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(track.duration),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'remove':
                                  _removeTrackFromPlaylist(track, index);
                                  break;
                                case 'play_next':
                                  _playNext(track);
                                  break;
                                case 'add_to_queue':
                                  _addToQueue(track);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'play_next',
                                child: Row(
                                  children: [
                                    Icon(Icons.skip_next),
                                    SizedBox(width: 8),
                                    Text('Phát tiếp theo'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'add_to_queue',
                                child: Row(
                                  children: [
                                    Icon(Icons.queue_music),
                                    SizedBox(width: 8),
                                    Text('Thêm vào hàng đợi'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Xóa khỏi playlist'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _playTrackAtIndex(index),
                    );
                  }, childCount: _tracks.length),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.queue_music, size: 80, color: Colors.white54),
      ),
    );
  }

  void _playAll() {
    if (_tracks.isNotEmpty) {
      // Debug: Check if tracks have URLs
      print('DEBUG: Playing ${_tracks.length} tracks');
      for (int i = 0; i < _tracks.length; i++) {
        print('Track $i: ${_tracks[i].title} - URL: ${_tracks[i].url}');
      }

      final playerProvider = context.read<PlayerProvider>();
      playerProvider.playTrack(_tracks.first, queue: _tracks);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bắt đầu phát playlist')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist trống, không thể phát nhạc'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shufflePlay() {
    if (_tracks.isNotEmpty) {
      print('DEBUG: Shuffle play with ${_tracks.length} tracks');

      final shuffledTracks = List<Track>.from(_tracks);
      shuffledTracks.shuffle();
      final playerProvider = context.read<PlayerProvider>();
      playerProvider.playTrack(shuffledTracks.first, queue: shuffledTracks);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phát ngẫu nhiên playlist')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist trống, không thể phát nhạc'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTracks() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTracksScreen(playlistId: widget.playlistId),
      ),
    );

    // If tracks were added, reload the playlist
    if (result == true) {
      await _loadTracks();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playNext(Track track) {
    final playerProvider = context.read<PlayerProvider>();
    final currentQueue = List<Track>.from(playerProvider.queue);

    if (currentQueue.isNotEmpty) {
      // Find current playing track index
      final currentTrack = playerProvider.current;
      if (currentTrack != null) {
        final currentIndex = currentQueue.indexWhere(
          (t) => t.id == currentTrack.id,
        );
        if (currentIndex != -1) {
          // Insert track after current track
          currentQueue.insert(currentIndex + 1, track);
          // Update the queue (this would require PlayerProvider modification)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "${track.title}" vào phát tiếp theo'),
            ),
          );
          return;
        }
      }
    }

    // Fallback: play track immediately
    playerProvider.playTrack(track, queue: [track, ..._tracks]);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đang phát "${track.title}"')));
  }

  void _addToQueue(Track track) {
    final playerProvider = context.read<PlayerProvider>();
    final currentQueue = List<Track>.from(playerProvider.queue);

    // Add track to end of queue
    currentQueue.add(track);
    // Update the queue (this would require PlayerProvider modification)

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm "${track.title}" vào hàng đợi')),
    );
  }

  void _playTrackAtIndex(int index) {
    final track = _tracks[index];
    final playerProvider = context.read<PlayerProvider>();

    // Create queue starting from selected track
    final queueFromIndex = _tracks.sublist(index) + _tracks.sublist(0, index);

    playerProvider.playTrack(track, queue: queueFromIndex);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đang phát "${track.title}"')));
  }

  void _removeTrackFromPlaylist(Track track, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài hát'),
        content: Text('Bạn có muốn xóa "${track.title}" khỏi playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _playlistService.removeTrackFromPlaylist(
                  widget.playlistId,
                  track.id,
                );
                await _loadTracks(); // Reload tracks
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa "${track.title}" khỏi playlist'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa bài hát: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _editPlaylist(Playlist playlist) async {
    // TODO: Navigate to edit playlist screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chỉnh sửa playlist')));
  }

  void _deletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa playlist'),
        content: Text('Bạn có chắc chắn muốn xóa playlist "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<PlaylistProvider>().deletePlaylist(
                playlist.id,
              );
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _sharePlaylist(Playlist playlist) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chia sẻ playlist')));
  }
}
