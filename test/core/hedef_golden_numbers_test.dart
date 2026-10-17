// Formüller core'a taşındı (owner, 2026-10-15): the numbers Hedef shows
// must be exactly the same before and after the move. The expected strings
// below were recorded on main (cb9ffee) before any formula was moved, by
// running this file on the unchanged code. Every displayed number of the
// shot view (turret requirement, spin drift / aerodynamic jump, moving
// target lead, wind bracket, WEZ hit chance, target ring) is compared as text, so a
// change in the last printed digit fails.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../support/pro_sections.dart';

class _Sample {
  final String name;
  final Map<String, dynamic> rifle, ammo;
  final RifleProfile profile;
  final ShotSettings settings;
  final String rangeText;
  const _Sample(
    this.name,
    this.rifle,
    this.ammo,
    this.profile,
    this.settings,
    this.rangeText,
  );
}

const _samples = <_Sample>[
  _Sample(
    'g308',
    {
      'id': 'manual_rifle_g308',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Test',
      'model': '308',
      'caliberMm': 7.62,
      'barrelLengthMm': 600,
      'twistDirection': 'right',
      'twistRateIn': 10,
    },
    {
      'id': 'manual_ammo_g308',
      'kind': 'ammo',
      'platform': 'firearm',
      'brand': 'Test 168',
      'model': '',
      'caliberMm': 7.62,
      'grain': 168,
      'ammoType': 'bullet',
      'bc': 0.462,
      'bcModel': 'g1',
    },
    RifleProfile(
      id: 'p-g308',
      name: 'G308',
      rifleId: 'manual_rifle_g308',
      ammunitionId: 'manual_ammo_g308',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 800,
      zeroRangeM: 100,
      sightHeightMm: 45,
    ),
    ShotSettings(
      inclineDeg: 10,
      windMaxText: '6',
      targetSpeedText: '2',
      targetMovesRight: true,
      bulletLengthText: '31',
      zeroUpText: '1',
      zeroRightText: '-0,5',
      groupText: '2',
      sdText: '10',
      targetSizeText: '20',
      rangeErrorText: '5',
      bcErrorText: '3',
      weatherSaved: true,
      weatherSi: {'wind': 4, 'windDirection': 90},
    ),
    '400',
  ),
  _Sample(
    'g65',
    {
      'id': 'manual_rifle_g65',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Test',
      'model': '6.5',
      'caliberMm': 6.71,
      'barrelLengthMm': 660,
      'twistDirection': 'left',
      'twistRateIn': 8,
    },
    {
      'id': 'manual_ammo_g65',
      'kind': 'ammo',
      'platform': 'firearm',
      'brand': 'Test 140',
      'model': '',
      'caliberMm': 6.71,
      'grain': 140,
      'ammoType': 'bullet',
      'bc': 0.315,
      'bcModel': 'g7',
    },
    RifleProfile(
      id: 'p-g65',
      name: 'G65',
      rifleId: 'manual_rifle_g65',
      ammunitionId: 'manual_ammo_g65',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 820,
      zeroRangeM: 100,
      sightHeightMm: 50,
    ),
    ShotSettings(
      inclineDeg: -15,
      windMaxText: '5',
      targetSpeedText: '1,5',
      targetMovesRight: false,
      bulletLengthText: '35',
      zeroUpText: '-0,8',
      zeroRightText: '1,2',
      groupText: '3',
      sdText: '8',
      targetSizeText: '30',
      weatherSaved: true,
      weatherSi: {'wind': 3, 'windDirection': 300},
    ),
    '800',
  ),
  _Sample(
    'g223',
    {
      'id': 'manual_rifle_g223',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Test',
      'model': '223',
      'caliberMm': 5.7,
      'barrelLengthMm': 508,
      'twistDirection': 'right',
      'twistRateIn': 7,
    },
    {
      'id': 'manual_ammo_g223',
      'kind': 'ammo',
      'platform': 'firearm',
      'brand': 'Test 77',
      'model': '',
      'caliberMm': 5.7,
      'grain': 77,
      'ammoType': 'bullet',
      'bc': 0.372,
      'bcModel': 'g1',
    },
    RifleProfile(
      id: 'p-g223',
      name: 'G223',
      rifleId: 'manual_rifle_g223',
      ammunitionId: 'manual_ammo_g223',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 840,
      zeroRangeM: 200,
      sightHeightMm: 60,
    ),
    // No wind: spin drift without aerodynamic jump; default target ring.
    ShotSettings(
      targetSpeedText: '3',
      targetMovesRight: true,
      bulletLengthText: '25,5',
      zeroUpText: '2',
      groupText: '4',
    ),
    '300',
  ),
];

/// Recorded on main cb9ffee before the move (see the header comment).
/// B: same numbers, read in the 2026-10-17 order "wind: clicks · wind max:
/// clicks" (fix/ruzgar-satirlari).
const _golden = <String, String>{
  'g308':
      'R400.0|U2.710497842933387|W-1.0263591063727064|T0.2|I10.0|S4,3 4,7'
      '|L2,0 119 30 0,60|B4,0 10 6,0 15|H66 20 400|D',
  'g65':
      'R800.0|U7.203701645523648|W1.0335538627918501|T0.3|I-15.0|S14,2 4,9'
      '|L1,5 191 24 1,27|B3,0 10 5,0 17|H30 30 800|D',
  'g223':
      'R300.0|U0.7896208886008387|W-0.07377618246746716|T0.1|I0.0|S2,2'
      '|L3,0 126 42 0,42|B-|H96 10 300|D',
};

String _numbers(String text) => RegExp(
  r'-?\d+(?:[.,]\d+)?',
).allMatches(text).map((m) => m.group(0)).join(' ');

void main() {
  for (final s in _samples) {
    testWidgets('Hedef numbers unchanged: ${s.name}', (tester) async {
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(s.profile.id): jsonEncode(s.settings.toJson()),
      });
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([s.rifle, s.ammo]),
      );
      addTearDown(
        () => CatalogRepository.installUserCatalog(UserCatalog.empty),
      );
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      Widget app(BallisticsView view) => MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: BallisticsScreen(profile: s.profile, view: view),
        ),
      );

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, const Key('pro-shot-range'));
      final range = find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(range);
      await tester.enterText(range, s.rangeText);
      await tester.pump();

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();

      final dial = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
      String text(String key) {
        final f = find.byKey(Key(key));
        if (f.evaluate().isEmpty) return '-';
        final w = tester.widget(f);
        return w is Text ? _numbers(w.data ?? w.textSpan!.toPlainText()) : '?';
      }

      final actual = [
        'R${dial.rangeM}',
        'U${dial.requiredUp}',
        'W${dial.requiredRight}',
        'T${dial.targetDiameterM}',
        'I${dial.inclineDeg}',
        'S${text('shot-spin-drift')}',
        'L${text('shot-lead')}',
        'B${text('shot-wind-bracket')}',
        'H${text('shot-hit-probability')}',
        'D${text('shot-wez-dominant')}',
      ].join('|');
      expect(actual, _golden[s.name]);
    });
  }
}
