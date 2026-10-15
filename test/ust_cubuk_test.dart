// Üst çubuk (owner, 2026-10-15): "tasarımı koyu renk yapalım… giriş yap
// ekranına koyu tema açık tema ekleriz, yukarısı böyle daha güzel
// görünüyor" and "kullanılmayacak kodlar silinecek". Every tab shows the page
// title left and one active-profile button right (name bold + caliber grey +
// ⌄). The "Koyu/Açık" theme button is deleted; the app is always dark and an
// old saved "Açık" choice is neither read nor deleted.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

RifleProfile _profile(String id, String name) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _button = Key('top-bar-profile-button');
const _tabs = ['Profil', 'Hava Durumu', 'Pro', 'Hedef', 'Araçlar'];

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

Finder _inButton(Finder matching) =>
    find.descendant(of: find.byKey(_button), matching: matching);

Future<void> _pumpHome(
  WidgetTester tester, {
  List<RifleProfile> profiles = const [],
  String? activeId,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width, 800) * 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = activeId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('üst çubukta tema düğmesi yok (hiçbir sekmede)', (tester) async {
    await _pumpHome(tester, profiles: [_profile('p1', 'Bir')], activeId: 'p1');
    for (final tab in _tabs) {
      await tester.tap(_tab(tab));
      await tester.pumpAndSettle();
      final bar = find.byType(MenzilTopBar);
      expect(find.byTooltip('Tema'), findsNothing, reason: tab);
      for (final label in const ['Koyu', 'Açık']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsNothing,
          reason: '$tab: $label',
        );
      }
      expect(find.byKey(_button), findsOneWidget, reason: tab);
    }
  });

  testWidgets('profil düğmesi ad + kalibre gösterir, 44 pt, sağda', (
    tester,
  ) async {
    await _pumpHome(tester, profiles: [_profile('p1', 'Bir')], activeId: 'p1');
    expect(_inButton(find.text('Bir')), findsOneWidget);
    expect(_inButton(find.text('6,35 mm')), findsOneWidget);
    expect(_inButton(find.byIcon(Icons.expand_more)), findsOneWidget);

    final name = tester.widget<Text>(_inButton(find.text('Bir')));
    expect(name.style?.fontWeight, FontWeight.w700);
    final caliber = tester.widget<Text>(_inButton(find.text('6,35 mm')));
    expect(caliber.style?.color, MenzilColors.dark.ink2);

    // A short name fits without "…".
    final paragraph = tester.renderObject<RenderParagraph>(
      _inButton(find.text('Bir')),
    );
    expect(paragraph.didExceedMaxLines, isFalse);

    final rect = tester.getRect(find.byKey(_button));
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(390 - rect.right, moreOrLessEquals(MenzilSpace.gutter));
  });

  testWidgets('profil düğmesine dokununca profil değiştirici açılır', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      profiles: [_profile('p1', 'Bir'), _profile('p2', 'İki')],
      activeId: 'p1',
    );
    expect(_inButton(find.text('Bir')), findsOneWidget);
    expect(_inButton(find.text('İki')), findsNothing);

    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    // The existing list opens with every saved profile.
    expect(find.text('İki'), findsWidgets);

    await tester.tap(find.text('İki').last);
    await tester.pumpAndSettle();
    expect(_inButton(find.text('İki')), findsOneWidget);
    expect(_inButton(find.text('Bir')), findsNothing);
    expect(_inButton(find.text('6,35 mm')), findsOneWidget);
  });

  testWidgets(
    'profil yokken düğme "Profil seç" der ve Profil sekmesine gider',
    (tester) async {
      await _pumpHome(tester);
      expect(_inButton(find.text('Profil seç')), findsOneWidget);
      final rect = tester.getRect(find.byKey(_button));
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(rect.width, greaterThanOrEqualTo(44));

      await tester.tap(_tab('Hava Durumu'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('top-bar-title')), findsOneWidget);

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      // Back on Profil: the brand replaces the page title.
      expect(find.byKey(const Key('top-bar-brand')), findsOneWidget);
      expect(find.byKey(const Key('top-bar-title')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in const [1.0, 1.3]) {
    testWidgets('320 pt dar ekran, uzun ad, yazı ${scale}x: taşma yok', (
      tester,
    ) async {
      const longName = 'Çok uzun bir profil adı deneme amaçlı yazıldı';
      await _pumpHome(
        tester,
        profiles: [_profile('p1', longName)],
        activeId: 'p1',
        width: 320,
        textScale: scale,
      );
      for (final tab in _tabs) {
        await tester.tap(_tab(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
        final rect = tester.getRect(find.byKey(_button));
        final slot = tester.getRect(
          find.byKey(const Key('top-bar-profile-slot')),
        );
        expect(rect.left, greaterThanOrEqualTo(slot.left - 0.01), reason: tab);
        expect(rect.right, lessThanOrEqualTo(320 - MenzilSpace.gutter + 0.01));
        expect(rect.height, greaterThanOrEqualTo(44), reason: tab);
        // The long name is shortened with "…" inside the button.
        final paragraph = tester.renderObject<RenderParagraph>(
          _inButton(find.text(longName)),
        );
        expect(paragraph.didExceedMaxLines, isTrue, reason: tab);
      }
    });
  }

  testWidgets(
    'eski kayıt "Açık" dese de uygulama koyu açılır, kayıt silinmez',
    (tester) async {
      SharedPreferences.setMockInitialValues({'theme.dark': false});
      await tester.pumpWidget(const SniperTurkApp());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      final home = tester.element(find.byType(HomeScreen));
      expect(Theme.of(home).brightness, Brightness.dark);
      expect(
        Theme.of(home).extension<MenzilColors>()?.bg,
        MenzilColors.dark.bg,
      );
      expect(find.byTooltip('Tema'), findsNothing);
      // The old choice stays in storage untouched.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('theme.dark'), isFalse);
    },
  );
}
