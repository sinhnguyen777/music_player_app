class UserModel {
  final String name;
  final String email;
  final String? avatarUrl;
  final String firebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.firebaseUid,
    this.createdAt,
    this.updatedAt,
  });

  // Firebase Firestore map
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
      avatarUrl: map['avatarUrl'],
      firebaseUid: map['firebaseUid'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // Factory for Firebase User
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
      avatarUrl: avatarUrl,
      firebaseUid: firebaseUid,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? firebaseUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
