import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';

class SoundCloudService {
  static const String _clientId = 'dUSSYkKvVfgl8MqbBbjwn7UbpM7QVNks';
  static const String _base = 'https://api-v2.soundcloud.com';

  Future<List<Track>> searchTracks(String q, {int limit = 20}) async {
    final url = Uri.parse(
      '$_base/search/tracks?q=${Uri.encodeComponent(q)}&limit=$limit&client_id=$_clientId',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final js = jsonDecode(res.body);
      final coll = (js['collection'] as List).cast<dynamic>();
      return coll
          .map((e) => Track.fromSoundCloudJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('SoundCloud search failed ${res.statusCode}');
  }

  // charts (hot/trending)
  Future<List<Track>> getCharts({String kind = 'top', int limit = 10}) async {
    final url = Uri.parse(
      '$_base/charts?kind=$kind&genre=soundcloud:genres:all-music&limit=$limit&client_id=$_clientId',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final js = jsonDecode(res.body);
      final coll = (js['collection'] as List).cast<dynamic>();
      final tracks = <Track>[];
      for (var item in coll) {
        final trackJson = item['track'] as Map<String, dynamic>?;
        if (trackJson != null) tracks.add(Track.fromSoundCloudJson(trackJson));
      }
      return tracks;
    }
    throw Exception('Charts failed ${res.statusCode}');
  }

  // Resolve streaming URL from transcodings
  Future<String?> resolveStreamUrlFromTrackJson(
    Map<String, dynamic> trackJson,
  ) async {
    try {
      final transcodings = trackJson['media']?['transcodings'] as List?;
      if (transcodings == null || transcodings.isEmpty) return null;
      Map<String, dynamic>? chosen;
      for (var t in transcodings) {
        final format = t['format'] as Map<String, dynamic>?;
        if (format != null && format['protocol'] == 'progressive') {
          chosen = Map<String, dynamic>.from(t);
          break;
        }
      }
      chosen ??= Map<String, dynamic>.from(transcodings.first);
      final href = chosen['url'];
      final res = await http.get(Uri.parse('$href?client_id=$_clientId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'];
      }
    } catch (e) {
      print('resolveStreamUrl error: $e');
    }
    return null;
  }

  Future<String?> getTrackStreamUrlFromTrack(Track t) async {
    final raw = t.raw;
    if (raw == null) return null;
    return resolveStreamUrlFromTrackJson(raw);
  }
}
