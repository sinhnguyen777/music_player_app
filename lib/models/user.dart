class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash; // hashed password
  final String? avatarUrl;

  // Firebase-specific properties
  final String? firebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
    this.firebaseUid,
    this.createdAt,
    this.updatedAt,
  });

  // SQLite map (existing)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': passwordHash,
      'avatar': avatarUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: m['id'] as int?,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      passwordHash: m['password'] ?? '',
      avatarUrl: m['avatar'],
    );
  }

  // Firebase Firestore map (new)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'firebaseUid': firebaseUid,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromFirestoreMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      passwordHash: '', // Not stored in Firestore for security
      avatarUrl: map['avatarUrl'],
      firebaseUid: map['firebaseUid'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // Factory for Firebase User (without password)
  factory UserModel.fromFirebase({
    required String firebaseUid,
    required String name,
    required String email,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      name: name,
      email: email,
      passwordHash: '', // Firebase handles auth, no local password needed
      avatarUrl: avatarUrl,
      firebaseUid: firebaseUid,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? avatarUrl,
    String? firebaseUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
