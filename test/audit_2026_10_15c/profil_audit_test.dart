// Pre-TestFlight audit 2026-10-15c, area PROFIL (main e7b29bf).
//
// #327 (28bbe43) Tür keeps the chosen Kalibre (PRF-7, PRF-8): checked for
//   EVERY caliber the user can reach, in both orders (Tür → Kalibre and
//   Kalibre → Tür): Marka | Model variants (every firearm cartridge and
//   every PCP diameter of lib/data/rifle_library.dart), Fabrika fişeği
//   before Kalibre (every cartridge of factory_ammo_library.dart), El dolumu
//   before Kalibre (every firearm diameter of bullet_library.dart), "Fişeğim
//   listede yok" (every Mermi çapı) and the PCP Kalibre list. The Kalibre
//   list itself (168 cartridges × 2 orders) is test/prf7_tur_kalibre_test.
//   Stored caliber -> solver: every listed rifle variant and factory round
//   carries its cartridge's Kalibre diameter, and one full new profile
//   (.300 Win Mag, Tür last) is saved and resolved.
// #329 (9104632) summary line on each profile card: compared with the
//   saved profile (m / yd, fps, BC + model, old profile without units,
//   MOA / MRAD, BC bands, PCP without BC). Hand values:
//   tools/denetim_2026_10_15c_profil.py.
//
// Findings:
//   PRF-11 (medium): the cartridge name is not saved (the rifle record keeps
//     caliberMm only). Profili Düzenle infers it by diameter (and twist for
//     a listed rifle): Anschütz 1782 Classic .300 Win Mag comes back as
//     .30-06 Springfield, the saved Fabrika round is not in its Model list
//     ("Seçiniz"), and BC modeli G1 -> G7 then keeps the G1 number 0.425
//     (the MUH-1 guard cannot find the round). A typed rifle comes back as
//     the first cartridge of its diameter (.300 Win Mag -> .308 Win).
//     Güncelle without touching keeps every number.         [3 skipped tests]
//   PRF-12 (low): a custom drag curve stores the sectional density as "bc"
//     with "bcModel: g1"; the card summary shows "BC 0,2637508912160438 G1"
//     for a 175 gr 7,82 mm bullet. Display only.             [skipped test]
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/bullet_library.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/rifle_library.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

// ---- Pumping and list boxes (as test/prf7_tur_kalibre_test.dart) ----------

Future<MemoryProfileStore> _pumpList(
  WidgetTester tester, [
  List<RifleProfile> profiles = const [],
]) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _openNew(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

MenzilSelect<T> _select<T>(WidgetTester tester, String key) =>
    tester.widget<MenzilSelect<T>>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(MenzilSelect<T>),
        matchRoot: true,
      ),
    );

/// Picks [value] in the list box under [key], as a tap on its item does.
Future<void> _pick<T>(WidgetTester tester, String key, T value) async {
  final select = _select<T>(tester, key);
  expect(
    select.items.any((i) => i.value == value && i.enabled),
    isTrue,
    reason: '"$value" is not a choice of $key',
  );
  select.onChanged!(value);
  await tester.pumpAndSettle();
}

Future<void> _pickTur(WidgetTester tester, WeaponPlatform p) =>
    _pick<WeaponPlatform>(tester, 'profile-platform', p);

/// The text the closed Kalibre box shows for its current choice.
String? _shownCaliber(WidgetTester tester) {
  final value = selectedValue<String>(tester, 'rifle-caliber');
  if (value == null) {
    return null;
  }
  final select = _select<String>(tester, 'rifle-caliber');
  final i = select.items.indexWhere((e) => e.value == value);
  return i < 0 ? null : select.selectedLabels![i];
}

bool _showsCartridge(String? shown, String name) =>
    shown == name || (shown?.startsWith('$name · ') ?? false);

/// The factory rounds the Fabrika fişeği lists show, by brand.
Future<Map<String, int>> _factoryListed(WidgetTester tester) async {
  final out = <String, int>{};
  final brands = [
    for (final i in _select<String>(tester, 'ammo-brand-select').items)
      if (i.value != null && !i.value!.startsWith('!')) i.value!,
  ];
  for (final b in brands) {
    await _pick<String>(tester, 'ammo-brand-select', b);
    out[b] = _select<int>(tester, 'ammo-model-select').items.length;
  }
  return out;
}

Map<String, int> _factoryExpected(String cartridge) {
  final out = <String, int>{};
  for (final a in FactoryAmmoLibrary.all) {
    if (a.cartridge == cartridge) {
      out[a.brand] = (out[a.brand] ?? 0) + 1;
    }
  }
  return out;
}

/// _trimDot of the editor: 8.0 -> "8", 8.15 -> "8.15".
String _trimDot(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

/// The Kalibre key a diameter without a cartridge name shows: the first
/// cartridge of that diameter, else "mm:<value>" ("(kayıtlı)").
String _keyForDiameter(double mm) {
  for (final (name, d) in Cartridges.firearm) {
    if ((d - mm).abs() < 0.005) {
      return name;
    }
  }
  return 'mm:${_trimDot(mm)}';
}

/// One listed rifle per firearm cartridge / per PCP diameter.
List<LibraryRifle> _oneRiflePer(WeaponPlatform platform) {
  final seen = <String>{};
  return [
    for (final r in RifleLibrary.all)
      if (r.platform == platform &&
          seen.add(
            platform == WeaponPlatform.firearm
                ? r.cartridge
                : _trimDot(r.diameterMm),
          ))
        r,
  ];
}

/// Marka, Model and the variant of [r], from the lists.
Future<void> _pickListedRifle(WidgetTester tester, LibraryRifle r) async {
  await _pick<String>(tester, 'rifle-brand-select', r.brand);
  await _pick<String>(tester, 'rifle-model-select', r.model);
  final variants = [
    for (final x in RifleLibrary.all)
      if (x.platform == r.platform && x.brand == r.brand && x.model == r.model)
        x,
  ];
  await _pick<String>(tester, 'rifle-caliber', 'v:${variants.indexOf(r)}');
}

// ---- Saved records (ManualCatalogStore JSON, as the app stores them) -------

/// The first listed .300 Win Mag factory round with a maker BC and model
/// (Aguila 180 gr SP, 0.425 G1, no G7 figure).
final FactoryAmmo _round300 = FactoryAmmoLibrary.all.firstWhere(
  (a) => a.cartridge == '.300 Win Mag' && a.bc != null && a.model != null,
);

Map<String, dynamic> _ammo300() => <String, dynamic>{
  'id': 'manual_ammo_d15c_300',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': _round300.brand,
  'model': _round300.name,
  'caliberMm': 7.82,
  'grain': _round300.grain,
  'ammoType': 'bullet',
  'bc': _round300.bc,
  'bcModel': _round300.model!.name,
};

/// Typed rifle (Kalibre .300 Win Mag was picked; 7.82 mm is saved).
const _typedRifle300 = <String, dynamic>{
  'id': 'manual_rifle_d15c_typed',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Özel',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

/// Listed rifle: Anschütz 1782 Classic, variant .300 Win Mag (1:10). The
/// same model has .30-06 Springfield, also 7.82 mm and 1:10, listed first.
const _listedRifle300 = <String, dynamic>{
  'id': 'manual_rifle_d15c_listed',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Anschütz',
  'model': '1782 Classic',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

const _typedScope = <String, dynamic>{
  'id': 'manual_scope_d15c',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Eski Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
};

const _typedAmmoG1 = <String, dynamic>{
  'id': 'manual_ammo_d15c_g1',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
  'bcBands': [
    {'mps': 700.0, 'bc': 0.475},
    {'mps': 0.0, 'bc': 0.44},
  ],
};

/// 175 gr, 7.82 mm: SD = 175 / 7000 / (7.82 / 25.4)^2 lb/in² (what the
/// editor writes as "bc" next to a custom curve).
const double _sd175 = 175 / 7000 / ((7.82 / 25.4) * (7.82 / 25.4));

const _curveAmmo = <String, dynamic>{
  'id': 'manual_ammo_d15c_curve',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eğrili Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': _sd175,
  'bcModel': 'g1',
  'dragCurve': [
    [0.5, 0.235],
    [0.8, 0.24],
    [1.0, 0.38],
    [1.2, 0.36],
    [2.0, 0.29],
  ],
};

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_d15c_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölyem',
  'model': 'PCP',
  'caliberMm': 6.35,
  'twistDirection': 'right',
  'twistRateIn': 17,
};

/// PCP slug saved without a BC (G1 kept as the chosen model only).
const _pcpSlugNoBc = <String, dynamic>{
  'id': 'manual_ammo_d15c_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Özel yapım',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bcModel': 'g1',
};

/// Records in the store the editor writes to AND in the live catalog.
void _seed(List<Map<String, dynamic>> entries) {
  SharedPreferences.setMockInitialValues({
    ManualCatalogStore.key: jsonEncode(entries),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      for (final e in entries) {...e},
    ]),
  );
}

/// A saved profile as JSON; [units] false: an old profile without
/// angularUnit / distanceUnit (metres, MRAD).
RifleProfile _profile({
  required String id,
  required String name,
  required String rifleId,
  required String ammoId,
  String scopeId = 'manual_scope_d15c',
  double velocityMps = 822.96, // 2700 fps
  double zeroM = 100,
  String? angularUnit = 'mrad',
  String? distanceUnit = 'meter',
}) => const ProfileCodec().decode({
  'id': id,
  'name': name,
  'rifleId': rifleId,
  'ammunitionId': ammoId,
  'scopeId': scopeId,
  'muzzleVelocityMps': velocityMps,
  'zeroRangeM': zeroM,
  'sightHeightMm': 45.0,
  if (angularUnit != null) 'angularUnit': angularUnit,
  if (distanceUnit != null) 'distanceUnit': distanceUnit,
  'mountCantMoa': 0.0,
});

/// What the solver reads from a saved profile (ProfileCatalogIntegrity).
Map<String, Object?> _solverInputs(RifleProfile p) {
  final r = const ProfileCatalogIntegrity().resolve(p);
  expect(r, isNotNull, reason: 'profile ${p.id} does not resolve');
  return {
    'muzzleVelocityMps': p.muzzleVelocityMps,
    'zeroRangeM': p.zeroRangeM,
    'sightHeightMm': p.sightHeightMm,
    'angularUnit': p.angularUnit,
    'distanceUnit': p.distanceUnit,
    'caliberMm': r!.rifle.caliberMm,
    'ammoCaliberMm': r.ammunition.caliberMm,
    'twistRateIn': r.rifle.twistRateIn,
    'twistDirection': r.rifle.twistDirection,
    'grain': r.ammunition.grain,
    'bc': r.ammunition.ballisticCoefficient,
    'bcModel': r.ammunition.ballisticModel,
    'clickValue': r.scope.clickValue,
    'clickUnit': r.scope.clickUnit,
  };
}

String _missingText(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

/// Presses Kaydet / Güncelle and expects the editor to close.
Future<void> _press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MenzilPrimaryButton, label);
  expect(
    tester.widget<MenzilPrimaryButton>(button).onPressed,
    isNotNull,
    reason: _missingText(tester),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('Profili Düzenle'), findsNothing);
  expect(find.text('Profil Oluştur'), findsNothing);
}

/// Every box of a new firearm profile except Tür (as
/// test/audit_2026_10_15b/profil_split_audit_test.dart), Kalibre [caliber].
Future<void> _fillAllButTur(WidgetTester tester, String caliber) async {
  await openRifleManual(tester);
  await enterRifleField(tester, 'rifle-brand', 'Test Marka');
  await enterRifleField(tester, 'rifle-model', 'Test Model');
  await chooseInSelect(tester, 'rifle-caliber', caliber);
  await enterRifleField(tester, 'rifle-twist-rate', '10');
  await chooseTwistDirection(tester, 'Sağ');
  await fillScopeForm(tester);
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await openAmmoManual(tester);
  await chooseInSelect(tester, 'ammo-brand-pick', 'Diğer');
  await enterRifleField(tester, 'ammo-brand', 'Atölye Fişek');
  await enterRifleField(tester, 'ammo-model', 'Özel 1');
  await chooseInSelect(tester, 'ammo-grain-select', 'Listede yok');
  await enterRifleField(tester, 'ammo-grain', '173');
  await enterRifleField(tester, 'ammo-bc', '0,5');
  await chooseInSelect(tester, 'ammo-bc-model', 'G7');
  await chooseInSelect(tester, 'profile-powder-coef', '1,5');
  await chooseInSelect(tester, 'profile-powder-temp', '21');
  await enterRifleField(tester, 'profile-velocity-fps', '2650');
  await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
  await enterRifleField(tester, 'profile-zero', '100');
  await enterRifleField(tester, 'scope-sight-height', '45');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  // ---- #327: stored caliber -> solver diameter on every path -------------

  group('#327 data: every list path stores the chosen caliber\'s diameter', () {
    test('every listed rifle variant carries its Kalibre diameter', () {
      for (final r in RifleLibrary.all) {
        final what = '${r.brand} ${r.model} ${r.cartridge}';
        if (r.platform == WeaponPlatform.firearm) {
          final d = Cartridges.diameterOf(r.cartridge);
          expect(d, isNotNull, reason: what);
          expect((d! - r.diameterMm).abs(), lessThan(0.005), reason: what);
        } else {
          expect(
            Cartridges.pcp.any((e) => (e.$1 - r.diameterMm).abs() < 0.005),
            isTrue,
            reason: what,
          );
        }
      }
    });

    test('every factory round carries its Kalibre diameter', () {
      for (final a in FactoryAmmoLibrary.all) {
        final d = Cartridges.diameterOf(a.cartridge);
        final what = '${a.brand} ${a.name}';
        expect(d, isNotNull, reason: what);
        expect((d! - a.diameterMm).abs(), lessThan(0.005), reason: what);
      }
    });

    test('no PCP Kalibre is a firearm diameter (a changed Tür empties it)', () {
      for (final (mm, label) in Cartridges.pcp) {
        for (final (name, d) in Cartridges.firearm) {
          expect(
            (mm - d).abs(),
            greaterThanOrEqualTo(0.005),
            reason: '$label $name',
          );
        }
      }
    });
  });

  // ---- #327: Marka | Model variants, both orders -------------------------

  for (final tureFirst in const [true, false]) {
    final order = tureFirst ? 'Tür → Marka/Model' : 'Marka/Model → Tür';
    group('$order keeps the variant\'s cartridge and its ammunition', () {
      for (final r in _oneRiflePer(WeaponPlatform.firearm)) {
        testWidgets('${r.cartridge} (${r.brand} ${r.model})', (tester) async {
          await _pumpList(tester);
          await _openNew(tester);
          if (tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          await _pickListedRifle(tester, r);
          final key = selectedValue<String>(tester, 'rifle-caliber');
          expect(_showsCartridge(_shownCaliber(tester), r.cartridge), isTrue);
          if (!tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          expect(selectedValue<String>(tester, 'rifle-caliber'), key);
          expect(
            _showsCartridge(_shownCaliber(tester), r.cartridge),
            isTrue,
            reason: 'Kalibre now "${_shownCaliber(tester)}"',
          );
          await _pick<bool>(tester, 'ammo-source', true); // Fabrika fişeği
          final expected = _factoryExpected(r.cartridge);
          if (expected.isEmpty) {
            expect(find.byKey(const Key('ammo-brand-select')), findsNothing);
            expect(find.byKey(const Key('ammo-brand-pick')), findsOneWidget);
          } else {
            expect(await _factoryListed(tester), expected);
          }
          expect(selectedValue<String>(tester, 'rifle-caliber'), key);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  group('PCP Tür → Marka/Model → Tür again keeps the variant', () {
    for (final r in _oneRiflePer(WeaponPlatform.pcp)) {
      testWidgets('${r.cartridge} (${r.brand} ${r.model})', (tester) async {
        await _pumpList(tester);
        await _openNew(tester);
        await _pickTur(tester, WeaponPlatform.pcp);
        await _pickListedRifle(tester, r);
        final key = selectedValue<String>(tester, 'rifle-caliber');
        expect(_showsCartridge(_shownCaliber(tester), r.cartridge), isTrue);
        await _pickTur(tester, WeaponPlatform.pcp);
        expect(selectedValue<String>(tester, 'rifle-caliber'), key);
        expect(_showsCartridge(_shownCaliber(tester), r.cartridge), isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ---- #327: Fabrika fişeği / El dolumu picked before Kalibre ------------

  final factoryCartridges = <String>{
    for (final a in FactoryAmmoLibrary.all) a.cartridge,
  }.toList();
  for (final tureFirst in const [true, false]) {
    final order = tureFirst ? 'Tür → Fabrika fişeği' : 'Fabrika fişeği → Tür';
    group('$order: the round\'s cartridge is the Kalibre and stays', () {
      for (final cartridge in factoryCartridges) {
        testWidgets(cartridge, (tester) async {
          final a = FactoryAmmoLibrary.all.firstWhere(
            (x) => x.cartridge == cartridge,
          );
          final ofBrand = [
            for (final x in FactoryAmmoLibrary.all)
              if (x.brand == a.brand) x,
          ];
          await _pumpList(tester);
          await _openNew(tester);
          if (tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          await _pick<bool>(tester, 'ammo-source', true);
          await _pick<String>(tester, 'ammo-brand-select', a.brand);
          await _pick<int>(tester, 'ammo-model-select', ofBrand.indexOf(a));
          expect(selectedValue<String>(tester, 'rifle-caliber'), cartridge);
          if (!tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          expect(selectedValue<String>(tester, 'rifle-caliber'), cartridge);
          expect(selectedValue<String>(tester, 'ammo-brand-select'), a.brand);
          expect(selectedValue<int>(tester, 'ammo-model-select'), isNotNull);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  final bulletCalibers = <double>{
    for (final b in BulletLibrary.all)
      if (b.platform == WeaponPlatform.firearm) b.caliberMm,
  }.toList();
  for (final tureFirst in const [true, false]) {
    final order = tureFirst ? 'Tür → El dolumu' : 'El dolumu → Tür';
    group('$order: the bullet\'s diameter is the Kalibre and stays', () {
      for (final cal in bulletCalibers) {
        testWidgets('${_trimDot(cal)} mm', (tester) async {
          final b = BulletLibrary.all.firstWhere(
            (x) => x.platform == WeaponPlatform.firearm && x.caliberMm == cal,
          );
          final ofBrand = [
            for (final x in BulletLibrary.all)
              if (x.platform == WeaponPlatform.firearm && x.brand == b.brand)
                x,
          ];
          await _pumpList(tester);
          await _openNew(tester);
          if (tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          await _pick<bool>(tester, 'ammo-source', false); // El dolumu
          await _pick<String>(tester, 'ammo-brand-select', b.brand);
          await _pick<int>(tester, 'ammo-model-select', ofBrand.indexOf(b));
          final key = _keyForDiameter(cal);
          expect(selectedValue<String>(tester, 'rifle-caliber'), key);
          if (!tureFirst) {
            await _pickTur(tester, WeaponPlatform.firearm);
          }
          expect(selectedValue<String>(tester, 'rifle-caliber'), key);
          expect(selectedValue<int>(tester, 'ammo-model-select'), isNotNull);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  testWidgets('Fişeğim listede yok: every Mermi çapı stays when Tür is '
      'picked', (tester) async {
    await _pumpList(tester);
    await _openNew(tester);
    await _pick<String>(tester, 'rifle-caliber', '!nodia');
    final diameters = [
      for (final i in _select<double>(tester, 'rifle-bullet-diameter').items)
        i.value!,
    ];
    expect(diameters.length, greaterThan(30));
    for (final d in diameters) {
      await _pick<double>(tester, 'rifle-bullet-diameter', d);
      await _pickTur(tester, WeaponPlatform.firearm);
      expect(selectedValue<String>(tester, 'rifle-caliber'), '!nodia');
      expect(
        selectedValue<double>(tester, 'rifle-bullet-diameter'),
        d,
        reason: '$d mm',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('PCP: every Kalibre stays when Tür PCP is picked again', (
    tester,
  ) async {
    await _pumpList(tester);
    await _openNew(tester);
    await _pickTur(tester, WeaponPlatform.pcp);
    for (final (mm, label) in Cartridges.pcp) {
      final key = 'mm:${_trimDot(mm)}';
      await _pick<String>(tester, 'rifle-caliber', key);
      await _pickTur(tester, WeaponPlatform.pcp);
      expect(
        selectedValue<String>(tester, 'rifle-caliber'),
        key,
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
  });

  // ---- User input -> saved -> solver -> card summary (#327 + #329) -------

  testWidgets('new profile: Kalibre .300 Win Mag, Tür last, saved -> solver '
      '7,82 mm and the card line matches', (tester) async {
    final store = await _pumpList(tester);
    await _openNew(tester);
    await _fillAllButTur(tester, '.300 Win Mag');
    await _pickTur(tester, WeaponPlatform.firearm);
    expect(selectedValue<String>(tester, 'rifle-caliber'), '.300 Win Mag');
    expect(_missingText(tester), isEmpty);
    await _press(tester, 'Kaydet');

    final saved = (await store.all()).single;
    final inputs = _solverInputs(saved);
    expect(inputs['caliberMm'], 7.82);
    expect(inputs['ammoCaliberMm'], 7.82);
    expect(inputs['twistRateIn'], 10);
    expect(inputs['grain'], 173);
    expect(inputs['bc'], 0.5);
    expect(inputs['bcModel'], BallisticModel.g7);
    // 2650 fps * 0.3048 = 807.72 m/s; 100 yd * 0.9144 = 91.44 m.
    expect(saved.muzzleVelocityMps, closeTo(807.72, 1e-9));
    expect(saved.zeroRangeM, closeTo(91.44, 1e-9));
    const line = '7,82 mm, sıfır 100,0 yd, 2650 fps, BC 0,5 G7';
    expect(profileListSummary(saved), line);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-row-summary'))).data,
      line,
    );
  });

  // ---- #329 summary line vs the saved profile ----------------------------

  group('#329 summary line matches the saved profile', () {
    test('old profile without units: metres; MOA and MRAD give the same '
        'line; BC bands: the main BC', () {
      _seed([_typedRifle300, _typedAmmoG1, _typedScope]);
      final old = _profile(
        id: 'old',
        name: 'Eski',
        rifleId: 'manual_rifle_d15c_typed',
        ammoId: 'manual_ammo_d15c_g1',
        angularUnit: null,
        distanceUnit: null,
      );
      expect(old.distanceUnit, DistanceUnit.meter);
      expect(old.angularUnit, AngularUnit.mrad);
      const line = '7,82 mm, sıfır 100 m, 2700 fps, BC 0,475 G1';
      expect(profileListSummary(old), line);
      final moa = _profile(
        id: 'moa',
        name: 'MOA',
        rifleId: 'manual_rifle_d15c_typed',
        ammoId: 'manual_ammo_d15c_g1',
        angularUnit: 'moa',
      );
      expect(profileListSummary(moa), line);
      // The solver reads the same caliber and main BC the line shows.
      final inputs = _solverInputs(old);
      expect(inputs['caliberMm'], 7.82);
      expect(inputs['bc'], 0.475);
    });

    test('yard: 274,32 m is "300,0 yd"; 800 m/s is 2625 fps', () {
      _seed([_typedRifle300, _typedAmmoG1, _typedScope]);
      final p = _profile(
        id: 'yd',
        name: 'Yard',
        rifleId: 'manual_rifle_d15c_typed',
        ammoId: 'manual_ammo_d15c_g1',
        velocityMps: 800,
        zeroM: 274.32,
        distanceUnit: 'yard',
      );
      expect(
        profileListSummary(p),
        '7,82 mm, sıfır 300,0 yd, 2625 fps, BC 0,475 G1',
      );
    });

    test('PCP slug saved without BC: no BC part', () {
      _seed([_pcpRifle, _pcpSlugNoBc, _typedScope]);
      final p = _profile(
        id: 'pcp',
        name: 'PCP',
        rifleId: 'manual_rifle_d15c_pcp',
        ammoId: 'manual_ammo_d15c_pcp',
        velocityMps: 274.32, // 900 fps
        zeroM: 25,
      );
      expect(profileListSummary(p), '6,35 mm, sıfır 25 m, 900 fps');
    });

    test('PRF-12: a custom drag curve is not shown as "BC <sectional '
        'density> G1"', () {
      _seed([_typedRifle300, _curveAmmo, _typedScope]);
      final p = _profile(
        id: 'curve',
        name: 'Eğri',
        rifleId: 'manual_rifle_d15c_typed',
        ammoId: 'manual_ammo_d15c_curve',
      );
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == 'manual_ammo_d15c_curve',
      );
      // The solver uses the curve; "bc" is the SD (0.26375 lb/in²).
      expect(a.dragCurve, isNotNull);
      expect(a.ballisticCoefficient, closeTo(0.2637508912, 1e-9));
      final s = profileListSummary(p);
      expect(s, startsWith('7,82 mm, sıfır 100 m, 2700 fps'));
      expect(s, isNot(contains(_sd175.toString().replaceAll('.', ','))));
      expect(s, isNot(contains('G1')));
    }, skip: 'PRF-12: the card shows the curve\'s sectional density as BC G1');
  });

  // ---- PRF-11: Profili Düzenle forgets the chosen cartridge --------------

  group('PRF-11: Profili Düzenle of a .300 Win Mag profile', () {
    RifleProfile seeded(String rifleId, Map<String, dynamic> rifle) {
      _seed([rifle, _ammo300(), _typedScope]);
      return _profile(
        id: 'd15c-$rifleId',
        name: 'Profil 300',
        rifleId: rifleId,
        ammoId: 'manual_ammo_d15c_300',
        velocityMps: 899.16, // 2950 fps
      );
    }

    test('precondition: the saved round is G1 with no maker G7 BC', () {
      expect(_round300.cartridge, '.300 Win Mag');
      expect(_round300.model, BallisticModel.g1);
      expect(_round300.bcG7, isNull);
      // Anschütz 1782 Classic lists .30-06 Springfield (7.82 mm, 1:10)
      // before .300 Win Mag (7.82 mm, 1:10).
      final v = [
        for (final r in RifleLibrary.all)
          if (r.brand == 'Anschütz' && r.model == '1782 Classic') r,
      ];
      final i3006 = v.indexWhere((r) => r.cartridge == '.30-06 Springfield');
      final i300 = v.indexWhere((r) => r.cartridge == '.300 Win Mag');
      expect(i3006, greaterThanOrEqualTo(0));
      expect(i3006, lessThan(i300));
      expect(v[i3006].diameterMm, v[i300].diameterMm);
      expect(v[i3006].twistRateIn, v[i300].twistRateIn);
    });

    testWidgets('typed rifle: Kalibre comes back as .300 Win Mag', (
      tester,
    ) async {
      final p = seeded('manual_rifle_d15c_typed', _typedRifle300);
      await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      // Today: ".308 Win" (the first 7.82 mm cartridge).
      expect(selectedValue<String>(tester, 'rifle-caliber'), '.300 Win Mag');
    }, skip: true); // PRF-11: cartridge not saved, reloaded by diameter

    testWidgets('listed rifle: the .300 Win Mag variant and the saved round '
        'come back', (tester) async {
      final p = seeded('manual_rifle_d15c_listed', _listedRifle300);
      await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(find.byKey(const Key('rifle-brand-select')), findsOneWidget);
      // Today: ".30-06 Springfield · …" and Model "Seçiniz".
      expect(_showsCartridge(_shownCaliber(tester), '.300 Win Mag'), isTrue);
      expect(selectedValue<int>(tester, 'ammo-model-select'), isNotNull);
    }, skip: true); // PRF-11: listed rifle reloads the first variant

    testWidgets('listed rifle: BC modeli G1 -> G7 does not keep the G1 '
        'number (MUH-1)', (tester) async {
      final p = seeded('manual_rifle_d15c_listed', _listedRifle300);
      await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(_text(tester, 'ammo-bc'), '0.425');
      await _pick<String>(tester, 'ammo-bc-model', 'g7');
      // Today: "0.425" stays and Güncelle saves BC 0.425 G7.
      expect(_text(tester, 'ammo-bc'), '');
    }, skip: true); // PRF-11: MUH-1 guard misses the reloaded round

    testWidgets('guard: typed rifle, BC modeli G1 -> G7 empties the G1-only '
        'maker BC (MUH-1 works when the round is listed)', (tester) async {
      final p = seeded('manual_rifle_d15c_typed', _typedRifle300);
      await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(_text(tester, 'ammo-bc'), '0.425');
      await _pick<String>(tester, 'ammo-bc-model', 'g7');
      expect(_text(tester, 'ammo-bc'), '');
    });

    testWidgets('guard: listed rifle, Güncelle without touching keeps every '
        'number', (tester) async {
      final p = seeded('manual_rifle_d15c_listed', _listedRifle300);
      final before = _solverInputs(p);
      expect(before['caliberMm'], 7.82);
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(_missingText(tester), isEmpty);
      await _press(tester, 'Güncelle');
      final after = _solverInputs((await store.all()).single);
      for (final k in before.keys) {
        final b = before[k], a = after[k];
        if (k == 'muzzleVelocityMps') {
          // Velocity box: fps with one decimal (<= 0.016 m/s).
          expect(a as double, closeTo(b as double, 0.02), reason: k);
        } else {
          expect(a, b, reason: k);
        }
      }
    });
  });
}
