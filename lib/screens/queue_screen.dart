import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hàng đợi phát',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<PlayerProvider>(
            builder: (context, playerProvider, child) {
              final queue = playerProvider.queue;
              if (queue.length > 1) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textPrimary),
                  onSelected: (value) {
                    switch (value) {
                      case 'clear':
                        _showClearQueueDialog(context, playerProvider);
                        break;
                      case 'shuffle':
                        // TODO: Implement shuffle queue
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shuffle queue coming soon!'),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'shuffle',
                      child: Row(
                        children: [
                          Icon(Icons.shuffle),
                          SizedBox(width: 8),
                          Text('Trộn hàng đợi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Xóa hàng đợi',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final queue = playerProvider.queue;
          final currentTrack = playerProvider.current;

          if (queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Hàng đợi trống',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm bài hát để bắt đầu phát',
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Queue Info Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      '${queue.length} bài hát trong hàng đợi',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Current Playing Section
              if (currentTrack != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Play indicator
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Album art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: currentTrack.artworkUrl.isNotEmpty
                              ? currentTrack.artworkUrl
                              : 'https://via.placeholder.com/48',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: accentColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ĐANG PHÁT',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentTrack.artist,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Next Up Section
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    final isCurrentTrack = currentTrack?.id == track.id;

                    // Skip current playing track (already shown above)
                    if (isCurrentTrack) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _buildQueueTrackTile(
                        context,
                        track,
                        index,
                        playerProvider,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQueueTrackTile(
    BuildContext context,
    Track track,
    int index,
    PlayerProvider playerProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Queue position indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: track.artworkUrl.isNotEmpty
                    ? track.artworkUrl
                    : 'https://via.placeholder.com/40',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        title: Text(
          track.title,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: TextStyle(color: textSecondary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textSecondary, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'play':
                // TODO: Jump to this track in queue
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Jumping to "${track.title}"')),
                );
                break;
              case 'remove':
                // TODO: Remove from queue
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${track.title}" from queue'),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Phát ngay'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Xóa khỏi hàng đợi',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Jump to this track
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Jumping to "${track.title}"')),
          );
        },
      ),
    );
  }

  void _showClearQueueDialog(
    BuildContext context,
    PlayerProvider playerProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Xóa hàng đợi', style: TextStyle(color: textPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn xóa tất cả bài hát khỏi hàng đợi?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear queue
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clear queue coming soon!')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
