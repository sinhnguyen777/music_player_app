import 'package:cloud_firestore/cloud_firestore.dart';

import 'playlist_stats.dart';

class Playlist {
  final String id; // Firebase document ID
  final String name;
  final String description;
  final String userFirebaseUid; // Firebase UID
  final List<String> trackIds; // Track document IDs
  final String? imageUrl; // Cover image
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic; // Public or private playlist
  final int trackCount; // Number of tracks
  final List<String> genreTags; // Genre tags for categorization
  final List<String> collaborators; // Firebase UIDs of collaborators
  final String? lastTrackAddedBy; // Firebase UID of last user to add track
  final DateTime? lastTrackAddedAt; // When the last track was added
  final PlaylistStats stats; // Additional statistics

  Playlist({
    required this.id,
    required this.name,
    required this.userFirebaseUid,
    this.description = '',
    this.trackIds = const [],
    this.imageUrl,
    this.genreTags = const [],
    this.collaborators = const [],
    this.lastTrackAddedBy,
    this.lastTrackAddedAt,
    PlaylistStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPublic = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       trackCount = trackIds.length,
       stats = stats ?? PlaylistStats(lastUpdated: DateTime.now());

  // Convert to Firebase Firestore map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'description': description,
      'userFirebaseUid': userFirebaseUid,
      'trackIds': trackIds,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublic': isPublic,
      'trackCount': trackCount,
      'genreTags': genreTags,
      'collaborators': collaborators,
      'lastTrackAddedBy': lastTrackAddedBy,
      'lastTrackAddedAt': lastTrackAddedAt?.toIso8601String(),
      'stats': stats.toFirestore(),
    };
  }

  // Create from Firebase Firestore map
  factory Playlist.fromFirestoreMap(Map<String, dynamic> map, String docId) {
    final trackIds = List<String>.from(map['trackIds'] ?? []);

    return Playlist(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userFirebaseUid: map['userFirebaseUid'] ?? '',
      trackIds: trackIds,
      imageUrl: map['imageUrl'],
      genreTags: List<String>.from(map['genreTags'] ?? []),
      collaborators: List<String>.from(map['collaborators'] ?? []),
      lastTrackAddedBy: map['lastTrackAddedBy'],
      lastTrackAddedAt: map['lastTrackAddedAt'] != null
          ? (map['lastTrackAddedAt'] is Timestamp
                ? (map['lastTrackAddedAt'] as Timestamp).toDate()
                : (map['lastTrackAddedAt'] is String
                      ? DateTime.parse(map['lastTrackAddedAt'])
                      : DateTime.now()))
          : null,
      stats: map['stats'] != null
          ? PlaylistStats.fromFirestore(map['stats'])
          : PlaylistStats(lastUpdated: DateTime.now()),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : (map['createdAt'] is String
                      ? DateTime.parse(map['createdAt'])
                      : DateTime.now()))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : (map['updatedAt'] is String
                      ? DateTime.parse(map['updatedAt'])
                      : DateTime.now()))
          : DateTime.now(),
      isPublic: map['isPublic'] ?? false,
    );
  }

  // Copy with method for updates
  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? userFirebaseUid,
    List<String>? trackIds,
    String? imageUrl,
    List<String>? genreTags,
    List<String>? collaborators,
    String? lastTrackAddedBy,
    DateTime? lastTrackAddedAt,
    PlaylistStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userFirebaseUid: userFirebaseUid ?? this.userFirebaseUid,
      trackIds: trackIds ?? this.trackIds,
      imageUrl: imageUrl ?? this.imageUrl,
      genreTags: genreTags ?? this.genreTags,
      collaborators: collaborators ?? this.collaborators,
      lastTrackAddedBy: lastTrackAddedBy ?? this.lastTrackAddedBy,
      lastTrackAddedAt: lastTrackAddedAt ?? this.lastTrackAddedAt,
      stats: stats ?? this.stats,
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
