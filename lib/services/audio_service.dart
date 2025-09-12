import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playUrl(String url) async {
    try {
      await player.setUrl(url);
      player.play();
    } catch (e) {
      print('audio play error: $e');
    }
  }

  void pause() => player.pause();
  void resume() => player.play();
  void stop() => player.stop();
  void dispose() => player.dispose();
}
