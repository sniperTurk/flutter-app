// Kronograf (Ö3, 2026-10-12): Araçlar > Kronograf takes a velocity string,
// shows mean / SD / ES / n (and the slope along the string on a PCP), and
// writes the mean to the profile, the SD to WEZ and the fitted powder
// coefficient to the profile, each only after an old -> new confirmation.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/chrono_field_info.dart';
import 'package:sniper_turk/features/tools/chrono_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/chrono_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';

import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_ch',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_ch',
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

RifleProfile _firearm({double? coef, double? refC}) => RifleProfile(
  id: 'p-ch',
  name: 'Ateşli 308',
  rifleId: 'manual_rifle_ch',
  ammunitionId: 'manual_ammo_ch',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: coef,
  powderTempReferenceC: refC,
);

const _pcp = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Future<MemoryProfileStore> _pump(WidgetTester tester, RifleProfile? p) async {
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  final active = MemoryActiveProfileStore();
  if (p != null) {
    await store.save(p);
    active.value = p.id;
  }
  await tester.pumpWidget(
    host(ChronoScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final f = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pumpAndSettle();
}

Future<void> _tapConfirmed(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('chrono-confirm')));
  await tester.pumpAndSettle();
}

Finder _shows(String text) => find.textContaining(text, findRichText: true);

Future<double> _savedVelocity(MemoryProfileStore store) async =>
    (await store.all()).single.muzzleVelocityMps;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Araçlar lists Kronograf right under Hız Doğrulama', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
    double y(String k) => tester.getTopLeft(find.byKey(Key(k))).dy;
    expect(find.byKey(const Key('tool-chrono')), findsOneWidget);
    expect(y('tool-chrono'), greaterThan(y('tool-truing')));
    expect(y('tool-chrono'), lessThan(y('tool-sight-height')));
  });

  testWidgets('no active profile: says so', (tester) async {
    await _pump(tester, null);
    expect(find.byKey(const Key('chrono-no-profile')), findsOneWidget);
    expect(find.byKey(const Key('chrono-velocities')), findsNothing);
  });

  testWidgets('a string gives mean, SD, ES and n; mean goes to the profile', (
    tester,
  ) async {
    final store = await _pump(tester, _firearm());
    // Every list box starts on "Seçiniz" (owner rule).
    expect(find.text('Seçiniz'), findsWidgets);
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '800\n805\n795');
    expect(find.byKey(const Key('chrono-result')), findsOneWidget);
    expect(_shows('800,0'), findsWidgets);
    expect(_shows('5,0'), findsWidgets);
    expect(_shows('10,0'), findsWidgets);
    expect(find.text('Atış sayısı'), findsOneWidget);

    await _tapConfirmed(tester, 'chrono-apply-velocity');
    expect(await _savedVelocity(store), closeTo(800, 1e-9));
  });

  testWidgets('fps entries reach the profile as the same speed', (
    tester,
  ) async {
    final store = await _pump(tester, _firearm());
    await chooseInSelect(tester, 'chrono-unit', 'fps');
    await _type(tester, 'chrono-velocities', '2625 2625 2625');
    await _tapConfirmed(tester, 'chrono-apply-velocity');
    expect(
      UnitSystem.mpsToFps(await _savedVelocity(store)),
      closeTo(2625, 0.2),
    );
  });

  testWidgets('velocities before a unit is chosen ask for the unit', (
    tester,
  ) async {
    await _pump(tester, _firearm());
    await _type(tester, 'chrono-velocities', '800 805 795');
    expect(find.byKey(const Key('chrono-need-unit')), findsOneWidget);
    expect(find.byKey(const Key('chrono-result')), findsNothing);
  });

  testWidgets('a bad line is named and nothing is offered', (tester) async {
    await _pump(tester, _firearm());
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '800\n8o5');
    expect(find.byKey(const Key('chrono-error')), findsOneWidget);
    expect(_shows('2. satır'), findsOneWidget);
    expect(find.byKey(const Key('chrono-apply-velocity')), findsNothing);
  });

  testWidgets('with a powder coefficient the mean is taken back to the '
      'reference temperature, and the cartridge temperature is required', (
    tester,
  ) async {
    final store = await _pump(tester, _firearm(coef: 1.5, refC: 20));
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '812 812 812');
    await tester.ensureVisible(find.byKey(const Key('chrono-apply-velocity')));
    await tester.tap(find.byKey(const Key('chrono-apply-velocity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chrono-confirm')), findsNothing);
    expect(find.byKey(const Key('chrono-error')), findsOneWidget);
    expect(await _savedVelocity(store), 800);

    await _type(tester, 'chrono-ammo-temp', '35');
    await _tapConfirmed(tester, 'chrono-apply-velocity');
    // 812 m/s at 35 °C with 1.5 %/15 °C is 800 m/s at 20 °C.
    expect(await _savedVelocity(store), closeTo(800, 0.05));
  });

  testWidgets('SD goes to WEZ in fps; other Pro values stay', (tester) async {
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor('p-ch'): jsonEncode(
        const ShotSettings(groupText: '2').toJson(),
      ),
    });
    await _pump(tester, _firearm());
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '800\n805\n795');
    await _tapConfirmed(tester, 'chrono-apply-sd');
    final saved = await const ShotSettingsStore().load('p-ch');
    expect(saved!.sdText, '16,4');
    expect(saved.groupText, '2');
  });

  testWidgets('PCP: no cartridge temperature or powder coefficient; the '
      'slope along the string is shown', (tester) async {
    await _pump(tester, _pcp);
    expect(find.byKey(const Key('chrono-ammo-temp')), findsNothing);
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '280 279 278 277 276');
    expect(find.text('Dizi eğimi'), findsOneWidget);
    expect(find.byKey(const Key('chrono-save-series')), findsNothing);
    expect(find.byKey(const Key('chrono-fit')), findsNothing);
  });

  testWidgets('PCP with En düşük | En yüksek: the mean is refused before '
      'the confirmation, nothing is written (feat/pcp-ortalama-hiz)', (
    tester,
  ) async {
    const pair = RifleProfile(
      id: 'p-pcp',
      name: 'PCP',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 270,
      pcpMinVelocityMps: 250,
      pcpMaxVelocityMps: 260,
      zeroRangeM: 25,
      sightHeightMm: 60,
    );
    final store = await _pump(tester, pair);
    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-velocities', '280 279 278 277 276');
    await tester.ensureVisible(find.byKey(const Key('chrono-apply-velocity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chrono-apply-velocity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chrono-confirm')), findsNothing);
    expect(find.textContaining('buradan tek bir hız yazılmaz'), findsOneWidget);
    final saved = (await store.all()).single;
    expect(saved.muzzleVelocityMps, 270);
    expect(saved.pcpMinVelocityMps, 250);
    expect(saved.pcpMaxVelocityMps, 260);
  });

  testWidgets('series at two temperatures give the powder coefficient', (
    tester,
  ) async {
    const chrono = ChronoStore();
    await chrono.add(
      'p-ch',
      ChronoSession(
        date: DateTime.utc(2026, 2, 3),
        tempC: 5,
        mps: const [790, 790, 790, 790, 790],
      ),
    );
    final store = await _pump(tester, _firearm());
    expect(find.byKey(const Key('chrono-fit')), findsNothing);

    await chooseInSelect(tester, 'chrono-unit', 'm/s');
    await _type(tester, 'chrono-ammo-temp', '35');
    await _type(tester, 'chrono-velocities', '814 814 814 814 814');
    await tester.ensureVisible(find.byKey(const Key('chrono-save-series')));
    await tester.tap(find.byKey(const Key('chrono-save-series')));
    await tester.pumpAndSettle();
    expect(await chrono.load('p-ch'), hasLength(2));
    expect(find.byKey(const Key('chrono-fit')), findsOneWidget);
    expect(_shows('1,5'), findsWidgets);

    await _tapConfirmed(tester, 'chrono-apply-coef');
    final p = (await store.all()).single;
    expect(p.powderTempCoefPercentPer15C, closeTo(1.5, 0.01));
    expect(p.powderTempReferenceC, closeTo(20, 1e-9));
    expect(p.muzzleVelocityMps, closeTo(802, 1e-9));
  });

  test('every ⓘ text is short Turkish with an example', () {
    for (final t in [
      ChronoFieldInfo.unit,
      ChronoFieldInfo.ammoTemperature,
      ChronoFieldInfo.velocities,
    ]) {
      expect(t, contains('Örnek'));
      expect(t.length, lessThan(400));
    }
  });
}
