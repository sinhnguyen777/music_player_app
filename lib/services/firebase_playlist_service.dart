import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/playlist.dart';

class FirebasePlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'playlists';

  // Create a new playlist
  Future<Playlist?> createPlaylist({
    required String name,
    required String userFirebaseUid,
    String description = '',
    bool isPublic = false,
    String? imageUrl,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();

      final playlist = Playlist(
        id: docRef.id, // Use Firestore document ID
        name: name,
        description: description,
        userFirebaseUid: userFirebaseUid,
        trackIds: [],
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
        isPublic: isPublic,
      );

      await docRef.set(playlist.toFirestoreMap());
      return playlist;
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }

  // Get user playlists
  Future<List<Playlist>> getUserPlaylists(String userFirebaseUid) async {
    try {
      print('🔥 Firebase Service: Getting playlists for UID: $userFirebaseUid');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: userFirebaseUid)
          .orderBy('updatedAt', descending: true)
          .get();

      print(
        '🔥 Firebase Service: Found ${querySnapshot.docs.length} documents',
      );

      final playlists = querySnapshot.docs
          .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
          .toList();

      print(
        '🔥 Firebase Service: Converted to ${playlists.length} playlist objects',
      );
      return playlists;
    } catch (e) {
      print('Error getting user playlists: $e');
      return [];
    }
  }

  // Get playlist by ID
  Future<Playlist?> getPlaylistById(String playlistId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(playlistId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Playlist.fromFirestoreMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting playlist by ID: $e');
      return null;
    }
  }

  // Update playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(playlist.id)
          .update(playlist.toFirestoreMap());
      return true;
    } catch (e) {
      print('Error updating playlist: $e');
      return false;
    }
  }

  // Delete playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection(_collection).doc(playlistId).delete();
      return true;
    } catch (e) {
      print('Error deleting playlist: $e');
      return false;
    }
  }

  // Add track to playlist
  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      final doc = _firestore.collection(_collection).doc(playlistId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);

        if (!snapshot.exists) {
          throw Exception('Playlist not found');
        }

        final data = snapshot.data()!;
        final trackIds = List<String>.from(data['trackIds'] ?? []);

        if (!trackIds.contains(trackId)) {
          trackIds.add(trackId);
          transaction.update(doc, {
            'trackIds': trackIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      print('Error adding track to playlist: $e');
      return false;
    }
  }

  // Remove track from playlist
  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      final doc = _firestore.collection(_collection).doc(playlistId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);

        if (!snapshot.exists) {
          throw Exception('Playlist not found');
        }

        final data = snapshot.data()!;
        final trackIds = List<String>.from(data['trackIds'] ?? []);

        trackIds.remove(trackId);
        transaction.update(doc, {
          'trackIds': trackIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Error removing track from playlist: $e');
      return false;
    }
  }

  // Reorder tracks in playlist
  Future<bool> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final doc = _firestore.collection(_collection).doc(playlistId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);

        if (!snapshot.exists) {
          throw Exception('Playlist not found');
        }

        final data = snapshot.data()!;
        final trackIds = List<String>.from(data['trackIds'] ?? []);

        if (oldIndex < trackIds.length && newIndex < trackIds.length) {
          final item = trackIds.removeAt(oldIndex);
          trackIds.insert(newIndex, item);

          transaction.update(doc, {
            'trackIds': trackIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      print('Error reordering tracks: $e');
      return false;
    }
  }

  // Search playlists
  Future<List<Playlist>> searchPlaylists(
    String query,
    String userFirebaseUid,
  ) async {
    try {
      // Firestore doesn't support full-text search natively
      // We'll get all user playlists and filter locally
      final allPlaylists = await getUserPlaylists(userFirebaseUid);

      final lowercaseQuery = query.toLowerCase();
      return allPlaylists.where((playlist) {
        return playlist.name.toLowerCase().contains(lowercaseQuery) ||
            playlist.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching playlists: $e');
      return [];
    }
  }

  // Get playlists containing a specific track
  Future<List<Playlist>> getPlaylistsContainingTrack(
    String trackId,
    String userFirebaseUid,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: userFirebaseUid)
          .where('trackIds', arrayContains: trackId)
          .get();

      return querySnapshot.docs
          .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting playlists containing track: $e');
      return [];
    }
  }

  // Get public playlists (for discovery)
  Future<List<Playlist>> getPublicPlaylists({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting public playlists: $e');
      return [];
    }
  }

  // Get playlist stream for real-time updates
  Stream<List<Playlist>> getUserPlaylistsStream(String userFirebaseUid) {
    return _firestore
        .collection(_collection)
        .where('userFirebaseUid', isEqualTo: userFirebaseUid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get playlist stream by ID for real-time updates
  Stream<Playlist?> getPlaylistStream(String playlistId) {
    return _firestore.collection(_collection).doc(playlistId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return Playlist.fromFirestoreMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}
