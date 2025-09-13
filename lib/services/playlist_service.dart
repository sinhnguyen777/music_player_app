import 'dart:convert';

import '../models/playlist.dart';
import 'db_service.dart';

class PlaylistService {
  final DBService _db = DBService();

  // Create a new playlist
  Future<Playlist?> createPlaylist({
    required String name,
    required int userId,
    String description = '',
    bool isPublic = false,
  }) async {
    try {
      final playlist = Playlist(
        name: name,
        description: description,
        userId: userId,
        isPublic: isPublic,
      );

      final database = await _db.db;
      final id = await database.insert('playlists', playlist.toMap());

      return playlist.copyWith(id: id);
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }

  // Get user's playlists
  Future<List<Playlist>> getUserPlaylists(int userId) async {
    try {
      final database = await _db.db;
      final List<Map<String, dynamic>> maps = await database.query(
        'playlists',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'updatedAt DESC',
      );

      return maps.map((map) => Playlist.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user playlists: $e');
      return [];
    }
  }

  // Get playlist by ID
  Future<Playlist?> getPlaylistById(int playlistId) async {
    try {
      final database = await _db.db;
      final List<Map<String, dynamic>> maps = await database.query(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      if (maps.isNotEmpty) {
        return Playlist.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting playlist: $e');
      return null;
    }
  }

  // Update playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    try {
      if (playlist.id == null) {
        throw Exception('Playlist ID is required for update');
      }

      final updatedPlaylist = playlist.copyWith(updatedAt: DateTime.now());
      final database = await _db.db;

      final count = await database.update(
        'playlists',
        updatedPlaylist.toMap(),
        where: 'id = ?',
        whereArgs: [playlist.id],
      );

      return count > 0;
    } catch (e) {
      print('Error updating playlist: $e');
      return false;
    }
  }

  // Delete playlist
  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final database = await _db.db;
      final count = await database.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      return count > 0;
    } catch (e) {
      print('Error deleting playlist: $e');
      return false;
    }
  }

  // Add track to playlist
  Future<bool> addTrackToPlaylist(int playlistId, String trackId) async {
    try {
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null) {
        throw Exception('Playlist not found');
      }

      if (playlist.containsTrack(trackId)) {
        return false; // Track already in playlist
      }

      final updatedPlaylist = playlist.addTrack(trackId);
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      print('Error adding track to playlist: $e');
      return false;
    }
  }

  // Remove track from playlist
  Future<bool> removeTrackFromPlaylist(int playlistId, String trackId) async {
    try {
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null) {
        throw Exception('Playlist not found');
      }

      final updatedPlaylist = playlist.removeTrack(trackId);
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      print('Error removing track from playlist: $e');
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
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null) {
        throw Exception('Playlist not found');
      }

      final updatedPlaylist = playlist.reorderTracks(oldIndex, newIndex);
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      print('Error reordering tracks: $e');
      return false;
    }
  }

  // Get playlists containing a specific track
  Future<List<Playlist>> getPlaylistsContainingTrack(
    String trackId,
    int userId,
  ) async {
    try {
      final database = await _db.db;
      final List<Map<String, dynamic>> maps = await database.query(
        'playlists',
        where: 'userId = ? AND trackIds LIKE ?',
        whereArgs: [userId, '%$trackId%'],
      );

      final playlists = maps.map((map) => Playlist.fromMap(map)).toList();

      // Filter to ensure exact match (in case of partial matches)
      return playlists
          .where((playlist) => playlist.containsTrack(trackId))
          .toList();
    } catch (e) {
      print('Error getting playlists containing track: $e');
      return [];
    }
  }

  // Search playlists by name
  Future<List<Playlist>> searchPlaylists(String query, int userId) async {
    try {
      final database = await _db.db;
      final List<Map<String, dynamic>> maps = await database.query(
        'playlists',
        where: 'userId = ? AND name LIKE ?',
        whereArgs: [userId, '%$query%'],
        orderBy: 'updatedAt DESC',
      );

      return maps.map((map) => Playlist.fromMap(map)).toList();
    } catch (e) {
      print('Error searching playlists: $e');
      return [];
    }
  }

  // Legacy methods for backwards compatibility
  @Deprecated('Use createPlaylist instead')
  Future<int> createPlaylistLegacy(int userId, String title) async {
    try {
      final playlist = await createPlaylist(name: title, userId: userId);
      return playlist?.id ?? -1;
    } catch (e) {
      print('Error in legacy createPlaylist: $e');
      return -1;
    }
  }

  @Deprecated('Use getUserPlaylists instead')
  Future<List<Map<String, dynamic>>> getPlaylistsLegacy(int userId) async {
    try {
      final playlists = await getUserPlaylists(userId);
      return playlists
          .map((p) => {'id': p.id, 'title': p.name, 'userId': p.userId})
          .toList();
    } catch (e) {
      print('Error in legacy getPlaylists: $e');
      return [];
    }
  }

  // Legacy method for track management
  @Deprecated('Use addTrackToPlaylist instead')
  Future<int> addTrackToPlaylistLegacy(
    int playlistId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
    try {
      final success = await addTrackToPlaylist(playlistId, trackId);
      return success ? 1 : 0;
    } catch (e) {
      print('Error in legacy addTrackToPlaylist: $e');
      return 0;
    }
  }

  // Get playlist items (tracks) - for backward compatibility
  Future<List<Map<String, dynamic>>> getPlaylistItems(int playlistId) async {
    try {
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null) return [];

      // Return track IDs as legacy format
      return playlist.trackIds
          .asMap()
          .entries
          .map(
            (entry) => {
              'id': entry.key,
              'playlistId': playlistId,
              'trackId': entry.value,
              'trackData': json.encode({'id': entry.value}),
            },
          )
          .toList();
    } catch (e) {
      print('Error getting playlist items: $e');
      return [];
    }
  }

  // Toggle favorite (legacy method)
  Future<int> toggleFavorite(
    int userId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
    try {
      final database = await _db.db;
      final existing = await database.query(
        'favorites',
        where: 'userId = ? AND trackId = ?',
        whereArgs: [userId, trackId],
      );

      if (existing.isNotEmpty) {
        return database.delete(
          'favorites',
          where: 'userId = ? AND trackId = ?',
          whereArgs: [userId, trackId],
        );
      } else {
        return database.insert('favorites', {
          'userId': userId,
          'trackId': trackId,
          'trackData': jsonEncode(trackData),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return 0;
    }
  }

  // Get favorites (legacy method)
  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    try {
      final database = await _db.db;
      return database.query(
        'favorites',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
}
