import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_player_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../widgets/playlist_tile.dart';
import 'create_playlist_screen.dart';
import 'login_screen.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  bool _isGridView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Playlist> _filteredPlaylists = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final playlistProvider = context.read<PlaylistProvider>();

      print('🔄 PlaylistsScreen init - Auth: ${authProvider.isAuthenticated}');
      print('🔄 User: ${authProvider.user?.name}');
      print('🔄 Firebase UID: ${authProvider.user?.firebaseUid}');

      playlistProvider.loadUserPlaylists();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text.trim());
    });
  }

  void _performSearch(String query) {
    final playlistProvider = context.read<PlaylistProvider>();
    final allPlaylists = playlistProvider.playlists;

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPlaylists = [];
      });
    } else {
      final filtered = allPlaylists.where((playlist) {
        return playlist.name.toLowerCase().contains(query.toLowerCase()) ||
            playlist.description.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _isSearching = true;
        _filteredPlaylists = filtered;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredPlaylists = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PlaylistProvider>().refreshPlaylists();
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm playlist...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild for suffixIcon
                },
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 80,
              ), // Space for mini player
              child: Consumer<PlaylistProvider>(
                builder: (context, playlistProvider, child) {
                  // Debug info
                  print(
                    '🔄 PlaylistsScreen rebuild - Loading: ${playlistProvider.isLoading}',
                  );
                  print(
                    '🔄 Playlists count: ${playlistProvider.playlists.length}',
                  );
                  print('🔄 Error: ${playlistProvider.errorMessage}');

                  if (playlistProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (playlistProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Có lỗi xảy ra',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            playlistProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              playlistProvider.loadUserPlaylists();
                            },
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Get playlists to display (filtered or all)
                  final playlistsToShow = _isSearching
                      ? _filteredPlaylists
                      : playlistProvider.playlists;

                  if (playlistsToShow.isEmpty && _isSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy playlist',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thử từ khóa khác',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  if (playlistsToShow.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có playlist nào',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tạo playlist đầu tiên của bạn',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createPlaylist,
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo playlist'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await playlistProvider.loadUserPlaylists();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isGridView
                          ? _buildGridView(playlistsToShow)
                          : _buildListView(playlistsToShow),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        tooltip: 'Tạo playlist mới',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const SizedBox(height: 80),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Vui lòng đăng nhập',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem và quản lý playlists của bạn.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Playlist> playlists) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return PlaylistTile(
          playlist: playlist,
          isGridView: true,
          onTap: () => _openPlaylist(playlist.id),
          onEdit: () => _editPlaylist(playlist.id),
          onDelete: () => _deletePlaylist(playlist.id),
        );
      },
    );
  }

  Widget _buildListView(List<Playlist> playlists) {
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return PlaylistTile(
          playlist: playlist,
          isGridView: false,
          onTap: () => _openPlaylist(playlist.id),
          onEdit: () => _editPlaylist(playlist.id),
          onDelete: () => _deletePlaylist(playlist.id),
        );
      },
    );
  }

  void _createPlaylist() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePlaylistScreen()),
    );

    if (result == true) {
      // Playlist được tạo thành công, reload danh sách
      if (mounted) {
        context.read<PlaylistProvider>().loadUserPlaylists();
      }
    }
  }

  void _editPlaylist(String playlistId) async {
    final playlist = context.read<PlaylistProvider>().playlists.firstWhere(
      (p) => p.id == playlistId,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(playlist: playlist),
      ),
    );

    if (result == true) {
      // Playlist được cập nhật thành công
      if (mounted) {
        context.read<PlaylistProvider>().loadUserPlaylists();
      }
    }
  }

  void _openPlaylist(String playlistId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlistId: playlistId),
      ),
    );
  }

  void _deletePlaylist(String playlistId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa playlist'),
        content: const Text('Bạn có chắc chắn muốn xóa playlist này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<PlaylistProvider>().deletePlaylist(playlistId);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
