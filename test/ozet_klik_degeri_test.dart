// Profil summary, Dürbün card (owner, 2026-10-17 18:18: Klik değeri
// "ekle"): the click the calculation uses is the card's last metric, after
// Dürbün üst kule, in the Profil editor's Klik değeri label format
// ("0,1 MRAD", "1/4 MOA"). Same click as Hedef's turret.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

/// Arken EP-5 5-25x56 FFP MOA: a catalog scope with 1/4 MOA clicks.
const _arkenMoa = 'lib-arken-optics-ep-5-5-25x56-ffp-moa';

const _fxRifle = <String, dynamic>{
  'id': 'manual_rifle_kd',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'manual_ammo_kd',
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

/// A typed ("Listede yok") scope with 0,05 MRAD clicks.
const _typedScope = <String, dynamic>{
  'id': 'manual_scope_kd',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'GaziSniper',
  'model': '6-36x56 FFP',
  'objectiveMm': 56,
  'click': 0.05,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 6,
  'maxMag': 36,
  'elevationRangeMrad': 26,
};

/// PCP: Hatsan Hercules .25 with the catalog Gazi Sniper 6-36 (0.1 MRAD).
const _pcpMrad = RifleProfile(
  id: 'p-kd-pcp',
  name: 'PCP MRAD',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// Firearm with the catalog Arken MOA scope (1/4 MOA).
const _fxMoa = RifleProfile(
  id: 'p-kd-fx',
  name: 'Ateşli MOA',
  rifleId: 'manual_rifle_kd',
  ammunitionId: 'manual_ammo_kd',
  scopeId: _arkenMoa,
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  angularUnit: AngularUnit.moa,
);

/// PCP with the typed 0,05 MRAD scope.
const _pcpTyped = RifleProfile(
  id: 'p-kd-typed',
  name: 'PCP elle',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'manual_scope_kd',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// MOA profile on the MRAD catalog scope: Hedef uses the standard ¼ MOA
/// click (units differ), so the card shows it too.
const _pcpMoaOnMrad = RifleProfile(
  id: 'p-kd-mix',
  name: 'PCP MOA',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _scopeCard = Key('profile-summary-scope');

Future<void> _profil(
  WidgetTester tester,
  RifleProfile profile, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = profile.id,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Click of the Hedef turret for [profile] (ScopeDialView.clickValue).
Future<double> _hedefClick(WidgetTester tester, RifleProfile profile) async {
  tester.view.physicalSize = const Size(390, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<ScopeDialView>(find.byType(ScopeDialView)).clickValue;
}

/// Checks that "Klik değeri" shows [value] and is the card's last metric:
/// after Dürbün üst kule, and no text of the card below or to the right
/// of its value in the last row.
void _expectLastClick(WidgetTester tester, String value) {
  final card = find.byKey(_scopeCard);
  expect(card, findsOneWidget);
  final label = find.descendant(of: card, matching: find.text('Klik değeri'));
  final shown = find.descendant(of: card, matching: find.text(value));
  expect(label, findsOneWidget);
  expect(shown, findsOneWidget, reason: value);

  final labelAt = tester.getTopLeft(label);
  final valueAt = tester.getTopLeft(shown);
  // The value sits under its own label, in the same box.
  expect(valueAt.dy, greaterThan(labelAt.dy));
  expect((valueAt.dx - labelAt.dx).abs(), lessThan(0.5));

  // After Dürbün üst kule in reading order (two columns, row by row).
  final kule = tester.getTopLeft(
    find.descendant(of: card, matching: find.text('Dürbün üst kule')),
  );
  final sameRow = (kule.dy - labelAt.dy).abs() < 0.5;
  expect(sameRow ? labelAt.dx > kule.dx : labelAt.dy > kule.dy, isTrue);

  // Nothing of the card comes after it.
  final texts = find.descendant(of: card, matching: find.byType(RichText));
  for (final e in texts.evaluate()) {
    final text = e.widget as RichText;
    final at = tester.getTopLeft(find.byWidget(text));
    final belowValue = at.dy > valueAt.dy + 0.5;
    final rightOfValue =
        (at.dy - valueAt.dy).abs() <= 0.5 && at.dx > valueAt.dx + 0.5;
    final rightOfLabel =
        (at.dy - labelAt.dy).abs() <= 0.5 && at.dx > labelAt.dx + 0.5;
    final name = text.text.toPlainText();
    expect(
      belowValue || rightOfValue || rightOfLabel,
      isFalse,
      reason: '"$name" after Klik değeri',
    );
  }
}

void main() {
  // The Profil page reloads personal records from ManualCatalogStore, so
  // they are saved there too (an empty store would drop them).
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = ManualCatalogStore();
    for (final e in const [_fxRifle, _fxAmmo, _typedScope]) {
      await store.upsert(e);
    }
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_fxRifle, _fxAmmo, _typedScope]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final (name, profile, label, click) in const [
    ('PCP, catalog MRAD 0.1', _pcpMrad, '0,1 MRAD', 0.1),
    ('firearm, catalog MOA 1/4', _fxMoa, '1/4 MOA', 0.25),
    ('PCP, typed 0,05 MRAD', _pcpTyped, '0,05 MRAD', 0.05),
    ('MOA profile on a MRAD catalog scope', _pcpMoaOnMrad, '1/4 MOA', 0.25),
  ]) {
    testWidgets('$name: Klik değeri "$label", last, same click as Hedef', (
      tester,
    ) async {
      await _profil(tester, profile);
      expect(tester.takeException(), isNull);
      _expectLastClick(tester, label);

      final hedef = await _hedefClick(tester, profile);
      expect(hedef, click, reason: 'Hedef click for $name');
    });
  }

  for (final profile in const [_pcpMrad, _fxMoa, _pcpTyped]) {
    testWidgets('${profile.name}: 320 pt, text ×1.3, no overflow', (
      tester,
    ) async {
      await _profil(tester, profile, width: 320, scale: 1.3);
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byKey(_scopeCard));
      expect(card.right, lessThanOrEqualTo(320 + 0.01));
      final label = find.descendant(
        of: find.byKey(_scopeCard),
        matching: find.text('Klik değeri'),
      );
      expect(label, findsOneWidget);
      expect(tester.getRect(label).right, lessThanOrEqualTo(card.right + 0.01));
    });
  }
}
