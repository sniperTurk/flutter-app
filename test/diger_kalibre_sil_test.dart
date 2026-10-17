// Owner, 2026-10-17 17:48–17:52 (TestFlight 113, Profil Oluştur > Tüfek:
// Marka Heym, Model Express): "Diğer kalibre" under the model's calibers
// opened the whole caliber list; the owner chose "A": remove it. A caliber
// the model does not list is entered through "Aradığın tüfek listede yok
// mu?" (typed rifle, full list as before).
//
// Guards:
// - a catalog model shows exactly its own calibers, no "Diğer kalibre";
// - the typed rifle keeps its full caliber list exactly as before;
// - Marka chosen, Model still "Seçiniz": the full list as before;
// - an old profile saved with an off-model caliber (picked earlier through
//   "Diğer kalibre") opens with that caliber in the box, as the last list
//   entry, and Güncelle without edits keeps every calculation input;
// - 320 pt at text ×1.3: no overflow.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _heymCalibers = [
  '.375 H&H Mag',
  '.404 Jeffery',
  '.416 Rigby',
  '.450 Rigby',
  '.458 Lott',
];

Finder _key(String key) => find.byKey(Key(key));

Finder _in(String key, Finder f) => find.descendant(of: _key(key), matching: f);

MenzilSelect<String> _caliberSelect(WidgetTester tester) =>
    tester.widget<MenzilSelect<String>>(
      _in('rifle-caliber', find.byType(MenzilSelect<String>)),
    );

List<String?> _values(WidgetTester tester) => [
  for (final i in _caliberSelect(tester).items) i.value,
];

List<String?> _labels(WidgetTester tester) => [
  for (final i in _caliberSelect(tester).items)
    i.child is Text ? (i.child as Text).data : null,
];

void _setView(WidgetTester tester, {double width = 430, double scale = 1}) {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _openNew(
  WidgetTester tester, {
  bool firearm = true,
  double width = 430,
  double scale = 1,
}) async {
  _setView(tester, width: width, scale: scale);
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

Future<void> _chooseHeymExpress(WidgetTester tester) async {
  await chooseInSelect(tester, 'rifle-brand-select', 'Heym');
  await chooseInSelect(tester, 'rifle-model-select', 'Express');
}

/// The full firearm Kalibre list as it was before this change: the two
/// headers, every cartridge, "Fişeğim listede yok".
List<String> get _fullFirearmValues => [
  '#popular',
  for (final (i, (name, _)) in Cartridges.firearm.indexed) ...[
    if (i == Cartridges.popularCount) '#all',
    name,
  ],
  '!nodia',
];

// ---- Old profile saved through "Diğer kalibre" -----------------------------

/// Heym Express saved with .308 Win (7.82 mm), which the model does not
/// list: before 2026-10-17 it was picked through "Diğer kalibre".
const _offModelRifle = <String, dynamic>{
  'id': 'manual_rifle_heym_308',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Heym',
  'model': 'Express',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 12,
  'sourceName': 'Kullanıcı girdisi',
};

const _ammo = <String, dynamic>{
  'id': 'manual_ammo_heym_308',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
  'sourceName': 'Kullanıcı girdisi',
};

const _scope = <String, dynamic>{
  'id': 'manual_scope_heym_308',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Atölyem Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
};

RifleProfile _profile() => const ProfileCodec().decode({
  'id': 'p-heym-308',
  'name': 'Heym 308',
  'rifleId': 'manual_rifle_heym_308',
  'ammunitionId': 'manual_ammo_heym_308',
  'scopeId': 'manual_scope_heym_308',
  'muzzleVelocityMps': 807.72,
  'zeroRangeM': 100,
  'sightHeightMm': 50,
  'pressureVelocity': const <Map<String, double>>[],
  'angularUnit': 'mrad',
  'distanceUnit': 'meter',
});

void _seed() {
  final entries = [_offModelRifle, _ammo, _scope];
  SharedPreferences.setMockInitialValues({
    ManualCatalogStore.key: jsonEncode(entries),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      for (final e in entries) {...e},
    ]),
  );
}

/// Everything the calculation reads from the stored profile.
Map<String, Object?> _solverInputs(RifleProfile p) {
  final r = const ProfileCatalogIntegrity().resolve(p);
  expect(r, isNotNull, reason: 'profile ${p.id} no longer resolves');
  final rifle = r!.rifle, a = r.ammunition, s = r.scope;
  return {
    'platform': rifle.platform,
    'brand': rifle.brand,
    'model': rifle.model,
    'caliberMm': rifle.caliberMm,
    'twistRateIn': rifle.twistRateIn,
    'twistDirection': rifle.twistDirection,
    'muzzleVelocityMps': p.muzzleVelocityMps,
    'zeroRangeM': p.zeroRangeM,
    'sightHeightMm': p.sightHeightMm,
    'angularUnit': p.angularUnit,
    'distanceUnit': p.distanceUnit,
    'grain': a.grain,
    'bc': a.ballisticCoefficient,
    'bcModel': a.ballisticModel,
    'ammoCaliberMm': a.caliberMm,
    'click': s.clickValue,
    'clickUnit': s.clickUnit,
  };
}

Future<MemoryProfileStore> _openSaved(
  WidgetTester tester, {
  double width = 430,
  double scale = 1,
}) async {
  _seed();
  _setView(tester, width: width, scale: scale);
  final store = MemoryProfileStore();
  await store.save(_profile());
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Heym 308').first);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
  return store;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Heym Express: Kalibre lists only its 5 calibers', (
    tester,
  ) async {
    await _openNew(tester);
    await _chooseHeymExpress(tester);
    expect(selectedValue<String>(tester, 'rifle-caliber'), isNull);
    expect(_in('rifle-caliber', find.text('Seçiniz')), findsOneWidget);
    expect(_values(tester), ['v:0', 'v:1', 'v:2', 'v:3', 'v:4']);
    expect(_labels(tester), _heymCalibers);
    // Opened: the same 5 entries, no "Diğer kalibre".
    await tester.ensureVisible(_key('rifle-caliber'));
    await tester.tap(_key('rifle-caliber'));
    await tester.pumpAndSettle();
    final menuItems = find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
    );
    expect(menuItems, findsNWidgets(5));
    for (final c in _heymCalibers) {
      expect(
        find.descendant(of: menuItems, matching: find.text(c)),
        findsOneWidget,
      );
    }
    expect(find.text('Diğer kalibre'), findsNothing);
    await tester.tap(
      find.descendant(of: menuItems, matching: find.text('.416 Rigby')),
    );
    await tester.pumpAndSettle();
    expect(selectedValue<String>(tester, 'rifle-caliber'), 'v:2');
    expect(_values(tester), ['v:0', 'v:1', 'v:2', 'v:3', 'v:4']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed rifle: the full caliber list is unchanged', (
    tester,
  ) async {
    await _openNew(tester);
    await openRifleManual(tester);
    expect(_values(tester), _fullFirearmValues);
    expect(_labels(tester), isNot(contains('Diğer kalibre')));
  });

  testWidgets('typed PCP rifle: the full PCP caliber list is unchanged', (
    tester,
  ) async {
    await _openNew(tester, firearm: false);
    await openRifleManual(tester);
    expect(_labels(tester), [for (final (_, name) in Cartridges.pcp) name]);
  });

  testWidgets('Marka chosen, Model "Seçiniz": the full list as before', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'rifle-brand-select', 'Heym');
    expect(selectedValue<String>(tester, 'rifle-model-select'), isNull);
    expect(_values(tester), _fullFirearmValues);
  });

  testWidgets('old profile with an off-model caliber opens unchanged; '
      'Güncelle keeps it', (tester) async {
    _seed();
    final before = _solverInputs(_profile());
    final store = await _openSaved(tester);
    expect(selectedValue<String>(tester, 'rifle-brand-select'), 'Heym');
    expect(selectedValue<String>(tester, 'rifle-model-select'), 'Express');
    // The saved caliber is the box's value and the last list entry, under
    // the model's own calibers; nothing else is added.
    expect(selectedValue<String>(tester, 'rifle-caliber'), '!saved');
    expect(_in('rifle-caliber', find.text('.308 Win')), findsWidgets);
    expect(_labels(tester), [..._heymCalibers, '.308 Win']);
    expect(_labels(tester), isNot(contains('Diğer kalibre')));
    // Picking the saved entry again changes nothing.
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    expect(selectedValue<String>(tester, 'rifle-caliber'), '!saved');
    final button = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    await tester.ensureVisible(button);
    expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsNothing);
    final saved = (await store.all()).single;
    expect(_solverInputs(saved), before);
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in [(320.0, 1.3), (390.0, 1.0)]) {
    testWidgets('no overflow at $width pt, text ×$scale', (tester) async {
      await _openNew(tester, width: width, scale: scale);
      await _chooseHeymExpress(tester);
      await tester.ensureVisible(_key('rifle-caliber'));
      await tester.tap(_key('rifle-caliber'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('.458 Lott').last);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'rifle-caliber'), 'v:4');
      expect(tester.takeException(), isNull);
    });

    testWidgets('old profile at $width pt, text ×$scale: no overflow', (
      tester,
    ) async {
      await _openSaved(tester, width: width, scale: scale);
      expect(selectedValue<String>(tester, 'rifle-caliber'), '!saved');
      await tester.ensureVisible(_key('rifle-caliber'));
      await tester.tap(_key('rifle-caliber'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
