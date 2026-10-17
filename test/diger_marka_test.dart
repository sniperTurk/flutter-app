// Profil → Mühimmat, "Diğer marka" and "Aradığın mühimmat listede yok mu?"
// (owner, 2026-10-17 21:26–21:53 Istanbul, TestFlight 113, approved
// drawings):
//
//   Diğer marka state:  Tip / Mühimmat türü | Marka ("Diğer marka") · Model
//                       (full width, filled "Diğer marka model 6,35", no
//                       chevron, no list) · Ağırlık (empty, gr) | BC · BC
//                       modeli | Mermi uzunluğu · … · the link, last.
//   Link:               "Aradığın mühimmat listede yok mu?" at the very
//                       bottom of the card, left-aligned; it opens a dialog
//                       with one box and sends the text to our catalog
//                       inbox (a fake here; never the real worker).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/ammo_report_dialog.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/product_report.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

Finder _key(String k) => find.byKey(Key(k));
Rect _rect(WidgetTester tester, String k) => tester.getRect(_key(k).first);
Finder _in(String key, Finder f) => find.descendant(of: _key(key), matching: f);

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_in(key, find.byType(TextField))).controller!.text;

List<T?> _values<T>(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<T>>(_in(key, find.byType(MenzilSelect<T>)))
          .items)
    i.value,
];

List<String> _labels<T>(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<T>>(_in(key, find.byType(MenzilSelect<T>)))
          .items)
    (i.child as Text).data!,
];

Finder get _openMenuItems => find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
);

Future<void> _pump(
  WidgetTester tester, {
  MemoryProfileStore? store,
  TestProductReport? report,
  double width = 430,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, 3200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final services = testServices(productReport: report ?? TestProductReport());
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) =>
          ToolsServicesScope(services: services, child: child!),
      home: ProfilesScreen(store: store ?? MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openNew(
  WidgetTester tester, {
  required bool pcp,
  MemoryProfileStore? store,
  TestProductReport? report,
  double width = 430,
  double textScale = 1.0,
}) async {
  await _pump(
    tester,
    store: store,
    report: report,
    width: width,
    textScale: textScale,
  );
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    pcp ? 'PCP Tüfek' : 'Ateşli Tüfek',
  );
}

/// Ateşli, .308 Win, Fabrika fişeği, Marka "Diğer marka".
Future<void> _firearmOther(WidgetTester tester) async {
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await chooseOtherAmmoBrand(tester);
}

void _expectFilledModelBox(WidgetTester tester, String text) {
  expect(_key('ammo-model-select'), findsNothing);
  expect(_key('ammo-model-other'), findsOneWidget);
  final field = tester.widget<TextField>(
    _in('ammo-model-other', find.byType(TextField)),
  );
  expect(field.controller!.text, text);
  expect(field.readOnly, isTrue);
  // No chevron: it is not a list.
  expect(_in('ammo-model-other', find.byIcon(Icons.expand_more)), findsNothing);
  // Model shares no row: full width like the Marka | Tip row.
  final card = _rect(tester, 'profile-ammo-form');
  final box = _rect(tester, 'ammo-model-other');
  expect(box.width, greaterThan(card.width * 0.75));
}

Future<void> _tapModelBox(WidgetTester tester) async {
  await tester.ensureVisible(_key('ammo-model-other'));
  await tester.tap(_in('ammo-model-other', find.byType(TextField)));
  await tester.pumpAndSettle();
}

/// Every box key of the Mühimmat card that is on screen.
const _cardKeys = [
  'ammo-type',
  'ammo-source',
  'ammo-brand-select',
  'ammo-model-select',
  'ammo-model-other',
  'ammo-grain',
  'ammo-bc',
  'ammo-bc-model',
  'ammo-length',
  'profile-pcp-velocity-min',
  'profile-pcp-velocity-max',
  'ammo-bc-warning',
  'ammo-typed-summary',
];

void _expectLinkLast(WidgetTester tester) {
  final link = _rect(tester, 'ammo-not-listed');
  final card = _rect(tester, 'profile-ammo-form');
  expect(link.bottom, lessThanOrEqualTo(card.bottom + 0.5));
  // Left-aligned: starts at the card's content edge.
  expect(link.left - card.left, lessThan(40));
  var seen = 0;
  for (final k in _cardKeys) {
    if (_key(k).evaluate().isEmpty) continue;
    seen++;
    expect(
      link.top,
      greaterThanOrEqualTo(_rect(tester, k).bottom - 0.5),
      reason: '$k must be above the link',
    );
  }
  expect(seen, greaterThanOrEqualTo(6));
  // And the link's own text is the only one.
  expect(
    _in('ammo-not-listed', find.text('Aradığın mühimmat listede yok mu?')),
    findsOneWidget,
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  final link = _key('ammo-not-listed');
  await Scrollable.ensureVisible(tester.element(link), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

FilledButton _sendButton(WidgetTester tester) =>
    tester.widget<FilledButton>(_key('ammo-report-send'));

Future<void> _typeReport(WidgetTester tester, String text) async {
  await tester.enterText(_in('ammo-report-text', find.byType(TextField)), text);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('"Diğer marka" in the Marka list', () {
    testWidgets('PCP: last item, after the listed brands', (tester) async {
      await _openNew(tester, pcp: true);
      await chooseInSelect(tester, 'rifle-caliber', '6.35 mm (.25)');
      await chooseInSelect(tester, 'ammo-type', 'Pellet');
      final values = _values<String>(tester, 'ammo-brand-select');
      expect(values.last, '__other');
      expect(_labels<String>(tester, 'ammo-brand-select').last, 'Diğer marka');
      expect(values.length, greaterThan(1));
      expect(values.where((v) => v == '__other'), hasLength(1));
      // No other "other" mechanism: no "Diğer", no "Listede yok".
      expect(
        _labels<String>(tester, 'ammo-brand-select'),
        isNot(anyElement(anyOf('Diğer', 'Listede yok'))),
      );
    });

    for (final source in const ['Fabrika fişeği', 'El dolumu']) {
      testWidgets('firearm, $source: last item', (tester) async {
        await _openNew(tester, pcp: false);
        await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
        await chooseInSelect(tester, 'ammo-source', source);
        final values = _values<String>(tester, 'ammo-brand-select');
        expect(values.last, '__other');
        expect(values.length, greaterThan(1));
        expect(
          _labels<String>(tester, 'ammo-brand-select').last,
          'Diğer marka',
        );
        expect(
          _labels<String>(tester, 'ammo-brand-select'),
          isNot(anyElement(anyOf('Diğer', 'Listede yok'))),
        );
        expect(_key('ammo-brand-pick'), findsNothing);
      });
    }

    testWidgets('firearm ⓘ describes "Diğer marka"', (tester) async {
      await _openNew(tester, pcp: false);
      final s = tester.widget<MenzilSelect<String>>(
        _in('ammo-brand-select', find.byType(MenzilSelect<String>)),
      );
      expect(s.info, ProfileFieldInfo.ammoBrandPick);
      expect(ProfileFieldInfo.ammoBrandPick, contains('"Diğer marka"'));
      expect(ProfileFieldInfo.pcpAmmoBrand, contains('"Diğer marka"'));
      expect(ProfileFieldInfo.ammoNothingListed, contains('"Diğer marka"'));
    });
  });

  group('picking "Diğer marka"', () {
    testWidgets('PCP 6,35: Model "Diğer marka model 6,35", no list, nothing '
        'filled', (tester) async {
      await _openNew(tester, pcp: true);
      await chooseInSelect(tester, 'rifle-caliber', '6.35 mm (.25)');
      await chooseInSelect(tester, 'ammo-type', 'Slug');
      // A listed slug first: its values must not stay.
      final brands = _labels<String>(tester, 'ammo-brand-select');
      await chooseInSelect(tester, 'ammo-brand-select', brands.first);
      final models = _labels<int>(tester, 'ammo-model-select');
      await chooseInSelect(tester, 'ammo-model-select', models.first);
      expect(_text(tester, 'ammo-grain'), isNotEmpty);
      await chooseOtherAmmoBrand(tester);
      expect(selectedValue<String>(tester, 'ammo-brand-select'), '__other');
      _expectFilledModelBox(tester, 'Diğer marka model 6,35');
      expect(_text(tester, 'ammo-grain'), '');
      expect(_text(tester, 'ammo-bc'), '');
      expect(_text(tester, 'ammo-length'), '');
      // Tip stays; BC modeli G1 as for any PCP round.
      expect(
        selectedValue<AmmunitionType>(tester, 'ammo-type'),
        AmmunitionType.slug,
      );
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
      expect(_in('ammo-grain', find.text('gr')), findsOneWidget);
      // Tapping the Model box opens nothing.
      await _tapModelBox(tester);
      expect(_openMenuItems, findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      // Kalibre 5,50: the text follows.
      await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
      _expectFilledModelBox(tester, 'Diğer marka model 5,50');
      expect(tester.takeException(), isNull);
    });

    testWidgets('firearm .308 Win: "Diğer marka model .308 Win"; listed '
        'values go; BC modeli G1 / G7 from "Seçiniz"', (tester) async {
      await _openNew(tester, pcp: false);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
      await chooseInSelect(
        tester,
        'ammo-model-select',
        'ELD Match 168 gr ELD Match',
      );
      expect(_text(tester, 'ammo-grain'), '168');
      await chooseOtherAmmoBrand(tester);
      _expectFilledModelBox(tester, 'Diğer marka model .308 Win');
      expect(_text(tester, 'ammo-grain'), '');
      expect(_text(tester, 'ammo-bc'), '');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), isNull);
      expect(_values<String>(tester, 'ammo-bc-model'), ['g1', 'g7']);
      // Mühimmat türü stays.
      expect(selectedValue<bool>(tester, 'ammo-source'), isTrue);
      await _tapModelBox(tester);
      expect(_openMenuItems, findsNothing);
      // Back to a listed brand: the Model list again; typed values go, so
      // nothing is saved under Hornady without a Model.
      await enterRifleField(tester, 'ammo-grain', '175');
      await enterRifleField(tester, 'ammo-bc', '0,5');
      await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
      expect(_key('ammo-model-select'), findsOneWidget);
      expect(_key('ammo-model-other'), findsNothing);
      expect(_text(tester, 'ammo-grain'), '');
      expect(_text(tester, 'ammo-bc'), '');
      expect(selectedValue<bool>(tester, 'ammo-source'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no Kalibre: "Diğer marka model"', (tester) async {
      await _openNew(tester, pcp: false);
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseOtherAmmoBrand(tester);
      _expectFilledModelBox(tester, 'Diğer marka model');
      await chooseInSelect(tester, 'rifle-caliber', '6.5 Creedmoor');
      _expectFilledModelBox(tester, 'Diğer marka model 6.5 Creedmoor');
    });

    testWidgets('firearm typed weight: plausibility as before', (tester) async {
      await _openNew(tester, pcp: false);
      await _firearmOther(tester);
      await enterRifleField(tester, 'ammo-grain', '11');
      expect(
        find.text(
          'Bu ağırlık bu kalibre için mantıklı değil. Kutudaki değeri kontrol '
          'edin.',
        ),
        findsOneWidget,
      );
      await enterRifleField(tester, 'ammo-grain', '173');
      expect(find.textContaining('mantıklı değil'), findsNothing);
      expect(_key('ammo-grain-select'), findsNothing);
    });
  });

  group('saving and opening again', () {
    testWidgets('PCP: saved as "Diğer marka" / "Diğer marka model 6,35"; '
        'reopens in the same state', (tester) async {
      final store = MemoryProfileStore();
      await _openNew(tester, pcp: true, store: store);
      await fillRifleForm(tester, caliber: '6.35 mm (.25)');
      await fillScopeForm(tester);
      await chooseInSelect(tester, 'ammo-type', 'Slug');
      await chooseOtherAmmoBrand(tester);
      await enterRifleField(tester, 'ammo-grain', '33,95');
      await enterRifleField(tester, 'ammo-bc', '0,08');
      await fillShotValues(tester);
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.brand, 'Diğer marka');
      expect(a.model, 'Diğer marka model 6,35');
      expect(a.grain, 33.95);
      expect(a.ballisticCoefficient, 0.08);
      expect(a.type, AmmunitionType.slug);
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(find.text('Profili Düzenle'), findsOneWidget);
      expect(selectedValue<String>(tester, 'ammo-brand-select'), '__other');
      _expectFilledModelBox(tester, 'Diğer marka model 6,35');
      expect(_text(tester, 'ammo-grain'), '33.95');
    });

    testWidgets('summary card: "Diğer marka model 6,35" (names the brand '
        'once)', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(const [
          {
            'id': 'manual_rifle_s',
            'kind': 'rifle',
            'platform': 'pcp',
            'brand': 'PCPM',
            'model': 'Test',
            'caliberMm': 6.35,
            'twistDirection': 'right',
            'twistRateIn': 18,
          },
          {
            'id': 'manual_ammo_s',
            'kind': 'ammo',
            'platform': 'pcp',
            'brand': 'Diğer marka',
            'model': 'Diğer marka model 6,35',
            'caliberMm': 6.35,
            'grain': 33.95,
            'ammoType': 'slug',
            'bc': 0.08,
            'bcModel': 'g1',
          },
        ]),
      );
      final store = MemoryProfileStore();
      const profile = RifleProfile(
        id: 's',
        name: 'Özet',
        rifleId: 'manual_rifle_s',
        ammunitionId: 'manual_ammo_s',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 280,
        zeroRangeM: 30,
        sightHeightMm: 50,
      );
      await store.save(profile);
      tester.view.physicalSize = const Size(390 * 3, 3200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(store: store, activeProfileId: 's'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _in(
          'profile-summary-ammo',
          find.textContaining('Diğer marka model 6,35', findRichText: true),
        ),
        findsWidgets,
      );
      expect(find.textContaining('Diğer marka Diğer marka'), findsNothing);
    });

    testWidgets('firearm: typed values saved; typed summary line', (
      tester,
    ) async {
      final store = MemoryProfileStore();
      await _openNew(tester, pcp: false, store: store);
      await fillRifleForm(tester, caliber: '.308 Win');
      await fillScopeForm(tester);
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseOtherAmmoBrand(tester);
      await enterRifleField(tester, 'ammo-grain', '173');
      await enterRifleField(tester, 'ammo-bc', '0,5');
      await chooseInSelect(tester, 'ammo-bc-model', 'G7');
      await enterRifleField(tester, 'ammo-length', '31,2');
      await chooseInSelect(tester, 'profile-powder-coef', '1,5');
      await chooseInSelect(tester, 'profile-powder-temp', '21');
      await fillShotValues(
        tester,
        velocityFps: '2650',
        zero: '100',
        sight: '45',
      );
      expect(
        _in(
          'ammo-typed-summary',
          find.text(
            'Diğer marka model .308 Win · .308 Win · 173 gr (11,2 g) · BC 0,5 '
            'G7',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.brand, 'Diğer marka');
      expect(a.model, 'Diğer marka model .308 Win');
      expect(a.grain, 173);
      expect(a.ballisticCoefficient, 0.5);
      expect(a.ballisticModel, BallisticModel.g7);
      expect(a.lengthMm, 31.2);
      expect(saved.powderTempCoefPercentPer15C, 1.5);
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-brand-select'), '__other');
      _expectFilledModelBox(tester, 'Diğer marka model .308 Win');
      expect(_text(tester, 'ammo-grain'), '173');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
      expect(
        tester
            .widget<MenzilPrimaryButton>(
              find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('an older typed firearm profile opens as Diğer marka with its '
        'saved names, values and bands; Güncelle keeps them', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(const [
          {
            'id': 'manual_rifle_old',
            'kind': 'rifle',
            'platform': 'firearm',
            'brand': 'Atölye',
            'model': 'Özel',
            'caliberMm': 7.82,
            'twistDirection': 'right',
            'twistRateIn': 10,
          },
          {
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
            'bcBands': [
              {'mps': 700.0, 'bc': 0.475},
              {'mps': 550.0, 'bc': 0.46},
              {'mps': 0.0, 'bc': 0.44},
            ],
          },
          {
            'id': 'manual_scope_old',
            'kind': 'scope',
            'platform': 'firearm',
            'brand': 'Optik',
            'model': '5-25x56',
            'objectiveMm': 56,
            'click': 0.1,
            'clickUnit': 'mrad',
            'focal': 'ffp',
            'minMag': 5,
            'maxMag': 25,
          },
        ]),
      );
      final store = MemoryProfileStore();
      await store.save(
        const RifleProfile(
          id: 'old',
          name: 'Eski Profil',
          rifleId: 'manual_rifle_old',
          ammunitionId: 'manual_ammo_old',
          scopeId: 'manual_scope_old',
          muzzleVelocityMps: 800,
          zeroRangeM: 100,
          sightHeightMm: 45,
          powderTempCoefPercentPer15C: 0.8,
          powderTempReferenceC: 20,
        ),
      );
      await _pump(tester, store: store);
      await tester.tap(find.text('Eski Profil').first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-brand-select'), '__other');
      _expectFilledModelBox(tester, 'Eski Marka Eski Fişek');
      expect(_text(tester, 'ammo-grain'), '175');
      expect(_text(tester, 'ammo-bc'), '0.475');
      expect(selectedValue<String>(tester, 'profile-powder-coef'), '0,8');
      await tester.tap(find.text('Güncelle'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.brand, 'Eski Marka');
      expect(a.model, 'Eski Fişek');
      expect(a.grain, 175);
      expect(a.ballisticCoefficient, 0.475);
      expect(a.bcBands, hasLength(3));
      expect(saved.powderTempCoefPercentPer15C, 0.8);
    });

    testWidgets('an older typed PCP profile opens as Diğer marka; Güncelle '
        'keeps it', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(const [
          {
            'id': 'manual_rifle_p',
            'kind': 'rifle',
            'platform': 'pcp',
            'brand': 'PCPM',
            'model': 'Test',
            'caliberMm': 5.5,
            'twistDirection': 'right',
            'twistRateIn': 18,
          },
          {
            'id': 'manual_ammo_p',
            'kind': 'ammo',
            'platform': 'pcp',
            'brand': 'Atölye',
            'model': 'Kendi Slug',
            'caliberMm': 5.5,
            'grain': 25,
            'ammoType': 'slug',
            'bc': 0.07,
            'bcModel': 'g1',
          },
          {
            'id': 'manual_scope_p',
            'kind': 'scope',
            'platform': 'pcp',
            'brand': 'Optik',
            'model': '4-16x44',
            'objectiveMm': 44,
            'click': 0.1,
            'clickUnit': 'mrad',
            'focal': 'ffp',
            'minMag': 4,
            'maxMag': 16,
          },
        ]),
      );
      final store = MemoryProfileStore();
      await store.save(
        const RifleProfile(
          id: 'oldp',
          name: 'Eski PCP',
          rifleId: 'manual_rifle_p',
          ammunitionId: 'manual_ammo_p',
          scopeId: 'manual_scope_p',
          muzzleVelocityMps: 280,
          zeroRangeM: 30,
          sightHeightMm: 50,
        ),
      );
      await _pump(tester, store: store);
      await tester.tap(find.text('Eski PCP').first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-brand-select'), '__other');
      _expectFilledModelBox(tester, 'Atölye Kendi Slug');
      expect(
        selectedValue<AmmunitionType>(tester, 'ammo-type'),
        AmmunitionType.slug,
      );
      await tester.tap(find.text('Güncelle'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.brand, 'Atölye');
      expect(a.model, 'Kendi Slug');
      expect(a.grain, 25);
    });
  });

  group('"Aradığın mühimmat listede yok mu?" is the last element of the '
      'card', () {
    for (final (width, scale) in const [
      (390.0, 1.0),
      (390.0, 1.3),
      (320.0, 1.0),
      (320.0, 1.3),
    ]) {
      testWidgets('PCP list and Diğer marka (width $width, text ×$scale)', (
        tester,
      ) async {
        await _openNew(tester, pcp: true, width: width, textScale: scale);
        await chooseInSelect(tester, 'rifle-caliber', '6.35 mm (.25)');
        _expectLinkLast(tester);
        await chooseInSelect(tester, 'ammo-type', 'Pellet');
        await chooseOtherAmmoBrand(tester);
        _expectLinkLast(tester);
        // Tip | Marka side by side at 390 pt.
        if (width == 390 && scale == 1.0) {
          final t = _rect(tester, 'ammo-type');
          final b = _rect(tester, 'ammo-brand-select');
          expect((t.top - b.top).abs(), lessThanOrEqualTo(1));
          expect(t.right, lessThan(b.left));
          final g = _rect(tester, 'ammo-grain');
          final bc = _rect(tester, 'ammo-bc');
          expect((g.top - bc.top).abs(), lessThanOrEqualTo(1));
          final m = _rect(tester, 'ammo-model-other');
          expect(m.top, greaterThanOrEqualTo(b.bottom - 0.5));
          expect(g.top, greaterThanOrEqualTo(m.bottom - 0.5));
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('firearm list and Diğer marka (width $width, text ×$scale)', (
        tester,
      ) async {
        await _openNew(tester, pcp: false, width: width, textScale: scale);
        await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
        await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
        _expectLinkLast(tester);
        await chooseOtherAmmoBrand(tester);
        await enterRifleField(tester, 'ammo-grain', '168');
        await enterRifleField(tester, 'ammo-bc', '0,462');
        await chooseInSelect(tester, 'ammo-bc-model', 'G1');
        expect(_key('ammo-typed-summary'), findsOneWidget);
        _expectLinkLast(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the dialog', () {
    testWidgets('exact texts; one box; Gönder only with text; 200 chars', (
      tester,
    ) async {
      final report = TestProductReport();
      await _openNew(tester, pcp: true, report: report);
      await _openDialog(tester);
      expect(
        _in(
          'ammo-report-dialog',
          find.text('Aradığın mühimmat listede yok mu?'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Şu an Marka kutusundaki "Diğer marka" seçeneğiyle devam '
          'edebilirsin. Listede olmayan mühimmatı bize yaz: marka, model, '
          'ağırlık. Üreticinin bilgileriyle listeye en kısa zamanda eklemeye '
          'çalışacağız.',
        ),
        findsOneWidget,
      );
      expect(_in('ammo-report-dialog', find.byType(TextField)), findsOneWidget);
      expect(
        _in('ammo-report-text', find.text('Marka, model, ağırlık')),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(
        _in('ammo-report-text', find.byType(TextField)),
      );
      expect(field.decoration!.hintText, 'örn. H&N Slug HP 50 gr');
      expect(field.decoration!.helperText, isNull);
      expect(field.maxLength, 200);
      expect(
        tester
            .widget<MenzilInput>(_key('ammo-report-text'))
            .info,
        AmmoReportDialog.textInfo,
      );
      // Left-aligned body and title.
      expect(
        tester.widget<Text>(_key('ammo-report-body')).textAlign,
        TextAlign.left,
      );
      expect(find.text('Vazgeç'), findsOneWidget);
      expect(find.text('Gönder'), findsOneWidget);
      expect(_sendButton(tester).onPressed, isNull);
      await _typeReport(tester, '   ');
      expect(_sendButton(tester).onPressed, isNull);
      await _typeReport(tester, 'x' * 250);
      expect(
        tester
            .widget<TextField>(_in('ammo-report-text', find.byType(TextField)))
            .controller!
            .text
            .length,
        200,
      );
      expect(_sendButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(_key('ammo-report-dialog'), findsNothing);
      expect(report.sent, isEmpty);
    });

    for (final (text, grain, unit) in const [
      ('50gr', 50.0, 'gr'),
      ('3,24 g', 50.0, 'g'),
      ('3.24 gram', 50.0, 'g'),
      ('50 grain', 50.0, 'gr'),
      ('abc', null, null),
    ]) {
      testWidgets('PCP "$text": the exact JSON; success closes', (
        tester,
      ) async {
        final report = TestProductReport();
        final store = MemoryProfileStore();
        await _openNew(tester, pcp: true, report: report, store: store);
        await chooseInSelect(tester, 'rifle-caliber', '6.35 mm (.25)');
        await chooseInSelect(tester, 'ammo-type', 'Pellet');
        await enterRifleField(tester, 'ammo-grain', '25,39');
        await _openDialog(tester);
        await _typeReport(tester, text);
        await tester.tap(_key('ammo-report-send'));
        await tester.pumpAndSettle();
        final body = report.sent.single;
        expect(body['tur'], 'muhimmat');
        expect(body['platform'], 'ios');
        expect(body['uygulamaSurumu'], '1.0.0+dev');
        expect(body.containsKey('kurulumKimligi'), isTrue);
        expect(body['kurulumKimligi'], isNull);
        final f = body['alanlar']! as Map<String, Object?>;
        expect(f['metin'], text);
        expect(f['silah'], 'pcp');
        expect(f['kalibre'], '6.35 mm (.25)');
        if (grain == null) {
          expect(f['okunanAgirlikGr'], isNull);
        } else {
          expect(f['okunanAgirlikGr'] as double, closeTo(grain, 0.01));
        }
        expect(f['okunanBirim'], unit);
        expect(f.keys, {
          'metin',
          'silah',
          'kalibre',
          'okunanAgirlikGr',
          'okunanBirim',
        });
        // Valid JSON for the worker.
        expect(jsonDecode(jsonEncode(body)), isA<Map<String, dynamic>>());
        expect(_key('ammo-report-dialog'), findsNothing);
        expect(find.text('Teşekkürler, bilgin bize ulaştı.'), findsOneWidget);
        // The profile is not changed or saved.
        expect(_text(tester, 'ammo-grain'), '25,39');
        expect(await store.all(), isEmpty);
      });
    }

    testWidgets('firearm: silah "atesli", kalibre ".308 Win"', (tester) async {
      final report = TestProductReport();
      await _openNew(tester, pcp: false, report: report);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await _openDialog(tester);
      await _typeReport(tester, 'Federal Gold Medal 175 gr');
      await tester.tap(_key('ammo-report-send'));
      await tester.pumpAndSettle();
      final f = report.sent.single['alanlar']! as Map<String, Object?>;
      expect(f['silah'], 'atesli');
      expect(f['kalibre'], '.308 Win');
      expect(f['okunanAgirlikGr'], 175.0);
      expect(f['okunanBirim'], 'gr');
    });

    testWidgets('no Kalibre: kalibre null', (tester) async {
      final report = TestProductReport();
      await _openNew(tester, pcp: true, report: report);
      await _openDialog(tester);
      await _typeReport(tester, 'JSB 18,13 gr');
      await tester.tap(_key('ammo-report-send'));
      await tester.pumpAndSettle();
      final f = report.sent.single['alanlar']! as Map<String, Object?>;
      expect(f['kalibre'], isNull);
    });

    for (final kind in ProductReportFailureKind.values) {
      testWidgets('failure ($kind): message, text kept, retry works', (
        tester,
      ) async {
        final report = TestProductReport()
          ..failure = ProductReportFailure(kind, 'x');
        await _openNew(tester, pcp: true, report: report);
        await _openDialog(tester);
        await _typeReport(tester, 'H&N Slug HP 50 gr');
        await tester.tap(_key('ammo-report-send'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Şu an gönderilemedi. İnternet bağlantını kontrol edip tekrar '
            'dene.',
          ),
          findsOneWidget,
        );
        expect(_key('ammo-report-dialog'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                _in('ammo-report-text', find.byType(TextField)),
              )
              .controller!
              .text,
          'H&N Slug HP 50 gr',
        );
        expect(find.text('Teşekkürler, bilgin bize ulaştı.'), findsNothing);
        report.failure = null;
        await tester.tap(_key('ammo-report-send'));
        await tester.pumpAndSettle();
        expect(report.sent, hasLength(2));
        expect(_key('ammo-report-dialog'), findsNothing);
        expect(find.text('Teşekkürler, bilgin bize ulaştı.'), findsOneWidget);
      });
    }

    testWidgets('while sending: Gönder off, one request only', (tester) async {
      final report = TestProductReport()..hold = Completer<void>();
      await _openNew(tester, pcp: true, report: report);
      await _openDialog(tester);
      await _typeReport(tester, '50gr');
      await tester.tap(_key('ammo-report-send'));
      await tester.pump();
      expect(_sendButton(tester).onPressed, isNull);
      await tester.tap(_key('ammo-report-send'), warnIfMissed: false);
      await tester.pump();
      report.hold!.complete();
      await tester.pumpAndSettle();
      expect(report.sent, hasLength(1));
    });

    for (final (width, scale) in const [(320.0, 1.3), (390.0, 1.0)]) {
      testWidgets('no overflow (width $width, text ×$scale), with the error', (
        tester,
      ) async {
        final report = TestProductReport()
          ..failure = const ProductReportFailure(
            ProductReportFailureKind.offline,
            'x',
          );
        await _openNew(
          tester,
          pcp: true,
          report: report,
          width: width,
          textScale: scale,
        );
        await _openDialog(tester);
        expect(tester.takeException(), isNull);
        await _typeReport(tester, 'H&N Slug HP 50 gr');
        await tester.tap(_key('ammo-report-send'));
        await tester.pumpAndSettle();
        expect(_key('ammo-report-failure'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final d = tester.getRect(_key('ammo-report-dialog'));
        expect(d.right, lessThanOrEqualTo(width + 0.5));
      });
    }

    test('dialog texts are the owner\'s words', () {
      expect(AmmoReportDialog.title, 'Aradığın mühimmat listede yok mu?');
      expect(
        AmmoReportDialog.failure,
        'Şu an gönderilemedi. İnternet bağlantını kontrol edip tekrar dene.',
      );
    });
  });

  group('calculation: Diğer marka = the typed ammunition before', () {
    testWidgets('same weight / BC / length / velocity → same solver output', (
      tester,
    ) async {
      final store = MemoryProfileStore();
      await _openNew(tester, pcp: false, store: store);
      await fillRifleForm(tester, caliber: '.308 Win');
      await fillScopeForm(tester);
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseOtherAmmoBrand(tester);
      await enterRifleField(tester, 'ammo-grain', '168');
      await enterRifleField(tester, 'ammo-bc', '0,462');
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      await enterRifleField(tester, 'ammo-length', '31,2');
      await fillShotValues(
        tester,
        velocityFps: '2650',
        zero: '100',
        sight: '45',
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final now = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      // The same round typed before 2026-10-17 ("Diğer" + typed brand).
      final before = UserCatalog.fromManualEntries(const [
        {
          'id': 'manual_ammo_before',
          'kind': 'ammo',
          'platform': 'firearm',
          'brand': 'Atölye Fişek',
          'model': 'Özel 1',
          'caliberMm': 7.82,
          'grain': 168,
          'lengthMm': 31.2,
          'ammoType': 'bullet',
          'bc': 0.462,
          'bcModel': 'g1',
        },
      ]).ammunition.single;
      expect(now.caliberMm, before.caliberMm);
      expect(now.grain, before.grain);
      expect(now.ballisticCoefficient, before.ballisticCoefficient);
      expect(now.ballisticModel, before.ballisticModel);
      expect(now.lengthMm, before.lengthMm);
      expect(now.bcBands, before.bcBands);
      expect(now.dragCurve, before.dragCurve);
      expect(now.type, before.type);
      List<TrajectoryPoint> solve(Ammunition a) =>
          const BallisticEngine().solve(
            BallisticInput(
              muzzleVelocityMps: saved.muzzleVelocityMps,
              grain: a.grain,
              zeroRangeM: saved.zeroRangeM,
              sightHeightMm: saved.sightHeightMm,
              rangesM: const [100, 300, 600, 1000],
              environment: const EnvironmentData(
                temperatureC: 15,
                pressureHpa: 1013.25,
                humidityPercent: 50,
                windMps: 4,
                windDirectionDeg: 90,
              ),
              ballisticCoefficient: a.ballisticCoefficient,
              ballisticModel: a.ballisticModel,
              bcBands: a.bcBands,
            ),
          );
      final p = solve(now), q = solve(before);
      expect(saved.muzzleVelocityMps, closeTo(UnitSystem.fpsToMps(2650), 1e-9));
      for (var i = 0; i < p.length; i++) {
        expect(p[i].correctionMrad, q[i].correctionMrad);
        expect(p[i].dropM, q[i].dropM);
        expect(p[i].windMrad, q[i].windMrad);
        expect(p[i].velocityMps, q[i].velocityMps);
        // ignore: avoid_print
        print(
          'DIGER-MARKA ${p[i].rangeM.toStringAsFixed(0)} m: '
          '${p[i].correctionMrad.toStringAsFixed(3)} mrad, '
          'düşüş ${p[i].dropM.toStringAsFixed(4)} m, '
          'rüzgâr ${p[i].windMrad.toStringAsFixed(3)} mrad, '
          '${p[i].velocityMps.toStringAsFixed(2)} m/s',
        );
      }
    });
  });
}
