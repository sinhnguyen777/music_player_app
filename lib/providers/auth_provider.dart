import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/db_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final DBService _db = DBService();
  UserModel? _user;
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    // possible future: load saved session
  }

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

  Future<bool> register(String name, String email, String password) async {
    final exist = await _db.getUserByEmail(email);
    if (exist != null) return false;
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
  }

  Future<bool> login(String email, String password) async {
    final u = await _db.getUserByEmail(email);
    if (u == null) return false;
    final salt = _saltFromEmail(email);
    final hash = _hash(password, salt);
    if (hash == u.passwordHash) {
      _user = u;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
