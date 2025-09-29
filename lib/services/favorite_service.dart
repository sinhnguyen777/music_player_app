import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/track.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get user's favorites collection reference
  CollectionReference? get _favoritesCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('favorites');
  }

  // Add track to favorites
  Future<bool> addToFavorites(Track track) async {
    try {
      if (_favoritesCollection == null) {
        print('User not authenticated');
        return false;
      }

      await _favoritesCollection!.doc(track.id).set({
        ...track.toFirestore(),
        'favoritedAt': FieldValue.serverTimestamp(),
      });

      print('Track ${track.title} added to favorites');
      return true;
    } catch (e) {
      print('Error adding track to favorites: $e');
      return false;
    }
  }

  // Remove track from favorites
  Future<bool> removeFromFavorites(String trackId) async {
    try {
      if (_favoritesCollection == null) {
        print('User not authenticated');
        return false;
      }

      await _favoritesCollection!.doc(trackId).delete();
      print('Track $trackId removed from favorites');
      return true;
    } catch (e) {
      print('Error removing track from favorites: $e');
      return false;
    }
  }

  // Check if track is in favorites
  Future<bool> isFavorite(String trackId) async {
    try {
      if (_favoritesCollection == null) return false;

      final doc = await _favoritesCollection!.doc(trackId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if track is favorite: $e');
      return false;
    }
  }

  // Get all favorite tracks
  Future<List<Track>> getFavorites() async {
    try {
      if (_favoritesCollection == null) return [];

      final querySnapshot = await _favoritesCollection!
          .orderBy('favoritedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Track.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Get favorites stream for real-time updates
  Stream<List<Track>> getFavoritesStream() {
    if (_favoritesCollection == null) {
      return Stream.value([]);
    }

    return _favoritesCollection!
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Track.fromFirestore(data);
          }).toList();
        });
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Track track) async {
    try {
      final isCurrentlyFavorite = await isFavorite(track.id);

      if (isCurrentlyFavorite) {
        return await removeFromFavorites(track.id);
      } else {
        return await addToFavorites(track);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Get favorite count
  Future<int> getFavoriteCount() async {
    try {
      if (_favoritesCollection == null) return 0;

      final snapshot = await _favoritesCollection!.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorite count: $e');
      return 0;
    }
  }

  // Clear all favorites
  Future<bool> clearAllFavorites() async {
    try {
      if (_favoritesCollection == null) return false;

      final snapshot = await _favoritesCollection!.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All favorites cleared');
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }
}
