import 'dart:async';

// import 'package:audio_service/audio_service.dart';  // Commented out temporarily
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/track.dart';
import '../services/listening_history_service.dart';
import '../services/soundcloud_service.dart';

enum RepeatMode {
  off, // No repeat
  all, // Repeat queue
  one, // Repeat current track
}

class PlayerProvider extends ChangeNotifier {
  final SoundCloudService _soundCloudService = SoundCloudService();
  final ListeningHistoryService _listeningHistoryService =
      ListeningHistoryService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Track> _queue = [];
  int _index = -1;
  RepeatMode _repeatMode = RepeatMode.off;

  // Tracking for listening history
  Track? _trackingTrack;
  DateTime? _trackStartTime;
  Duration _lastPosition = Duration.zero;
  Timer? _listeningTimer;
  bool _historyAlreadySaved = false;
  DateTime? _lastHistorySaveTime;
  String? _currentSessionId;

  PlayerProvider() {
    // Clean up any existing timers on restart
    _resetTracking();
    print('🔄 PlayerProvider initialized - tracking reset');
  }

  Track? get current {
    final track = (_index >= 0 && _index < _queue.length)
        ? _queue[_index]
        : null;
    // print('🎵 Current track getter: index $_index, track: ${track?.title}');
    return track;
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
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
    // Setup audio session for background playback
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      print('Failed to configure audio session: $e');
    }

    _audioPlayer.playerStateStream.listen((state) {
      _handlePlayerStateChange(state);
      notifyListeners();
    });
    _audioPlayer.processingStateStream.listen((proc) {
      if (proc == ProcessingState.completed) {
        // IMPORTANT: Save completion history BEFORE calling next()
        // because next() will call _onTrackStopped() and reset tracking
        _onTrackCompleted();

        // Small delay to ensure history is saved before switching tracks
        Future.delayed(Duration(milliseconds: 100), () {
          next(fromCompletion: true);
        });
      }
    });

    // Listen to position changes for tracking
    _audioPlayer.positionStream.listen((position) {
      _lastPosition = position;
      // DEBUG: Log position every 10 seconds for tracking
      if (position.inSeconds % 10 == 0 &&
          position.inMilliseconds % 1000 < 100) {
        print(
          '🔊 Position: ${position.inSeconds}s - Tracking: ${_trackingTrack?.title ?? "None"}',
        );
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    print('🎵 DEBUG PlayerProvider: playTrack called for "${track.title}"');
    print('🎵 DEBUG PlayerProvider: Track URL: ${track.url}');

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

    print('🎵 About to call _startCurrent()');
    await _startCurrent();
  }

  Future<void> _startCurrent() async {
    print('🎵 _startCurrent() called');
    final t = current;
    if (t == null) {
      print('❌ DEBUG PlayerProvider: No current track');
      return;
    }

    print('DEBUG PlayerProvider: Starting track "${t.title}"');
    print('DEBUG PlayerProvider: Track source: ${t.source}');
    print('DEBUG PlayerProvider: Track has raw data: ${t.raw != null}');

    String? streamUrl;

    // For SoundCloud tracks, always get fresh stream URL
    if (t.source == 'soundcloud' || t.raw != null) {
      print('DEBUG PlayerProvider: Getting stream URL from SoundCloud API');
      streamUrl = await _soundCloudService.getTrackStreamUrlFromTrack(t);
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

    try {
      print('🎵 DEBUG PlayerProvider: Bắt đầu phát track "${t.title}"');

      // Try background playback with MediaItem first
      try {
        final mediaItem = _createMediaItem(t);
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(streamUrl), tag: mediaItem),
        );
        print('✅ Track được phát với background notification');
      } catch (backgroundError) {
        print('❌ Lỗi background playback: $backgroundError');
        print('🔄 Chuyển sang chế độ đơn giản...');

        // Fall back to simple mode
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(streamUrl)),
        );
        print('✅ Track được phát ở chế độ đơn giản');
      }

      // Start playback
      await _audioPlayer.play();
    } catch (e) {
      print('❌ Lỗi phát nhạc hoàn toàn: $e');
      return;
    }

    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
    notifyListeners();
  }

  Future<void> next({bool fromCompletion = false}) async {
    if (_queue.isEmpty) return;

    print(
      '🎵 Next track called. Current index: $_index. Queue length: ${_queue.length}',
    );

    // Only save history if NOT called from completion (completion already saved)
    if (!fromCompletion) {
      _onTrackStopped();
    } else {
      // Just reset tracking without saving (already saved in _onTrackCompleted)
      _resetTracking();
    }

    switch (_repeatMode) {
      case RepeatMode.one:
        // Repeat current track
        print('🔄 Repeat mode: one - repeating current track');
        await _startCurrent();
        break;
      case RepeatMode.all:
        // Move to next track, loop back to start if at end
        _index = (_index + 1) % _queue.length;
        print('🔄 Repeat mode: all - moved to index $_index');
        notifyListeners(); // Notify before starting to update UI immediately
        await _startCurrent();
        break;
      case RepeatMode.off:
        // Move to next track, stop if at end
        if (_index < _queue.length - 1) {
          _index++;
          print('⏭️ Moved to next track at index $_index');
          notifyListeners(); // Notify before starting to update UI immediately
          await _startCurrent();
        } else {
          // Reached end of queue, stop playing
          print('⏹️ Reached end of queue, stopping');
          await _audioPlayer.stop();
          notifyListeners(); // Notify UI that playback stopped
        }
        break;
    }

    // Always notify listeners after index change
    notifyListeners();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    print('🎵 Previous track called. Current index: $_index');

    // Save current track's listening history before switching
    _onTrackStopped();

    _index = (_index - 1);
    if (_index < 0) _index = 0;

    print('⏮️ Moved to previous track at index $_index');
    notifyListeners(); // Notify before starting to update UI immediately
    await _startCurrent();

    // Always notify listeners after index change
    notifyListeners();
  }

  List<Track> get queue => _queue;

  Future<void> stop() async {
    _onTrackStopped();
    await _audioPlayer.stop();
    notifyListeners();
  }

  // === LISTENING HISTORY TRACKING ===

  void _handlePlayerStateChange(PlayerState state) {
    print(
      '🎮 Player state changed: playing=${state.playing}, current=${current?.title}',
    );

    if (state.playing && _trackingTrack != current) {
      // New track started playing
      print('🎵 Starting new track tracking');
      _onTrackStarted();
    } else if (state.playing &&
        _trackingTrack == current &&
        _listeningTimer == null) {
      // Track resumed, restart timer
      print('▶️ Restarting tracking timer');
      _startListeningTimer();
    } else if (!state.playing && _trackingTrack != null) {
      // Track paused or stopped
      print('⏸️ Track paused/stopped');
      _onTrackPaused();
    }
  }

  void _onTrackStarted() {
    final track = current;
    if (track == null) return;

    // Generate unique session ID to prevent duplicates
    _currentSessionId = '${track.id}_${DateTime.now().millisecondsSinceEpoch}';

    print('🎵 Bắt đầu theo dõi: ${track.title} (Session: $_currentSessionId)');
    _trackingTrack = track;
    _trackStartTime = DateTime.now();
    _lastPosition = Duration.zero;
    _historyAlreadySaved = false;

    // Start timer to check listening progress every 5 seconds
    _startListeningTimer();
  }

  void _startListeningTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkAndSaveListeningProgress();
    });
  }

  void _checkAndSaveListeningProgress() {
    if (_trackingTrack == null ||
        _trackStartTime == null ||
        _historyAlreadySaved) {
      return;
    }

    final track = _trackingTrack!;
    final listenDuration = _lastPosition.inSeconds;
    final trackDuration = track.duration > 0
        ? track.duration
        : _lastPosition.inSeconds;
    final percentage = trackDuration > 0
        ? (listenDuration / trackDuration).clamp(0.0, 1.0)
        : 0.0;

    print('🔍 Kiểm tra tiến độ: ${track.title}');
    print('   - Nghe được: ${listenDuration}s/${trackDuration}s');
    print('   - Phần trăm: ${(percentage * 100).toStringAsFixed(1)}%');

    // Save history if listened for at least 30 seconds OR 30% of track
    if ((listenDuration >= 30 || percentage >= 0.3) && !_historyAlreadySaved) {
      // Debounce: Check if we recently saved history for this track
      final now = DateTime.now();
      if (_lastHistorySaveTime != null &&
          now.difference(_lastHistorySaveTime!).inSeconds < 10) {
        print('⏭️ Skipping history save - too recent (debounce)');
        return;
      }

      print('✅ Đủ điều kiện lưu lịch sử!');
      _historyAlreadySaved = true;
      _lastHistorySaveTime = now;

      _listeningHistoryService.addListeningHistory(
        track,
        playDuration: listenDuration,
        playPercentage: percentage,
        metadata: {
          'completed': false,
          'sessionStartTime': _trackStartTime!.toIso8601String(),
          'playerState': 'threshold_reached',
          'sessionId': _currentSessionId,
          // Save track info needed for replay
          'trackUrl': track.url,
          'trackRaw': track.raw,
        },
      );
    }
  }

  void _onTrackPaused() {
    if (_trackingTrack == null || _trackStartTime == null) return;

    // Stop listening timer when paused
    _listeningTimer?.cancel();

    // Final check when paused (if not already saved)
    if (!_historyAlreadySaved) {
      _checkAndSaveListeningProgress();
    }
  }

  void _onTrackStopped() {
    if (_trackingTrack == null || _trackStartTime == null) return;

    // Stop listening timer
    _listeningTimer?.cancel();

    // Final check when stopped (if not already saved)
    if (!_historyAlreadySaved) {
      _checkAndSaveListeningProgress();
    }

    _resetTracking();
  }

  void _onTrackCompleted() {
    if (_trackingTrack == null || _trackStartTime == null) return;

    print('✅ Track completed: ${_trackingTrack!.title}');

    // Stop listening timer
    _listeningTimer?.cancel();

    final track = _trackingTrack!;
    final listenDuration = _lastPosition.inSeconds;

    if (!_historyAlreadySaved) {
      // Save completion if not saved yet
      print('💾 Saving completion history (first time)...');
      _listeningHistoryService.addListeningHistory(
        track,
        playDuration: listenDuration,
        playPercentage: 1.0, // 100% completed
        metadata: {
          'completed': true,
          'sessionStartTime': _trackStartTime!.toIso8601String(),
          'playerState': 'completed',
          'sessionId': _currentSessionId,
          'trackUrl': track.url,
          'trackRaw': track.raw,
        },
      );
      print('✅ Completion history saved for: ${track.title}');
    } else {
      print('ℹ️  History already saved for: ${track.title} - Skip duplicate');
    }

    _resetTracking();
  }

  void _resetTracking() {
    _listeningTimer?.cancel();
    _trackingTrack = null;
    _trackStartTime = null;
    _lastPosition = Duration.zero;
    _historyAlreadySaved = false;
    _lastHistorySaveTime = null;
    _currentSessionId = null;
    print('🔄 Tracking reset completed');
  }

  /// Create MediaItem for background playback
  /// Create MediaItem for background playback
  MediaItem _createMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.artist, // Use artist as album for now
      artUri: track.artworkUrl.isNotEmpty
          ? Uri.tryParse(track.artworkUrl)
          : null,
      duration: track.duration > 0
          ? Duration(milliseconds: track.duration)
          : null,
      extras: {
        'source': track.source,
        'trackId': track.id,
        'trackUrl': track.url,
      },
    );
  }

  /// Reset player state (call when user logs out)
  Future<void> reset() async {
    try {
      // Stop current playback
      await _audioPlayer.stop();

      // Clear queue and reset index
      _queue.clear();
      _index = -1;

      // Reset repeat mode
      _repeatMode = RepeatMode.off;

      // Reset tracking
      _resetTracking();

      print('🔄 Player reset successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error resetting player: $e');
      // Still notify listeners to update UI
      notifyListeners();
    }
  }

  /// Dispose method for cleanup
  @override
  @override
  void dispose() {
    _listeningTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
