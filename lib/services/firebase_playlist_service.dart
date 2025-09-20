import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/playlist.dart';
import '../models/track.dart';

class FirebasePlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'playlists';

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      print('🔥 Testing Firestore connection...');
      await _firestore.collection('test').doc('connection').get();
      print('🔥 Firestore connection test successful');
      return true;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  // Create a new playlist
  Future<Playlist?> createPlaylist({
    required String name,
    required String userFirebaseUid,
    String description = '',
    bool isPublic = false,
    String? imageUrl,
  }) async {
    try {
      print('🔥 Creating playlist: $name for user: $userFirebaseUid');
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

      final firestoreData = playlist.toFirestoreMap();
      print('🔥 Playlist data to save: $firestoreData');

      await docRef.set(firestoreData);
      print('🔥 Playlist saved successfully with ID: ${docRef.id}');

      // Verify the playlist was saved
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('🔥 Verification: Playlist exists in Firestore');
      } else {
        print('❌ Verification failed: Playlist not found in Firestore');
      }

      return playlist;
    } catch (e) {
      print('❌ Error creating playlist: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Get user playlists
  Future<List<Playlist>> getUserPlaylists(String userFirebaseUid) async {
    try {
      print('🔥 Firebase Service: Getting playlists for UID: $userFirebaseUid');

      // First, let's try without orderBy to see if that's the issue
      print('🔥 Firebase Service: Trying query without orderBy first...');
      final simpleQuery = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: userFirebaseUid)
          .get();

      print(
        '🔥 Firebase Service: Simple query found ${simpleQuery.docs.length} documents',
      );

      if (simpleQuery.docs.isNotEmpty) {
        // If simple query works, try with orderBy
        try {
          print('🔥 Firebase Service: Trying query with orderBy...');
          final querySnapshot = await _firestore
              .collection(_collection)
              .where('userFirebaseUid', isEqualTo: userFirebaseUid)
              .orderBy('updatedAt', descending: true)
              .get();

          print(
            '🔥 Firebase Service: OrderBy query found ${querySnapshot.docs.length} documents',
          );

          // Log the raw data for debugging
          for (var doc in querySnapshot.docs) {
            print('🔥 Raw document data: ${doc.data()}');
          }

          final playlists = querySnapshot.docs
              .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
              .toList();

          print(
            '🔥 Firebase Service: Converted to ${playlists.length} playlist objects',
          );
          return playlists;
        } catch (orderByError) {
          print('❌ OrderBy failed, using simple query: $orderByError');
          // Fall back to simple query if orderBy fails
          final playlists = simpleQuery.docs
              .map((doc) => Playlist.fromFirestoreMap(doc.data(), doc.id))
              .toList();
          return playlists;
        }
      } else {
        print('🔥 Firebase Service: No documents found for user');
        return [];
      }
    } catch (e) {
      print('❌ Error getting user playlists: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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

  // Add track to playlist with enhanced stats
  Future<bool> addTrackToPlaylist(
    String playlistId,
    Track track,
    String addedBy,
  ) async {
    try {
      final doc = _firestore.collection(_collection).doc(playlistId);
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        // Get playlist
        final playlistSnapshot = await transaction.get(doc);
        if (!playlistSnapshot.exists) {
          throw Exception('Playlist not found');
        }

        // Get current playlist data
        final playlist = Playlist.fromFirestoreMap(
          playlistSnapshot.data()!,
          playlistSnapshot.id,
        );
        final trackIds = List<String>.from(playlist.trackIds);
        final trackCount = trackIds.length;

        // Use track's actual ID as document ID for easier lookup
        final trackDoc = _firestore.collection('tracks').doc(track.id);

        // Create track with metadata
        final trackWithMetadata = track.copyWith(
          addedAt: now,
          addedBy: addedBy,
          trackNumber: trackCount + 1,
        );

        // Save track data
        transaction.set(trackDoc, trackWithMetadata.toFirestore());

        // Add track reference to playlist and update stats
        if (!trackIds.contains(track.id)) {
          trackIds.add(track.id);

          // Update playlist stats
          final currentStats = playlist.stats;
          final updatedStats = currentStats.copyWith(
            totalTracks: currentStats.totalTracks + 1,
            totalDuration: currentStats.totalDuration + track.duration,
            lastUpdated: now,
          );

          // Update genre tags
          final updatedGenreTags = {...playlist.genreTags};
          updatedGenreTags.addAll(track.genres);

          // Update artist and genre counts
          updatedStats.updateArtistCount(track.artist, increment: true);
          updatedStats.updateGenreCounts(track.genres, increment: true);

          transaction.update(doc, {
            'trackIds': trackIds,
            'updatedAt': now.toIso8601String(),
            'trackCount': trackIds.length,
            'lastTrackAddedAt': now.toIso8601String(),
            'lastTrackAddedBy': addedBy,
            'stats': updatedStats.toFirestore(),
            'genreTags': updatedGenreTags.toList(),
          });
        }
      });

      return true;
    } catch (e) {
      print('Error adding track to playlist: $e');
      return false;
    }
  }

  // Remove track from playlist with stats update
  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      print('DEBUG: Removing track $trackId from playlist $playlistId');
      final playlistRef = _firestore.collection(_collection).doc(playlistId);
      final trackRef = _firestore.collection('tracks').doc(trackId);

      await _firestore.runTransaction((transaction) async {
        final playlistSnapshot = await transaction.get(playlistRef);
        if (!playlistSnapshot.exists) {
          throw Exception('Playlist not found');
        }

        final playlist = Playlist.fromFirestoreMap(
          playlistSnapshot.data()!,
          playlistSnapshot.id,
        );
        final trackIds = List<String>.from(playlist.trackIds);

        print('DEBUG: Current trackIds in playlist: $trackIds');
        print('DEBUG: Trying to remove trackId: $trackId');
        print(
          'DEBUG: trackIds contains trackId: ${trackIds.contains(trackId)}',
        );

        // Get track data for stats update
        final trackDoc = await transaction.get(trackRef);
        if (!trackDoc.exists) {
          print(
            'DEBUG: Track document not found, continuing with removal anyway',
          );
          // Continue with removal even if track doc doesn't exist
          if (trackIds.remove(trackId)) {
            final now = DateTime.now();
            transaction.update(playlistRef, {
              'trackIds': trackIds,
              'updatedAt': now.toIso8601String(),
              'trackCount': trackIds.length,
            });
            print('DEBUG: Track removed successfully (no stats update)');
          } else {
            print('DEBUG: Track not found in playlist trackIds');
            print('DEBUG: Looking for exact matches:');
            for (int i = 0; i < trackIds.length; i++) {
              print(
                '  trackIds[$i] = "${trackIds[i]}" (type: ${trackIds[i].runtimeType})',
              );
              print('  equals trackId? ${trackIds[i] == trackId}');
            }
          }
          return;
        }

        final track = Track.fromFirestore(trackDoc.data()!);

        if (trackIds.remove(trackId)) {
          final now = DateTime.now();
          final currentStats = playlist.stats;

          // Update playlist stats
          final updatedStats = currentStats.copyWith(
            totalTracks: currentStats.totalTracks - 1,
            totalDuration: currentStats.totalDuration - track.duration,
            lastUpdated: now,
          );

          // Update genre and artist counts
          updatedStats.updateGenreCounts(track.genres, increment: false);
          updatedStats.updateArtistCount(track.artist, increment: false);

          // Update playlist document
          transaction.update(playlistRef, {
            'trackIds': trackIds,
            'updatedAt': now.toIso8601String(),
            'trackCount': trackIds.length,
            'stats': updatedStats.toFirestore(),
          });

          print('DEBUG: Track removed successfully with stats update');
        } else {
          print('DEBUG: Track not found in playlist trackIds');
        }
      });

      return true;
    } catch (e) {
      print('Error removing track from playlist: $e');
      return false;
    }
  }

  // Get tracks from playlist
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null || playlist.trackIds.isEmpty) {
        return [];
      }

      final trackDocs = await Future.wait(
        playlist.trackIds.map(
          (id) => _firestore.collection('tracks').doc(id).get(),
        ),
      );

      return trackDocs
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => Track.fromFirestore(doc.data()!))
          .toList();
    } catch (e) {
      print('Error getting playlist tracks: $e');
      return [];
    }
  }

  // Get track stream for real-time updates
  Stream<List<Track>> getPlaylistTracksStream(String playlistId) {
    return _firestore
        .collection(_collection)
        .doc(playlistId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (!snapshot.exists || snapshot.data() == null) {
            return [];
          }

          final trackIds = List<String>.from(
            snapshot.data()!['trackIds'] ?? [],
          );
          if (trackIds.isEmpty) {
            return [];
          }

          final trackDocs = await Future.wait(
            trackIds.map((id) => _firestore.collection('tracks').doc(id).get()),
          );

          return trackDocs
              .where((doc) => doc.exists && doc.data() != null)
              .map((doc) => Track.fromFirestore(doc.data()!))
              .toList();
        });
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

          // Update track numbers
          final trackUpdates = <Future<void>>[];
          for (var i = 0; i < trackIds.length; i++) {
            final trackRef = _firestore.collection('tracks').doc(trackIds[i]);
            trackUpdates.add(trackRef.update({'trackNumber': i + 1}));
          }
          await Future.wait(trackUpdates);

          // Update playlist
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

  // Add multiple tracks to playlist
  Future<bool> addTracksToPlaylist(
    String playlistId,
    List<Track> tracks,
    String addedBy,
  ) async {
    try {
      final doc = _firestore.collection(_collection).doc(playlistId);
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        // Get playlist
        final playlistSnapshot = await transaction.get(doc);
        if (!playlistSnapshot.exists) {
          throw Exception('Playlist not found');
        }

        // Get current track list and count
        final data = playlistSnapshot.data()!;
        final trackIds = List<String>.from(data['trackIds'] ?? []);
        var trackCount = trackIds.length;

        // Add each track
        for (var track in tracks) {
          final trackDoc = _firestore.collection('tracks').doc(track.id);
          trackCount++;

          // Create track with metadata
          final trackWithMetadata = track.copyWith(
            addedAt: now,
            addedBy: addedBy,
            trackNumber: trackCount,
          );

          // Save track data
          transaction.set(trackDoc, trackWithMetadata.toFirestore());
          trackIds.add(track.id);
        }

        // Update playlist
        transaction.update(doc, {
          'trackIds': trackIds,
          'updatedAt': FieldValue.serverTimestamp(),
          'trackCount': trackIds.length,
          'lastTrackAddedAt': now.toIso8601String(),
        });
      });

      return true;
    } catch (e) {
      print('Error adding tracks to playlist: $e');
      return false;
    }
  }

  // Move track to position
  Future<bool> moveTrackToPosition(
    String playlistId,
    String trackId,
    int newPosition,
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
        final currentIndex = trackIds.indexOf(trackId);

        if (currentIndex != -1 &&
            newPosition >= 0 &&
            newPosition < trackIds.length) {
          trackIds.removeAt(currentIndex);
          trackIds.insert(newPosition, trackId);

          // Update track numbers
          final trackUpdates = <Future<void>>[];
          for (var i = 0; i < trackIds.length; i++) {
            final trackRef = _firestore.collection('tracks').doc(trackIds[i]);
            trackUpdates.add(trackRef.update({'trackNumber': i + 1}));
          }
          await Future.wait(trackUpdates);

          // Update playlist
          transaction.update(doc, {
            'trackIds': trackIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      print('Error moving track: $e');
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

  // Alternative method to remove track by finding it in the tracks list
  Future<bool> removeTrackFromPlaylistByIndex(
    String playlistId,
    int trackIndex,
  ) async {
    try {
      print(
        'DEBUG: Removing track at index $trackIndex from playlist $playlistId',
      );

      final playlistRef = _firestore.collection(_collection).doc(playlistId);

      await _firestore.runTransaction((transaction) async {
        final playlistSnapshot = await transaction.get(playlistRef);
        if (!playlistSnapshot.exists) {
          throw Exception('Playlist not found');
        }

        final playlist = Playlist.fromFirestoreMap(
          playlistSnapshot.data()!,
          playlistSnapshot.id,
        );
        final trackIds = List<String>.from(playlist.trackIds);

        if (trackIndex >= 0 && trackIndex < trackIds.length) {
          final removedTrackId = trackIds.removeAt(trackIndex);

          final now = DateTime.now();
          transaction.update(playlistRef, {
            'trackIds': trackIds,
            'updatedAt': now.toIso8601String(),
            'trackCount': trackIds.length,
          });

          print('DEBUG: Removed track $removedTrackId at index $trackIndex');
        } else {
          throw Exception('Invalid track index');
        }
      });

      return true;
    } catch (e) {
      print('Error removing track from playlist by index: $e');
      return false;
    }
  }

  // Sync playlist trackCount with actual available tracks
  Future<bool> syncPlaylistTrackCount(String playlistId) async {
    try {
      final playlistRef = _firestore.collection(_collection).doc(playlistId);
      final playlistSnapshot = await playlistRef.get();

      if (!playlistSnapshot.exists) {
        print('Playlist not found for sync');
        return false;
      }

      final playlist = Playlist.fromFirestoreMap(
        playlistSnapshot.data()!,
        playlistSnapshot.id,
      );

      // Get actual existing tracks
      final trackDocs = await Future.wait(
        playlist.trackIds.map(
          (id) => _firestore.collection('tracks').doc(id).get(),
        ),
      );

      final existingTrackIds = trackDocs
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => doc.id)
          .toList();

      final actualTrackCount = existingTrackIds.length;

      // Update playlist if trackCount is different
      if (playlist.trackCount != actualTrackCount) {
        print(
          'Syncing playlist $playlistId: ${playlist.trackCount} -> $actualTrackCount tracks',
        );

        await playlistRef.update({
          'trackIds': existingTrackIds,
          'trackCount': actualTrackCount,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      }

      return false; // No update needed
    } catch (e) {
      print('Error syncing playlist track count: $e');
      return false;
    }
  }
}
