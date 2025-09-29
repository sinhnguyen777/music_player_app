import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/favorite_provider.dart';
import '../widgets/track_tile.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _filteredFavorites = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    await favoriteProvider.loadFavorites();
    _updateFilteredFavorites();
  }

  void _updateFilteredFavorites() {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    setState(() {
      _filteredFavorites = favoriteProvider.searchFavorites(_searchQuery);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _updateFilteredFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text(
          'Favorite Songs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: favoriteProvider.isLoading
                    ? null
                    : () async {
                        await favoriteProvider.refresh();
                        _updateFilteredFavorites();
                      },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF282828),
            onSelected: (value) async {
              if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          if (favoriteProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            );
          }

          if (favoriteProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading favorites',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    favoriteProvider.error!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => favoriteProvider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (favoriteProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite songs yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding songs to your favorites!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search favorites...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${favoriteProvider.favoriteCount} favorite songs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${_filteredFavorites.length} results',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Favorites List
              Expanded(
                child: _filteredFavorites.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching with different keywords',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final track = _filteredFavorites[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TrackTile(
                                    track: track,
                                    list: _filteredFavorites,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _toggleFavorite(track),
                                ),
                              ],
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

  void _toggleFavorite(Track track) async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    await favoriteProvider.toggleFavorite(track);
    _updateFilteredFavorites();

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Removed from favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF404040).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFF1DB954),
            onPressed: () async {
              await favoriteProvider.addToFavorites(track);
              _updateFilteredFavorites();
            },
          ),
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Clear All Favorites',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove all songs from your favorites? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final favoriteProvider = Provider.of<FavoriteProvider>(
                context,
                listen: false,
              );
              final success = await favoriteProvider.clearAllFavorites();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: success ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          success
                              ? 'All favorites cleared'
                              : 'Failed to clear favorites',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? const Color(0xFF404040).withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                );
              }

              _updateFilteredFavorites();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
