import 'package:cloud_firestore/cloud_firestore.dart';

class ListeningHistory {
  final String id; // Document ID
  final String userFirebaseUid; // User ID
  final String trackId; // Track ID
  final String trackTitle;
  final String trackArtist;
  final String trackArtworkUrl;
  final int trackDuration;
  final DateTime listenedAt; // Thời gian nghe
  final int playDuration; // Thời gian nghe thực tế (giây)
  final double playPercentage; // Phần trăm bài hát đã nghe (0.0 - 1.0)
  final String source; // Source của track (soundcloud, spotify, etc.)
  final Map<String, dynamic>? metadata; // Thông tin bổ sung

  ListeningHistory({
    required this.id,
    required this.userFirebaseUid,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    required this.trackArtworkUrl,
    required this.trackDuration,
    required this.listenedAt,
    required this.playDuration,
    required this.playPercentage,
    required this.source,
    this.metadata,
  });

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userFirebaseUid': userFirebaseUid,
      'trackId': trackId,
      'trackTitle': trackTitle,
      'trackArtist': trackArtist,
      'trackArtworkUrl': trackArtworkUrl,
      'trackDuration': trackDuration,
      'listenedAt': Timestamp.fromDate(listenedAt),
      'playDuration': playDuration,
      'playPercentage': playPercentage,
      'source': source,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory ListeningHistory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ListeningHistory(
      id: doc.id,
      userFirebaseUid: data['userFirebaseUid'] ?? '',
      trackId: data['trackId'] ?? '',
      trackTitle: data['trackTitle'] ?? '',
      trackArtist: data['trackArtist'] ?? '',
      trackArtworkUrl: data['trackArtworkUrl'] ?? '',
      trackDuration: data['trackDuration'] ?? 0,
      listenedAt: (data['listenedAt'] as Timestamp).toDate(),
      playDuration: data['playDuration'] ?? 0,
      playPercentage: (data['playPercentage'] ?? 0.0).toDouble(),
      source: data['source'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Create from Firestore map
  factory ListeningHistory.fromFirestoreMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ListeningHistory(
      id: docId,
      userFirebaseUid: data['userFirebaseUid'] ?? '',
      trackId: data['trackId'] ?? '',
      trackTitle: data['trackTitle'] ?? '',
      trackArtist: data['trackArtist'] ?? '',
      trackArtworkUrl: data['trackArtworkUrl'] ?? '',
      trackDuration: data['trackDuration'] ?? 0,
      listenedAt: data['listenedAt'] is Timestamp
          ? (data['listenedAt'] as Timestamp).toDate()
          : DateTime.parse(data['listenedAt']),
      playDuration: data['playDuration'] ?? 0,
      playPercentage: (data['playPercentage'] ?? 0.0).toDouble(),
      source: data['source'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Copy with method
  ListeningHistory copyWith({
    String? id,
    String? userFirebaseUid,
    String? trackId,
    String? trackTitle,
    String? trackArtist,
    String? trackArtworkUrl,
    int? trackDuration,
    DateTime? listenedAt,
    int? playDuration,
    double? playPercentage,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return ListeningHistory(
      id: id ?? this.id,
      userFirebaseUid: userFirebaseUid ?? this.userFirebaseUid,
      trackId: trackId ?? this.trackId,
      trackTitle: trackTitle ?? this.trackTitle,
      trackArtist: trackArtist ?? this.trackArtist,
      trackArtworkUrl: trackArtworkUrl ?? this.trackArtworkUrl,
      trackDuration: trackDuration ?? this.trackDuration,
      listenedAt: listenedAt ?? this.listenedAt,
      playDuration: playDuration ?? this.playDuration,
      playPercentage: playPercentage ?? this.playPercentage,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ListeningHistory(trackTitle: $trackTitle, artist: $trackArtist, '
        'listenedAt: $listenedAt, playPercentage: ${(playPercentage * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListeningHistory &&
        other.id == id &&
        other.trackId == trackId &&
        other.userFirebaseUid == userFirebaseUid;
  }

  @override
  int get hashCode => Object.hash(id, trackId, userFirebaseUid);
}
