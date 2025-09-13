import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Register with email and password
  Future<UserModel?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    print('🔥📝 Starting Firebase Auth registration...');
    try {
      // Create user with Firebase Auth
      print('🔥📝 Creating user with email: $email');
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        print('🔥📝 ERROR: Firebase user is null after creation');
        throw Exception('Failed to create user');
      }

      print('🔥📝 Firebase user created successfully: ${firebaseUser.uid}');

      // Update display name
      await firebaseUser.updateDisplayName(username);
      print('🔥📝 Display name updated to: $username');

      // Create user document in Firestore
      final UserModel newUser = UserModel.fromFirebase(
        firebaseUid: firebaseUser.uid,
        name: username,
        email: email,
        createdAt: DateTime.now(),
      );

      print('🔥📝 Creating Firestore document...');
      final firestoreData = newUser.toFirestoreMap();
      print('🔥📝 Firestore data: $firestoreData');

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(firestoreData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore write timeout after 10 seconds');
            },
          );
      print('🔥📝 Firestore document created successfully');

      print('🔥📝 Registration completed successfully for: $email');
      return newUser;
    } on FirebaseAuthException catch (e) {
      print('🔥📝 Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('🔥📝 General exception: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Login with email and password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      // Get user data from Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromFirestoreMap(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromFirestoreMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('users')
          .doc(user.firebaseUid)
          .update(updatedUser.toFirestoreMap());

      // Update Firebase Auth display name if changed
      if (_auth.currentUser?.displayName != user.name) {
        await _auth.currentUser?.updateDisplayName(user.name);
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Reset password failed: ${e.toString()}');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Delete account failed: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu, vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập không được phép';
      default:
        return 'Lỗi xác thực: ${e.message ?? e.code}';
    }
  }
}
