class Track {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final Map<String, dynamic>? raw; // original JSON

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.raw,
  });

  factory Track.fromSoundCloudJson(Map<String, dynamic> json) {
    final artwork = json['artwork_url'] ?? json['user']?['avatar_url'] ?? '';
    return Track(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      artist: json['user']?['username'] ?? '',
      artworkUrl: artwork.toString().replaceAll('-large', '-t500x500'),
      raw: json,
    );
  }
}
