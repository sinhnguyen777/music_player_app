import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/soundcloud_service.dart';

class HomeProvider with ChangeNotifier {
  final SoundCloudService _sc = SoundCloudService();

  List<Track> hot = [];
  List<Track> trending = [];
  List<Track> latest = [];
  List<Track> recommended = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> init() async {
    // Don't call API immediately on init to prevent app crash
    // Let user manually refresh when needed
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAll() async {
    if (isLoading) return; // Prevent multiple simultaneous calls

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Add timeout to prevent hanging
      await Future.wait([
        _fetchHot(),
        _fetchTrending(),
        _fetchLatest(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timeout');
        },
      );

      recommended = trending.isNotEmpty ? trending : hot; // simple heuristic
      errorMessage = null;
    } catch (e) {
      print('HomeProvider fetchAll error: $e');
      errorMessage =
          'Failed to load music data. Please check your internet connection.';
      // Keep existing data if any
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchHot() async {
    try {
      hot = await _sc.getCharts(kind: 'top', limit: 10);
    } catch (e) {
      print('Failed to fetch hot tracks: $e');
      hot = [];
    }
  }

  Future<void> _fetchTrending() async {
    try {
      trending = await _sc.getCharts(kind: 'trending', limit: 10);
    } catch (e) {
      print('Failed to fetch trending tracks: $e');
      trending = [];
    }
  }

  Future<void> _fetchLatest() async {
    try {
      latest = await _sc.searchTracks('latest', limit: 10);
    } catch (e) {
      print('Failed to fetch latest tracks: $e');
      latest = [];
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
