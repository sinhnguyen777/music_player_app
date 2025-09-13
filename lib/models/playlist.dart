class Playlist {
  final dynamic id; // Can be int (SQLite) or String (Firebase)
  final String name;
  final String description;
  final int? userId; // User ID from SQLite users table (legacy)
  final String? userFirebaseUid; // Firebase UID (new)
  final List<String> trackIds; // Track IDs from SoundCloud
  final String? imageUrl; // Cover image
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic; // Public hoặc private playlist
  final int trackCount; // Số lượng tracks

  Playlist({
    this.id,
    required this.name,
    this.description = '',
    this.userId,
    this.userFirebaseUid,
    this.trackIds = const [],
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPublic = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       trackCount = trackIds.length;

  // Convert to Firebase Firestore map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'description': description,
      'userFirebaseUid': userFirebaseUid,
      'trackIds': trackIds,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublic': isPublic,
    };
  }

  // Create from Firebase Firestore map
  factory Playlist.fromFirestoreMap(Map<String, dynamic> map, String docId) {
    return Playlist(
      id: docId, // Use Firestore document ID
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userFirebaseUid: map['userFirebaseUid'],
      trackIds: List<String>.from(map['trackIds'] ?? []),
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
      isPublic: map['isPublic'] ?? false,
    );
  }

  // Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'trackIds': trackIds.join(','), // Convert list to comma-separated string
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublic': isPublic ? 1 : 0, // SQLite boolean as int
      'trackCount': trackIds.length,
    };
  }

  // Create from SQLite map
  factory Playlist.fromMap(Map<String, dynamic> map) {
    final trackIdsString = map['trackIds'] as String? ?? '';
    final trackIdsList = trackIdsString.isEmpty
        ? <String>[]
        : trackIdsString.split(',').where((id) => id.isNotEmpty).toList();

    return Playlist(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? 0,
      trackIds: trackIdsList,
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isPublic: (map['isPublic'] ?? 0) == 1,
    );
  }

  // Copy with method for updates
  Playlist copyWith({
    dynamic id,
    String? name,
    String? description,
    int? userId,
    String? userFirebaseUid,
    List<String>? trackIds,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userFirebaseUid: userFirebaseUid ?? this.userFirebaseUid,
      trackIds: trackIds ?? this.trackIds,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // Add track to playlist
  Playlist addTrack(String trackId) {
    if (trackIds.contains(trackId)) {
      return this; // Track already exists
    }
    final newTrackIds = List<String>.from(trackIds)..add(trackId);
    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  // Remove track from playlist
  Playlist removeTrack(String trackId) {
    final newTrackIds = List<String>.from(trackIds)..remove(trackId);
    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  // Reorder tracks
  Playlist reorderTracks(int oldIndex, int newIndex) {
    final newTrackIds = List<String>.from(trackIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final track = newTrackIds.removeAt(oldIndex);
    newTrackIds.insert(newIndex, track);

    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  // Check if playlist contains track
  bool containsTrack(String trackId) {
    return trackIds.contains(trackId);
  }

  // Get playlist duration (placeholder - would need track durations)
  Duration get totalDuration {
    // TODO: Calculate from actual track durations
    return Duration(minutes: trackIds.length * 3); // Rough estimate
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, tracks: ${trackIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Playlist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
