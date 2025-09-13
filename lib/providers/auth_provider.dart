import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/db_service.dart';
import '../services/firebase_auth_service.dart';

enum AuthMode { sqlite, firebase }

class AuthProvider with ChangeNotifier {
  final DBService _db = DBService();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  UserModel? _user;
  AuthMode _authMode = AuthMode.firebase; // Default to Firebase
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  AuthMode get authMode => _authMode;
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
            _authMode = AuthMode.firebase;
            notifyListeners();
          }
        }
      } catch (e) {
        print('Failed to restore Firebase session: $e');
      }
    }
  }

  void setAuthMode(AuthMode mode) {
    _authMode = mode;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // SQLite authentication methods (legacy)
  String _hash(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  String _saltFromEmail(String email) {
    return email
        .split('')
        .reversed
        .join(); // demo salt; production: use random salt + bcrypt
  }

  Future<bool> _registerSQLite(
    String name,
    String email,
    String password,
  ) async {
    try {
      final exist = await _db.getUserByEmail(email);
      if (exist != null) {
        _errorMessage = 'Email đã được sử dụng';
        notifyListeners();
        return false;
      }

      final salt = _saltFromEmail(email);
      final hash = _hash(password, salt);
      final u = UserModel(
        name: name,
        email: email,
        passwordHash: hash,
        avatarUrl: null,
      );
      await _db.createUser(u);
      return true;
    } catch (e) {
      _errorMessage = 'Đăng ký thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _loginSQLite(String email, String password) async {
    try {
      final u = await _db.getUserByEmail(email);
      if (u == null) {
        _errorMessage = 'Không tìm thấy tài khoản';
        notifyListeners();
        return false;
      }

      final salt = _saltFromEmail(email);
      final hash = _hash(password, salt);
      if (hash == u.passwordHash) {
        _user = u;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Mật khẩu không đúng';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Đăng nhập thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Firebase authentication methods (new)
  Future<bool> _registerFirebase(
    String name,
    String email,
    String password,
  ) async {
    print('🔥 Starting Firebase registration for: $email');
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

  Future<bool> _loginFirebase(String email, String password) async {
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

  // Public methods that delegate to appropriate auth mode
  Future<bool> register(String name, String email, String password) async {
    clearError();

    switch (_authMode) {
      case AuthMode.sqlite:
        return await _registerSQLite(name, email, password);
      case AuthMode.firebase:
        return await _registerFirebase(name, email, password);
    }
  }

  Future<bool> login(String email, String password) async {
    clearError();

    switch (_authMode) {
      case AuthMode.sqlite:
        return await _loginSQLite(email, password);
      case AuthMode.firebase:
        return await _loginFirebase(email, password);
    }
  }

  Future<void> logout() async {
    clearError();

    try {
      if (_authMode == AuthMode.firebase && _firebaseAuth.isLoggedIn) {
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
    if (_authMode != AuthMode.firebase) {
      _errorMessage = 'Chức năng này chỉ khả dụng với Firebase';
      notifyListeners();
      return false;
    }

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
    if (_authMode != AuthMode.firebase) {
      _errorMessage = 'Chức năng này chỉ khả dụng với Firebase';
      notifyListeners();
      return false;
    }

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
    if (_authMode != AuthMode.firebase) {
      _errorMessage = 'Chức năng này chỉ khả dụng với Firebase';
      notifyListeners();
      return false;
    }

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
