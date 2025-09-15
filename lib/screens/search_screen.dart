import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/soundcloud_service.dart';
import '../widgets/track_tile.dart';
import '../main.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = SoundCloudService();
  final _q = TextEditingController();
  List<Track> _results = [];
  bool _loading = false;

  void _search() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      _results = await _api.searchTracks(q, limit: 30);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Search',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
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
                controller: _q,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Songs, Albums, Artists, Podcasts',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  suffixIcon: _q.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary),
                          onPressed: () {
                            _q.clear();
                            setState(() {
                              _results = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _search(),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          if (_loading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                backgroundColor: cardColor,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for your favorite music',
                          style: TextStyle(color: textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TrackTile(track: _results[i], list: _results),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
