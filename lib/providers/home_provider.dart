import 'package:flutter/material.dart';
import '../services/soundcloud_service.dart';
import '../models/track.dart';

class HomeProvider with ChangeNotifier {
  final SoundCloudService _sc = SoundCloudService();

  List<Track> hot = [];
  List<Track> trending = [];
  List<Track> latest = [];
  List<Track> recommended = [];

  Future<void> init() async {
    await fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      hot = await _sc.getCharts(kind: 'top', limit: 10);
    } catch (_) {
      hot = [];
    }
    try {
      trending = await _sc.getCharts(kind: 'trending', limit: 10);
    } catch (_) {
      trending = [];
    }
    try {
      latest = await _sc.searchTracks('latest', limit: 10);
    } catch (_) {
      latest = [];
    }
    recommended = trending; // simple heuristic
    notifyListeners();
  }
}
