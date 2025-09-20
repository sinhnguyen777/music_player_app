import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/soundcloud_service.dart';

enum RepeatMode {
  off, // No repeat
  all, // Repeat queue
  one, // Repeat current track
}

class PlayerProvider with ChangeNotifier {
  final SoundCloudService _sc = SoundCloudService();
  final AudioService _audio = AudioService();
  List<Track> _queue = [];
  int _index = -1;
  RepeatMode _repeatMode = RepeatMode.off;

  PlayerProvider();

  Track? get current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  AudioPlayer get audioPlayer => _audio.player;
  Stream<PlayerState> get playerStateStream => _audio.player.playerStateStream;
  Stream<Duration> get positionStream => _audio.player.positionStream;
  Stream<Duration?> get durationStream => _audio.player.durationStream;
  RepeatMode get repeatMode => _repeatMode;

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

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
    print('DEBUG PlayerProvider: Track source: ${t.source}');
    print('DEBUG PlayerProvider: Track has raw data: ${t.raw != null}');

    String? streamUrl;

    // For SoundCloud tracks, always get fresh stream URL
    if (t.source == 'soundcloud' || t.raw != null) {
      print('DEBUG PlayerProvider: Getting stream URL from SoundCloud API');
      streamUrl = await _sc.getTrackStreamUrlFromTrack(t);
      print('DEBUG PlayerProvider: SoundCloud stream URL: $streamUrl');
    }

    // Fallback to direct URL if available
    if (streamUrl == null || streamUrl.isEmpty) {
      streamUrl = t.url;
      print('DEBUG PlayerProvider: Using direct URL: $streamUrl');
    }

    // Final fallback from raw data
    if (streamUrl == null || streamUrl.isEmpty) {
      streamUrl = t.raw?['stream_url'];
      print('DEBUG PlayerProvider: Using raw stream URL: $streamUrl');
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

    switch (_repeatMode) {
      case RepeatMode.one:
        // Repeat current track
        await _startCurrent();
        break;
      case RepeatMode.all:
        // Move to next track, loop back to start if at end
        _index = (_index + 1) % _queue.length;
        await _startCurrent();
        break;
      case RepeatMode.off:
        // Move to next track, stop if at end
        if (_index < _queue.length - 1) {
          _index++;
          await _startCurrent();
        } else {
          // Reached end of queue, stop playing
          _audio.stop();
        }
        break;
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    _index = (_index - 1);
    if (_index < 0) _index = 0;
    await _startCurrent();
  }

  List<Track> get queue => _queue;

  void stop() {
    _audio.stop();
    notifyListeners();
  }
}
