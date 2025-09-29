import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/favorite_service.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();

  List<Track> _favorites = [];
  Map<String, bool> _favoriteStatus = {};
  bool _isLoading = false;
  String? _error;

  List<Track> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get favoriteCount => _favorites.length;

  // Check if a track is favorite
  bool isFavorite(String trackId) {
    return _favoriteStatus[trackId] ?? false;
  }

  // Initialize provider - load favorites
  Future<void> initialize() async {
    await loadFavorites();
  }

  // Load all favorites
  Future<void> loadFavorites() async {
    _setLoading(true);
    _setError(null);

    try {
      _favorites = await _favoriteService.getFavorites();

      // Update favorite status map
      _favoriteStatus.clear();
      for (final track in _favorites) {
        _favoriteStatus[track.id] = true;
      }

      print('Loaded ${_favorites.length} favorite tracks');
    } catch (e) {
      _setError('Error loading favorites: $e');
      print('Error loading favorites: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add track to favorites
  Future<bool> addToFavorites(Track track) async {
    try {
      final success = await _favoriteService.addToFavorites(track);

      if (success) {
        if (!_favorites.any((t) => t.id == track.id)) {
          _favorites.insert(0, track); // Add to beginning for newest first
        }
        _favoriteStatus[track.id] = true;
        notifyListeners();

        print('Added ${track.title} to favorites');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error adding to favorites: $e');
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove track from favorites
  Future<bool> removeFromFavorites(String trackId) async {
    try {
      final success = await _favoriteService.removeFromFavorites(trackId);

      if (success) {
        _favorites.removeWhere((track) => track.id == trackId);
        _favoriteStatus[trackId] = false;
        notifyListeners();

        print('Removed track $trackId from favorites');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error removing from favorites: $e');
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Track track) async {
    final isCurrentlyFavorite = isFavorite(track.id);

    if (isCurrentlyFavorite) {
      return await removeFromFavorites(track.id);
    } else {
      return await addToFavorites(track);
    }
  }

  // Refresh favorites from server
  Future<void> refresh() async {
    await loadFavorites();
  }

  // Clear all favorites
  Future<bool> clearAllFavorites() async {
    try {
      final success = await _favoriteService.clearAllFavorites();

      if (success) {
        _favorites.clear();
        _favoriteStatus.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error clearing favorites: $e');
      print('Error clearing favorites: $e');
      return false;
    }
  }

  // Check favorite status for a track (from server)
  Future<void> checkFavoriteStatus(String trackId) async {
    try {
      final isFav = await _favoriteService.isFavorite(trackId);
      _favoriteStatus[trackId] = isFav;
      notifyListeners();
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  // Batch check favorite status for multiple tracks
  Future<void> checkMultipleFavoriteStatus(List<Track> tracks) async {
    try {
      for (final track in tracks) {
        final isFav = await _favoriteService.isFavorite(track.id);
        _favoriteStatus[track.id] = isFav;
      }
      notifyListeners();
    } catch (e) {
      print('Error checking multiple favorite status: $e');
    }
  }

  // Get favorite tracks by genre
  List<Track> getFavoritesByGenre(String genre) {
    return _favorites
        .where(
          (track) => track.genres.any(
            (g) => g.toLowerCase().contains(genre.toLowerCase()),
          ),
        )
        .toList();
  }

  // Search favorites
  List<Track> searchFavorites(String query) {
    if (query.isEmpty) return _favorites;

    final lowercaseQuery = query.toLowerCase();
    return _favorites
        .where(
          (track) =>
              track.title.toLowerCase().contains(lowercaseQuery) ||
              track.artist.toLowerCase().contains(lowercaseQuery) ||
              track.albumName?.toLowerCase().contains(lowercaseQuery) == true,
        )
        .toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _favorites.clear();
    _favoriteStatus.clear();
    super.dispose();
  }
}
