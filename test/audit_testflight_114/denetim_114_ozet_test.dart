// Denetim TestFlight 114: D114-0 (main does not compile after #389 + #395)
// and D114-2 (Profiller listesi shows the Tüfek box velocity, the
// calculation uses the PCP mean). This file imports the Profil library, so
// it cannot load until D114-0 is fixed; the source guard below says why.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test(
    'D114-0: every Profil helper the Kalibre box calls still exists',
    () {
      final rifle = File(
        'lib/features/profiles/profile_editor_rifle.dart',
      ).readAsStringSync();
      final lib = [
        for (final f in Directory('lib/features/profiles').listSync())
          if (f is File && f.path.endsWith('.dart')) f.readAsStringSync(),
      ].join('\n');
      if (rifle.contains('_shortCartridge(')) {
        expect(lib, contains('static String _shortCartridge('));
      }
    },
    skip:
        'D114-0 (YÜKSEK): #389 _shortCartridge ve short: kullanıyor, #395 '
        'bunları sildi; main derlenmiyor.',
  );

  test(
    'D114-2: Profiller listesi shows the velocity the calculation uses',
    () {
      // 250 / 260 m/s pair, Tüfek 300 m/s: Hedef uses 255 m/s = 837 fps;
      // the list line shows the Tüfek box, 984 fps.
      const p = RifleProfile(
        id: 'd114',
        name: 'D114',
        rifleId: 'd114-yok-rifle',
        ammunitionId: 'd114-yok-ammo',
        scopeId: 'd114-yok-scope',
        muzzleVelocityMps: 300,
        zeroRangeM: 30,
        sightHeightMm: 50,
        pcpMinVelocityMps: 250,
        pcpMaxVelocityMps: 260,
      );
      expect(profileListSummary(p), contains('837 fps'));
    },
    skip:
        'D114-2 (ORTA): Profil özeti / Profiller listesi / Kronograf '
        'Tüfek kartındaki hızı gösteriyor, hesap ortalamayı kullanıyor.',
  );
}
