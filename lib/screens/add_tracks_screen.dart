import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';
import '../services/firebase_playlist_service.dart';
import '../services/soundcloud_service.dart';

class AddTracksScreen extends StatefulWidget {
  final String playlistId;

  const AddTracksScreen({super.key, required this.playlistId});

  @override
  State<AddTracksScreen> createState() => _AddTracksScreenState();
}

class _AddTracksScreenState extends State<AddTracksScreen> {
  final FirebasePlaylistService _playlistService = FirebasePlaylistService();
  final SoundCloudService _soundCloudService = SoundCloudService();
  final TextEditingController _searchController = TextEditingController();
  List<Track> _searchResults = [];
  List<Track> _selectedTracks = [];
  List<Track> _existingTracks = [];
  bool _isSearching = false;
  bool _isLoadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingTracks();
    _loadTrendingTracks(); // Load trending tracks initially
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTracks() async {
    try {
      final tracks = await _playlistService.getPlaylistTracks(
        widget.playlistId,
      );
      setState(() {
        _existingTracks = tracks;
        _isLoadingExisting = false;
      });
    } catch (e) {
      print('Error loading existing tracks: $e');
      setState(() {
        _isLoadingExisting = false;
      });
    }
  }

  bool _isTrackAlreadyInPlaylist(Track track) {
    return _existingTracks.any((t) => t.id == track.id);
  }

  int _getNewTracksCount() {
    return _selectedTracks
        .where((track) => !_isTrackAlreadyInPlaylist(track))
        .length;
  }

  Future<void> _loadTrendingTracks() async {
    if (_searchController.text.isNotEmpty)
      return; // Don't load if user is searching

    try {
      setState(() {
        _isSearching = true;
      });

      final trendingTracks = await _soundCloudService.getCharts(limit: 10);
      setState(() {
        _searchResults = trendingTracks;
        _isSearching = false;
      });
    } catch (e) {
      print('Error loading trending tracks: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchTracks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Search from SoundCloud API
      final tracks = await _soundCloudService.searchTracks(query, limit: 10);

      print('=====> tracks: $tracks');

      setState(() {
        _searchResults = tracks;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching tracks: $e');

      // Fallback to sample tracks if SoundCloud fails
      final sampleTracks = [
        Track(
          id: 'sample1_$query',
          title: '$query Song 1',
          artist: 'Artist 1',
          artworkUrl: 'https://picsum.photos/200?random=1',
          duration: 180,
          source: 'sample',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ),
        Track(
          id: 'sample2_$query',
          title: '$query Song 2',
          artist: 'Artist 2',
          artworkUrl: 'https://picsum.photos/200?random=2',
          duration: 210,
          source: 'sample',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        ),
        Track(
          id: 'sample3_$query',
          title: '$query Song 3',
          artist: 'Artist 3',
          artworkUrl: 'https://picsum.photos/200?random=3',
          duration: 195,
          source: 'sample',
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        ),
      ];

      setState(() {
        _searchResults = sampleTracks;
        _isSearching = false;
      });
    }
  }

  void _toggleTrackSelection(Track track) {
    setState(() {
      if (_selectedTracks.any((t) => t.id == track.id)) {
        _selectedTracks.removeWhere((t) => t.id == track.id);
      } else {
        _selectedTracks.add(track);
      }
    });
  }

  Future<void> _addSelectedTracks() async {
    if (_selectedTracks.isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Filter out tracks that are already in the playlist
      final tracksToAdd = _selectedTracks
          .where((track) => !_isTrackAlreadyInPlaylist(track))
          .toList();

      final alreadyExistingTracks = _selectedTracks
          .where((track) => _isTrackAlreadyInPlaylist(track))
          .toList();

      // Add only new tracks
      int addedCount = 0;
      for (final track in tracksToAdd) {
        try {
          await _playlistService.addTrackToPlaylist(
            widget.playlistId,
            track,
            currentUser.uid,
          );
          addedCount++;
        } catch (e) {
          print('Error adding track ${track.title}: $e');
        }
      }

      if (mounted) {
        String message = '';
        if (addedCount > 0 && alreadyExistingTracks.isEmpty) {
          message = 'Đã thêm $addedCount bài hát vào playlist';
        } else if (addedCount > 0 && alreadyExistingTracks.isNotEmpty) {
          message =
              'Đã thêm $addedCount bài hát mới. ${alreadyExistingTracks.length} bài hát đã có sẵn';
        } else if (addedCount == 0 && alreadyExistingTracks.isNotEmpty) {
          message =
              'Tất cả ${alreadyExistingTracks.length} bài hát đã có trong playlist';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: addedCount > 0 ? Colors.green : Colors.orange,
          ),
        );

        // Always return to playlist detail, regardless of whether tracks were added
        Navigator.pop(context, addedCount > 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding track: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tracks'),
        actions: [
          if (_selectedTracks.isNotEmpty)
            TextButton(
              onPressed: _addSelectedTracks,
              child: Text(
                'Thêm (${_getNewTracksCount()}/${_selectedTracks.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for tracks...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                });
                                _loadTrendingTracks(); // Reload trending when cleared
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onSubmitted: (_) => _searchTracks(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchTracks,
                  child: const Text('Tìm'),
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: _isLoadingExisting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải danh sách bài hát hiện tại...'),
                      ],
                    ),
                  )
                : _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Bạn đang xem các bài hát trending từ SoundCloud',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sử dụng thanh tìm kiếm để tìm bài hát khác',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final track = _searchResults[index];
                      final isSelected = _selectedTracks.any(
                        (t) => t.id == track.id,
                      );
                      final isAlreadyInPlaylist = _isTrackAlreadyInPlaylist(
                        track,
                      );

                      return ListTile(
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: track.artworkUrl.isNotEmpty
                                  ? Image.network(
                                      track.artworkUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.music_note,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.music_note),
                                    ),
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            if (isAlreadyInPlaylist)
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.playlist_add_check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isAlreadyInPlaylist ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isAlreadyInPlaylist
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            if (isAlreadyInPlaylist)
                              Text(
                                'Đã có trong playlist',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(track.duration),
                              style: TextStyle(
                                color: isAlreadyInPlaylist
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Consumer<PlayerProvider>(
                              builder: (context, playerProvider, child) {
                                final isCurrentTrack =
                                    playerProvider.current?.id == track.id;
                                final isPlaying =
                                    playerProvider.audioPlayer.playing &&
                                    isCurrentTrack;

                                return IconButton(
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    color: isCurrentTrack
                                        ? Theme.of(context).primaryColorLight
                                        : Colors.grey[600],
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    if (isCurrentTrack && isPlaying) {
                                      playerProvider.togglePlayPause();
                                    } else {
                                      playerProvider.playTrack(
                                        track,
                                        queue: [track],
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () => _toggleTrackSelection(track),
                        tileColor: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : isAlreadyInPlaylist
                            ? Colors.grey.withOpacity(0.1)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
