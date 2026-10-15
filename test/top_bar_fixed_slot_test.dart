// Üst çubuk (owner, 2026-10-13): "Sayfalar arası geçiş yaparken ortadaki
// kutu (profil kutusu) büyüyüp küçülüyor, bu olmasın" and "Sniper Türk
// yazısını biraz büyüt". The title slot has a fixed width on every tab, so
// the profile box keeps the same left edge and width; the brand is 20 pt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

// The order of the owner's video, then back to Profil.
const _tabs = ['Hava Durumu', 'Pro', 'Hedef', 'Araçlar', 'Profil'];

const _profileSlot = Key('top-bar-profile-slot');
const _titleSlot = Key('top-bar-title-slot');

Future<void> _pumpHome(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width, 800) * 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
}

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

/// Visits every tab and returns the profile box rect on each (Profil first).
Future<Map<String, Rect>> _profileRects(WidgetTester tester) async {
  final rects = <String, Rect>{
    'Profil (başlangıç)': tester.getRect(find.byKey(_profileSlot)),
  };
  expect(tester.takeException(), isNull, reason: 'Profil');
  for (final tab in _tabs) {
    await tester.tap(_tab(tab));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: tab);
    rects[tab] = tester.getRect(find.byKey(_profileSlot));
    // Titles stay left-aligned at the gutter, inside the fixed slot.
    final slot = tester.getRect(find.byKey(_titleSlot));
    expect(slot.left, MenzilSpace.gutter, reason: tab);
    final shown = find.byKey(
      Key(tab == 'Profil' ? 'top-bar-brand' : 'top-bar-title'),
    );
    final text = tester.getRect(shown);
    expect(text.left, moreOrLessEquals(slot.left), reason: tab);
    expect(text.right, lessThanOrEqualTo(slot.right + 0.01), reason: tab);
  }
  return rects;
}

void _expectSame(Map<String, Rect> rects) {
  final first = rects.values.first;
  rects.forEach((tab, r) {
    expect(r.left, first.left, reason: '$tab: profil kutusu sol kenarı');
    expect(r.width, first.width, reason: '$tab: profil kutusu genişliği');
  });
}

void main() {
  for (final (name, width) in const [
    ('normal telefon 390', 390.0),
    ('iPhone SE / mini 375', 375.0),
    ('dar telefon 320', 320.0),
  ]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('$name @ yazı ${scale}x: profil kutusu her sekmede aynı', (
        tester,
      ) async {
        await _pumpHome(tester, width: width, textScale: scale);
        final rects = await _profileRects(tester);
        _expectSame(rects);
        // The box keeps usable width (the test font is wider than Inter, so
        // these are lower bounds) and the right-side gap stays equal to the
        // left gutter: the profile button ends at the gutter (the theme
        // button was deleted, owner 2026-10-15).
        expect(rects.values.first.width, greaterThan(width >= 375 ? 60 : 40));
        expect(find.byTooltip('Tema'), findsNothing);
        final button = tester.getRect(
          find.byKey(const Key('top-bar-profile-button')),
        );
        expect(width - button.right, moreOrLessEquals(MenzilSpace.gutter));
      });
    }
  }

  testWidgets('Sniper Türk markası 20 punto, sayfa başlıkları 18', (
    tester,
  ) async {
    await _pumpHome(tester, width: 390);
    final brand = tester.widget<Text>(find.byKey(const Key('top-bar-brand')));
    expect(brand.data, 'Sniper Türk');
    expect(brand.style?.fontSize, 20);
    expect(MenzilBrand.fontSize, 20);

    await tester.tap(_tab('Hava Durumu'));
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.byKey(const Key('top-bar-title')));
    expect(title.style?.fontSize, MenzilTopBar.titleSize);
    expect(MenzilTopBar.titleSize, 18);
  });

  test('slot genişliği en geniş başlıktan, üst sınırla', () {
    const titles = ['Hava Durumu', 'Pro Ayarlar', 'Atış Çözümü', 'Araçlar'];
    final titleStyle = MenzilType.heading(
      Colors.black,
      size: MenzilTopBar.titleSize,
    );
    final brandStyle = MenzilBrand.style(Colors.black);
    double measure(String s, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    final widest = [
      for (final t in titles) measure(t, titleStyle),
      measure('Sniper Türk', brandStyle),
    ].reduce((a, b) => a > b ? a : b);

    final wide = MenzilTopBar.titleSlotWidth(
      barWidth: 2000,
      titles: titles,
      includeBrand: true,
      titleStyle: titleStyle,
      brandStyle: brandStyle,
      textScaler: TextScaler.noScaling,
    );
    expect(wide, widest.ceilToDouble());
    // The short "Araçlar" alone would be narrower; the slot does not follow
    // the current title.
    final shortOnly = MenzilTopBar.titleSlotWidth(
      barWidth: 2000,
      titles: const ['Araçlar'],
      includeBrand: false,
      titleStyle: titleStyle,
      brandStyle: brandStyle,
      textScaler: TextScaler.noScaling,
    );
    expect(shortOnly, lessThan(wide));
    // Capped at 42 % of the bar.
    final capped = MenzilTopBar.titleSlotWidth(
      barWidth: 100,
      titles: titles,
      includeBrand: true,
      titleStyle: titleStyle,
      brandStyle: brandStyle,
      textScaler: const TextScaler.linear(1.25),
    );
    expect(capped, 100 * MenzilTopBar.titleSlotMaxFraction);
  });
}
