import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

enum PlaybackState { stopped, playing, paused, loading, error }

enum RepeatMode { off, one, all }

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializePlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Track> _playlist = [];
  int _currentIndex = 0;
  PlaybackState _state = PlaybackState.stopped;
  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffleIndices = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  List<Track> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Track? get currentTrack =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  PlaybackState get state => _state;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isPaused => _state == PlaybackState.paused;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  bool get hasNext {
    if (_isShuffled) {
      return _shuffleIndices.isNotEmpty &&
          _shuffleIndices.indexOf(_currentIndex) < _shuffleIndices.length - 1;
    }
    return _currentIndex < _playlist.length - 1;
  }

  bool get hasPrevious {
    if (_isShuffled) {
      return _shuffleIndices.isNotEmpty &&
          _shuffleIndices.indexOf(_currentIndex) > 0;
    }
    return _currentIndex > 0;
  }

  void _initializePlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _state = PlaybackState.stopped;
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _state = PlaybackState.loading;
          break;
        case ProcessingState.ready:
          _state = state.playing ? PlaybackState.playing : PlaybackState.paused;
          break;
        case ProcessingState.completed:
          _onTrackCompleted();
          break;
      }
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> setPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    _playlist = tracks;
    _currentIndex = startIndex.clamp(0, tracks.length - 1);
    _generateShuffleIndices();
    await _loadCurrentTrack();
    notifyListeners();
  }

  Future<void> playTrack(Track track) async {
    final index = _playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _currentIndex = index;
      await _loadCurrentTrack();
      await play();
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await _loadCurrentTrack();
      await play();
    }
  }

  Future<void> _loadCurrentTrack() async {
    if (_playlist.isEmpty || currentTrack == null) return;

    try {
      final track = currentTrack!;

      // For demo purposes, we'll use a placeholder URL
      // In a real app, you would use track.url
      final audioUrl =
          track.url ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      await _audioPlayer.setUrl(audioUrl);
    } catch (e) {
      print('Error loading track: $e');
      _state = PlaybackState.error;
      notifyListeners();
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing track: $e');
      _state = PlaybackState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> next() async {
    if (!hasNext) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = _isShuffled ? _shuffleIndices.first : 0;
      } else {
        return;
      }
    } else {
      if (_isShuffled) {
        final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
        _currentIndex = _shuffleIndices[currentShuffleIndex + 1];
      } else {
        _currentIndex++;
      }
    }

    await _loadCurrentTrack();
    if (_state == PlaybackState.playing) {
      await play();
    }
    notifyListeners();
  }

  Future<void> previous() async {
    if (!hasPrevious) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = _isShuffled
            ? _shuffleIndices.last
            : _playlist.length - 1;
      } else {
        return;
      }
    } else {
      if (_isShuffled) {
        final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
        _currentIndex = _shuffleIndices[currentShuffleIndex - 1];
      } else {
        _currentIndex--;
      }
    }

    await _loadCurrentTrack();
    if (_state == PlaybackState.playing) {
      await play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    _generateShuffleIndices();
    notifyListeners();
  }

  void toggleRepeat() {
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

  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(_playlist.length, (index) => index);
    if (_isShuffled) {
      _shuffleIndices.shuffle();
      // Ensure current track stays at current position
      if (_playlist.isNotEmpty) {
        _shuffleIndices.remove(_currentIndex);
        _shuffleIndices.insert(0, _currentIndex);
      }
    }
  }

  void _onTrackCompleted() {
    switch (_repeatMode) {
      case RepeatMode.one:
        play(); // Replay current track
        break;
      case RepeatMode.off:
      case RepeatMode.all:
        if (hasNext || _repeatMode == RepeatMode.all) {
          next();
        } else {
          _state = PlaybackState.stopped;
          notifyListeners();
        }
        break;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
