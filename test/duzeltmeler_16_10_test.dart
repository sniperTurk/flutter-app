// Düzeltmeler 16.10.2026 (owner, 2026-10-16 20:06 "onayladım", design PR
// #366, docs/design/duzeltmeler-2026-10-16/README.md; item 5 changed by the
// owner at 20:07: "Profil seçici select diğer selectler gibi açılacak").
//
// 1. Profil ekle is only as wide as its text + 16 pt on each side.
// 2+3. Mühimmat sıcaklığı: the solver gets exactly main's numbers
//    (golden values read from main e7b29bf with the same steps).
// 4+6. Hedef: the compact click line; at 390×844 the distance control, the
//    line and the whole scope are visible without scrolling.
// 5. The top-bar profile list is the MenzilSelect list (same route, look,
//    placement), never wider than the button, rows "name  caliber".
// Report: docs/reports/duzeltmeler_16_10.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';

/// Inter under the SF proxy names (as test/sistem_yazisi_test.dart), so
/// text widths are close to the phone's.
Future<void> _loadStandIn() async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('Inter-'))
      .toList();
  expect(files, isNotEmpty);
  for (final name in {MenzilType.textFamily, MenzilType.displayFamily}) {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
}

RifleProfile _pcp(String id, String name) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// A phone [width]×[height] pt with the iPhone's safe-area insets.
void _phone(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width, height) * 3;
  tester.view.padding = FakeViewPadding(
    top: (height >= 800 ? 47 : 20) * 3,
    bottom: (height >= 800 ? 34 : 0) * 3,
  );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _home(
  WidgetTester tester,
  List<RifleProfile> profiles, {
  String? activeId,
}) async {
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      darkTheme: MenzilTheme.dark(),
      themeMode: ThemeMode.dark,
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()
          ..value = activeId ?? profiles.first.id,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

/// The route a widget of the open list lives in, by its type name.
String _routeName(WidgetTester tester, Finder f) =>
    ModalRoute.of(tester.element(f))!.runtimeType.toString();

/// The open list's surface (the Material that draws the list).
Finder _listSurface(Finder row) =>
    find.ancestor(of: row, matching: find.byType(Material)).first;

void main() {
  setUpAll(_loadStandIn);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('1. Profil ekle', () {
    for (final width in const [320.0, 390.0]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('as wide as its text + 16 pt each side: '
            '${width.toInt()} pt, ×$scale', (tester) async {
          _phone(tester, width: width, textScale: scale);
          await _home(tester, [_pcp('p1', 'Bir')]);
          expect(tester.takeException(), isNull);
          final add = find.byKey(const Key('profiles-add'));
          expect(tester.widget<MenzilPrimaryButton>(add).expand, isFalse);
          final button = tester.getRect(add);
          final textFinder = find.descendant(
            of: add,
            matching: find.text('Profil ekle'),
          );
          final text = tester.getRect(textFinder);
          final natural = tester
              .renderObject<RenderParagraph>(textFinder)
              .getMaxIntrinsicWidth(double.infinity);
          // No fixed 148 pt any more: narrower, the text drawn full size.
          expect(button.width, lessThan(148));
          expect(text.width, moreOrLessEquals(natural, epsilon: 0.5));
          expect(text.left - button.left, moreOrLessEquals(16, epsilon: 0.5));
          expect(button.right - text.right, moreOrLessEquals(16, epsilon: 0.5));
          // One line, the same height as before (46 pt control, 48 pt tap
          // target), same amber.
          expect(text.height, lessThan(button.height / 2 + 4));
          expect(button.height, greaterThanOrEqualTo(MenzilSpace.control));
          expect(button.height, lessThanOrEqualTo(48));
          expect(tester.widget<MenzilPrimaryButton>(add).amber, isTrue);
          // Same place: right end of the "Profiller" row, at the gutter.
          final header = tester.getRect(
            find.byKey(const Key('profiles-list-header')),
          );
          expect(button.right, moreOrLessEquals(header.right, epsilon: 0.5));
          expect(button.right, moreOrLessEquals(width - MenzilSpace.gutter));
          // ignore: avoid_print
          print(
            'PROFIL_EKLE_16_10|${width.toInt()}|x$scale'
            '|buton=${button.width.toStringAsFixed(1)}'
            '|yazi=${text.width.toStringAsFixed(1)}',
          );
        });
      }
    }

    testWidgets('very large text (×2): one line, no overflow', (tester) async {
      _phone(tester, width: 320, textScale: 2);
      await _home(tester, [_pcp('p1', 'Bir')]);
      expect(tester.takeException(), isNull);
      final add = find.byKey(const Key('profiles-add'));
      final button = tester.getRect(add);
      final text = tester.getRect(
        find.descendant(of: add, matching: find.text('Profil ekle')),
      );
      expect(text.left, greaterThanOrEqualTo(button.left));
      expect(text.right, lessThanOrEqualTo(button.right));
      expect(text.height, lessThan(button.height));
      expect(button.right, lessThanOrEqualTo(320));
    });
  });

  group('2+3. Mühimmat sıcaklığı reaches the solver as on main', () {
    const rifle = <String, dynamic>{
      'id': 'manual_rifle_mb',
      'kind': 'rifle',
      'platform': 'firearm',
      'brand': 'Test',
      'model': '308',
      'caliberMm': 7.62,
      'twistDirection': 'right',
      'twistRateIn': 10,
    };
    const ammo = <String, dynamic>{
      'id': 'manual_ammo_mb',
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
    const firearm = RifleProfile(
      id: 'p-mb',
      name: 'MB',
      rifleId: 'manual_rifle_mb',
      ammunitionId: 'manual_ammo_mb',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 800,
      zeroRangeM: 100,
      sightHeightMm: 45,
      powderTempCoefPercentPer15C: 1.5,
      powderTempReferenceC: 15,
    );
    // Read from main e7b29bf (before this change) with exactly these steps:
    // saved Mühimmat sıcaklığı, Pro range 600 m, Hedef requiredUp (MRAD).
    const goldenWarm = 5.245725605337864; // ammo 35 °C
    const goldenAir = 5.529980691211749; // empty: the air temperature

    setUp(
      () => CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([rifle, ammo]),
      ),
    );
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Widget app(BallisticsView view) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: firearm, view: view),
      ),
    );

    Finder field(Key key) =>
        find.descendant(of: find.byKey(key), matching: find.byType(TextField));

    Future<double> up600(WidgetTester tester) async {
      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      final range = field(const Key('pro-shot-range'));
      await tester.ensureVisible(range);
      await tester.enterText(range, '600');
      await tester.pump();
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredUp!;
    }

    for (final (saved, golden) in const [('35', goldenWarm), ('', goldenAir)]) {
      testWidgets('saved "$saved" loads into Pro and gives main\'s number', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({
          ShotSettingsStore.keyFor(firearm.id): jsonEncode(
            ShotSettings(ammoTempText: saved).toJson(),
          ),
        });
        tester.view.physicalSize = const Size(430, 3000) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(BallisticsView.pro));
        await tester.pumpAndSettle();
        await openProFor(tester, const Key('env-ammo-temp'));
        expect(
          tester
              .widget<TextField>(field(const Key('env-ammo-temp')))
              .controller!
              .text,
          saved,
        );
        expect(await up600(tester), golden);
      });
    }

    testWidgets('typed in Pro: the same numbers as main', (tester) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Future<void> type(String v) async {
        await tester.pumpWidget(app(BallisticsView.pro));
        await tester.pumpAndSettle();
        await openProFor(tester, const Key('env-ammo-temp'));
        final f = field(const Key('env-ammo-temp'));
        await tester.ensureVisible(f);
        await tester.enterText(f, v);
        await tester.pumpAndSettle();
      }

      await type('35');
      expect(await up600(tester), goldenWarm);
      await type('');
      expect(await up600(tester), goldenAir);
    });
  });

  group('4+6. Hedef', () {
    testWidgets('390×844: distance, click line and the whole scope visible '
        'without scrolling; the big row is gone', (tester) async {
      _phone(tester);
      await _home(tester, [_pcp('p1', 'Bir')]);
      await tester.tap(_tab('Hedef'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final nav = tester.getRect(find.byType(MenzilBottomNavigation));
      final slider = tester.getRect(find.byType(Slider).first);
      final line = tester.getRect(find.byKey(TurretSolutionRow.rowKey));
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      // Nothing scrolled.
      final page = Scrollable.of(
        tester.element(find.byKey(TurretSolutionRow.rowKey)),
      ).position;
      expect(page.pixels, 0);
      // The line: right under the slider, one compact line (22 pt).
      expect(line.top, greaterThanOrEqualTo(slider.bottom));
      expect(line.top - slider.bottom, lessThanOrEqualTo(2.5));
      expect(line.height, moreOrLessEquals(TurretSolutionRow.lineHeight));
      expect(line.bottom, lessThanOrEqualTo(reticle.top));
      // The whole scope above the bottom menu.
      expect(reticle.bottom, lessThanOrEqualTo(nav.top));
      // No big 34 pt click number any more.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.style?.fontSize ?? 0) == 34,
        ),
        findsNothing,
      );
      // ignore: avoid_print
      print(
        'HEDEF_16_10|390x844|slider_alt=${slider.bottom.toStringAsFixed(1)}'
        '|satir=${line.top.toStringAsFixed(1)}-${line.bottom.toStringAsFixed(1)}'
        '|durbun_alt=${reticle.bottom.toStringAsFixed(1)}'
        '|menu_ust=${nav.top.toStringAsFixed(1)}'
        '|pay=${(nav.top - reticle.bottom).toStringAsFixed(1)}',
      );
    });

    for (final scale in const [1.0, 1.3]) {
      testWidgets('320 pt, ×$scale: the line never wraps or overflows', (
        tester,
      ) async {
        _phone(tester, width: 320, height: 568, textScale: scale);
        await _home(tester, [_pcp('p1', 'Bir')]);
        await tester.tap(_tab('Hedef'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final key in const [
          TurretSolutionRow.elevationKey,
          TurretSolutionRow.windageKey,
        ]) {
          final p = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(RichText),
            ),
          );
          expect(p.didExceedMaxLines, isFalse);
          final r = tester.getRect(find.byKey(key));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(320));
        }
      });
    }
  });

  group('5. Top-bar profile list = the MenzilSelect list', () {
    testWidgets('same route, surface, border, corner and row text as an '
        'opened MenzilSelect', (tester) async {
      _phone(tester);
      // A standard MenzilSelect first.
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.dark(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MenzilSelect<String>(
                  key: const Key('ref-select'),
                  label: 'Kalibre',
                  initialValue: null,
                  hint: 'Seçiniz',
                  items: const [
                    DropdownMenuItem(value: 'a', child: Text('.308 Win')),
                    DropdownMenuItem(value: 'b', child: Text('6,5 Creedmoor')),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('ref-select')));
      await tester.pumpAndSettle();
      final refRow = find.text('6,5 Creedmoor').last;
      final refRoute = _routeName(tester, refRow);
      final refSurface = tester.widget<Material>(_listSurface(refRow));
      final refStyle = DefaultTextStyle.of(tester.element(refRow)).style;
      final refRowHeight = tester
          .getSize(
            find.ancestor(of: refRow, matching: find.byType(InkWell)).first,
          )
          .height;
      expect(refRoute, startsWith('_MenzilMenuRoute<'));

      // The top-bar list.
      await _home(tester, [_pcp('p1', 'Bir'), _pcp('p2', 'İki')]);
      await tester.tap(find.byKey(const Key('top-bar-profile-button')));
      await tester.pumpAndSettle();
      final row = find.text('İki').last;
      expect(_routeName(tester, row), startsWith('_MenzilMenuRoute<'));
      final surface = tester.widget<Material>(_listSurface(row));
      expect(surface.color, refSurface.color);
      expect(surface.elevation, refSurface.elevation);
      expect(surface.shape, refSurface.shape);
      final style = DefaultTextStyle.of(tester.element(row)).style;
      expect(style.fontSize, refStyle.fontSize);
      expect(style.fontWeight, refStyle.fontWeight);
      expect(style.color, refStyle.color);
      final rowHeight = tester
          .getSize(find.ancestor(of: row, matching: find.byType(InkWell)).first)
          .height;
      expect(rowHeight, refRowHeight);
      // No Flutter dropdown route any more.
      expect(_routeName(tester, row), isNot(contains('_DropdownRoute')));
    });

    testWidgets('under the button, never wider, rows name + caliber; a pick '
        'changes the active profile', (tester) async {
      _phone(tester);
      await _home(tester, [_pcp('p1', 'Bir'), _pcp('p2', 'İki')]);
      final pill = tester.getRect(
        find.byKey(const Key('top-bar-profile-button')),
      );
      await tester.tap(find.byKey(const Key('top-bar-profile-button')));
      await tester.pumpAndSettle();
      final row = find.text('İki').last;
      final list = tester.getRect(_listSurface(row));
      expect(list.width, lessThanOrEqualTo(pill.width + 0.01));
      expect(list.left, moreOrLessEquals(pill.left, epsilon: 0.01));
      expect(list.top, moreOrLessEquals(pill.bottom + MenzilSelect.menuGap));
      expect(list.right, lessThanOrEqualTo(390));
      // Each row: name and caliber (like the button).
      for (final id in const ['p1', 'p2']) {
        final item = find.byKey(ValueKey(('top-bar-profile-item', id)));
        expect(
          find.descendant(of: item, matching: find.text('6,35 mm')),
          findsOneWidget,
        );
      }
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('top-bar-profile-button')),
          matching: find.text('İki'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final (width, scale) in const [
      (390.0, 1.0),
      (320.0, 1.0),
      (320.0, 1.3),
    ]) {
      testWidgets('long names stay distinguishable: ${width.toInt()} pt, '
          '×$scale (UST-1)', (tester) async {
        _phone(tester, width: width, textScale: scale);
        const a = 'Tikka T3x Varmint gece avı ana namlu';
        const b = 'Tikka T3x Varmint gece avı yedek namlu';
        // A short active name keeps the button (and so the list) narrow.
        await _home(tester, [
          _pcp('p0', 'bbbbb'),
          _pcp('pa', a),
          _pcp('pb', b),
        ]);
        expect(tester.takeException(), isNull);
        final pill = tester.getRect(
          find.byKey(const Key('top-bar-profile-button')),
        );
        await tester.tap(find.byKey(const Key('top-bar-profile-button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final ra = find.text(a);
        final rb = find.text(b);
        expect(ra, findsOneWidget);
        expect(rb, findsOneWidget);
        // Full names, wrapped, never cut with "…".
        for (final f in [ra, rb]) {
          final p = tester.renderObject<RenderParagraph>(f);
          expect(p.didExceedMaxLines, isFalse);
          expect(p.text.toPlainText(), isNot(contains('…')));
        }
        final list = tester.getRect(_listSurface(ra));
        expect(list.width, lessThanOrEqualTo(pill.width + 0.01));
        expect(list.left, greaterThanOrEqualTo(0));
        expect(list.right, lessThanOrEqualTo(width + 0.01));
        // Rows do not overlap; the caliber of each is under or beside it.
        final itemA = tester.getRect(
          find.byKey(const ValueKey(('top-bar-profile-item', 'pa'))),
        );
        final itemB = tester.getRect(
          find.byKey(const ValueKey(('top-bar-profile-item', 'pb'))),
        );
        expect(itemB.top, greaterThanOrEqualTo(itemA.bottom - 0.01));
        // A tap on the lower line of a wrapped row picks that row.
        await tester.tapAt(Offset(itemB.center.dx, itemB.bottom - 6));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('top-bar-profile-button')),
            matching: find.byType(Text),
          ),
          findsWidgets,
        );
        final shown = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('top-bar-profile-button')),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data)
            .toList();
        expect(shown, contains(b));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('VoiceOver: a button named "Aktif tüfek profili" with the '
        'profile as its value; its tap opens the same list', (tester) async {
      final handle = tester.ensureSemantics();
      _phone(tester);
      await _home(tester, [_pcp('p1', 'Bir'), _pcp('p2', 'İki')]);
      final node = tester.getSemantics(
        find.bySemanticsLabel('Aktif tüfek profili'),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.value, 'Bir 6,35 mm');
      tester.semantics.tap(find.semantics.byLabel('Aktif tüfek profili'));
      await tester.pumpAndSettle();
      expect(
        _routeName(tester, find.text('İki').last),
        startsWith('_MenzilMenuRoute<'),
      );
      handle.dispose();
    });
  });
}
