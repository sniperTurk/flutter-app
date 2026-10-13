// PCP tüp ve regülatör basıncı on screen (owner, 2026-10-12): Profil shows
// Tüp basıncı | Regülatör basıncı and the basınca göre hız rows on PCP only;
// Pro takes the tube pressure left; a firearm sees none of it and its
// solution does not change; a PCP with nothing entered solves as before.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/rifle_form.dart';

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Test',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.03,
  'bcModel': 'ga',
};
const _fxRifle = <String, dynamic>{
  'id': 'manual_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'manual_ammo_fx',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

const _pcpPlain = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'manual_rifle_pcp',
  ammunitionId: 'manual_ammo_pcp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 30,
  sightHeightMm: 60,
);

/// Regulated at 150 bar; measured 255 m/s at 120 bar and 270 m/s at 150.
const _pcpRegulated = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'manual_rifle_pcp',
  ammunitionId: 'manual_ammo_pcp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 30,
  sightHeightMm: 60,
  pressureBar: 150,
  tubePressureBar: 250,
  pressureVelocityTable: [
    PressureVelocityPoint(bar: 120, mps: 255),
    PressureVelocityPoint(bar: 150, mps: 270),
  ],
);

const _fx = RifleProfile(
  id: 'p-fx',
  name: 'FX',
  rifleId: 'manual_rifle_fx',
  ammunitionId: 'manual_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

Future<void> _openNew(WidgetTester tester, {required bool firearm}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    firearm ? 'Ateşli Tüfek' : 'PCP Tüfek',
  );
}

const _pcpKeys = [
  'profile-tube-pressure',
  'profile-regulator-pressure',
  'profile-pv-title',
  'profile-pv-bar-0',
  'profile-pv-fps-0',
];

void main() {
  group('Profil', () {
    testWidgets('PCP: Tüp basıncı | Regülatör basıncı side by side, empty, '
        'with ⓘ and no parentheses', (tester) async {
      await _openNew(tester, firearm: false);
      for (final k in _pcpKeys) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
      final t = find.byKey(const Key('profile-tube-pressure'));
      final r = find.byKey(const Key('profile-regulator-pressure'));
      await tester.ensureVisible(t);
      await tester.pumpAndSettle();
      final tr = tester.getRect(t), rr = tester.getRect(r);
      expect((tr.top - rr.top).abs(), lessThan(1));
      expect(tr.right, lessThan(rr.left));
      final b = tester.getRect(find.byKey(const Key('profile-pv-bar-0')));
      final f = tester.getRect(find.byKey(const Key('profile-pv-fps-0')));
      expect((b.top - f.top).abs(), lessThan(1));
      expect(find.text('Tüp basıncı'), findsOneWidget);
      expect(find.text('Regülatör basıncı'), findsOneWidget);
      for (final k in [
        'profile-tube-pressure',
        'profile-regulator-pressure',
        'profile-pv-bar-0',
        'profile-pv-fps-0',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(Key(k)),
            matching: find.byType(MenzilInfoButton),
          ),
          findsOneWidget,
          reason: k,
        );
        final field = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(Key(k)),
            matching: find.byType(TextField),
          ),
        );
        expect(field.controller!.text, '', reason: k);
        expect(field.decoration?.hintText, isNull, reason: k);
        expect(field.decoration?.helperText, isNull, reason: k);
      }
    });

    testWidgets('firearm: none of the PCP pressure fields', (tester) async {
      await _openNew(tester, firearm: true);
      for (final k in _pcpKeys) {
        expect(find.byKey(Key(k)), findsNothing, reason: k);
      }
    });
  });

  group('Pro and Hedef', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo, _fxRifle, _fxAmmo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Widget app(RifleProfile profile, BallisticsView view) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: profile, view: view),
      ),
    );

    Future<void> big(WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<double> elevation(
      WidgetTester tester,
      RifleProfile profile, {
      String? tube,
    }) async {
      // A fresh workspace each time (no state carried between profiles).
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(profile, BallisticsView.pro));
      await tester.pumpAndSettle();
      if (tube != null) {
        const key = Key('pro-tube-pressure');
        await openProFor(tester, key);
        final f = find.descendant(
          of: find.byKey(key),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(f);
        await tester.enterText(f, tube);
        await tester.pump();
      }
      await tester.pumpWidget(app(profile, BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredUp!;
    }

    testWidgets('firearm: no tube pressure on Pro', (tester) async {
      await big(tester);
      await tester.pumpWidget(app(_fx, BallisticsView.pro));
      await tester.pumpAndSettle();
      await tapProHeader(tester, find.byKey(const Key('pro-section-rifle')));
      expect(find.byKey(const Key('pro-turret-scale')), findsOneWidget);
      expect(find.byKey(const Key('pro-tube-pressure')), findsNothing);
    });

    testWidgets('PCP: tube pressure box on Pro with ⓘ', (tester) async {
      await big(tester);
      await tester.pumpWidget(app(_pcpPlain, BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, const Key('pro-tube-pressure'));
      final box = find.byKey(const Key('pro-tube-pressure'));
      expect(box, findsOneWidget);
      expect(
        find.descendant(of: box, matching: find.byType(MenzilInfoButton)),
        findsOneWidget,
      );
    });

    testWidgets('a saved tube pressure never moves a firearm solution', (
      tester,
    ) async {
      await big(tester);
      final a = await elevation(tester, _fx);
      // A tube pressure stored for this profile id (e.g. from a PCP profile
      // restored under the same id) is ignored on a firearm.
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(_fx.id): jsonEncode(
          const ShotSettings(tubePressureText: '50').toJson(),
        ),
      });
      final b = await elevation(tester, _fx);
      expect(b, a);
      expect(find.byKey(const Key('shot-pcp-regulator')), findsNothing);
    });

    testWidgets('regulated, tube above the regulator: as before', (
      tester,
    ) async {
      await big(tester);
      final plain = await elevation(tester, _pcpPlain);
      final fields = await elevation(tester, _pcpRegulated);
      expect(fields, closeTo(plain, 1e-12));
      final above = await elevation(tester, _pcpRegulated, tube: '200');
      expect(above, closeTo(plain, 1e-12));
      expect(find.byKey(const Key('shot-pcp-regulator')), findsNothing);
    });

    testWidgets('regulated, tube below the regulator: warning and the '
        'slower measured velocity', (tester) async {
      await big(tester);
      final plain = await elevation(tester, _pcpRegulated);
      final low = await elevation(tester, _pcpRegulated, tube: '120');
      expect(find.byKey(const Key('shot-pcp-regulator')), findsOneWidget);
      // 255 m/s against a zero at 270 m/s: the pellet drops more.
      expect(low, isNot(closeTo(plain, 1e-6)));
    });

    testWidgets('Pro shows the warning and the velocity used', (tester) async {
      await big(tester);
      await tester.pumpWidget(app(_pcpRegulated, BallisticsView.pro));
      await tester.pumpAndSettle();
      const key = Key('pro-tube-pressure');
      await openProFor(tester, key);
      final f = find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(f);
      // Comma decimals are accepted.
      await tester.enterText(f, '120,0');
      await tester.pump();
      expect(find.byKey(const Key('pro-pcp-regulator')), findsOneWidget);
      final used = tester
          .widget<Text>(find.byKey(const Key('pro-pcp-velocity')))
          .data!;
      expect(used, contains('${(255 * 3.280839895).toStringAsFixed(0)} fps'));
    });
  });
}
