import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String? albumName;
  final String? albumArtist;
  final int duration; // Duration in seconds
  final List<String> genres;
  final String? url; // URL to the audio file
  final Map<String, dynamic>? raw; // original JSON
  final DateTime? addedAt;
  final String? addedBy; // Firebase UID of user who added the track
  final int? trackNumber; // Position in playlist
  final String? source; // e.g., 'soundcloud', 'spotify', etc.

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.albumName,
    this.albumArtist,
    this.duration = 0,
    List<String>? genres,
    this.url,
    this.raw,
    this.addedAt,
    this.addedBy,
    this.trackNumber,
    this.source,
  }) : genres = genres ?? [];

  // Create Track from SoundCloud data
  factory Track.fromSoundCloudJson(Map<String, dynamic> json) {
    final artwork = json['artwork_url'] ?? json['user']?['avatar_url'] ?? '';
    return Track(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      artist: json['user']?['username'] ?? '',
      artworkUrl: artwork.toString().replaceAll('-large', '-t500x500'),
      duration:
          (json['duration'] ?? 0) ~/ 1000, // Convert milliseconds to seconds
      genres: List<String>.from(
        json['genre']?.split(',').map((g) => g.trim()) ?? [],
      ),
      url: json['stream_url'],
      raw: json,
      source: 'soundcloud',
    );
  }

  // Convert Track to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'albumName': albumName,
      'albumArtist': albumArtist,
      'duration': duration,
      'genres': genres,
      'url': url,
      'raw': raw,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
      'addedBy': addedBy,
      'trackNumber': trackNumber,
      'source': source,
    };
  }

  // Create Track from Firestore document
  factory Track.fromFirestore(Map<String, dynamic> doc) {
    DateTime? parsedAddedAt;
    if (doc['addedAt'] != null) {
      // Handle both Timestamp and String formats
      if (doc['addedAt'] is String) {
        parsedAddedAt = DateTime.parse(doc['addedAt']);
      } else if (doc['addedAt'] is Timestamp) {
        parsedAddedAt = (doc['addedAt'] as Timestamp).toDate();
      }
    }

    return Track(
      id: doc['id'] as String,
      title: doc['title'] as String,
      artist: doc['artist'] as String,
      artworkUrl: doc['artworkUrl'] as String,
      albumName: doc['albumName'] as String?,
      albumArtist: doc['albumArtist'] as String?,
      duration: doc['duration'] as int? ?? 0,
      genres: List<String>.from(doc['genres'] ?? []),
      url: doc['url'] as String?,
      raw: doc['raw'] as Map<String, dynamic>?,
      addedAt: parsedAddedAt,
      addedBy: doc['addedBy'] as String?,
      trackNumber: doc['trackNumber'] as int?,
      source: doc['source'] as String?,
    );
  }

  // Copy with method for updates
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? artworkUrl,
    String? albumName,
    String? albumArtist,
    int? duration,
    List<String>? genres,
    String? url,
    Map<String, dynamic>? raw,
    DateTime? addedAt,
    String? addedBy,
    int? trackNumber,
    String? source,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      albumName: albumName ?? this.albumName,
      albumArtist: albumArtist ?? this.albumArtist,
      duration: duration ?? this.duration,
      genres: genres ?? this.genres,
      url: url ?? this.url,
      raw: raw ?? this.raw,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      trackNumber: trackNumber ?? this.trackNumber,
      source: source ?? this.source,
    );
  }
}
