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

  // Constants
  static const int MAX_TRACKS_PER_BATCH =
      10; // Maximum tracks that can be added at once
  static const int BATCH_SIZE =
      1; // Process tracks one by one to prevent crashes
  static const int WARNING_THRESHOLD =
      8; // Show warning when selecting this many tracks

  List<Track> _searchResults = [];
  List<Track> _selectedTracks = [];
  List<Track> _existingTracks = [];
  bool _isSearching = false;
  bool _isLoadingExisting = true;
  bool _isAddingTracks = false;
  String _loadingMessage = '';

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
    print(
      '🚀 Starting _addSelectedTracks with ${_selectedTracks.length} tracks',
    );

    if (_selectedTracks.isEmpty) {
      print('⚠️ No tracks selected, returning early');
      return;
    }

    // Check if user selected too many tracks
    if (_selectedTracks.length > MAX_TRACKS_PER_BATCH) {
      print(
        '⚠️ Too many tracks selected: ${_selectedTracks.length} > $MAX_TRACKS_PER_BATCH',
      );
      _showTooManyTracksDialog();
      return;
    }

    // Set loading state
    print('🔄 Setting loading state to true');
    setState(() {
      _isAddingTracks = true;
      _loadingMessage = 'Chuẩn bị thêm bài hát...';
    });

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

      print('🎵 Adding ${tracksToAdd.length} new tracks to playlist');

      // Add tracks in smaller batches to avoid timeout
      int totalAddedCount = 0;

      for (int i = 0; i < tracksToAdd.length; i += BATCH_SIZE) {
        final batch = tracksToAdd.skip(i).take(BATCH_SIZE).toList();
        final track = batch.first; // Since BATCH_SIZE = 1

        // Update loading message
        if (mounted) {
          setState(() {
            _loadingMessage =
                'Đang thêm bài hát ${i + 1}/${tracksToAdd.length}...\n${track.title}';
          });
        }

        try {
          print(
            '🎵 Attempting to add track ${i + 1}/${tracksToAdd.length}: ${track.title}',
          );
          print('📊 Track details:');
          print('   - ID: ${track.id}');
          print('   - Source: ${track.source}');
          print('   - URL: ${track.url}');
          print('   - Has raw data: ${track.raw != null}');
          if (track.raw != null) {
            print('   - Raw keys: ${track.raw!.keys.take(5)}');
            print('   - Raw stream_url: ${track.raw!['stream_url']}');
          }

          // Add delay before each track (except first one)
          if (i > 0) {
            print('⏱️ Waiting 500ms before next track...');
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Use the safer single track method
          final success = await _playlistService
              .addSingleTrackSafely(widget.playlistId, track, currentUser.uid)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  print('⏰ Timeout adding track: ${track.title}');
                  return false;
                },
              );

          if (success) {
            totalAddedCount++;
            print('✅ Successfully added track ${i + 1}/${tracksToAdd.length}');
          } else {
            print('⚠️ Failed to add track ${i + 1}/${tracksToAdd.length}');
          }
        } catch (e, stackTrace) {
          print('❌ Error adding track ${i + 1}: $e');
          print('❌ Stack trace: $stackTrace');

          // Show user feedback for failed track
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lỗi track ${i + 1}: ${e.toString().length > 25 ? e.toString().substring(0, 25) + '...' : e.toString()}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 1),
              ),
            );
          }
          // Continue with next track even if one fails
        }
      }

      if (mounted) {
        String message = '';
        if (totalAddedCount > 0 && alreadyExistingTracks.isEmpty) {
          message = 'Đã thêm $totalAddedCount bài hát vào playlist';
        } else if (totalAddedCount > 0 && alreadyExistingTracks.isNotEmpty) {
          message =
              'Đã thêm $totalAddedCount bài hát mới. ${alreadyExistingTracks.length} bài hát đã có sẵn';
        } else if (totalAddedCount == 0 && alreadyExistingTracks.isNotEmpty) {
          message =
              'Tất cả ${alreadyExistingTracks.length} bài hát đã có trong playlist';
        } else {
          message = 'Có lỗi xảy ra khi thêm bài hát';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: totalAddedCount > 0 ? Colors.green : Colors.orange,
          ),
        );

        // Always return to playlist detail, regardless of whether tracks were added
        Navigator.pop(context, totalAddedCount > 0);
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
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isAddingTracks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Tracks'),
            actions: [
              if (_selectedTracks.isNotEmpty)
                _isAddingTracks
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _addSelectedTracks,
                        style: _selectedTracks.length > MAX_TRACKS_PER_BATCH
                            ? TextButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.2),
                                side: const BorderSide(color: Colors.red),
                              )
                            : _selectedTracks.length >= WARNING_THRESHOLD
                            ? TextButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                side: const BorderSide(color: Colors.orange),
                              )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedTracks.length > MAX_TRACKS_PER_BATCH)
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 16,
                              )
                            else if (_selectedTracks.length >=
                                WARNING_THRESHOLD)
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 16,
                              ),
                            if (_selectedTracks.length >= WARNING_THRESHOLD)
                              const SizedBox(width: 4),
                            Text(
                              _selectedTracks.length > MAX_TRACKS_PER_BATCH
                                  ? 'Quá nhiều (${_selectedTracks.length}/$MAX_TRACKS_PER_BATCH)'
                                  : _selectedTracks.length >= WARNING_THRESHOLD
                                  ? 'Nhiều (${_getNewTracksCount()}/${_selectedTracks.length})'
                                  : 'Thêm (${_getNewTracksCount()}/${_selectedTracks.length})',
                              style: TextStyle(
                                color:
                                    _selectedTracks.length >
                                        MAX_TRACKS_PER_BATCH
                                    ? Colors.red
                                    : _selectedTracks.length >=
                                          WARNING_THRESHOLD
                                    ? Colors.orange
                                    : Colors.white,
                              ),
                            ),
                          ],
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
                      child: const Text('Search'),
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
                            Text('Loading existing tracks...'),
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
                            Icon(
                              Icons.library_music,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'You are viewing trending tracks from SoundCloud',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Use the search bar to find other tracks',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
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
                                            ? Theme.of(
                                                context,
                                              ).primaryColorLight
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
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                : isAlreadyInPlaylist
                                ? Colors.grey.withOpacity(0.1)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Loading overlay
        if (_isAddingTracks)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage.isNotEmpty
                            ? _loadingMessage
                            : 'Đang thêm bài hát vào playlist...',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showTooManyTracksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Quá nhiều bài hát', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đã chọn ${_selectedTracks.length} bài hát.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Để đảm bảo hiệu suất tốt nhất, chúng tôi khuyến nghị thêm tối đa $MAX_TRACKS_PER_BATCH bài hát cùng lúc.',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Với $BATCH_SIZE bài hát mỗi batch, quá trình sẽ diễn ra nhanh và ổn định hơn.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Bỏ chọn một số bài hát\n• Hoặc thêm theo từng nhóm nhỏ',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(color: Color(0xFF1DB954)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear selection to help user start over
              setState(() {
                _selectedTracks.clear();
              });
            },
            child: const Text(
              'Xóa hết lựa chọn',
              style: TextStyle(color: Colors.white70),
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
