// Layout regression guard for iPhone sizes. Any RenderFlex overflow or other
// layout exception during these pumps fails the test, so every tab is
// rendered at the smallest supported phone, a Dynamic Island phone and the
// largest Pro Max, with default and enlarged text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _longName = RifleProfile(
  id: 'p1',
  name:
      'Çok uzun bir profil adı — sahada kullanılan 6.35 mm Hercules Bully kurulumu',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

class _Device {
  final String name;
  final Size logical;
  final EdgeInsets safeArea;
  const _Device(this.name, this.logical, this.safeArea);
}

const _devices = [
  _Device('iPhone SE', Size(320, 568), EdgeInsets.only(top: 20)),
  _Device(
    'iPhone 15 (Dynamic Island)',
    Size(393, 852),
    EdgeInsets.only(top: 59, bottom: 34),
  ),
  _Device(
    'iPhone 15 Pro Max',
    Size(430, 932),
    EdgeInsets.only(top: 59, bottom: 34),
  ),
];

void main() {
  for (final device in _devices) {
    for (final textScale in const [1.0, 1.3]) {
      testWidgets(
        '${device.name} @ text ${textScale}x renders every tab without overflow',
        (tester) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = device.logical * 3;
          tester.view.padding = FakeViewPadding(
            top: device.safeArea.top * 3,
            bottom: device.safeArea.bottom * 3,
          );
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final store = MemoryProfileStore();
          await store.save(_longName);
          await tester.pumpWidget(
            MaterialApp(
              theme: MenzilTheme.light(),
              home: HomeScreen(
                profileStore: store,
                activeProfileStore: MemoryActiveProfileStore(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // The app opens on Profil.
          expect(tester.takeException(), isNull, reason: 'Profil at start');

          // Atış (solved on its own when it opens).
          await tester.tap(find.text('Atış'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          for (final tab in const [
            'Hava Durumu',
            'Pro',
            'Profil',
            'Araçlar',
            'Atış',
          ]) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }

          // Table after a solve (horizontal scroll, not squeezed columns);
          // Tablo is the second mode of the Atış tab.
          await tester.tap(find.text('Tablo'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('DOPE oluştur'));
          await tester.tap(find.text('DOPE oluştur'));
          await tester.pumpAndSettle();
          expect(find.byType(DataTable), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Profile editor (two columns or one, depending on width).
          await tester.tap(find.text('Profil'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Yeni profil'));
          await tester.tap(find.text('Yeni profil'));
          await tester.pumpAndSettle();
          expect(find.text('Profil Oluştur'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('dark theme renders the shell', (tester) async {
    final store = MemoryProfileStore();
    await store.save(_longName);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        darkTheme: MenzilTheme.dark(),
        themeMode: ThemeMode.dark,
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atış'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
