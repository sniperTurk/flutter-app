// Pre-TestFlight audit 2026-10-15c, area APP SHELL / NAVIGATION.
//
// #331 (196dea1): top bar = page title left, active-profile button right
// (name + caliber + ⌄); the Koyu/Açık theme button is deleted, the app is
// always dark. #328 (99b0e5d): main buttons text only. #326 / #343: Rehber
// wording ("Kuleleri kur", "Profil ekle"). #339 system font test, #347 icon
// background, #322 default profile name (top bar display only).
//
// State flow checked: the top-bar dropdown calls HomeScreen._choose, which
// writes ActiveProfileStore and sets `active`; the Hava Durumu / Pro / Hedef
// workspace (one BallisticsScreen) is keyed on the profile id and units, so
// a switch builds a fresh workspace (turrets at 0, new unit, new solve).
// Profil gets activeProfileId, Araçlar gets the platform; tool pages are
// pushed routes over the top bar and read the store when they open.
//
// Findings:
//   UST-1 (medium, #331): the open profile list is only as wide as the
//         button, which is now only as wide as the ACTIVE profile's name.
//         With a short active name the other profiles' names are cut with
//         "…" although the bar has room (before #331 the list was the
//         width of the whole profile slot).                [skipped test]
//   UST-2 (low): switching from Hedef to a profile that does not resolve
//         against the catalog leaves the previous profile's clicks on the
//         watch (no "Çözüm yok" is sent; the watch only marks them stale
//         after 2 min).                                      [skipped test]
//   UST-3 (low, #331): CatalogStartupErrorApp still uses MenzilTheme.light()
//         and follows the phone setting, so that screen is light on a phone
//         in light mode while the app is "always dark".     [skipped test]
//   DGM-1 (low, #343): Rehber step 1 says 'Profil sayfasında "Profil
//         oluştur"a dokun', but on first launch the Profil page's button is
//         "İlk profilimi oluştur"; "Profil oluştur" only exists on Hava
//         Durumu / Pro / Hedef.                              [skipped test]
//   DGM-2 (low, #328/#329): MenzilPrimaryButton keeps the `oneLine` + icon
//         layout (iconLead, iconLabelGap) that no page uses any more since
//         "Profil ekle" became text only (owner rule: unused code is
//         deleted).                                          [skipped test]
// Passing guards: profile switch on Hedef with dialled turrets (MRAD/metre
// -> MOA/yard) gives the same numbers as a freshly opened workspace of the
// new profile; no theme code is left in lib/; the guide's Hedef button
// names exist.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/guide/usage_guide_content.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/main.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

// Gazi Sniper 6–36×56 FFP (0.1 mrad clicks) on a Hatsan Hercules .25 with
// the G Maz slug: catalog entries used by the other shell tests.
const _mradMetre = RifleProfile(
  id: 'ust-mrad-metre',
  name: 'MRAD metre',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _moaYard = RifleProfile(
  id: 'ust-moa-yard',
  name: 'MOA yard',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 27.432, // 30 yd
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
  distanceUnit: DistanceUnit.yard,
);

/// Does not resolve: 2000 m/s is above ProductionLimits.maxMuzzleVelocityMps
/// (1500), so ProfileCatalogIntegrity.resolve returns null (the same path as
/// an old profile whose catalog entry no longer matches).
const _broken = RifleProfile(
  id: 'ust-broken',
  name: 'Bozuk profil',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 2000,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

RifleProfile _named(String id, String name) => RifleProfile(
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

class _FakeTransport implements WatchTransport {
  final sent = <Map<String, Object>>[];
  final controller = StreamController<Map<Object?, Object?>>.broadcast();

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    sent.add(message);
    return WatchSendResult.sent;
  }

  @override
  Stream<Map<Object?, Object?>> get incoming => controller.stream;
}

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

Future<void> _pumpHome(
  WidgetTester tester, {
  List<RifleProfile> profiles = const [],
  String? activeId,
  Size size = const Size(390, 2400),
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
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

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(_tab(label));
  await tester.pumpAndSettle();
}

/// The top-bar button: open the list and pick [name].
Future<void> _switchTo(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(_button));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

String _guideText() => [
  UsageGuideContent.intro,
  for (final s in UsageGuideContent.sections) ...[s.title, ...s.paragraphs],
].join('\n');

Iterable<File> _libDartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('üst çubuk profil düğmesi', () {
    testWidgets(
      'switch on Hedef with dialled turrets: fresh workspace, new units, '
      'same numbers as opening the new profile directly',
      (tester) async {
        await _pumpHome(
          tester,
          profiles: [_mradMetre, _moaYard],
          activeId: _mradMetre.id,
        );
        await _openTab(tester, 'Hedef');
        final before = _dial(tester);
        expect(before.unit, AngularUnit.mrad);
        expect(before.clickValue, 0.1);
        expect(before.requiredUp, isNotNull);

        // Dial the solution: the turrets now hold the MRAD profile's clicks.
        final kur = find.byKey(ScopeDialKeys.dialSolution);
        await tester.ensureVisible(kur);
        await tester.pumpAndSettle();
        await tester.tap(kur);
        await tester.pumpAndSettle();
        expect(_dial(tester).elevationClicks, isNot(0));

        await _switchTo(tester, 'MOA yard');
        expect(
          find.descendant(
            of: find.byKey(_button),
            matching: find.text('MOA yard'),
          ),
          findsOneWidget,
        );
        final switched = _dial(tester);
        // No click of the old profile is left on the turrets.
        expect(switched.elevationClicks, 0);
        expect(switched.windageClicks, 0);
        expect(switched.unit, AngularUnit.moa);
        // Gazi turret is MRAD; a MOA profile uses the standard ¼ MOA click.
        expect(switched.clickValue, 0.25);
        expect(switched.requiredUp, isNotNull);
        final switchedUp = switched.requiredUp!;
        expect(tester.takeException(), isNull);

        // Reference: the same profile opened on its own.
        await tester.pumpWidget(
          MaterialApp(
            theme: MenzilTheme.dark(),
            home: const Scaffold(
              body: BallisticsScreen(
                profile: _moaYard,
                view: BallisticsView.shot,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fresh = _dial(tester);
        expect(fresh.unit, AngularUnit.moa);
        expect(switchedUp, closeTo(fresh.requiredUp!, 1e-9));
      },
    );

    testWidgets(
      'UST-1: the open list shows another profile name in full',
      (tester) async {
        // A wide bar: the slot right of the title has room for the whole
        // name (17 letters); only the list width cuts it.
        await _pumpHome(
          tester,
          profiles: [
            _named('ust-a', 'A'),
            _named('ust-b', 'Gece avi tufegi 2'),
          ],
          activeId: 'ust-a',
          size: const Size(800, 900),
        );
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        final item = tester.renderObject<RenderParagraph>(
          find.text('Gece avi tufegi 2').last,
        );
        expect(item.didExceedMaxLines, isFalse);
      },
      skip: true, // UST-1: list is as narrow as the short active name
    );

    testWidgets(
      'UST-2: switching from Hedef to an unresolved profile clears the watch',
      (tester) async {
        final t = _FakeTransport();
        WatchBridge.instance = WatchBridge(transport: t);
        addTearDown(() => WatchBridge.instance = WatchBridge());
        await _pumpHome(
          tester,
          profiles: [_mradMetre, _broken],
          activeId: _mradMetre.id,
        );
        await _openTab(tester, 'Hedef');
        final shown = t.sent.lastWhere((m) => m['ok'] == true);
        expect(shown['profile'], 'MRAD metre');

        await _switchTo(tester, 'Bozuk profil');
        expect(find.textContaining('katalogla eşleşmiyor'), findsOneWidget);
        // The watch must not keep the old profile's clicks as current.
        expect(t.sent.last['ok'], false);
      },
      skip: true, // UST-2: no withdraw when the workspace is removed
    );
  });

  group('koyu tema', () {
    test('no theme code is left in lib/', () {
      const leftovers = [
        'MenzilThemeController',
        'MenzilThemeScope',
        'MenzilBarButton',
        'themeLabel',
        'onThemeTap',
        "'theme.dark'",
        '"theme.dark"',
      ];
      for (final f in _libDartFiles()) {
        final src = f.readAsStringSync();
        for (final word in leftovers) {
          expect(src.contains(word), isFalse, reason: '${f.path}: $word');
        }
      }
    });

    testWidgets(
      'UST-3: catalog error screen is dark on a light-mode phone',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          const CatalogStartupErrorApp(issues: ['deneme']),
        );
        await tester.pumpAndSettle();
        final ctx = tester.element(find.text('Katalog yüklenemedi'));
        expect(Theme.of(ctx).brightness, Brightness.dark);
      },
      skip: true, // UST-3: MenzilTheme.light() + system theme mode
    );
  });

  group('düğmeler ve rehber', () {
    test('the Hedef buttons the guide names exist', () {
      final src = File(
        'lib/features/ballistics/scope_turrets.dart',
      ).readAsStringSync();
      for (final label in const [
        'Kuleleri kur',
        'Kuleleri sıfırla',
        'Kule sınırına kuruldu',
      ]) {
        expect(_guideText(), contains('"$label"'), reason: label);
        expect(src, contains("'$label'"), reason: label);
      }
    });

    testWidgets('first launch: Profil shows "İlk profilimi oluştur"', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text('İlk profilimi oluştur'), findsOneWidget);
    });

    testWidgets(
      'DGM-1: the button the guide names on Profil exists there',
      (tester) async {
        final first = UsageGuideContent.sections
            .firstWhere((s) => s.title == 'İlk profil')
            .paragraphs
            .first;
        final match = RegExp(r'"([^"]+)"a dokun').firstMatch(first);
        final label = match!.group(1)!;
        await _pumpHome(tester);
        // Still on Profil (the app opens there): the welcome page.
        expect(find.text(label), findsOneWidget, reason: label);
      },
      skip: true, // DGM-1: guide says "Profil oluştur", page has another
    );

    test(
      'DGM-2: no unused oneLine + icon layout in MenzilPrimaryButton',
      () {
        final callers = _libDartFiles()
            .where((f) => !f.path.endsWith('menzil_widgets.dart'))
            .where((f) => f.readAsStringSync().contains('iconLead:'))
            .map((f) => f.path)
            .toList();
        expect(callers, isEmpty);
        final src = File('lib/ui/menzil_widgets.dart').readAsStringSync();
        expect(src, isNot(contains('iconLead')));
      },
      skip: 'DGM-2: iconLead layout kept although no page uses it',
    );
  });
}
