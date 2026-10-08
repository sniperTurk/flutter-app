// Dürbün ayağı (canted scope mount, e.g. a 30/60/90 MOA "No Limit" base).
//
// The mount does not change the drop or the correction from zero. It moves
// the zeroed turret down in its travel, so the scope gets that many more
// clicks to dial UP (owner, 2026-10-08: 60 MOA × 4 = 240 clicks on a
// 1/4 MOA scope).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/tools/tool_support.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks, 26 mrad elevation travel.
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

RifleProfile _withMount(double moa) => RifleProfile(
  id: _profile.id,
  name: _profile.name,
  rifleId: _profile.rifleId,
  ammunitionId: _profile.ammunitionId,
  scopeId: _profile.scopeId,
  muzzleVelocityMps: _profile.muzzleVelocityMps,
  zeroRangeM: _profile.zeroRangeM,
  sightHeightMm: _profile.sightHeightMm,
  pressureBar: _profile.pressureBar,
  mountCantMoa: moa,
);

Widget _view({
  required double requiredUp,
  required int up,
  int? down,
  double mountMoa = 0,
  int mountClicks = 0,
  bool travelKnown = true,
  int elevationClicks = 0,
  ValueChanged<int>? onElevation,
}) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ScopeDialView(
        unit: AngularUnit.moa,
        clickValue: 0.25,
        elevationClicks: elevationClicks,
        windageClicks: 0,
        maxElevationClicks: up,
        maxElevationDownClicks: down,
        mountCantMoa: mountMoa,
        mountCantClicks: mountClicks,
        travelKnown: travelKnown,
        maxWindageClicks: 120,
        onElevationChanged: onElevation ?? (_) {},
        onWindageChanged: (_) {},
        requiredUp: requiredUp,
        firstFocalPlane: true,
        rangeM: 200,
        samples: const [],
        toDisplayRange: (m) => m,
        distanceUnit: 'm',
        metric: true,
      ),
    ),
  ),
);

String _note(WidgetTester tester, Key key) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join(' ');

void main() {
  group('ScopeDialMath.mountCantClicks', () {
    test('MOA scopes follow MOA × (1 / click value)', () {
      // The owner's table.
      for (final (moa, click, clicks) in const [
        (30.0, 0.25, 120),
        (60.0, 0.25, 240),
        (90.0, 0.25, 360),
        (30.0, 0.125, 240),
        (60.0, 0.125, 480),
        (90.0, 0.125, 720),
        (30.0, 0.5, 60),
        (60.0, 0.5, 120),
        (90.0, 0.5, 180),
      ]) {
        expect(
          ScopeDialMath.mountCantClicks(moa, click, AngularUnit.moa),
          clicks,
          reason: '$moa MOA @ $click',
        );
      }
    });

    test('MRAD scopes convert MOA first and never overstate the gain', () {
      // 30 MOA = 8.727 mrad → 87 clicks of 0.1 mrad (not 88).
      expect(ScopeDialMath.mountCantClicks(30, 0.1, AngularUnit.mrad), 87);
      expect(ScopeDialMath.mountCantClicks(60, 0.1, AngularUnit.mrad), 174);
      expect(ScopeDialMath.mountCantClicks(90, 0.1, AngularUnit.mrad), 261);
      expect(ScopeDialMath.mountCantClicks(0, 0.1, AngularUnit.mrad), 0);
      expect(
        () => ScopeDialMath.mountCantClicks(-1, 0.1, AngularUnit.mrad),
        throwsArgumentError,
      );
    });
  });

  group('profile value', () {
    test('empty is a normal mount; bounds are enforced', () {
      expect(ProfileInput.parseMountCant(''), 0);
      expect(ProfileInput.parseMountCant('  '), 0);
      expect(ProfileInput.parseMountCant('60'), 60);
      expect(ProfileInput.parseMountCant('45,5'), 45.5);
      expect(ProfileInput.parseMountCant('0'), 0);
      for (final bad in const ['-1', '121', 'abc', 'NaN']) {
        expect(
          () => ProfileInput.parseMountCant(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('codec round-trips it; old profiles read as 0; junk fails', () {
      const codec = ProfileCodec();
      final json = codec.encode(_withMount(60));
      expect(json['mountCantMoa'], 60);
      expect(codec.decode(json).mountCantMoa, 60);

      final legacy = Map<String, dynamic>.of(json)..remove('mountCantMoa');
      expect(codec.decode(legacy).mountCantMoa, 0);

      for (final bad in <Object>[-5, 500, 'sixty', double.nan]) {
        expect(
          () => codec.decode(Map.of(json)..['mountCantMoa'] = bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('tool updates keep the mount', () {
      final updated = ToolProfileUpdate.apply(
        _withMount(30),
        sightHeightMm: 55,
      );
      expect(updated.sightHeightMm, 55);
      expect(updated.mountCantMoa, 30);
    });
  });

  group('scope view', () {
    testWidgets('a mount gives the turret room: no travel warning', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // 1/4 MOA scope with 120 clicks (30 MOA) of travel up from centre;
      // 200 m needs 37.8 MOA = 151 clicks.
      await tester.pumpWidget(_view(requiredUp: 37.8, up: 120));
      expect(find.byKey(ScopeDialKeys.mountNote), findsNothing);
      expect(find.byKey(ScopeDialKeys.travelNote), findsOneWidget);
      final warning = _note(tester, ScopeDialKeys.travelNote);
      expect(warning, contains('151 klik'));
      expect(warning, contains('120 klik'));
      // 31 clicks × 0.25 = 7.75 MOA missing → at least 8 MOA.
      expect(warning, contains('en az 8 MOA dürbün ayağı'));

      // Same scope on a 60 MOA mount: 240 more clicks up, none down.
      int? dialled;
      await tester.pumpWidget(
        _view(
          requiredUp: 37.8,
          up: 360,
          down: 0,
          mountMoa: 60,
          mountClicks: 240,
          onElevation: (v) => dialled = v,
        ),
      );
      expect(find.byKey(ScopeDialKeys.travelNote), findsNothing);
      final info = _note(tester, ScopeDialKeys.mountNote);
      expect(info, contains('60 MOA'));
      expect(info, contains('+240 klik'));
      expect(info, contains('360 klik'));

      // The required clicks do not change with the mount.
      await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
      await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
      await tester.pump();
      expect(dialled, 151);
    });

    testWidgets('the mount takes its clicks from the DOWN travel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      int? dialled;
      // Closer than zero: 2 MOA down needed, a 60 MOA mount leaves none.
      await tester.pumpWidget(
        _view(
          requiredUp: -2,
          up: 360,
          down: 0,
          mountMoa: 60,
          mountClicks: 240,
          onElevation: (v) => dialled = v,
        ),
      );
      final warning = _note(tester, ScopeDialKeys.travelNote);
      expect(warning, contains('aşağı'));
      expect(warning, contains('tutuş'));
      await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
      await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
      await tester.pump();
      expect(dialled, 0);
    });

    testWidgets('without catalog travel no mount size is suggested', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _view(requiredUp: 37.8, up: 120, travelKnown: false),
      );
      final warning = _note(tester, ScopeDialKeys.travelNote);
      expect(warning, isNot(contains('dürbün ayağı gerekir')));
    });

    testWidgets('the shot tab uses the profile mount', (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(_withMount(60));
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
      await tester.tap(find.text('Atış'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hesapla'));
      await tester.pumpAndSettle();
      // 13 mrad half travel = 130 clicks; 60 MOA = 17.45 mrad = 174 clicks.
      final info = _note(tester, ScopeDialKeys.mountNote);
      expect(info, contains('+174 klik'));
      expect(info, contains('304 klik'));
    });
  });

  testWidgets('Profil: "Dürbün ayağı" is typed in MOA and explained', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_withMount(60));
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: store, activeProfileId: 'p1'),
      ),
    );
    await tester.pumpAndSettle();
    // The summary shows the mount.
    expect(find.textContaining('Dürbün ayağı'), findsWidgets);

    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('scope-mount-cant'));
    expect(field, findsOneWidget);
    expect(
      find.descendant(
        of: field,
        matching: find.textContaining('MOA', findRichText: true),
      ),
      findsWidgets,
    );
    final input = find.descendant(of: field, matching: find.byType(TextField));
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);

    await tester.enterText(input, '150');
    await tester.pump();
    expect(
      find.descendant(of: field, matching: find.textContaining('0–120 MOA')),
      findsOneWidget,
    );
    await tester.enterText(input, '60');
    await tester.pump();
    expect(
      find.descendant(of: field, matching: find.textContaining('0–120 MOA')),
      findsNothing,
    );
  });
}
