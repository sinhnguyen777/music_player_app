import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db_service.dart';

class PlaylistService {
  final DBService _db = DBService();

  Future<int> createPlaylist(int userId, String title) async {
    final database = await _db.db;
    return database.insert('playlists', {'userId': userId, 'title': title});
  }

  Future<List<Map<String, dynamic>>> getPlaylists(int userId) async {
    final database = await _db.db;
    return database.query(
      'playlists',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> addTrackToPlaylist(
    int playlistId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
    final database = await _db.db;
    return database.insert('playlist_items', {
      'playlistId': playlistId,
      'trackId': trackId,
      'trackData': jsonEncode(trackData),
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylistItems(int playlistId) async {
    final database = await _db.db;
    return database.query(
      'playlist_items',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );
  }

  Future<int> removeItem(int id) async {
    final database = await _db.db;
    return database.delete('playlist_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorite(
    int userId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
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
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    final database = await _db.db;
    return database.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}
