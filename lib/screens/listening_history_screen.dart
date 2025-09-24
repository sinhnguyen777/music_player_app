import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/listening_history.dart';
import '../models/track.dart';
import '../providers/listening_history_provider.dart';
import '../providers/player_provider.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);

    // Load data when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListeningHistoryProvider>().loadAll();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    await context.read<ListeningHistoryProvider>().loadMoreHistory();

    setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Listening History',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
            onPressed: () {
              context.read<ListeningHistoryProvider>().refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimary),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clean',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Old History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: textSecondary,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Statistics'),
            Tab(text: 'Top Tracks'),
          ],
        ),
      ),
      body: Consumer<ListeningHistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading && historyProvider.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error occurred',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    historyProvider.error!,
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => historyProvider.refresh(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryTab(historyProvider),
              _buildStatsTab(historyProvider),
              _buildTopTracksTab(historyProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(ListeningHistoryProvider provider) {
    if (provider.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_outlined, color: textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(
              'No listening history yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start listening to music to see your history here',
              style: TextStyle(color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.history.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.history.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final history = provider.history[index];
          return _buildHistoryItem(history);
        },
      ),
    );
  }

  Widget _buildHistoryItem(ListeningHistory history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _playTrack(history),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Album art
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: history.trackArtworkUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.trackTitle,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      history.trackArtist,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(history.listenedAt),
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.play_circle_outline,
                          size: 12,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(history.playPercentage * 100).toInt()}%',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play button
              IconButton(
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: accentColor,
                  size: 28,
                ),
                onPressed: () => _playTrack(history),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(ListeningHistoryProvider provider) {
    final stats = provider.stats;

    if (stats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview
          _buildStatsCard('Overview of the past 30 days', [
            _buildStatItem(
              icon: Icons.music_note,
              label: 'Total Tracks',
              value: '${stats['totalTracks'] ?? 0}',
            ),
            _buildStatItem(
              icon: Icons.access_time,
              label: 'Total Listening Time',
              value: provider.formatTotalListeningTime(),
            ),
            _buildStatItem(
              icon: Icons.person,
              label: 'Unique Artists',
              value: '${stats['uniqueArtists'] ?? 0}',
            ),
            _buildStatItem(
              icon: Icons.trending_up,
              label: 'Average/Day',
              value: '${stats['averagePerDay'] ?? 0}',
            ),
          ]),

          const SizedBox(height: 20),

          // Top genres (nếu có)
          if (stats['topGenres'] != null &&
              (stats['topGenres'] as List).isNotEmpty)
            _buildStatsCard(
              'Top Genres',
              (stats['topGenres'] as List)
                  .take(5)
                  .map(
                    (genre) => _buildStatItem(
                      icon: Icons.category,
                      label: genre.key,
                      value: '${genre.value}',
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopTracksTab(ListeningHistoryProvider provider) {
    if (provider.topTracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.topTracks.length,
      itemBuilder: (context, index) {
        final track = provider.topTracks[index];
        return _buildTopTrackItem(track, index + 1);
      },
    );
  }

  Widget _buildTopTrackItem(Map<String, dynamic> track, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Play track
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rank <= 3 ? accentColor : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Album art
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: track['trackArtworkUrl'] ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['trackTitle'] ?? '',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track['trackArtist'] ?? '',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${track['count'] ?? 0} times',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    context
                        .read<ListeningHistoryProvider>()
                        .formatListeningTime(track['totalDuration'] ?? 0),
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _playTrack(ListeningHistory history) {
    // Create Track from history data
    final track = Track(
      id: history.trackId,
      title: history.trackTitle,
      artist: history.trackArtist,
      artworkUrl: history.trackArtworkUrl,
      duration: history.trackDuration,
      source: history.source,
    );

    // Play track using PlayerProvider
    context.read<PlayerProvider>().playTrack(track);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clean':
        _showCleanHistoryDialog();
        break;
      case 'export':
        _showExportDialog();
        break;
    }
  }

  void _showCleanHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Clean History', style: TextStyle(color: textPrimary)),
        content: Text(
          'Delete listening history older than 90 days?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<ListeningHistoryProvider>()
                  .cleanOldHistory();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Cleanup successful' : 'An error occurred',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature will be developed later'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
