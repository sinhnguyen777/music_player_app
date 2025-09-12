import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/soundcloud_service.dart';
import '../services/audio_service.dart';

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
    if (queue != null) {
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
    if (t == null) return;
    final streamUrl =
        await _sc.getTrackStreamUrlFromTrack(t) ?? t.raw?['stream_url'] ?? null;
    if (streamUrl == null) {
      debugPrint('No stream URL for track ${t.title}');
      return;
    }
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
