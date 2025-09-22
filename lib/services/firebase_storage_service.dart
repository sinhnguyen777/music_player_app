import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Explicit storage bucket from environment
  static final String _storageBucket =
      'music-player-app-85a31.firebasestorage.app';

  /// Test Firebase Storage connection
  static Future<void> testStorageConnection() async {
    try {
      print('Testing Firebase Storage connection...');
      print('Storage bucket: ${_storage.bucket}');
      print('Expected bucket: $_storageBucket');

      // Try to list files in root (this will fail if no access but show different error)
      try {
        final listResult = await _storage.ref().listAll();
        print(
          'Storage access test successful. Found ${listResult.items.length} items',
        );
      } catch (e) {
        print('Storage list test result: $e');
      }
    } catch (e) {
      print('Storage connection test failed: $e');
    }
  }

  /// Upload avatar image to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      // Test storage connection first
      await testStorageConnection();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User have not logged in');
      }

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('File does not exist');
      }

      // Check file size (limit to 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size is too large (max 5MB)');
      }

      print('Starting upload avatar for user: ${user.uid}');
      print('File size: ${fileSize / 1024 / 1024} MB');

      // Create unique filename with user ID and timestamp
      final fileName =
          'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('File path: avatars/$fileName');

      // Try different ways to create storage reference
      Reference ref;
      try {
        // Method 1: Use explicit bucket
        final storageWithBucket = FirebaseStorage.instanceFor(
          bucket: _storageBucket,
        );
        ref = storageWithBucket.ref('avatars/$fileName');
        print('Storage reference (with explicit bucket) created successfully');
      } catch (e) {
        print('Method 1 failed: $e');
        try {
          // Method 2: Direct path
          ref = _storage.ref('avatars/$fileName');
          print('Storage reference (method 2) created successfully');
        } catch (e2) {
          print('Method 2 failed: $e2');
          // Method 3: Child path
          ref = _storage.ref().child('avatars').child(fileName);
          print('Storage reference (method 3) created successfully');
        }
      }

      print('Starting upload task...');

      // Upload file with metadata
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('Upload complete: ${snapshot.state}');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Avatar upload successful: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');

      if (e.code == 'storage/object-not-found') {
        throw Exception(
          'Firebase Storage bucket not found. Please check your Firebase configuration.',
        );
      } else if (e.code == 'storage/unauthorized') {
        throw Exception(
          'No access to Firebase Storage. Please check your security rules.',
        );
      } else if (e.code == 'storage/canceled') {
        throw Exception('Upload canceled. Please try again.');
      } else if (e.code == 'storage/unknown') {
        throw Exception('Unknown error from Firebase Storage.');
      } else {
        throw Exception('Firebase Storage error: ${e.message ?? e.code}');
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      throw Exception('Error uploading avatar: $e');
    }
  }

  /// Delete old avatar from Firebase Storage
  /// Takes the full download URL and extracts the file path to delete
  static Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract file path from the URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after '/o/' and before '?'
      final filePathIndex = pathSegments.indexOf('o');
      if (filePathIndex != -1 && filePathIndex + 1 < pathSegments.length) {
        String filePath = pathSegments[filePathIndex + 1];
        // URL decode the path
        filePath = Uri.decodeComponent(filePath);

        final ref = _storage.ref().child(filePath);

        // Check if file exists before trying to delete
        try {
          await ref.getMetadata();
          await ref.delete();
          print('Avatar deleted successfully: $filePath');
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            // File doesn't exist, which is fine - already "deleted"
            print('Avatar file not found (already deleted): $filePath');
          } else {
            // Re-throw other Firebase exceptions
            rethrow;
          }
        }
      }
    } catch (e) {
      // Only log the error, don't rethrow for deletion operations
      print('Error deleting avatar: $e');
      // Don't rethrow - avatar deletion failing shouldn't prevent profile updates
    }
  }

  /// Upload avatar with progress tracking
  /// Returns a stream of upload progress and final download URL
  static Stream<TaskSnapshot> uploadAvatarWithProgress(File imageFile) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final fileName =
        'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('avatars/$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    return uploadTask.snapshotEvents;
  }

  /// Get storage reference for user's avatars
  static Reference getUserAvatarsRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _storage.ref().child('avatars');
  }

  /// Check if file exists in storage
  static Future<bool> fileExists(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final filePath = uri.pathSegments.last.split('?').first;
      final ref = _storage.ref().child('avatars/$filePath');

      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}
