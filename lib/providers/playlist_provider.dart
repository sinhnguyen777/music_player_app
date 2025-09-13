import 'package:flutter/material.dart';
import 'package:music_player_app/providers/auth_provider.dart';

import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final AuthProvider? authProvider;
  int? get _userId => authProvider?.user?.id;

  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _errorMessage;

  PlaylistProvider(this.authProvider) {
    if (_userId != null) {
      loadUserPlaylists();
    }
  }

  // Getters
  List<Playlist> get playlists => _playlists;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize provider
  Future<void> init() async {
    // Load initial data if needed
  }

  // Load user playlists
  Future<void> loadUserPlaylists() async {
    if (_userId == null) {
      _playlists = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _playlists = await _playlistService.getUserPlaylists(_userId!);
      _clearError();
    } catch (e) {
      _setError('Failed to load playlists: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create new playlist
  Future<bool> createPlaylist({
    required String name,
    String description = '',
    bool isPublic = false,
  }) async {
    if (_userId == null) {
      _setError('User not logged in');
      return false;
    }
    _setLoading(true);
    try {
      final playlist = await _playlistService.createPlaylist(
        name: name,
        userId: _userId!,
        description: description,
        isPublic: isPublic,
      );

      if (playlist != null) {
        _playlists.insert(0, playlist); // Add to beginning
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create playlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    try {
      final success = await _playlistService.updatePlaylist(playlist);
      if (success) {
        final index = _playlists.indexWhere((p) => p.id == playlist.id);
        if (index != -1) {
          _playlists[index] = playlist;
          if (_currentPlaylist?.id == playlist.id) {
            _currentPlaylist = playlist;
          }
          notifyListeners();
        }
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to update playlist: ${e.toString()}');
      return false;
    }
  }

  // Delete playlist
  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final success = await _playlistService.deletePlaylist(playlistId);
      if (success) {
        _playlists.removeWhere((p) => p.id == playlistId);
        if (_currentPlaylist?.id == playlistId) {
          _currentPlaylist = null;
        }
        notifyListeners();
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete playlist: ${e.toString()}');
      return false;
    }
  }

  // Add track to playlist
  Future<bool> addTrackToPlaylist(int playlistId, String trackId) async {
    try {
      final success = await _playlistService.addTrackToPlaylist(
        playlistId,
        trackId,
      );
      if (success) {
        await _refreshPlaylist(playlistId);
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to add track: ${e.toString()}');
      return false;
    }
  }

  // Remove track from playlist
  Future<bool> removeTrackFromPlaylist(int playlistId, String trackId) async {
    try {
      final success = await _playlistService.removeTrackFromPlaylist(
        playlistId,
        trackId,
      );
      if (success) {
        await _refreshPlaylist(playlistId);
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to remove track: ${e.toString()}');
      return false;
    }
  }

  // Reorder tracks in playlist
  Future<bool> reorderPlaylistTracks(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final success = await _playlistService.reorderPlaylistTracks(
        playlistId,
        oldIndex,
        newIndex,
      );
      if (success) {
        await _refreshPlaylist(playlistId);
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to reorder tracks: ${e.toString()}');
      return false;
    }
  }

  // Set current playlist
  void setCurrentPlaylist(Playlist? playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  // Load playlist by ID
  Future<Playlist?> loadPlaylistById(int playlistId) async {
    try {
      final playlist = await _playlistService.getPlaylistById(playlistId);
      if (playlist != null) {
        _clearError();
      }
      return playlist;
    } catch (e) {
      _setError('Failed to load playlist: ${e.toString()}');
      return null;
    }
  }

  // Search playlists
  Future<List<Playlist>> searchPlaylists(String query) async {
    if (_userId == null) return [];
    try {
      final results = await _playlistService.searchPlaylists(query, _userId!);
      _clearError();
      return results;
    } catch (e) {
      _setError('Failed to search playlists: ${e.toString()}');
      return [];
    }
  }

  // Get playlists containing a track
  Future<List<Playlist>> getPlaylistsContainingTrack(String trackId) async {
    if (_userId == null) return [];
    try {
      final results = await _playlistService.getPlaylistsContainingTrack(
        trackId,
        _userId!,
      );
      _clearError();
      return results;
    } catch (e) {
      _setError('Failed to get playlists: ${e.toString()}');
      return [];
    }
  }

  // Check if track is in any playlist
  bool isTrackInAnyPlaylist(String trackId) {
    return _playlists.any((playlist) => playlist.containsTrack(trackId));
  }

  // Get playlists containing specific track (from loaded playlists)
  List<Playlist> getLoadedPlaylistsContainingTrack(String trackId) {
    return _playlists
        .where((playlist) => playlist.containsTrack(trackId))
        .toList();
  }

  // Refresh specific playlist
  Future<void> _refreshPlaylist(int playlistId) async {
    final updatedPlaylist = await _playlistService.getPlaylistById(playlistId);
    if (updatedPlaylist != null) {
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = updatedPlaylist;
        if (_currentPlaylist?.id == playlistId) {
          _currentPlaylist = updatedPlaylist;
        }
        notifyListeners();
      }
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    print('PlaylistProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _playlists.clear();
    _currentPlaylist = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Get playlist statistics
  Map<String, dynamic> getPlaylistStats() {
    return {
      'totalPlaylists': _playlists.length,
      'totalTracks': _playlists.fold<int>(
        0,
        (sum, playlist) => sum + playlist.trackCount,
      ),
      'publicPlaylists': _playlists.where((p) => p.isPublic).length,
      'privatePlaylists': _playlists.where((p) => !p.isPublic).length,
    };
  }
}
