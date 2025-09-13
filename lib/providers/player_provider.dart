import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/soundcloud_service.dart';

class PlayerProvider with ChangeNotifier {
  final SoundCloudService _sc = SoundCloudService();
  final AudioService _audio = AudioService();
  List<Track> _queue = [];
  int _index = -1;

  PlayerProvider();

  Track? get current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  AudioPlayer get audioPlayer => _audio.player;
  Stream<PlayerState> get playerStateStream => _audio.player.playerStateStream;
  Stream<Duration> get positionStream => _audio.player.positionStream;
  Stream<Duration?> get durationStream => _audio.player.durationStream;

  Future<void> init() async {
    await _audio.init();
    _audio.player.playerStateStream.listen((state) => notifyListeners());
    _audio.player.processingStateStream.listen((proc) {
      if (proc == ProcessingState.completed) {
        next();
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    print('DEBUG PlayerProvider: playTrack called for "${track.title}"');
    print('DEBUG PlayerProvider: Track URL: ${track.url}');

    if (queue != null) {
      print('DEBUG PlayerProvider: Setting queue with ${queue.length} tracks');
      _queue = queue;
      _index = _queue.indexWhere((t) => t.id == track.id);
      if (_index == -1) _index = 0;
    } else {
      if (_queue.isEmpty) _queue = [track];
      _index = _queue.indexWhere((t) => t.id == track.id);
      if (_index == -1) {
        _queue.add(track);
        _index = _queue.length - 1;
      }
    }
    await _startCurrent();
  }

  Future<void> _startCurrent() async {
    final t = current;
    if (t == null) {
      print('DEBUG PlayerProvider: No current track');
      return;
    }

    print('DEBUG PlayerProvider: Starting track "${t.title}"');

    // Priority: use track.url if available, otherwise try SoundCloud service
    String? streamUrl = t.url;

    if (streamUrl == null || streamUrl.isEmpty) {
      print('DEBUG PlayerProvider: No direct URL, trying SoundCloud service');
      streamUrl =
          await _sc.getTrackStreamUrlFromTrack(t) ?? t.raw?['stream_url'];
    }

    if (streamUrl == null || streamUrl.isEmpty) {
      print('DEBUG PlayerProvider: No stream URL found for track ${t.title}');
      return;
    }

    print('DEBUG PlayerProvider: Playing URL: $streamUrl');
    await _audio.playUrl(streamUrl);
    notifyListeners();
  }

  void togglePlayPause() {
    if (_audio.player.playing)
      _audio.pause();
    else
      _audio.resume();
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    _index = (_index + 1) % _queue.length;
    await _startCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    _index = (_index - 1);
    if (_index < 0) _index = 0;
    await _startCurrent();
  }

  List<Track> get queue => _queue;
}
