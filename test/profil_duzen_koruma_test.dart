// Profil Oluştur / Profili Düzenle koruması (owner, 2026-10-14 16:56–17:12):
// "Sayfalar son yaptığımız düzenleme ile açılsın; bir şey ekleyip
// çıkardığımızda yaptığımız işler bozulmasın."
//
// Pins the Dürbün and Tüfek layout (which boxes, in which order, which share
// a row) for every way into the form: a new profile, Profili Düzenle of a
// list item, of a profile saved before the 13 Oct catalog update (#235,
// older names), of a typed item and of a Kopyala copy, plus save -> reopen
// round trips. Also items 2-4 of the same task: Model boxes wrap instead of
// shrinking, "Kaydetmek için eksik" names only boxes that are on screen,
// "Barut katsayısı" has no unit beside it.
//
// If one of these fails, a later change has silently undone an owner
// decision: change the code back, or get the owner's word before changing
// the test.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profile_catalog_match.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

// ---- Old saved data (JSON as written before the 13 Oct catalog update) ---

/// A Tikka saved with another spelling than today's list ("T3x TACT A1").
const _oldRifle = {
  'id': 'manual_rifle_old',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'TIKKA',
  'model': 'T3X Tact A1',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};

/// A typed firearm round (stays typed; Mühimmat is not part of this task).
const _oldAmmo = {
  'id': 'manual_ammo_old',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
};

/// Arken SH-4 GENII 4-16x50 FFP (MRAD) saved under the older series name
/// "SH-4 Gen II"; the exact rule (brand + series) no longer finds it.
const _oldScope = {
  'id': 'manual_scope_old',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Arken SH-4 Gen II',
  'model': '4-16x50 FFP',
  'objectiveMm': 50,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
  'reticle': 'VPR-MIL',
};

/// A scope that is in no list: it must open in the typed entry.
const _typedScope = {
  'id': 'manual_scope_typed',
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

/// A rifle that is in no list.
const _typedRifle = {
  'id': 'manual_rifle_typed',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Özel Yapım',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

/// The profile as stored by the app (ProfileCodec JSON).
Map<String, dynamic> _profileJson({
  String id = 'old',
  String name = 'Eski Profil',
  String rifleId = 'manual_rifle_old',
  String scopeId = 'manual_scope_old',
  String angularUnit = 'mrad',
}) => {
  'id': id,
  'name': name,
  'rifleId': rifleId,
  'ammunitionId': 'manual_ammo_old',
  'scopeId': scopeId,
  'muzzleVelocityMps': 800.0,
  'zeroRangeM': 100.0,
  'sightHeightMm': 45.0,
  'angularUnit': angularUnit,
  'distanceUnit': 'meter',
  'mountCantMoa': 0.0,
};

RifleProfile _decode(Map<String, dynamic> j) => const ProfileCodec().decode(j);

void _install(List<Map<String, Object>> entries) =>
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([
        for (final e in entries) {...e},
      ]),
    );

// ---- Pumping ----

void _view(WidgetTester tester, {double width = 430}) {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpList(
  WidgetTester tester,
  ProfileStore store, {
  String? active,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store, activeProfileId: active),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openNew(WidgetTester tester, {double width = 430}) async {
  _view(tester, width: width);
  await _pumpList(tester, MemoryProfileStore());
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

Future<MemoryProfileStore> _openSaved(
  WidgetTester tester,
  RifleProfile profile,
) async {
  _view(tester);
  final store = MemoryProfileStore();
  await store.save(profile);
  await _pumpList(tester, store);
  await _openEdit(tester, profile.name);
  return store;
}

Future<void> _update(WidgetTester tester) async {
  final button = find.text('Güncelle');
  expect(
    tester
        .widget<MenzilPrimaryButton>(
          find.ancestor(of: button, matching: find.byType(MenzilPrimaryButton)),
        )
        .onPressed,
    isNotNull,
    reason: _missingText(tester),
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsNothing);
}

// ---- Layout ----

Finder _prefix(String p) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(p),
);

/// Every Dürbün box / line that can be on the card, by a short name.
final Map<String, Finder> _scopeParts = {
  'Marka': find.byKey(const Key('scope-brand-select')),
  'Marka (yazılı)': find.byKey(const Key('scope-brand')),
  'Listeden seç': find.byKey(const Key('scope-back-to-list')),
  'Birim': _prefix('scope-filter-unit-'),
  'Odak': _prefix('scope-filter-ffp-'),
  'Tüp': _prefix('scope-filter-tube-'),
  'Büyütme': _prefix('scope-filter-mag-'),
  'Model': find.byKey(const Key('scope-model-select')),
  'Minimum büyütme': find.byKey(const Key('scope-min-mag')),
  'Maksimum büyütme': find.byKey(const Key('scope-max-mag')),
  'Mercek çapı': find.byKey(const Key('scope-objective')),
  'Odak düzlemi': find.byKey(const Key('scope-focal-plane')),
  'Dürbün birimi': find.byKey(const Key('scope-unit')),
  'Klik değeri': find.byKey(const Key('scope-click')),
  'Dürbün ayağı': find.byKey(const Key('scope-mount')),
  'Üst kule klik sayısı': find.byKey(const Key('scope-travel-elevation')),
  'Retikül': find.byKey(const Key('scope-reticle')),
  'Dürbün: …': find.byKey(const Key('scope-designation')),
  'Aradığın dürbün listede yok mu?': find.byKey(const Key('scope-not-listed')),
};

/// Every Tüfek box / line that can be on the card.
final Map<String, Finder> _rifleParts = {
  'Marka': find.byKey(const Key('rifle-brand-select')),
  'Marka (yazılı)': find.byKey(const Key('rifle-brand')),
  'Model': find.byKey(const Key('rifle-model-select')),
  'Model (yazılı)': find.byKey(const Key('rifle-model')),
  'Aradığın tüfek listede yok mu?': find.byKey(const Key('rifle-not-listed')),
  'Listeden seç': find.byKey(const Key('rifle-back-to-list')),
  'Namlu çıkış hızı': find.byKey(const Key('profile-velocity-fps')),
  'Kalibre': find.byKey(const Key('rifle-caliber')),
  'Mermi çapı': find.byKey(const Key('rifle-bullet-diameter')),
  'Namlu yiv yönü': find.byKey(const Key('rifle-twist-direction')),
  'Yiv oranı': find.byKey(const Key('rifle-twist-rate')),
  'Sight height': find.byKey(const Key('scope-sight-height')),
  'Mesafe birimi': find.byKey(const Key('profile-distance-unit')),
  'Sıfırlama mesafesi': find.byKey(const Key('profile-zero')),
};

/// The parts on screen, row by row ("A | B" = one row), top to bottom.
List<String> _layout(WidgetTester tester, Map<String, Finder> parts) {
  final at =
      <(String, Offset)>[
        for (final MapEntry(:key, :value) in parts.entries)
          if (value.evaluate().isNotEmpty)
            (key, tester.getTopLeft(value.first)),
      ]..sort((a, b) {
        final dy = a.$2.dy - b.$2.dy;
        if (dy.abs() > 2) return dy.sign.toInt();
        return a.$2.dx.compareTo(b.$2.dx);
      });
  final rows = <List<String>>[];
  double? top;
  for (final (name, o) in at) {
    if (top != null && (o.dy - top).abs() <= 2) {
      rows.last.add(name);
    } else {
      rows.add([name]);
      top = o.dy;
    }
  }
  return [for (final r in rows) r.join(' | ')];
}

List<String> _scopeLayout(WidgetTester t) => _layout(t, _scopeParts);
List<String> _rifleLayout(WidgetTester t) => _layout(t, _rifleParts);

/// Dürbün of a list scope before a Marka is chosen.
const _scopeNewLayout = [
  'Marka',
  'Model',
  'Dürbün ayağı | Üst kule klik sayısı',
  'Retikül',
  'Dürbün: …',
  'Aradığın dürbün listede yok mu?',
];

/// Dürbün after a Marka in a new profile: the four filters, then Model.
const _scopeFilterLayout = [
  'Marka',
  'Birim | Odak',
  'Tüp | Büyütme',
  'Model',
  'Dürbün ayağı | Üst kule klik sayısı',
  'Retikül',
  'Dürbün: …',
  'Aradığın dürbün listede yok mu?',
];

/// Profili Düzenle of a list scope: filters hidden until Marka changes, the
/// five record values hidden (owner, 2026-10-13).
const _scopeEditLayout = _scopeNewLayout;

/// The typed scope ("Aradığın dürbün listede yok mu?" / no list match).
const _scopeTypedLayout = [
  'Marka (yazılı)',
  'Listeden seç',
  'Minimum büyütme | Maksimum büyütme',
  'Mercek çapı | Odak düzlemi',
  'Dürbün birimi | Klik değeri',
  'Dürbün ayağı | Üst kule klik sayısı',
  'Retikül',
  'Dürbün: …',
];

/// Tüfek from the lists (new profile and every list rifle on edit).
const _rifleListLayout = [
  'Marka',
  'Model',
  'Aradığın tüfek listede yok mu?',
  'Namlu çıkış hızı | Kalibre',
  'Namlu yiv yönü | Yiv oranı',
  'Sight height | Mesafe birimi',
  'Sıfırlama mesafesi',
];

/// Tüfek typed in (no list match).
const _rifleTypedLayout = [
  'Marka (yazılı)',
  'Model (yazılı)',
  'Listeden seç',
  'Namlu çıkış hızı | Kalibre',
  'Namlu yiv yönü | Yiv oranı',
  'Sight height | Mesafe birimi',
  'Sıfırlama mesafesi',
];

String _designation(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('scope-designation'))).data!;

String _typed(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

// ---- "Kaydetmek için eksik" ----

String _missingText(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

/// Section -> names, e.g. {'Dürbün': ['Model', 'Dürbün ayağı']}.
Map<String, List<String>> _missing(WidgetTester tester) {
  final text = _missingText(tester);
  if (text.isEmpty) return {};
  final body = text.substring('Kaydetmek için eksik: '.length);
  return {
    for (final part in body.split(' · '))
      part.substring(0, part.indexOf(': ')): part
          .substring(part.indexOf(': ') + 2)
          .split(', '),
  };
}

/// The box each banner name points at; one of them must be on screen.
const Map<String, Map<String, List<String>>> _bannerBoxes = {
  'Tüfek': {
    'Marka': ['rifle-brand-select', 'rifle-brand'],
    'Model': ['rifle-model-select', 'rifle-model'],
    'Namlu çıkış hızı': ['profile-velocity-fps'],
    'Yiv yönü': ['rifle-twist-direction'],
    'Kalibre': ['rifle-caliber'],
    'Yiv oranı': ['rifle-twist-rate'],
    'Sight height': ['scope-sight-height'],
    'Sıfırlama mesafesi': ['profile-zero'],
    'Mesafe birimi': ['profile-distance-unit'],
  },
  'Dürbün': {
    'Marka': ['scope-brand-select', 'scope-brand'],
    'Model': ['scope-model-select'],
    'Min. büyütme': ['scope-min-mag'],
    'Maks. büyütme': ['scope-max-mag'],
    'Mercek çapı': ['scope-objective'],
    'Odak düzlemi': ['scope-focal-plane'],
    'Dürbün birimi': ['scope-unit'],
    'Dürbün ayağı': ['scope-mount'],
    'Klik değeri': ['scope-click'],
    'Üst kule klik sayısı': ['scope-travel-elevation'],
  },
};

/// Every Tüfek / Dürbün name in the banner is a box the user can see.
void _bannerNamesVisibleBoxes(WidgetTester tester) {
  final m = _missing(tester);
  for (final section in const ['Tüfek', 'Dürbün']) {
    for (final name in m[section] ?? const <String>[]) {
      final keys = _bannerBoxes[section]![name];
      expect(keys, isNotNull, reason: '$section: $name has no box');
      expect(
        keys!.any((k) => find.byKey(Key(k)).evaluate().isNotEmpty),
        isTrue,
        reason: '$section: "$name" is listed but its box is not on screen',
      );
    }
  }
}

const _hiddenScopeNames = [
  'Min. büyütme',
  'Maks. büyütme',
  'Mercek çapı',
  'Odak düzlemi',
  'Dürbün birimi',
  'Klik değeri',
];

// ---- Item 2: Model text wraps at its normal size ----

Finder _box(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(InputDecorator),
);

void _wrapsAtNormalSize(WidgetTester tester, String key, String text) {
  final wrapped = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byKey(const Key('menzil-select-wrapped')),
  );
  expect(wrapped, findsOneWidget, reason: key);
  final t = tester.widget<Text>(wrapped);
  expect(t.data, text);
  // Normal size, never scaled down.
  expect(t.style?.fontSize, 15);
  expect(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(FittedBox)),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(MenzilFitText),
    ),
    findsNothing,
  );
  final p = tester.renderObject<RenderParagraph>(wrapped);
  expect(p.didExceedMaxLines, isFalse, reason: 'cut');
  // More than one line: the box grows instead.
  expect(p.size.height, greaterThan(1.8 * 15), reason: 'one line only');
  expect(
    tester.getSize(_box(key)).height,
    greaterThan(tester.getSize(_box('profile-platform')).height + 10),
    reason: 'the box did not grow',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('matching (pure)', () {
    test('old scope naming finds today\'s list record', () {
      final saved = UserCatalog.fromManualEntries([
        {..._oldScope},
      ]).scopes.single;
      final hit = ProfileCatalogMatch.scope(saved, [
        for (final s in CatalogRepository.scopes)
          if (!s.userEntered) s,
      ], (s) => s.model);
      expect(hit?.id, 'lib-arken-optics-sh-4-genii-4-16x50-ffp');
    });

    test('a scope in no list gives no match', () {
      final saved = UserCatalog.fromManualEntries([
        {..._typedScope},
      ]).scopes.single;
      expect(
        ProfileCatalogMatch.scope(saved, [
          for (final s in CatalogRepository.scopes)
            if (!s.userEntered) s,
        ], (s) => s.model),
        isNull,
      );
    });

    test('the numbers must agree: another büyütme is no match', () {
      final saved = UserCatalog.fromManualEntries([
        {..._oldScope, 'maxMag': 18, 'magnification': '4-18x'},
      ]).scopes.single;
      expect(
        ProfileCatalogMatch.scope(saved, [
          for (final s in CatalogRepository.scopes)
            if (!s.userEntered) s,
        ], (s) => s.model),
        isNull,
      );
    });
  });

  group('Dürbün and Tüfek layout per entry path', () {
    testWidgets('new profile', (tester) async {
      await _openNew(tester);
      expect(_scopeLayout(tester), _scopeNewLayout);
      expect(_rifleLayout(tester), _rifleListLayout);
      await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
      expect(_scopeLayout(tester), _scopeFilterLayout);
      await chooseInSelect(
        tester,
        'scope-model-select',
        'Titan 3-18x50 FFP MOA',
      );
      // A catalog pick: the five record values stay hidden.
      expect(_scopeLayout(tester), _scopeFilterLayout);
      expect(_designation(tester), contains('3-18x50 FFP'));
      // The typed scope from the link, and back.
      await openScopeManual(tester);
      expect(_scopeLayout(tester), _scopeTypedLayout);
      await tester.tap(find.byKey(const Key('scope-back-to-list')));
      await tester.pumpAndSettle();
      expect(_scopeLayout(tester), _scopeNewLayout);
      // Tüfek typed from the link, and back.
      await openRifleManual(tester);
      expect(_rifleLayout(tester), _rifleTypedLayout);
      final back = find.byKey(const Key('rifle-back-to-list'));
      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(_rifleLayout(tester), _rifleListLayout);
    });

    testWidgets('Profili Düzenle: list scope (gazi-6-36) and list rifle', (
      tester,
    ) async {
      await _openSaved(
        tester,
        const RifleProfile(
          id: 'p-gazi',
          name: 'Gazi Profil',
          rifleId: 'hatsan-hercules-635',
          ammunitionId: 'gmaz-51',
          scopeId: 'gazi-6-36',
          muzzleVelocityMps: 270,
          zeroRangeM: 25,
          sightHeightMm: 60,
          pressureBar: 200,
        ),
      );
      expect(_scopeLayout(tester), _scopeEditLayout);
      expect(
        selectedValue<String>(tester, 'scope-brand-select'),
        'Gazi Sniper',
      );
      expect(selectedValue<String>(tester, 'scope-model-select'), isNotNull);
      expect(_designation(tester), 'Dürbün: Gazi Sniper 6-36x56 FFP');
      // The built-in HATSAN / Hercules is the list's Hatsan / Hercules.
      expect(_rifleLayout(tester), _rifleListLayout);
      expect(selectedValue<String>(tester, 'rifle-brand-select'), 'Hatsan');
      expect(selectedValue<String>(tester, 'rifle-model-select'), 'Hercules');
      expect(selectedValue<bool?>(tester, 'rifle-origin'), isTrue);
      // A changed Marka brings the filters back (owner, 2026-10-13).
      await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
      expect(_scopeLayout(tester), _scopeFilterLayout);
    });

    testWidgets('Profili Düzenle: saved before the 13 Oct update (JSON)', (
      tester,
    ) async {
      _install([_oldRifle, _oldAmmo, _oldScope]);
      await _openSaved(tester, _decode(_profileJson()));
      // Opens in the lists like a new pick, not in the typed boxes.
      expect(_scopeLayout(tester), _scopeEditLayout);
      expect(
        selectedValue<String>(tester, 'scope-brand-select'),
        'Arken Optics',
      );
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
      expect(selectedValue<String>(tester, 'scope-reticle'), 'VPR-MIL');
      // Saved values in use (boxes hidden, values kept).
      expect(_designation(tester), 'Dürbün: Arken SH-4 Gen II 4-16x50 FFP');
      expect(_rifleLayout(tester), _rifleListLayout);
      expect(selectedValue<String>(tester, 'rifle-brand-select'), 'Tikka');
      expect(
        selectedValue<String>(tester, 'rifle-model-select'),
        'T3x TACT A1',
      );
      expect(selectedValue<bool?>(tester, 'rifle-origin'), isFalse);
      expect(_typed(tester, 'rifle-twist-rate'), '11');
      // Nothing is missing: the old profile saves as it is.
      expect(_missing(tester)['Tüfek'], isNull);
      expect(_missing(tester)['Dürbün'], isNull);
    });

    testWidgets('old profile: Güncelle -> reopen keeps layout and values', (
      tester,
    ) async {
      _install([_oldRifle, _oldAmmo, _oldScope]);
      final store = await _openSaved(tester, _decode(_profileJson()));
      await _update(tester);
      final saved = (await store.all()).single;
      final rifle = CatalogRepository.allRifles.singleWhere(
        (r) => r.id == saved.rifleId,
      );
      expect(rifle.brand, 'Tikka');
      expect(rifle.model, 'T3x TACT A1');
      expect(rifle.caliberMm, 7.82);
      expect(rifle.twistRateIn, 11);
      final scope = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == saved.scopeId,
      );
      // Saved values are never replaced by the list record's.
      expect(scope.brand, 'Arken SH-4 Gen II');
      expect(scope.minMagnification, 4);
      expect(scope.maxMagnification, 16);
      expect(scope.objectiveDiameterMm, 50);
      expect(scope.firstFocalPlane, isTrue);
      expect(scope.clickValue, 0.1);
      expect(scope.reticle, 'VPR-MIL');
      expect(saved.muzzleVelocityMps, closeTo(800, 0.5));

      await _openEdit(tester, 'Eski Profil');
      expect(_scopeLayout(tester), _scopeEditLayout);
      expect(_rifleLayout(tester), _rifleListLayout);
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
      expect(
        selectedValue<String>(tester, 'rifle-model-select'),
        'T3x TACT A1',
      );
    });

    testWidgets('built-in list scope: Güncelle -> reopen stays in the lists', (
      tester,
    ) async {
      _install([_oldRifle, _oldAmmo]);
      final store = await _openSaved(
        tester,
        _decode(
          _profileJson(scopeId: 'lib-arken-optics-sh-4-genii-4-16x50-ffp'),
        ),
      );
      expect(_scopeLayout(tester), _scopeEditLayout);
      await _update(tester);
      final saved = (await store.all()).single;
      expect(saved.scopeId, startsWith('manual_scope_'));
      await _openEdit(tester, 'Eski Profil');
      expect(_scopeLayout(tester), _scopeEditLayout);
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
    });

    testWidgets('Profili Düzenle: typed items with no list match', (
      tester,
    ) async {
      _install([_typedRifle, _oldAmmo, _typedScope]);
      await _openSaved(
        tester,
        _decode(
          _profileJson(
            rifleId: 'manual_rifle_typed',
            scopeId: 'manual_scope_typed',
          ),
        ),
      );
      expect(_scopeLayout(tester), _scopeTypedLayout);
      expect(_typed(tester, 'scope-brand'), 'Atölyem Optik');
      expect(selectedValue<double>(tester, 'scope-min-mag'), 4);
      expect(selectedValue<double>(tester, 'scope-max-mag'), 16);
      expect(selectedValue<double>(tester, 'scope-objective'), 44);
      expect(selectedValue<bool>(tester, 'scope-focal-plane'), isFalse);
      expect(_rifleLayout(tester), _rifleTypedLayout);
      expect(_typed(tester, 'rifle-brand'), 'Atölyem');
      expect(_typed(tester, 'rifle-model'), 'Özel Yapım');
      _bannerNamesVisibleBoxes(tester);
    });

    testWidgets('Kopyala: the copy opens like the original', (tester) async {
      _install([_oldRifle, _oldAmmo, _oldScope]);
      _view(tester);
      final store = MemoryProfileStore();
      await store.save(_decode(_profileJson()));
      await _pumpList(tester, store, active: 'old');
      await tester.ensureVisible(find.text('Kopyala'));
      await tester.tap(find.text('Kopyala'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _openEdit(tester, 'Eski Profil (kopya)');
      expect(_scopeLayout(tester), _scopeEditLayout);
      expect(_rifleLayout(tester), _rifleListLayout);
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
      expect(
        selectedValue<String>(tester, 'rifle-model-select'),
        'T3x TACT A1',
      );
    });
  });

  group('Kaydetmek için eksik names only boxes on screen', () {
    testWidgets('list scope not chosen: "Model", not the hidden boxes', (
      tester,
    ) async {
      await _openNew(tester);
      var dur = _missing(tester)['Dürbün']!;
      expect(dur.take(2), ['Marka', 'Model']);
      for (final n in _hiddenScopeNames) {
        expect(dur, isNot(contains(n)), reason: n);
      }
      _bannerNamesVisibleBoxes(tester);

      await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
      dur = _missing(tester)['Dürbün']!;
      expect(dur.first, 'Model');
      expect(dur, isNot(contains('Marka')));
      for (final n in _hiddenScopeNames) {
        expect(dur, isNot(contains(n)), reason: n);
      }
      _bannerNamesVisibleBoxes(tester);

      await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
      expect(_missing(tester)['Dürbün'], ['Model']);

      await chooseInSelect(
        tester,
        'scope-model-select',
        'Titan 3-18x50 FFP MOA',
      );
      expect(_missing(tester)['Dürbün'], isNull);
    });

    testWidgets('a value the record lacks is named with its box', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'scope-brand-select', 'Gamo');
      await chooseInSelect(
        tester,
        'scope-model-select',
        '3-9X50 Illuminated Reticle · MOA',
      );
      expect(find.byKey(const Key('scope-focal-plane')), findsOneWidget);
      expect(_missing(tester)['Dürbün'], contains('Odak düzlemi'));
      _bannerNamesVisibleBoxes(tester);
    });

    testWidgets('typed scope names its own boxes', (tester) async {
      await _openNew(tester);
      await openScopeManual(tester);
      final dur = _missing(tester)['Dürbün']!;
      for (final n in [
        'Marka',
        'Min. büyütme',
        'Odak düzlemi',
        'Klik değeri',
      ]) {
        expect(dur, contains(n), reason: n);
      }
      expect(dur, isNot(contains('Model')));
      _bannerNamesVisibleBoxes(tester);
    });

    testWidgets('Tüfek: list and typed rifle name only their boxes', (
      tester,
    ) async {
      await _openNew(tester);
      expect(_missing(tester)['Tüfek']!.take(2), ['Marka', 'Model']);
      _bannerNamesVisibleBoxes(tester);
      await openRifleManual(tester);
      _bannerNamesVisibleBoxes(tester);
    });
  });

  group('Model boxes wrap at the normal size (like Mühimmat Model)', () {
    testWidgets('Dürbün Model', (tester) async {
      const line = 'ED-ELR Gen III 5-40x56 SFIR FFP Zero Stop MOA';
      await _openNew(tester);
      await chooseInSelect(tester, 'scope-brand-select', 'Discovery Optics');
      await chooseInSelect(tester, 'scope-model-select', line);
      expect(selectedValue<String>(tester, 'scope-model-select'), line);
      _wrapsAtNormalSize(tester, 'scope-model-select', line);
      // The open list keeps the size too (no shrinking FittedBox).
      final box = find.byKey(const Key('scope-model-select'));
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pumpAndSettle();
      final inMenu = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
        ),
        matching: find.byType(FittedBox),
      );
      expect(inMenu, findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tüfek Model', (tester) async {
      const model = 'Mark V Backcountry 2.0 Carbon 6.5-300 Wby Mag';
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-brand-select', 'Weatherby');
      await chooseInSelect(tester, 'rifle-model-select', model);
      expect(selectedValue<String>(tester, 'rifle-model-select'), model);
      _wrapsAtNormalSize(tester, 'rifle-model-select', model);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short Model stays one line in a normal box', (tester) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-brand-select', 'Tikka');
      await chooseInSelect(tester, 'rifle-model-select', 'T3x UPR');
      final wrapped = find.descendant(
        of: find.byKey(const Key('rifle-model-select')),
        matching: find.byKey(const Key('menzil-select-wrapped')),
      );
      expect(tester.widget<Text>(wrapped).data, 'T3x UPR');
      expect(
        tester.getSize(_box('rifle-model-select')).height,
        moreOrLessEquals(
          tester.getSize(_box('rifle-brand-select')).height,
          epsilon: 1,
        ),
      );
    });
  });

  group('Mühimmat: Barut katsayısı', () {
    testWidgets('no unit beside the label; Hız ölçüm sıcaklığı keeps °C', (
      tester,
    ) async {
      await _openNew(tester);
      MenzilFieldLabel label(String key) => tester.widget<MenzilFieldLabel>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(MenzilFieldLabel),
        ),
      );
      expect(label('profile-powder-coef').label, 'Barut katsayısı');
      expect(label('profile-powder-coef').unit, isNull);
      expect(find.text('%/15 °C'), findsNothing);
      expect(label('profile-powder-temp').label, 'Hız ölçüm sıcaklığı');
      expect(label('profile-powder-temp').unit, '°C');
      // The unit is explained in its ⓘ.
      expect(find.byTooltip('Bilgi: Barut katsayısı'), findsOneWidget);
    });
  });
}
