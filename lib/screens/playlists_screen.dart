import 'package:flutter/material.dart';
import 'package:music_player_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          // Debug info
          print(
            '🔄 PlaylistsScreen rebuild - Loading: ${playlistProvider.isLoading}',
          );
          print('🔄 Playlists count: ${playlistProvider.playlists.length}');
          print('🔄 Error: ${playlistProvider.errorMessage}');

          if (playlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (playlistProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
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

          if (playlistProvider.playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: Colors.grey[400]),
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
              child: _isGridView ? _buildGridView() : _buildListView(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        tooltip: 'Tạo playlist mới',
        child: const Icon(Icons.add),
      ),
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

  Widget _buildGridView() {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: playlistProvider.playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlistProvider.playlists[index];
            return PlaylistTile(
              playlist: playlist,
              isGridView: true,
              onTap: () => _openPlaylist(playlist.id!),
              onEdit: () => _editPlaylist(playlist.id!),
              onDelete: () => _deletePlaylist(playlist.id!),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return ListView.builder(
          itemCount: playlistProvider.playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlistProvider.playlists[index];
            return PlaylistTile(
              playlist: playlist,
              isGridView: false,
              onTap: () => _openPlaylist(playlist.id!),
              onEdit: () => _editPlaylist(playlist.id!),
              onDelete: () => _deletePlaylist(playlist.id!),
            );
          },
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

  void _editPlaylist(int playlistId) async {
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm playlist'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên playlist...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            if (query.isNotEmpty) {
              context.read<PlaylistProvider>().searchPlaylists(query);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset search to show all playlists
              context.read<PlaylistProvider>().loadUserPlaylists();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
