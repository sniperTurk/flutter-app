// PCP Tüfek and Mühimmat cards, units inside the boxes (owner, 2026-10-16
// 20:49–21:04 Istanbul, approved drawing; PR #368):
//
//   Tüfek, PCP:     Kalibre | Namlu çıkış hızı · Yiv oranı | Namlu yiv yönü ·
//                   Tüp basıncı | Regülatör basıncı · Sıfırlama mesafesi |
//                   Mesafe birimi · Sight height (alone, last).
//   Tüfek, Ateşli:  the same without Tüp basıncı | Regülatör basıncı.
//   Mühimmat, PCP:  Tip | Marka · Model · "Aradığın mühimmat listede yok
//                   mu?" · Ağırlık | BC · BC modeli · En düşük | En yüksek
//                   namlu çıkış hızı (optional). No pressures, no "Basınca
//                   göre hız".
//   MenzilInput:    the unit inside the box at its right; ⓘ in the label row.
//
// Velocity used by every calculation (RifleProfile.velocityMps): En düşük
// and En yüksek both given → their mean; both empty → the Tüfek card's
// Namlu çıkış hızı; only one → the Tüfek card's Namlu çıkış hızı, and the
// editor shows "En düşük ve en yüksek hızın ikisini de girin." on the empty
// box and does not save (like Barut sıcaklığı). Older PCP profiles load with
// their Namlu çıkış hızı and calculate as on main.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

// ---- Fixtures ----------------------------------------------------------

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcpm',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'PCPM',
  'model': 'Test',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_pcpm',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'PCPM 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};

double _mps(double fps) => UnitSystem.fpsToMps(fps);

/// PCP pellet, zero 30 m, 50 mm. [rifleFps]: the Tüfek card's Namlu çıkış
/// hızı; [minFps] / [maxFps]: the Mühimmat card's optional pair.
RifleProfile _pcp({
  String id = 'pcpm',
  String name = 'PCP Hız',
  double rifleFps = 950,
  double? minFps,
  double? maxFps,
  double? tubeBar,
  double? regulatorBar,
}) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'manual_rifle_pcpm',
  ammunitionId: 'manual_ammo_pcpm',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: _mps(rifleFps),
  pcpMinVelocityMps: minFps == null ? null : _mps(minFps),
  pcpMaxVelocityMps: maxFps == null ? null : _mps(maxFps),
  zeroRangeM: 30,
  sightHeightMm: 50,
  tubePressureBar: tubeBar,
  pressureBar: regulatorBar,
);

void _install() => CatalogRepository.installUserCatalog(
  UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo]),
);

Finder _key(String k) => find.byKey(Key(k));
Rect _rect(WidgetTester tester, String k) => tester.getRect(_key(k));

/// The box (the text field or the closed list) under [key].
Finder _boxOf(String key) =>
    find.descendant(of: _key(key), matching: find.byType(InputDecorator));

Future<void> _openNew(
  WidgetTester tester, {
  required bool pcp,
  double width = 390,
  double textScale = 1.0,
  MemoryProfileStore? store,
}) async {
  tester.view.physicalSize = Size(width * 3, 3200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store ?? MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    pcp ? 'PCP Tüfek' : 'Ateşli Tüfek',
  );
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(of: _key(key), matching: find.byType(TextField)),
    )
    .controller!
    .text;

String _missing(WidgetTester tester) {
  final f = _key('profile-missing');
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data ?? '';
}

/// [rows] top to bottom inside the card [cardKey]: each row starts below
/// the whole previous row; a two-box row is side by side (left first) when
/// the card has two columns, the second under the first when it has one.
void _expectRows(WidgetTester tester, String cardKey, List<List<String>> rows) {
  final card = _rect(tester, cardKey);
  double? previousBottom;
  for (final row in rows) {
    final rects = [for (final k in row) _rect(tester, k)];
    for (final (i, r) in rects.indexed) {
      expect(r.left, greaterThanOrEqualTo(card.left - 0.5), reason: row[i]);
      expect(r.right, lessThanOrEqualTo(card.right + 0.5), reason: row[i]);
      expect(r.bottom, lessThanOrEqualTo(card.bottom + 0.5), reason: row[i]);
    }
    final top = rects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
    if (previousBottom != null) {
      expect(
        top,
        greaterThanOrEqualTo(previousBottom - 0.5),
        reason: '${row.join(' | ')} below the row above',
      );
    }
    if (rects.length == 2) {
      final a = rects[0], b = rects[1];
      if (a.width < card.width * 0.75) {
        expect((a.top - b.top).abs(), lessThanOrEqualTo(1), reason: '$row');
        expect(a.right, lessThan(b.left), reason: '$row');
        expect((a.width - b.width).abs(), lessThan(1), reason: '$row');
      } else {
        expect(b.top, greaterThanOrEqualTo(a.bottom - 0.5), reason: '$row');
      }
    }
    previousBottom = rects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
  }
}

const _pcpRifleRows = [
  ['rifle-not-listed'],
  ['rifle-caliber', 'profile-velocity-fps'],
  ['rifle-twist-rate', 'rifle-twist-direction'],
  ['profile-tube-pressure', 'profile-regulator-pressure'],
  ['profile-zero', 'profile-distance-unit'],
  ['scope-sight-height'],
];

const _firearmRifleRows = [
  ['rifle-not-listed'],
  ['rifle-caliber', 'profile-velocity-fps'],
  ['rifle-twist-rate', 'rifle-twist-direction'],
  ['profile-zero', 'profile-distance-unit'],
  ['scope-sight-height'],
];

const _pcpAmmoRows = [
  ['ammo-type', 'ammo-brand-select'],
  ['ammo-model-select'],
  ['ammo-not-listed'],
  ['ammo-grain', 'ammo-bc'],
  ['ammo-bc-model'],
  ['profile-pcp-velocity-min', 'profile-pcp-velocity-max'],
];

/// Sight height is the last box of the Tüfek card, as wide as the card's
/// rows (full width).
void _sightLast(WidgetTester tester) {
  final sight = _rect(tester, 'scope-sight-height');
  final model = _rect(tester, 'rifle-model-select');
  expect((sight.left - model.left).abs(), lessThan(1));
  expect((sight.width - model.width).abs(), lessThan(1));
  for (final k in const [
    'rifle-caliber',
    'profile-velocity-fps',
    'rifle-twist-rate',
    'rifle-twist-direction',
    'profile-zero',
    'profile-distance-unit',
  ]) {
    expect(sight.top, greaterThanOrEqualTo(_rect(tester, k).bottom - 0.5));
  }
}

// ---- Hedef / Hız Doğrulama helpers ------------------------------------

Widget _hedef(RifleProfile p) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: BallisticsView.shot),
  ),
);

Future<double> _requiredUp(WidgetTester tester, RifleProfile p) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_hedef(p));
  await tester.pumpAndSettle();
  final up = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
  expect(up.requiredUp, isNotNull);
  return up.requiredUp!;
}

/// The truing page's default air (15 °C, 1013,25 hPa, %50).
const _truingAir = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 50,
);

/// Correction at [rangeM] for the 18 gr pellet zeroed and shot at [mps].
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
  final f = find.descendant(of: _key(key), matching: find.byType(TextField));
  final target = f.evaluate().isEmpty ? _key(key) : f;
  await tester.ensureVisible(target);
  await tester.enterText(target, text);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _pumpTruing(
  WidgetTester tester,
  RifleProfile p,
) async {
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(p);
  final active = MemoryActiveProfileStore()..value = p.id;
  await tester.pumpWidget(
    host(TruingScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
  return store;
}

/// Hız Doğrulama, Namlu çıkış hızı mode: an observation shot at [shotFps]
/// at 100 m; returns whether "profile uygula" is enabled.
Future<bool> _trueVelocity(WidgetTester tester, double shotFps) async {
  final observed = _correction(_mps(shotFps), 0.031, 100);
  await _enter(tester, 'truing-range', '100');
  await _enter(
    tester,
    'truing-observed',
    observed.toStringAsFixed(4).replaceAll('.', ','),
  );
  await _tapKey(tester, 'truing-compute');
  expect(_key('truing-result'), findsOneWidget);
  final apply = _key('truing-apply');
  await tester.ensureVisible(apply);
  return tester.widget<MenzilSecondaryButton>(apply).onPressed != null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _install();
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('Tüfek card order (by vertical position)', () {
    for (final (width, scale) in const [
      (390.0, 1.0),
      (390.0, 1.3),
      (320.0, 1.0),
      (320.0, 1.3),
    ]) {
      testWidgets('PCP (width $width, text ×$scale)', (tester) async {
        await _openNew(tester, pcp: true, width: width, textScale: scale);
        _expectRows(tester, 'profile-rifle-form', _pcpRifleRows);
        _sightLast(tester);
        // Tüp | Regülatör on the Tüfek card, not on the Mühimmat card.
        for (final k in const [
          'profile-tube-pressure',
          'profile-regulator-pressure',
          'profile-velocity-fps',
        ]) {
          expect(
            find.descendant(of: _key('profile-rifle-form'), matching: _key(k)),
            findsOneWidget,
            reason: k,
          );
          expect(
            find.descendant(of: _key('profile-ammo-form'), matching: _key(k)),
            findsNothing,
            reason: k,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('Ateşli Tüfek (width $width, text ×$scale)', (tester) async {
        await _openNew(tester, pcp: false, width: width, textScale: scale);
        _expectRows(tester, 'profile-rifle-form', _firearmRifleRows);
        _sightLast(tester);
        expect(_key('profile-tube-pressure'), findsNothing);
        expect(_key('profile-regulator-pressure'), findsNothing);
        expect(_key('profile-pcp-velocity-min'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('two columns at 390 pt: every row holds two boxes', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      for (final row in _pcpRifleRows.where((r) => r.length == 2)) {
        final a = _rect(tester, row[0]), b = _rect(tester, row[1]);
        expect((a.top - b.top).abs(), lessThanOrEqualTo(1), reason: '$row');
        expect(a.right, lessThan(b.left), reason: '$row');
      }
    });

    testWidgets('Namlu çıkış hızı: PCP ⓘ text, required, labels unchanged', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      final info = tester.widget<MenzilInfoButton>(
        find.descendant(
          of: _key('profile-velocity-fps'),
          matching: find.byType(MenzilInfoButton),
        ),
      );
      expect(info.text, ProfileFieldInfo.velocity);
      expect(_missing(tester), contains('Namlu çıkış hızı'));
      for (final label in const [
        'Kalibre',
        'Namlu çıkış hızı',
        'Yiv oranı',
        'Namlu yiv yönü',
        'Tüp basıncı',
        'Regülatör basıncı',
        'Sıfırlama mesafesi',
        'Mesafe birimi',
        'Sight height',
      ]) {
        expect(
          find.descendant(
            of: _key('profile-rifle-form'),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
      final fx = tester.widget<MenzilInfoButton>(
        find.descendant(
          of: _key('profile-velocity-fps'),
          matching: find.byType(MenzilInfoButton),
        ),
      );
      expect(fx.text, ProfileFieldInfo.velocityFirearm);
    });
  });

  group('PCP Mühimmat card', () {
    for (final (width, scale) in const [
      (390.0, 1.0),
      (390.0, 1.3),
      (320.0, 1.0),
      (320.0, 1.3),
    ]) {
      testWidgets('order (width $width, text ×$scale)', (tester) async {
        await _openNew(tester, pcp: true, width: width, textScale: scale);
        _expectRows(tester, 'profile-ammo-form', _pcpAmmoRows);
        expect(find.text('Aradığın mühimmat listede yok mu?'), findsOneWidget);
        // Deleted: "Basınca göre hız"; moved: Tüp | Regülatör.
        expect(find.text('Basınca göre hız'), findsNothing);
        expect(_key('profile-pv-bar-0'), findsNothing);
        for (final k in const [
          'profile-tube-pressure',
          'profile-regulator-pressure',
        ]) {
          expect(
            find.descendant(of: _key('profile-ammo-form'), matching: _key(k)),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Marka and Model always visible; Marka waits for Tip', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      MenzilSelect<String> brand() => tester.widget<MenzilSelect<String>>(
        find.descendant(
          of: _key('ammo-brand-select'),
          matching: find.byType(MenzilSelect<String>),
        ),
      );
      expect(_key('ammo-model-select'), findsOneWidget);
      expect(brand().onChanged, isNull);
      expect(brand().info, ProfileFieldInfo.pcpAmmoBrand);
      await chooseInSelect(tester, 'ammo-type', 'Pellet');
      expect(brand().onChanged, isNotNull);
      await chooseInSelect(tester, 'ammo-brand-select', 'H&N');
      expect(selectedValue<String>(tester, 'ammo-brand-select'), 'H&N');
    });

    testWidgets('typed entry: Tip on top, Marka | Model typed', (tester) async {
      await _openNew(tester, pcp: true);
      await chooseInSelect(tester, 'ammo-type', 'Slug');
      await openAmmoManual(tester);
      expect(selectedValue<AmmunitionType>(tester, 'ammo-type'), isNotNull);
      final b = _rect(tester, 'ammo-brand'), m = _rect(tester, 'ammo-model');
      expect((b.top - m.top).abs(), lessThan(1));
      expect(b.right, lessThan(m.left));
      expect(_key('ammo-back-to-list'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('units and ⓘ inside the compact boxes (approved design)', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      for (final (key, unit) in const [
        ('ammo-grain', 'gr'),
        ('profile-pcp-velocity-min', 'fps'),
        ('profile-pcp-velocity-max', 'fps'),
      ]) {
        final box = tester.getRect(_boxOf(key).first);
        final u = find.descendant(of: _key(key), matching: find.text(unit));
        expect(u, findsOneWidget, reason: key);
        final r = tester.getRect(u);
        expect(r.left, greaterThanOrEqualTo(box.left), reason: key);
        expect(r.right, lessThanOrEqualTo(box.right), reason: key);
        final info = find.descendant(
          of: _key(key),
          matching: find.byType(MenzilInfoButton),
        );
        final i = tester.getRect(info);
        expect(i.top, greaterThanOrEqualTo(box.top - 0.5), reason: key);
        expect(i.bottom, lessThanOrEqualTo(box.bottom + 0.5), reason: key);
      }
    });
  });

  group('units inside the box (MenzilInput, every page)', () {
    for (final (width, scale) in const [
      (390.0, 1.0),
      (320.0, 1.0),
      (320.0, 1.3),
    ]) {
      testWidgets('Tüfek card: unit in the box at the right, ⓘ in the label '
          'row, value never under the unit (width $width, text ×$scale)', (
        tester,
      ) async {
        await _openNew(tester, pcp: true, width: width, textScale: scale);
        for (final (key, unit) in const [
          ('profile-velocity-fps', 'fps'),
          ('rifle-twist-rate', 'inç'),
          ('profile-tube-pressure', 'bar'),
          ('profile-regulator-pressure', 'bar'),
          ('profile-zero', 'm'),
          ('scope-sight-height', 'mm'),
        ]) {
          // A long value: the text area ends where the unit starts.
          await enterRifleField(tester, key, '1234567890123456');
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          final box = tester.getRect(_boxOf(key).first);
          final unitFinder = find.descendant(
            of: _key(key),
            matching: find.byKey(const ValueKey('menzil-input-unit')),
          );
          expect(unitFinder, findsOneWidget, reason: key);
          expect(tester.widget<Text>(unitFinder).data, unit, reason: key);
          final u = tester.getRect(unitFinder);
          expect(u.left, greaterThanOrEqualTo(box.left), reason: key);
          expect(u.right, lessThanOrEqualTo(box.right), reason: key);
          expect(u.top, greaterThanOrEqualTo(box.top), reason: key);
          expect(u.bottom, lessThanOrEqualTo(box.bottom), reason: key);
          expect(u.center.dx, greaterThan(box.center.dx), reason: key);
          final editable = tester.getRect(
            find.descendant(of: _key(key), matching: find.byType(EditableText)),
          );
          expect(editable.right, lessThanOrEqualTo(u.left + 0.5), reason: key);
          // Not in the label row any more.
          expect(
            find.descendant(
              of: find.descendant(
                of: _key(key),
                matching: find.byType(MenzilFieldLabel),
              ),
              matching: find.text(unit),
            ),
            findsNothing,
            reason: key,
          );
          // ⓘ in the label row, above the box.
          final info = tester.getRect(
            find.descendant(
              of: _key(key),
              matching: find.byType(MenzilInfoButton),
            ),
          );
          expect(info.bottom, lessThanOrEqualTo(box.top + 0.5), reason: key);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('labels fit on one line at 390 pt', (tester) async {
      await _openNew(tester, pcp: true);
      final one = tester.getRect(
        find.descendant(
          of: _key('rifle-twist-rate'),
          matching: find.text('Yiv oranı'),
        ),
      );
      for (final (key, label) in const [
        ('profile-zero', 'Sıfırlama mesafesi'),
        ('profile-velocity-fps', 'Namlu çıkış hızı'),
        ('profile-regulator-pressure', 'Regülatör basıncı'),
      ]) {
        final r = tester.getRect(
          find.descendant(of: _key(key), matching: find.text(label)),
        );
        expect((r.height - one.height).abs(), lessThan(1), reason: label);
      }
    });
  });

  group('owner ⓘ texts, word for word', () {
    testWidgets('Tüp basıncı and Regülatör basıncı (Tüfek card)', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      for (final (key, title, text) in const [
        ('profile-tube-pressure', 'Tüp basıncı', ProfileFieldInfo.tubePressure),
        (
          'profile-regulator-pressure',
          'Regülatör basıncı',
          ProfileFieldInfo.regulatorPressure,
        ),
        (
          'profile-pcp-velocity-min',
          'En düşük namlu çıkış hızı',
          ProfileFieldInfo.pcpMinVelocity,
        ),
        (
          'profile-pcp-velocity-max',
          'En yüksek namlu çıkış hızı',
          ProfileFieldInfo.pcpMaxVelocity,
        ),
      ]) {
        final w = tester.widget<MenzilInfoButton>(
          find.descendant(
            of: _key(key),
            matching: find.byType(MenzilInfoButton),
          ),
        );
        expect(w.title, title);
        expect(w.text, text);
      }
      expect(
        ProfileFieldInfo.tubePressure,
        'Regülatörsüz tüfekte tüp basıncı düştükçe hız da değişir. Hesabın '
        'doğru olması için tüpünüzü her 10 atışta bir doldurun. Örnek: '
        "tüpünüzü 300 bar'a dolduruyorsanız 250 bar'ın altında atış yapmayın.",
      );
      expect(
        ProfileFieldInfo.regulatorPressure,
        'Regülatörlü tüfekte hız, tüp basıncı regülatör basıncının üstünde '
        'kaldıkça sabittir. Hesabın doğru olması için tüp basıncınızın '
        'regülatör basıncının altına inmemesine dikkat edin. Tüfeğinizde '
        'regülatör yoksa bu kutuyu boş bırakın. Örnek: regülatörünüz 200 '
        "bar'a ayarlıysa tüp basıncınız 210 bar'a inince tüpünüzü doldurun.",
      );
      // The velocity boxes are optional: their texts never say required.
      for (final t in const [
        ProfileFieldInfo.pcpMinVelocity,
        ProfileFieldInfo.pcpMaxVelocity,
      ]) {
        final lower = t.toLowerCase();
        expect(lower, isNot(contains('zorunlu')));
        expect(lower, isNot(contains('gerekli')));
        expect(lower, isNot(contains('mutlaka')));
      }
    });
  });

  group('En düşük | En yüksek in the editor', () {
    testWidgets('both empty: nothing missing for them', (tester) async {
      await _openNew(tester, pcp: true);
      expect(_missing(tester), isNot(contains('En düşük')));
      expect(_missing(tester), isNot(contains('En yüksek')));
    });

    testWidgets('only En düşük: the empty box says both are needed and '
        'saving waits', (tester) async {
      await _openNew(tester, pcp: true);
      await enterRifleField(tester, 'profile-pcp-velocity-min', '830');
      expect(
        find.descendant(
          of: _key('profile-pcp-velocity-max'),
          matching: find.text('En düşük ve en yüksek hızın ikisini de girin.'),
        ),
        findsOneWidget,
      );
      expect(_missing(tester), contains('En yüksek namlu çıkış hızı'));
      // Only En yüksek: the same on En düşük.
      await enterRifleField(tester, 'profile-pcp-velocity-min', '');
      await enterRifleField(tester, 'profile-pcp-velocity-max', '860');
      expect(
        find.descendant(
          of: _key('profile-pcp-velocity-min'),
          matching: find.text('En düşük ve en yüksek hızın ikisini de girin.'),
        ),
        findsOneWidget,
      );
      expect(_missing(tester), contains('En düşük namlu çıkış hızı'));
    });

    testWidgets('En düşük > En yüksek: Turkish error; range 100–4900 fps', (
      tester,
    ) async {
      await _openNew(tester, pcp: true);
      await fillPcpVelocities(tester, minFps: '860', maxFps: '830');
      expect(
        find.descendant(
          of: _key('profile-pcp-velocity-max'),
          matching: find.text('En düşük hızdan küçük olamaz.'),
        ),
        findsOneWidget,
      );
      expect(_missing(tester), contains('En yüksek namlu çıkış hızı'));
      await fillPcpVelocities(tester, minFps: '830', maxFps: '860');
      expect(find.text('En düşük hızdan küçük olamaz.'), findsNothing);
      await fillPcpVelocities(tester, minFps: '50', maxFps: '6000');
      expect(find.text('100–4900 arasında bir değer girin.'), findsNWidgets(2));
    });

    for (final (minFps, maxFps) in const [('830', '860'), ('', '')]) {
      testWidgets('saving Namlu çıkış hızı 950 with En düşük "$minFps" / En '
          'yüksek "$maxFps"', (tester) async {
        final store = MemoryProfileStore();
        await _openNew(tester, pcp: true, store: store);
        await fillRifleForm(tester);
        await fillScopeForm(tester);
        await enterRifleField(tester, 'scope-travel-elevation', '170');
        await fillAmmoForm(tester);
        await fillShotValues(tester, velocityFps: '950');
        await enterRifleField(tester, 'profile-tube-pressure', '250');
        await enterRifleField(tester, 'profile-regulator-pressure', '200');
        if (minFps.isNotEmpty) {
          await fillPcpVelocities(tester, minFps: minFps, maxFps: maxFps);
        }
        await tester.ensureVisible(find.text('Kaydet'));
        await tester.tap(find.text('Kaydet'));
        await tester.pumpAndSettle();
        final saved = (await store.all()).single;
        // Same saved keys as before for the Tüfek card's values.
        expect(saved.muzzleVelocityMps, closeTo(_mps(950), 1e-9));
        expect(saved.tubePressureBar, 250);
        expect(saved.pressureBar, 200);
        if (minFps.isEmpty) {
          expect(saved.pcpMinVelocityMps, isNull);
          expect(saved.pcpMaxVelocityMps, isNull);
          expect(saved.velocityMps, closeTo(_mps(950), 1e-9));
        } else {
          expect(saved.pcpMinVelocityMps, closeTo(_mps(830), 1e-9));
          expect(saved.pcpMaxVelocityMps, closeTo(_mps(860), 1e-9));
          expect(UnitSystem.mpsToFps(saved.velocityMps), closeTo(845, 1e-9));
        }
        // Profili Düzenle: every value comes back in its box.
        await tester.tap(find.text(saved.name).first);
        await tester.pumpAndSettle();
        expect(_text(tester, 'profile-velocity-fps'), '950');
        expect(_text(tester, 'profile-pcp-velocity-min'), minFps);
        expect(_text(tester, 'profile-pcp-velocity-max'), maxFps);
        expect(_text(tester, 'profile-tube-pressure'), '250');
        expect(_text(tester, 'profile-regulator-pressure'), '200');
      });
    }
  });

  group('the velocity every calculation uses', () {
    test('RifleProfile.velocityMps and ProfileInput', () {
      expect(
        UnitSystem.mpsToFps(_pcp(minFps: 830, maxFps: 860).velocityMps),
        closeTo(845, 1e-9),
      );
      expect(_pcp().velocityMps, _mps(950));
      expect(_pcp(minFps: 830).velocityMps, _mps(950));
      expect(_pcp(maxFps: 860).velocityMps, _mps(950));
      expect(_pcp(minFps: 860, maxFps: 830).velocityMps, _mps(950));
      ProfileInput v(String? min, String? max, WeaponPlatform p) =>
          ProfileInput.validate(
            name: 'P',
            muzzleVelocityText: '${_mps(950)}',
            zeroRangeText: '30',
            sightHeightText: '50',
            platform: p,
            pcpMinVelocityText: min,
            pcpMaxVelocityText: max,
          );
      final both = v('${_mps(830)}', '${_mps(860)}', WeaponPlatform.pcp);
      expect(both.muzzleVelocityMps, _mps(950));
      expect(both.pcpMinVelocityMps, _mps(830));
      expect(both.pcpMaxVelocityMps, _mps(860));
      final none = v(null, null, WeaponPlatform.pcp);
      expect(none.pcpMinVelocityMps, isNull);
      expect(
        () => v('${_mps(830)}', null, WeaponPlatform.pcp),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'En düşük ve en yüksek hızın ikisini de girin.',
          ),
        ),
      );
      expect(
        () => v('${_mps(860)}', '${_mps(830)}', WeaponPlatform.pcp),
        throwsFormatException,
      );
      final fx = v('${_mps(830)}', '${_mps(860)}', WeaponPlatform.firearm);
      expect(fx.pcpMinVelocityMps, isNull);
      expect(fx.muzzleVelocityMps, _mps(950));
    });

    testWidgets('Hedef: 830 / 860 (Tüfek 950) = 845; empty = Tüfek 950; '
        'only En düşük 830 = Tüfek 950', (tester) async {
      final mean = await _requiredUp(
        tester,
        _pcp(rifleFps: 950, minFps: 830, maxFps: 860),
      );
      final at845 = await _requiredUp(tester, _pcp(rifleFps: 845));
      final empty = await _requiredUp(tester, _pcp(rifleFps: 950));
      final at950 = await _requiredUp(
        tester,
        _pcp(rifleFps: 700, minFps: 950, maxFps: 950),
      );
      final onlyMin = await _requiredUp(
        tester,
        _pcp(rifleFps: 950, minFps: 830),
      );
      expect(mean, closeTo(at845, 1e-9));
      expect(empty, closeTo(at950, 1e-9));
      expect(onlyMin, closeTo(empty, 1e-9));
      // 845 and 950 fps are clearly different solutions.
      expect((mean - empty).abs(), greaterThan(0.1));
      expect(_key('shot-pcp-velocity-missing'), findsNothing);
    });

    testWidgets('Hedef: Tüp / Regülatör basıncı are not in the formula', (
      tester,
    ) async {
      final plain = await _requiredUp(tester, _pcp(minFps: 830, maxFps: 860));
      final pressures = await _requiredUp(
        tester,
        _pcp(minFps: 830, maxFps: 860, tubeBar: 120, regulatorBar: 150),
      );
      expect(pressures, closeTo(plain, 1e-12));
    });

    testWidgets('Hız Doğrulama with 830 / 860: shows and trues 845, never '
        'writes it', (tester) async {
      final p = _pcp(rifleFps: 950, minFps: 830, maxFps: 860);
      final store = await _pumpTruing(tester, p);
      expect(find.textContaining('Namlu çıkış hızı: 845 fps'), findsOneWidget);
      expect(_key('truing-pcp-mean'), findsOneWidget);
      // Shot at exactly the mean: the trued velocity is the mean.
      final canApply = await _trueVelocity(tester, 845);
      expect(find.text('845 fps'), findsWidgets);
      expect(canApply, isFalse);
      final saved = (await store.all()).single;
      expect(saved.muzzleVelocityMps, p.muzzleVelocityMps);
      expect(saved.pcpMinVelocityMps, p.pcpMinVelocityMps);
      expect(saved.pcpMaxVelocityMps, p.pcpMaxVelocityMps);
    });

    for (final (label, profile) in [
      ('empty', _pcp(rifleFps: 950)),
      ('only En düşük 830', _pcp(rifleFps: 950, minFps: 830)),
    ]) {
      testWidgets('Hız Doğrulama, $label: uses the Tüfek 950 fps', (
        tester,
      ) async {
        await _pumpTruing(tester, profile);
        expect(
          find.textContaining('Namlu çıkış hızı: 950 fps'),
          findsOneWidget,
        );
        expect(_key('truing-pcp-mean'), findsNothing);
        final canApply = await _trueVelocity(tester, 950);
        expect(find.text('950 fps'), findsWidgets);
        // As on main: the Tüfek velocity may be applied (after confirm).
        expect(canApply, isTrue);
      });
    }
  });

  group('older PCP profile (saved before 2026-10-16)', () {
    /// A PCP profile JSON without the new keys, regulated above its
    /// regulator pressure (main solved it with its Namlu çıkış hızı).
    Map<String, dynamic> oldJson() {
      final j = const ProfileCodec().encode(
        _pcp(
          id: 'eski',
          name: 'Eski PCP',
          rifleFps: 885.8,
          tubeBar: 250,
          regulatorBar: 150,
        ),
      );
      return Map<String, dynamic>.of(j)
        ..remove('pcpMinVelocityMps')
        ..remove('pcpMaxVelocityMps');
    }

    test('decodes with its velocity and no pair', () {
      final p = const ProfileCodec().decode(oldJson());
      expect(p.muzzleVelocityMps, closeTo(_mps(885.8), 1e-9));
      expect(p.pcpMinVelocityMps, isNull);
      expect(p.velocityMps, p.muzzleVelocityMps);
    });

    testWidgets('Profili Düzenle: Namlu çıkış hızı in its box, pair empty, '
        'nothing missing, Güncelle keeps it', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 3200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(const ProfileCodec().decode(oldJson()));
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eski PCP').first);
      await tester.pumpAndSettle();
      expect(find.text('Profili Düzenle'), findsOneWidget);
      expect(_text(tester, 'profile-velocity-fps'), '885.8');
      expect(_text(tester, 'profile-pcp-velocity-min'), '');
      expect(_text(tester, 'profile-pcp-velocity-max'), '');
      expect(_text(tester, 'profile-tube-pressure'), '250');
      expect(_text(tester, 'profile-regulator-pressure'), '150');
      expect(_missing(tester), isNot(contains('namlu çıkış')));
      expect(_missing(tester), isNot(contains('Namlu çıkış')));
      expect(find.text('Namlu çıkış hızlarını girin'), findsNothing);
    });

    testWidgets('Hedef: a number, no "Namlu çıkış hızlarını girin", the '
        'same as main', (tester) async {
      final p = const ProfileCodec().decode(oldJson());
      final up = await _requiredUp(tester, p);
      expect(find.textContaining('Namlu çıkış hızlarını girin'), findsNothing);
      expect(_key('shot-pcp-velocity-missing'), findsNothing);
      debugPrint('PCP_OLD_GOLDEN U$up');
      // Recorded by running this same case on main (see the report).
      expect('$up', _oldPcpGoldenOnMain);
    });

    test('profile list summary shows its velocity', () {
      final p = const ProfileCodec().decode(oldJson());
      expect(profileListSummary(p), contains('886 fps'));
      expect(profileListSummary(p), isNot(contains('girin')));
    });
  });
}

/// requiredUp of the older PCP profile above on main (e7b29bf), printed by
/// the same case run there (test-diag run 38947080076 on branch
/// tmp/pcp-eski-golden-main = main + one printing test).
const _oldPcpGoldenOnMain = '6.142636207799528';
