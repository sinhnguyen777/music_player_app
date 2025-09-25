import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MusicAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Listen to player state changes and notify the system
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: queue.value.isNotEmpty ? 0 : null,
        ),
      );
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Listen to queue changes
    queue.add([]);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    // Implement skip to next logic
    print('Skip to next requested');
  }

  @override
  Future<void> skipToPrevious() async {
    // Implement skip to previous logic
    print('Skip to previous requested');
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    // Update the current media item
    this.mediaItem.add(mediaItem);

    // Load and play the audio
    try {
      // mediaItem.id contains the stream URL
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem),
      );
      await _player.play();
    } catch (e) {
      print('Error playing media item: $e');
    }
  }

  Future<void> playFromUrl(String streamUrl, MediaItem mediaItem) async {
    // Update the current media item
    this.mediaItem.add(mediaItem);

    // Load and play the audio
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(streamUrl), tag: mediaItem),
      );
      await _player.play();
    } catch (e) {
      print('Error playing from URL: $e');
    }
  }

  AudioPlayer get player => _player;

  Future<void> dispose() async {
    await _player.dispose();
  }
}
