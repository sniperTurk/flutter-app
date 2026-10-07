// Layout and accessibility checks beyond the portrait matrix in
// menzil_responsive_test.dart: landscape, on-screen keyboard, very large
// text, dark theme on every tab, imperial unit display and the iOS tap-target
// and labelling guidelines that VoiceOver users depend on. These run in the
// Flutter test environment; they are not a substitute for a VoiceOver pass on
// a physical iPhone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Hercules Bully 6.35',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _tabs = ['Profil', 'Atış', 'Tablo', 'Ortam', 'Araçlar'];

Future<void> _setView(
  WidgetTester tester,
  Size logical, {
  EdgeInsets padding = EdgeInsets.zero,
  double keyboard = 0,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = logical * 3;
  tester.view.padding = FakeViewPadding(
    left: padding.left * 3,
    top: padding.top * 3,
    right: padding.right * 3,
    bottom: padding.bottom * 3,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      darkTheme: MenzilTheme.dark(),
      themeMode: themeMode,
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

Future<void> _visitEveryTab(WidgetTester tester) async {
  // The app opens on Profil.
  expect(tester.takeException(), isNull, reason: 'Profil at start');
  await tester.tap(_tab('Atış'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Hesapla'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hesapla'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Atış after solve');
  for (final tab in _tabs) {
    await tester.tap(_tab(tab));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: tab);
  }
}

void main() {
  for (final (name, size, padding) in const [
    ('iPhone SE landscape', Size(568, 320), EdgeInsets.zero),
    (
      'iPhone 15 Pro Max landscape',
      Size(932, 430),
      EdgeInsets.only(left: 59, right: 59, bottom: 21),
    ),
  ]) {
    testWidgets('$name renders every tab without overflow', (tester) async {
      await _setView(tester, size, padding: padding);
      await _pumpHome(tester);
      await _visitEveryTab(tester);
    });
  }

  testWidgets('iPhone 15 @ text 2.0x renders every tab without overflow', (
    tester,
  ) async {
    await _setView(
      tester,
      const Size(393, 852),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      textScale: 2.0,
    );
    await _pumpHome(tester);
    await _visitEveryTab(tester);
  });

  testWidgets('dark theme renders every tab', (tester) async {
    await _setView(
      tester,
      const Size(393, 852),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
    );
    await _pumpHome(tester, themeMode: ThemeMode.dark);
    await _visitEveryTab(tester);
  });

  testWidgets('on-screen keyboard on iPhone SE does not break Ortam editing', (
    tester,
  ) async {
    await _setView(
      tester,
      const Size(320, 568),
      padding: const EdgeInsets.only(top: 20),
    );
    await _pumpHome(tester);
    await tester.tap(_tab('Ortam'));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byKey(BallisticsFieldKeys.temperature),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.tap(field);
    tester.view.viewInsets = const FakeViewPadding(bottom: 216 * 3);
    await tester.pumpAndSettle();
    await tester.enterText(field, '31');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TextField>(field).controller!.text, '31');
  });

  testWidgets('imperial preference converts the workspace atomically', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({SettingsStore.metricKey: false});
    await _setView(
      tester,
      const Size(393, 852),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
    );
    await _pumpHome(tester);
    String text(Key key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(key, skipOffstage: false),
            matching: find.byType(TextField, skipOffstage: false),
          ),
        )
        .controller!
        .text;
    // Ortam shows the atmosphere inputs; the shell's ICAO defaults (15 °C,
    // 1013.25 hPa, 0 m, 0 m/s) must arrive converted, all together.
    await tester.tap(_tab('Ortam'));
    await tester.pumpAndSettle();
    expect(text(BallisticsFieldKeys.temperature), '59.0');
    expect(text(BallisticsFieldKeys.pressure), '29.92');
    expect(text(BallisticsFieldKeys.altitude), '0');
    expect(text(BallisticsFieldKeys.wind), '0.0');
    expect(find.text('yd'), findsWidgets);

    // An edited imperial value survives tab switches unchanged.
    await tester.enterText(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.temperature),
        matching: find.byType(TextField),
      ),
      '86',
    );
    await tester.tap(_tab('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Atış'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Ortam'));
    await tester.pumpAndSettle();
    expect(text(BallisticsFieldKeys.temperature), '86');
    expect(text(BallisticsFieldKeys.pressure), '29.92');
    expect(tester.takeException(), isNull);
  });

  testWidgets('VoiceOver prerequisites: labelled controls and 44 pt targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _setView(
      tester,
      const Size(393, 852),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
    );
    await _pumpHome(tester);
    for (final tab in _tabs) {
      await tester.tap(_tab(tab));
      await tester.pumpAndSettle();
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
        reason: tab,
      );
      await expectLater(
        tester,
        meetsGuideline(iOSTapTargetGuideline),
        reason: tab,
      );
    }
    semantics.dispose();
  });
}
