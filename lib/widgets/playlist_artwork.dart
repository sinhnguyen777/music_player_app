import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';

class PlaylistArtwork extends StatelessWidget {
  final List<Track> tracks;
  final double size;
  final double borderRadius;

  const PlaylistArtwork({
    Key? key,
    required this.tracks,
    this.size = 200,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get unique artwork URLs (up to 4)
    final artworkUrls = tracks
        .map((track) => track.artworkUrl)
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(4)
        .toList();

    if (artworkUrls.isEmpty) {
      return _buildPlaceholder();
    }

    if (artworkUrls.length == 1) {
      return _buildSingleImage(artworkUrls.first);
    }

    return _buildGridImages(artworkUrls);
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.queue_music, size: size * 0.4, color: Colors.grey[600]),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildGridImages(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImageGrid(imageUrls),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageTile(imageUrls[0])),
          const SizedBox(width: 1),
          Expanded(child: _buildImageTile(imageUrls[1])),
        ],
      );
    }

    if (imageUrls.length == 3) {
      return Row(
        children: [
          Expanded(child: _buildImageTile(imageUrls[0])),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageTile(imageUrls[1])),
                const SizedBox(height: 1),
                Expanded(child: _buildImageTile(imageUrls[2])),
              ],
            ),
          ),
        ],
      );
    }

    // 4 or more images
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImageTile(imageUrls[0])),
              const SizedBox(width: 1),
              Expanded(child: _buildImageTile(imageUrls[1])),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImageTile(imageUrls[2])),
              const SizedBox(width: 1),
              Expanded(
                child: imageUrls.length > 3
                    ? _buildImageTileWithOverlay(
                        imageUrls[3],
                        imageUrls.length - 4,
                      )
                    : _buildImageTile(imageUrls[2]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: Colors.white54,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[800],
        child: Icon(
          Icons.music_note,
          size: size * 0.15,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildImageTileWithOverlay(String imageUrl, int remainingCount) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImageTile(imageUrl),
        if (remainingCount > 0)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Compact version for small displays
class PlaylistArtworkCompact extends StatelessWidget {
  final List<Track> tracks;
  final double size;

  const PlaylistArtworkCompact({Key? key, required this.tracks, this.size = 56})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlaylistArtwork(tracks: tracks, size: size, borderRadius: 6);
  }
}
