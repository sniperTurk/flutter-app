import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The turret click sound (owner, 2026-10-15 23:30: "Dürbün kulelerini
/// çevirme klik sesi ekleyelim"; 23:31: "Kuleyi kuleden çevirirken de klik
/// sesi gelsin").
///
/// The turret drums ask for one [click] per click step the user makes, by
/// an arrow tap or by dragging the drum. Programmatic moves ("Kuleleri
/// kur", "Kuleleri sıfırla", auto-set, profile change) never call it.
///
/// [instance] is the app-wide sound. It is silent until `main()` installs
/// [AudioTurretClickSound], so widget tests never touch real audio; tests
/// that count clicks install a fake.
abstract class TurretClickSound {
  static TurretClickSound instance = const SilentTurretClickSound();

  /// Loads the sound so the first click plays without delay. Idempotent.
  void preload();

  /// One click step.
  void click();
}

/// No sound (the default outside the app, e.g. in widget tests).
class SilentTurretClickSound implements TurretClickSound {
  const SilentTurretClickSound();

  @override
  void preload() {}

  @override
  void click() {}
}

/// The real sound: a small pool of preloaded players, round robin, so rapid
/// clicks never wait for a previous one to finish.
///
/// * Audio session (iOS AVAudioSession): category ambient. It follows the
///   silent/ring switch and mixes with the user's music, never stopping it.
/// * Volume: moderate (the file peaks at -6 dBFS, played at [volume]).
/// * Clicks closer than [minGap] (25 ms) to the previous one are dropped,
///   not queued: a fast drag stays in time with the drum instead of
///   trailing behind it.
/// * Any audio failure is swallowed; the turret keeps working silently.
class AudioTurretClickSound implements TurretClickSound {
  AudioTurretClickSound({this.poolSize = 4, this.volume = 0.5});

  static const String asset = 'sounds/turret_click.wav';
  static const Duration minGap = Duration(milliseconds: 25);

  final int poolSize;
  final double volume;

  final List<AudioPlayer> _players = [];
  final Stopwatch _sinceLast = Stopwatch();
  Future<void>? _loading;
  int _next = 0;

  static final AudioContext _ambient = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      // Ambient already mixes with other audio; the mixWithOthers option
      // is only accepted with playback / playAndRecord categories.
      options: const {},
    ),
  );

  @override
  void preload() => _loading ??= _load();

  Future<void> _load() async {
    try {
      await AudioPlayer.global.setAudioContext(_ambient);
      for (var i = 0; i < poolSize; i++) {
        final p = AudioPlayer(playerId: 'turret_click_$i');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(volume);
        await p.setSource(AssetSource(asset));
        _players.add(p);
      }
    } catch (e) {
      debugPrint('Turret click sound unavailable: $e');
    }
  }

  @override
  void click() {
    preload();
    if (_sinceLast.isRunning && _sinceLast.elapsed < minGap) return;
    _sinceLast
      ..reset()
      ..start();
    if (_players.isEmpty) return; // still loading: drop, never queue
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    _restart(p);
  }

  Future<void> _restart(AudioPlayer p) async {
    try {
      await p.seek(Duration.zero);
      await p.resume();
    } catch (e) {
      debugPrint('Turret click sound failed: $e');
    }
  }
}
