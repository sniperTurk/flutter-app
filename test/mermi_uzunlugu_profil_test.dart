// Mermi uzunluğu Profil > Mühimmat'ta (owner, 2026-10-17 11:34–11:41, "al
// bunu oraya"): ateşli silahta ve PCP'de BC modeli | Mermi uzunluğu aynı
// satırda (BC modeli solda), birim mm, ⓘ metni sahibin metni. Hesap profil
// uzunluğunu kullanır; profilde yoksa eski sürümde Pro'ya yazılmış değer
// (aynı profilin 'bulletLength' kaydı) kullanılır, sayılar değişmez.
// Report: docs/reports/pro_barut_not.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _info =
    'Merminin ucundan dibine boyu, milimetre olarak. Üreticinin sitesinde ya '
    'da kutusunda yazar; kumpasla da ölçülebilir. Örnek: kumpasta 31,2 '
    'okunursa 31,2 yazın. Spin drift hesaplamasının yapılabilmesi için yiv '
    'yönü ve yiv oranının profil oluşturulurken girilmiş olması '
    'gerekmektedir.';

// Typed firearm set (as test/audit_2026_10_14b/profile_match_audit_test.dart).
const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mu',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Özel Yapım',
  'caliberMm': 7.82,
  'twistDirection': 'left',
  'twistRateIn': 12,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_mu',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'G7 Fişek',
  'caliberMm': 7.82,
  'grain': 177,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};
const _scope = <String, dynamic>{
  'id': 'manual_scope_mu',
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

final _profile = const ProfileCodec().decode({
  'id': 'mu',
  'name': 'Uzunluk Profili',
  'rifleId': 'manual_rifle_mu',
  'ammunitionId': 'manual_ammo_mu',
  'scopeId': 'manual_scope_mu',
  'muzzleVelocityMps': 850.0,
  'zeroRangeM': 100.0,
  'sightHeightMm': 45.0,
  'pressureVelocity': const <Map<String, double>>[],
  'angularUnit': 'mrad',
  'distanceUnit': 'meter',
  'mountCantMoa': 0.0,
});

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

Future<void> _size(
  WidgetTester tester,
  double width, [
  double height = 2600,
]) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _scaled(Widget home, double scale) => MaterialApp(
  theme: MenzilTheme.light(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: home,
);

/// The stored firearm profile opened in Profili Düzenle.
Future<MemoryProfileStore> _openEdit(
  WidgetTester tester, {
  double width = 430,
  double scale = 1,
}) async {
  await _size(tester, width);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(_scaled(ProfilesScreen(store: store), scale));
  await tester.pumpAndSettle();
  final row = find.text(_profile.name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
  return store;
}

/// A new PCP profile (Profil ekle → PCP Tüfek).
Future<void> _openNewPcp(
  WidgetTester tester, {
  double width = 430,
  double scale = 1,
}) async {
  await _size(tester, width);
  await tester.pumpWidget(
    _scaled(ProfilesScreen(store: MemoryProfileStore()), scale),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
}

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

/// BC modeli | Mermi uzunluğu on one row (same top ±0.5 pt, BC modeli left),
/// unit mm, label without parentheses and the owner's ⓘ text.
void _expectPair(WidgetTester tester) {
  final model = tester.getRect(find.byKey(const Key('ammo-bc-model')));
  final length = tester.getRect(find.byKey(const Key('ammo-length')));
  expect(length.top, moreOrLessEquals(model.top, epsilon: 0.5));
  expect(model.right, lessThan(length.left));
  final input = tester.widget<MenzilInput>(
    find.byKey(const Key('ammo-length')),
  );
  expect(input.label, 'Mermi uzunluğu');
  expect(input.unit, 'mm');
  expect(input.info, _info);
  expect(input.helperText, isNull);
  // The unit belongs to this field (shown with the box, not elsewhere).
  expect(
    find.descendant(
      of: find.byKey(const Key('ammo-length')),
      matching: find.text('mm'),
    ),
    findsOneWidget,
  );
  // One ⓘ for the field, with the owner's text.
  expect(
    find.descendant(
      of: find.byKey(const Key('ammo-length')),
      matching: find.byType(MenzilInfoButton),
    ),
    findsOneWidget,
  );
}

void main() {
  setUp(() => _seed([_rifle, _ammo, _scope]));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('ⓘ text is the owner text, one text for firearm and PCP', () {
    expect(ProfileFieldInfo.ammoLength, _info);
  });

  testWidgets('firearm: BC modeli | Mermi uzunluğu on one row', (tester) async {
    await _openEdit(tester);
    await tester.ensureVisible(find.byKey(const Key('ammo-length')));
    await tester.pumpAndSettle();
    _expectPair(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PCP: BC modeli | Mermi uzunluğu on one row', (tester) async {
    await _openNewPcp(tester);
    await tester.ensureVisible(find.byKey(const Key('ammo-length')));
    await tester.pumpAndSettle();
    _expectPair(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('firearm: a typed length is saved with the ammunition and '
      'shown again; emptied, none is saved', (tester) async {
    var store = await _openEdit(tester);
    await enterRifleField(tester, 'ammo-length', '31,2');
    await tester.pumpAndSettle();
    Future<void> update() async {
      final button = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
      expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await update();
    Future<Map<String, dynamic>> savedAmmo() async {
      final saved = (await store.all()).single;
      final entries = await ManualCatalogStore().all();
      return entries.singleWhere((e) => e['id'] == saved.ammunitionId);
    }

    final ammo = await savedAmmo();
    expect(ammo['lengthMm'], 31.2);
    expect(ammo['grain'], 177);
    expect(ammo['bc'], 0.243);

    // Opened again: the box shows it.
    final saved = (await store.all()).single;
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
    );
    await tester.pumpWidget(const SizedBox());
    store = MemoryProfileStore();
    await store.save(saved);
    await tester.pumpWidget(_scaled(ProfilesScreen(store: store), 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_profile.name).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_field('ammo-length')).controller!.text,
      '31.2',
    );

    // Emptied (optional): saved without a length.
    await enterRifleField(tester, 'ammo-length', '');
    await tester.pumpAndSettle();
    await update();
    expect((await savedAmmo()).containsKey('lengthMm'), isFalse);
  });

  testWidgets('a length outside 1–60 mm blocks saving', (tester) async {
    await _openEdit(tester);
    await enterRifleField(tester, 'ammo-length', '70');
    await tester.pumpAndSettle();
    final button = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNull);
    await enterRifleField(tester, 'ammo-length', '60');
    await tester.pumpAndSettle();
    expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNotNull);
  });

  for (final pcp in [false, true]) {
    testWidgets('${pcp ? 'PCP' : 'firearm'}: 320 pt, text scale 1.3, no '
        'overflow', (tester) async {
      if (pcp) {
        await _openNewPcp(tester, width: 320, scale: 1.3);
      } else {
        await _openEdit(tester, width: 320, scale: 1.3);
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('ammo-length')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(const Key('ammo-length'))).right,
        lessThanOrEqualTo(320 + 0.01),
      );
      final model = tester.getRect(find.byKey(const Key('ammo-bc-model')));
      final length = tester.getRect(find.byKey(const Key('ammo-length')));
      // Two columns: one row; one column (narrow / large text): BC modeli
      // first, Mermi uzunluğu under it.
      if ((length.top - model.top).abs() >= 0.5) {
        expect(length.top, greaterThan(model.top));
      } else {
        expect(model.right, lessThan(length.left));
      }
    });
  }

  group('calculation: Profil length, else the old Pro value', () {
    // Firearm .308-like set with right twist for a clear spin drift.
    const rifle = <String, dynamic>{
      'id': 'manual_rifle_mc',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Test',
      'model': '308',
      'caliberMm': 7.62,
      'twistDirection': 'right',
      'twistRateIn': 10,
    };
    const ammo = <String, dynamic>{
      'id': 'manual_ammo_mc',
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
    const profile = RifleProfile(
      id: 'p-mc',
      name: 'MC',
      rifleId: 'manual_rifle_mc',
      ammunitionId: 'manual_ammo_mc',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 800,
      zeroRangeM: 100,
      sightHeightMm: 45,
    );

    Future<({double right, String? note})> shot(
      WidgetTester tester, {
      double? profileLength,
      String? legacy,
    }) async {
      await _size(tester, 430, 3000);
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(profile.id): jsonEncode(
          ShotSettings(bulletLengthText: legacy ?? '').toJson(),
        ),
      });
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([
          rifle,
          {...ammo, if (profileLength != null) 'lengthMm': profileLength},
        ]),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: const Scaffold(
            body: BallisticsScreen(profile: profile, view: BallisticsView.shot),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final note = find.byKey(const Key('shot-spin-drift'));
      return (
        right: tester
            .widget<ScopeDialView>(find.byType(ScopeDialView))
            .requiredRight,
        note: note.evaluate().isEmpty ? null : tester.widget<Text>(note).data,
      );
    }

    testWidgets('old Pro 31 mm only = Profil 31 mm; Profil wins over Pro', (
      tester,
    ) async {
      final legacy = await shot(tester, legacy: '31');
      expect(legacy.note, contains('sağa'));
      final fromProfile = await shot(tester, profileLength: 31);
      expect(fromProfile.right, legacy.right);
      expect(fromProfile.note, legacy.note);
      // Profil 31 mm and an old Pro 38 mm: the Profil length.
      final both = await shot(tester, profileLength: 31, legacy: '38');
      expect(both.right, legacy.right);
      expect(both.note, legacy.note);
      // Old Pro 38 mm alone differs (the length is really used).
      final legacy38 = await shot(tester, legacy: '38');
      expect(
        legacy38.note != legacy.note || legacy38.right != legacy.right,
        isTrue,
      );
      // Neither: no spin drift.
      expect((await shot(tester)).note, isNull);
    });

    testWidgets('the old Pro value stays saved under its key', (tester) async {
      await shot(tester, profileLength: 31, legacy: '38');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(ShotSettingsStore.keyFor(profile.id))!;
      expect((jsonDecode(raw) as Map)['bulletLength'], '38');
    });
  });
}
