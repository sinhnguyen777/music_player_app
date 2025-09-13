class PlaylistStats {
  final int totalTracks;
  final int totalDuration;
  final DateTime lastUpdated;
  final int totalPlays;
  final Map<String, int> genreCounts;
  final Map<String, int> artistCounts;

  PlaylistStats({
    this.totalTracks = 0,
    this.totalDuration = 0,
    required this.lastUpdated,
    this.totalPlays = 0,
    Map<String, int>? genreCounts,
    Map<String, int>? artistCounts,
  }) : genreCounts = genreCounts ?? {},
       artistCounts = artistCounts ?? {};

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'totalTracks': totalTracks,
      'totalDuration': totalDuration,
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalPlays': totalPlays,
      'genreCounts': genreCounts,
      'artistCounts': artistCounts,
    };
  }

  // Create from Firestore map
  factory PlaylistStats.fromFirestore(Map<String, dynamic> map) {
    return PlaylistStats(
      totalTracks: map['totalTracks'] as int? ?? 0,
      totalDuration: map['totalDuration'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
      totalPlays: map['totalPlays'] as int? ?? 0,
      genreCounts: Map<String, int>.from(map['genreCounts'] ?? {}),
      artistCounts: Map<String, int>.from(map['artistCounts'] ?? {}),
    );
  }

  // Create copy with updated values
  PlaylistStats copyWith({
    int? totalTracks,
    int? totalDuration,
    DateTime? lastUpdated,
    int? totalPlays,
    Map<String, int>? genreCounts,
    Map<String, int>? artistCounts,
  }) {
    return PlaylistStats(
      totalTracks: totalTracks ?? this.totalTracks,
      totalDuration: totalDuration ?? this.totalDuration,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalPlays: totalPlays ?? this.totalPlays,
      genreCounts: genreCounts ?? Map<String, int>.from(this.genreCounts),
      artistCounts: artistCounts ?? Map<String, int>.from(this.artistCounts),
    );
  }

  // Update genre counts
  void updateGenreCounts(List<String> genres, {bool increment = true}) {
    for (final genre in genres) {
      if (increment) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      } else {
        genreCounts[genre] = (genreCounts[genre] ?? 1) - 1;
        if (genreCounts[genre] == 0) {
          genreCounts.remove(genre);
        }
      }
    }
  }

  // Update artist counts
  void updateArtistCount(String artist, {bool increment = true}) {
    if (increment) {
      artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
    } else {
      artistCounts[artist] = (artistCounts[artist] ?? 1) - 1;
      if (artistCounts[artist] == 0) {
        artistCounts.remove(artist);
      }
    }
  }

  // Get most popular genres
  List<MapEntry<String, int>> getMostPopularGenres({int limit = 5}) {
    final sorted = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // Get most popular artists
  List<MapEntry<String, int>> getMostPopularArtists({int limit = 5}) {
    final sorted = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // Format total duration as string (e.g., "2h 30m")
  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
