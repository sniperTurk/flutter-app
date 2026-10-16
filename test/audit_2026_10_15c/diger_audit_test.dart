// Pre-TestFlight audit 2026-10-15c — "diğer": the non-design PRs merged
// after 4c51b77:
//  * #335 (680498f) RUZ-1/RUZ-2 En çok rüzgâr empties when the wind changes;
//  * #338 (2570d46) KUL-2 Hız Doğrulama on a regulator-less PCP table;
//  * #345 (b588d43) MUH-1/2/3/5; #355 (297a2fb) Mühimmat sıcaklığı section;
//  * #356 (5d209c8) one İrtifa box; #228 / #353 Garmin bridge.
//
// References are hand calculations, not another ballistic app:
// tools/denetim_2026_10_15c_diger.py (unit definitions, the documented
// powder rule, the repository's own reference solver
// tools/formula_reference.py), checked by
// tools/test_denetim_2026_10_15c_diger.py (also the secret scan and the
// compile-time flag inventory).
//
// Findings (expected behaviour; skipped while main fails it):
//   KUL-10 (high)  Hız Doğrulama BC / Sürüklenme eğrisi on a regulator-less
//                  PCP with a usable "Basınca göre hız" table solves with
//                  the Profil Namlu çıkış hızı (270 m/s), while Hedef zeroes
//                  and shoots with the table velocity (255 m/s at 120 bar).
//                  The applied BC (0,031 → about 0,025) makes Hedef miss the
//                  truing range itself by about 0,8 mrad at 100 m.
//   RUZ-4 (low)    hidden WIND_OBSERVATION: the Rüzgâr gözlemi select
//                  writes Rüzgâr hızı without emptying a "Düzeltme al"
//                  En çok rüzgâr (the RUZ-2 rule).
// The other tests are passing guards.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';

import '../support/tool_fakes.dart';

// ---- KUL-10: regulator-less PCP with a usable table ----------------------

const _k10Rifle = <String, dynamic>{
  'id': 'manual_rifle_k10',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'K10',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _k10Ammo = <String, dynamic>{
  'id': 'manual_ammo_k10',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'K10 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};

/// Profil Namlu çıkış hızı 270 m/s; table 120 bar → 255 m/s, 200 bar →
/// 270 m/s; Tüp basıncı 120 bar; no regulator. Hedef uses 255 m/s for zero
/// and shot (Denetim F3, test/audit_2026_10_14b design guard).
const _k10Profile = RifleProfile(
  id: 'k10',
  name: 'K10 PCP',
  rifleId: 'manual_rifle_k10',
  ammunitionId: 'manual_ammo_k10',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 30,
  sightHeightMm: 50,
  tubePressureBar: 120,
  pressureVelocityTable: [
    PressureVelocityPoint(bar: 120, mps: 255),
    PressureVelocityPoint(bar: 200, mps: 270),
  ],
);

/// The truing page's default air (15 °C, 1013,25 hPa, %50).
const _truingAir = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 50,
);

/// Correction at [rangeM] for the pellet shot at [mps] (zero and shot at the
/// same velocity, as Hedef does on this rifle).
double _correction(double mps, double bc, double rangeM) =>
    const BallisticEngine()
        .solve(
          BallisticInput(
            muzzleVelocityMps: mps,
            grain: 18,
            zeroRangeM: 30,
            sightHeightMm: 50,
            rangesM: [rangeM],
            environment: _truingAir,
            ballisticCoefficient: bc,
            ballisticModel: BallisticModel.g1,
          ),
        )
        .single
        .correctionMrad;

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final f = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

// ---- Garmin / Apple Watch ------------------------------------------------

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

// Catalog Hatsan Hercules .25 + Gazi 6–36 (MOA), as in
// test/hedef_sonuc_ustte_test.dart.
const _moaProfile = RifleProfile(
  id: 'p-grm-moa',
  name: 'GRM MOA',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('KUL-10 Hız Doğrulama BC on a regulator-less PCP table', () {
    test('hand check: the observation is a 255 m/s shot; at 270 m/s the '
        'same BC predicts less drop', () {
      final at255 = _correction(255, 0.031, 100);
      final at270 = _correction(270, 0.031, 100);
      // tools/denetim_2026_10_15c_diger.py: 6,89 mrad (reference solver).
      expect(at255, closeTo(6.89, 0.15));
      expect(at270, lessThan(at255 - 0.5));
    });

    testWidgets('the applied BC reproduces the observation in Hedef '
        '(255 m/s table velocity)', (tester) async {
      await ManualCatalogStore().upsert(_k10Rifle);
      await ManualCatalogStore().upsert(_k10Ammo);
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
      );
      final store = MemoryProfileStore();
      await store.save(_k10Profile);
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final active = MemoryActiveProfileStore()..value = _k10Profile.id;
      await tester.pumpWidget(
        host(TruingScreen(profileStore: store, activeProfileStore: active)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Namlu çıkış hızı').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Balistik katsayı (BC)').last);
      await tester.pumpAndSettle();

      final observed = _correction(255, 0.031, 100);
      await _enter(tester, 'truing-range', '100');
      await _enter(
        tester,
        'truing-observed',
        observed.toStringAsFixed(4).replaceAll('.', ','),
      );
      await _tapKey(tester, 'truing-compute');
      expect(find.byKey(const Key('truing-error')), findsNothing);
      await _tapKey(tester, 'truing-bc-apply');
      await _tapKey(tester, 'truing-bc-confirm');

      final record = (await ManualCatalogStore().all()).singleWhere(
        (e) => e['id'] == 'manual_ammo_k10',
      );
      final bc = (record['bc'] as num).toDouble();
      // Hedef on this rifle: 255 m/s for zero and shot. Today the BC was
      // solved at 270 m/s (about 0,025) and Hedef then shows about 0,8 mrad
      // more than the observation at the truing range itself.
      expect(_correction(255, bc, 100), closeTo(observed, 0.05));
    }, skip: true); // KUL-10: BC truing uses Profil hızı, Hedef the table hızı
  });

  group('RUZ-4 hidden Rüzgâr gözlemi and a "Düzeltme al" value', () {
    test('guard: WIND_OBSERVATION stays a default-off flag', () {
      final src = File(
        'lib/features/ballistics/ballistics_screen.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r"bool\.fromEnvironment\(\s*'WIND_OBSERVATION',?\s*\)",
        ).hasMatch(src),
        isTrue,
      );
    });

    test('the select empties a button-filled En çok rüzgâr like a typed '
        'wind (RUZ-2 rule)', () {
      final src = File(
        'lib/features/ballistics/ballistics_screen.dart',
      ).readAsStringSync();
      final start = src.indexOf('void _pickWindObservation(');
      expect(start, greaterThan(0));
      final body = src.substring(start, src.indexOf('\n  }\n', start));
      expect(body, contains('_windMaxFollowsWind'));
    }, skip: 'RUZ-4: Rüzgâr gözlemi writes the wind, keeps the old max');
  });

  group('guard #355: Mühimmat sıcaklığı empty → air temperature', () {
    test('hand values (k 1,5 %/15 °C, T0 21 °C, 2650 fps)', () {
      double fps(double air, double? ammo) =>
          2650 *
          PowderTemperature.factor(
            coefPercentPer15C: 1.5,
            referenceTempC: 21,
            todayTempC: PowderTemperature.effectiveTempC(
              airC: air,
              ammoC: ammo,
            ),
          );
      // 2650 · (1 + 0,015 · (5 − 21) / 15) = 2607,60 fps.
      expect(fps(5, null), closeTo(2607.60, 1e-9));
      // Ammo 30 °C: 2650 · (1 + 0,015 · 9 / 15) = 2673,85 fps.
      expect(fps(5, 30), closeTo(2673.85, 1e-9));
      // Empty Sıcaklık is solved as 15 °C: 2634,10 fps.
      expect(fps(15, null), closeTo(2634.10, 1e-9));
      // Outside −50…60 °C the air temperature is used.
      expect(fps(5, 70), closeTo(2607.60, 1e-9));
    });
  });

  group('guard #228 / #353: the watch gets exactly the Hedef numbers', () {
    testWidgets('clicks, angles, unit and click value equal the result row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final t = _FakeTransport();
      WatchBridge.instance = WatchBridge(transport: t);
      addTearDown(() => WatchBridge.instance = WatchBridge());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BallisticsScreen(
              profile: _moaProfile,
              view: BallisticsView.shot,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final d = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
      final msg = t.sent.lastWhere((m) => m['ok'] == true);
      final up = (d.requiredUp! / d.clickValue).round();
      final right = (d.requiredRight / d.clickValue).round();
      expect(msg['up'], up);
      expect(msg['right'], right);
      expect(msg['unit'], d.unit.label);
      expect(msg['click'], d.clickValue);
      expect(
        (msg['upAngle']! as num).toDouble(),
        closeTo(d.requiredUp!, 0.005 + 1e-9),
      );
      expect(
        (msg['rightAngle']! as num).toDouble(),
        closeTo(d.requiredRight, 0.005 + 1e-9),
      );
      // The big number of "Üst kule" is the same click count.
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(TurretSolutionRow.elevationKey),
              matching: find.byType(Text),
            ),
          )
          .map((w) => w.data)
          .toList();
      expect(texts, contains('${up.abs()} klik'));
      // No wind entered: no wind travels to the watch.
      expect(msg.containsKey('windSpeed'), isFalse);
    });
  });
}
