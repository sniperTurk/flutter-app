// Hava Durumu: the top card title "Hava" is deleted (owner, 2026-10-16
// 21:10: "Hava Durumu sayfası 'Hava' ifadesini sil, zaten yukarıda Hava
// Durumu yazıyor"). The top bar still says "Hava Durumu" and the first card
// (Sıcaklık, Bağıl nem, fetch buttons) sits directly under it, MenzilPage's
// top padding (MenzilSpace.md, 10 pt) below the bar, like Pro Ayarlar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<void> _openHavaDurumu(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(MenzilBottomNavigation),
      matching: find.text('Hava Durumu'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(390, 844), Size(320, 568)]) {
    testWidgets('Hava Durumu at ${size.width.toInt()} pt: no "Hava" title, '
        'top bar "Hava Durumu", first card directly under it', (tester) async {
      await _openHavaDurumu(tester, size);

      // The page with an active profile, not the no-profile variant.
      expect(find.byKey(const Key('environment-no-profile')), findsNothing);

      // The top bar still names the page.
      expect(
        tester.widget<Text>(find.byKey(const Key('top-bar-title'))).data,
        'Hava Durumu',
      );

      // The "Hava" section title is gone; nothing on the page reads "Hava".
      expect(find.byKey(const Key('environment-weather-header')), findsNothing);
      expect(find.text('Hava'), findsNothing);
      // The other section titles stay.
      for (final title in const ['Basınç Ölçer', 'İrtifa', 'Rüzgâr']) {
        expect(find.text(title), findsWidgets, reason: title);
      }

      // The first card (Sıcaklık, Bağıl nem) is the page's first child:
      // MenzilSpace.md (10 pt) under the top bar, nothing in between.
      final temperature = find.byKey(BallisticsFieldKeys.temperature);
      final card = find
          .ancestor(of: temperature, matching: find.byType(MenzilCard))
          .first;
      final bar = tester.getRect(find.byType(MenzilTopBar));
      final cardRect = tester.getRect(card);
      expect(cardRect.top - bar.bottom, closeTo(MenzilSpace.md, 0.5));
      // Visible without scrolling: its Sıcaklık and Bağıl nem boxes are on
      // screen above the bottom navigation.
      final nav = tester.getRect(find.byType(MenzilBottomNavigation));
      expect(tester.getRect(temperature).bottom, lessThan(nav.top));
      expect(
        tester.getRect(find.byKey(BallisticsFieldKeys.humidity)).bottom,
        lessThan(nav.top),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
