import 'package:audioplayers/audioplayers.dart';

class AmbienceService {
  AmbienceService._();

  static final AmbienceService instance = AmbienceService._();
  static const double _volumeBoost = 3.0;

  final AudioPlayer _player = AudioPlayer();
  String _current = 'none';

  static const Map<String, List<String>> _assets = {
    'rain': [
      'audio/ambience/rain.mp3',
      'audio/ambience/rain.wav',
    ],
    'forest': [
      'audio/ambience/forest.mp3',
      'audio/ambience/forest.wav',
    ],
    'ocean': [
      'audio/ambience/ocean.mp3',
      'audio/ambience/ocean.wav',
    ],
    'cafe': [
      'audio/ambience/cafe.mp3',
      'audio/ambience/cafe.wav',
    ],
    'urban': [
      'audio/ambience/urban.mp3',
      'audio/ambience/urban.wav',
    ],
    'soft-beats': [
      'audio/ambience/soft-beats.mp3',
      'audio/ambience/soft-beats.wav',
    ],
    'wind': [
      'audio/ambience/wind.mp3',
      'audio/ambience/wind.wav',
    ],
    'horror': [
      'audio/ambience/horror.mp3',
      'audio/ambience/horror.wav',
    ],
  };

  Future<void> play(String type, double volume) async {
    if (type == _current) {
      await _player.setVolume(volume);
      return;
    }
    if (!_assets.containsKey(type)) {
      await stop();
      return;
    }
    _current = type;
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume((volume * _volumeBoost).clamp(0.0, 4.0));
    final sources = _assets[type]!;
    for (final source in sources) {
      try {
        await _player.play(AssetSource(source));
        return;
      } catch (_) {
        // Try next format if asset is missing.
      }
    }
  }

  Future<void> stop() async {
    _current = 'none';
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
