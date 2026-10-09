// Real screenshots of the Pro Ayarlar page for the owner's review. Runs only
// in the ci-diagnostics workflow (which creates ci-logs/ and commits it);
// everywhere else it is skipped.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _profile = RifleProfile(
  id: 'p-shot',
  name: 'Hercules',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var any = false;
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      any = true;
    }
  }
  if (any) await loader.load();
}

void main() {
  final out = Directory('ci-logs/screens');
  final enabled = Directory('ci-logs').existsSync();

  testWidgets('Pro Ayarlar screenshots', (tester) async {
    if (!enabled) return;
    out.createSync(recursive: true);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      const sys = '/System/Library/Fonts/Supplemental';
      const fonts = ['$sys/Arial.ttf', '$sys/Arial Bold.ttf'];
      for (final family in [
        'Roboto',
        '.SF UI Text',
        '.SF UI Display',
        'Barlow Condensed',
        'Roboto Condensed',
        'Arial Narrow',
      ]) {
        await _loadFont(family, fonts);
      }
      final root = Platform.environment['FLUTTER_ROOT'] ?? '';
      await _loadFont('MaterialIcons', [
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });

    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_profile);
    const boundary = Key('shot-boundary');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MenzilTheme.light(),
          home: HomeScreen(
            profileStore: store,
            activeProfileStore: MemoryActiveProfileStore()..value = 'p-shot',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await captureImage(
          find.byKey(boundary).evaluate().single,
        );
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await shot('1-pro-kapali');
    for (final (id, name) in [
      ('angle', '2-aci'),
      ('wind', '3-ruzgar'),
      ('coriolis', '4-coriolis'),
      ('target', '5-hedef'),
      ('rifle', '6-tufek'),
    ]) {
      final header = find.byKey(Key('pro-section-$id'));
      await tester.ensureVisible(header);
      await tester.pumpAndSettle();
      await tester.tap(header);
      await tester.pumpAndSettle();
      // Scroll the opened box to the top of the page.
      await tester.ensureVisible(header);
      await shot(name);
    }
  });
}
