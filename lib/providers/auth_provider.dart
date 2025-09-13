import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  UserModel? _user;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    // Check if user is already logged in with Firebase
    if (_firebaseAuth.isLoggedIn) {
      try {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          final userProfile = await _firebaseAuth.getUserProfile(
            firebaseUser.uid,
          );
          if (userProfile != null) {
            _user = userProfile;
            notifyListeners();
          }
        }
      } catch (e) {
        print('Failed to restore Firebase session: $e');
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Firebase authentication methods
  Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    print('🔥 Starting Firebase registration for: $email');
    clearError();
    
    try {
      final user = await _firebaseAuth.register(
        email: email,
        password: password,
        username: name,
      );

      print(
        '🔥 Firebase register result: ${user != null ? 'SUCCESS' : 'NULL'}',
      );

      if (user != null) {
        _user = user;
        print('🔥 User set successfully: ${user.name}');
        notifyListeners();
        return true;
      }

      print('🔥 User is null after registration');
      _errorMessage = 'Không thể tạo tài khoản';
      notifyListeners();
      return false;
    } catch (e) {
      print('🔥 Firebase register error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    clearError();
    
    try {
      final user = await _firebaseAuth.login(email: email, password: password);

      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    clearError();

    try {
      if (_firebaseAuth.isLoggedIn) {
        await _firebaseAuth.logout();
      }

      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại: ${e.toString()}';
      notifyListeners();
    }
  }

  // Firebase-specific methods
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      await _firebaseAuth.updateUserProfile(updatedUser);
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _firebaseAuth.deleteAccount();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
