// Owner, 2026-10-13 (simulator tour): without a profile the Hedef page must
// not compute or show any solution, and the Profil summary shows the picked
// Dürbün ayağı ("0 MOA") instead of "Yok".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

RifleProfile _profile(double mountCantMoa) => RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  mountCantMoa: mountCantMoa,
);

Future<MemoryProfileStore> _pumpHome(
  WidgetTester tester, {
  RifleProfile? profile,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  if (profile != null) await store.save(profile);
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
  return store;
}

/// Any solution text the Hedef page shows when it solves.
void _expectNoSolution() {
  expect(find.byType(ScopeDialView), findsNothing);
  expect(find.byType(BallisticsScreen), findsNothing);
  expect(find.byKey(ScopeDialKeys.reticle), findsNothing);
  expect(find.byKey(ScopeDialKeys.workings), findsNothing);
  expect(find.textContaining('Vuruş noktası'), findsNothing);
  expect(find.textContaining('Hesap dökümü'), findsNothing);
  expect(find.textContaining('Kule:'), findsNothing);
  expect(find.textContaining('Kırmızı sayılar'), findsNothing);
  expect(find.byKey(const Key('empty-shot-range')), findsNothing);
  expect(find.byType(Slider), findsNothing);
}

void main() {
  group('Hedef without a profile', () {
    testWidgets('shows only the empty state, no solution numbers', (
      tester,
    ) async {
      await _pumpHome(tester);
      await tester.tap(find.text('Hedef'));
      await tester.pumpAndSettle();

      expect(find.byKey(EmptyStateKeys.shotPreview), findsOneWidget);
      expect(find.text('Tahmin yok, hesap var.'), findsOneWidget);
      expect(find.byKey(EmptyStateKeys.create), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(EmptyStateKeys.shotPreview),
          matching: find.text('Profil oluştur'),
        ),
        findsOneWidget,
      );
      _expectNoSolution();
      // The page holds no number at all (only the slogan card).
      final texts = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byKey(EmptyStateKeys.shotPreview),
              matching: find.byType(RichText),
            ),
          )
          .map((r) => r.text.toPlainText())
          .join(' ');
      expect(RegExp(r'\d').hasMatch(texts), isFalse, reason: texts);
    });

    testWidgets('the profile is deleted while Hedef was used', (tester) async {
      final store = await _pumpHome(tester, profile: _profile(0));
      await tester.tap(find.text('Hedef'));
      await tester.pumpAndSettle();
      expect(find.byType(ScopeDialView), findsOneWidget);

      // Delete the only profile on Profil, then come back to Hedef.
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      final menu = find.byTooltip('Profil işlemleri');
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
      await tester.pumpAndSettle();
      expect(await store.all(), isEmpty);
      await tester.tap(find.text('Hedef'));
      await tester.pumpAndSettle();
      expect(find.byKey(EmptyStateKeys.shotPreview), findsOneWidget);
      _expectNoSolution();
    });
  });

  testWidgets('with a profile the Hedef solution still appears', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _profile(0));
    await tester.tap(find.text('Hedef'));
    await tester.pumpAndSettle();
    expect(find.byKey(EmptyStateKeys.shotPreview), findsNothing);
    expect(find.byType(ScopeDialView), findsOneWidget);
    expect(find.byKey(ScopeDialKeys.impactText), findsOneWidget);
    expect(find.textContaining('Vuruş noktası'), findsWidgets);
    expect(find.byKey(ScopeDialKeys.workings), findsOneWidget);
  });

  group('Profil summary: Dürbün ayağı', () {
    for (final (moa, shown) in const [(0.0, '0 MOA'), (15.0, '15 MOA')]) {
      testWidgets('$shown mount', (tester) async {
        await _pumpHome(tester, profile: _profile(moa));
        final card = find.byKey(const Key('profile-summary-scope'));
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text(shown)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('Yok')),
          findsNothing,
        );
      });
    }

    test('tile text: 0 / 15 / 30 MOA and "—" when unset', () {
      final zero = mountCantSummary(0);
      expect((zero.label, zero.value, zero.unit), ('Dürbün ayağı', '0', 'MOA'));
      final fifteen = mountCantSummary(15);
      expect((fifteen.value, fifteen.unit), ('15', 'MOA'));
      final thirty = mountCantSummary(30);
      expect((thirty.value, thirty.unit), ('30', 'MOA'));
      final unset = mountCantSummary(null);
      expect((unset.value, unset.unit), ('—', null));
    });
  });
}
