class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash; // hashed password
  final String? avatarUrl;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
  });

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
}
