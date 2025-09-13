import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/playlist_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().loadPlaylistById(widget.playlistId);
    });
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
                            '${playlist.trackCount} bài hát',
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
                              onPressed: playlist.trackCount > 0
                                  ? _playAll
                                  : null,
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
                              onPressed: playlist.trackCount > 0
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
              if (playlist.trackCount == 0)
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
                    // TODO: Load actual track data from trackIds
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('Track ${index + 1}'),
                      subtitle: const Text('Artist name'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'remove':
                              _removeTrack(index);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
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
                      onTap: () => _playTrack(index),
                    );
                  }, childCount: playlist.trackCount),
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
    // TODO: Implement play all functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phát tất cả bài hát trong playlist')),
    );
  }

  void _shufflePlay() {
    // TODO: Implement shuffle play functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Phát ngẫu nhiên playlist')));
  }

  void _addTracks() {
    // TODO: Navigate to track selection screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thêm bài hát vào playlist')));
  }

  void _playTrack(int index) {
    // TODO: Implement play track functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Phát bài hát ${index + 1}')));
  }

  void _removeTrack(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài hát'),
        content: const Text('Bạn có muốn xóa bài hát này khỏi playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement remove track
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa bài hát ${index + 1}')),
              );
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
                playlist.id!,
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
