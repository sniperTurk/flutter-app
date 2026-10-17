// Pro Ayarlar spacing (owner, 2026-10-17 20:55–21:01, TestFlight 113
// screenshot 20:54: "Bu sayfadaki aralık mesafelerini düzelteceğiz", "20 pt
// yap", "açılır olanları 60 yap", "tamam böyle düzenle"):
// - Atış mesafesi card: card top edge → label top 20 pt (was ≈44 pt; the
//   empty space was the ⓘ's 44 pt label row with the label at its bottom).
//   Label, box, button and their gaps unchanged; the ⓘ keeps its 44 × 44 pt
//   target and the card stays where it was on the page.
// - Closed section header cards: 60 pt (was ≈76 pt); the whole header is
//   the tap target; title, ⓘ, summary and chevron vertically centred.
// - Gap between cards unchanged (8 pt + the 1 pt edge ≈ 9 pt on screen).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_aralik',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_aralik',
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
const _profile = RifleProfile(
  id: 'p-aralik',
  name: 'Aralık',
  rifleId: 'manual_rifle_aralik',
  ammunitionId: 'manual_ammo_aralik',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// The collapsible boxes in page order (Mühimmat sıcaklığı: firearm only).
const _boxes = <String, String>{
  'angle': 'Açı',
  'wind': 'Rüzgâr düzeltmesi',
  'coriolis': 'Coriolis',
  'gravity': 'Yerçekimi',
  'target': 'Hareketli hedef',
  'rifle': 'Tüfek düzeltmeleri',
  'ammo-temp': 'Mühimmat sıcaklığı',
};

const _eps = 0.5;

Widget _app(double textScale) => MaterialApp(
  theme: MenzilTheme.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: BallisticsScreen(
      profile: _profile,
      view: BallisticsView.pro,
      onContinueToShot: () {},
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(textScale));
  await tester.pumpAndSettle();
}

/// The visible card surface (the Material), without its outer margin.
Rect _surface(WidgetTester tester, Key key) => tester.getRect(
  find.descendant(of: find.byKey(key), matching: find.byType(Material)).first,
);

Rect _rangeCard(WidgetTester tester) =>
    _surface(tester, const Key('pro-range-card'));
Rect _boxCard(WidgetTester tester, String id) =>
    _surface(tester, Key('pro-box-$id'));
Finder _header(String id) => find.byKey(Key('pro-section-$id'));

Rect _rangeLabel(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.byKey(const Key('pro-shot-range')),
    matching: find.text('Atış mesafesi'),
  ),
);

Finder get _rangeInfo => find.descendant(
  of: find.byKey(const Key('pro-shot-range')),
  matching: find.byType(IconButton),
);

/// The same card-surface → label distance, header heights and gaps for one
/// width and text scale.
void _expectGeometry(WidgetTester tester, {required String where}) {
  // 1. Atış mesafesi: card top edge → label top = 20 pt.
  final card = _rangeCard(tester);
  expect(
    _rangeLabel(tester).top - card.top,
    moreOrLessEquals(20, epsilon: _eps),
    reason: '$where: card top → label top',
  );
  // The card stays where it was on the page (page top padding 10 pt).
  final page = tester.getRect(
    find.byKey(const PageStorageKey('ballistics-pro')),
  );
  expect(
    card.top - page.top,
    moreOrLessEquals(MenzilSpace.md, epsilon: _eps),
    reason: '$where: page top → card top',
  );

  // 2. Closed headers: 60 pt cards, the whole header is the tap target.
  var previousBottom = card.bottom;
  for (final id in _boxes.keys) {
    final box = _boxCard(tester, id);
    final header = tester.getRect(_header(id));
    expect(
      box.height,
      moreOrLessEquals(60, epsilon: _eps),
      reason: '$where: $id closed height',
    );
    expect(header.height, greaterThanOrEqualTo(44), reason: '$where: $id tap');
    expect(
      header.height,
      moreOrLessEquals(box.height, epsilon: _eps),
      reason: '$where: $id whole header tappable',
    );
    // 3. Gap between cards unchanged: 8 pt (MenzilSpace.sm).
    expect(
      box.top - previousBottom,
      moreOrLessEquals(MenzilSpace.sm, epsilon: _eps),
      reason: '$where: gap above $id',
    );
    previousBottom = box.bottom;
  }
}

/// Title, ⓘ, summary and chevron share the header's vertical centre.
void _expectCentred(WidgetTester tester, String id, {required String where}) {
  final centre = tester.getRect(_header(id)).center.dy;
  final parts = <String, Finder>{
    'title': find.descendant(of: _header(id), matching: find.text(_boxes[id]!)),
    'ⓘ': find.byKey(Key('pro-info-$id')),
    'summary': find.byKey(Key('pro-summary-$id')),
    'chevron': find.descendant(
      of: _header(id),
      matching: find.byIcon(Icons.expand_more),
    ),
  };
  for (final MapEntry(:key, :value) in parts.entries) {
    expect(
      tester.getRect(value).center.dy,
      moreOrLessEquals(centre, epsilon: _eps),
      reason: '$where: $id $key centred',
    );
  }
}

Future<void> _loadStandInFont() async {
  final files = Directory('assets/fonts').listSync().whereType<File>().where((
    f,
  ) {
    final name = f.uri.pathSegments.last;
    return name.startsWith('Inter-') && name.endsWith('.otf');
  }).toList();
  expect(files, isNotEmpty);
  for (final family in [MenzilType.textFamily, MenzilType.displayFamily]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadStandInFont);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final (width, scale) in [(390.0, 1.0), (320.0, 1.0), (390.0, 1.3)]) {
    testWidgets('$width pt × $scale: label 20 pt below the card top, closed '
        'headers 60 pt, gaps 8 pt, parts centred', (tester) async {
      await _pump(tester, width: width, textScale: scale);
      expect(tester.takeException(), isNull);
      final where = '$width×$scale';
      _expectGeometry(tester, where: where);
      for (final id in _boxes.keys) {
        _expectCentred(tester, id, where: where);
      }
    });
  }

  testWidgets('320 pt × 1.3, long title and summary: no overflow, headers '
      'at least 60 pt and fully tappable', (tester) async {
    await _pump(tester, width: 320, textScale: 1.3);
    // A longer summary on Tüfek düzeltmeleri ("… ayar açık").
    final rifle = _header('rifle');
    await tester.ensureVisible(rifle);
    await tester.tapAt(tester.getTopLeft(rifle) + const Offset(12, 30));
    await tester.pumpAndSettle();
    Finder field(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('pro-turret-scale'), '1,02');
    await tester.enterText(field('pro-zero-up'), '1');
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(rifle) + const Offset(12, 30));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('pro-summary-rifle'))).data,
      contains('ayar açık'),
    );
    expect(tester.takeException(), isNull);
    for (final id in _boxes.keys) {
      final box = _boxCard(tester, id);
      final header = tester.getRect(_header(id));
      expect(box.height, greaterThanOrEqualTo(60 - _eps), reason: id);
      expect(header.height, moreOrLessEquals(box.height, epsilon: _eps));
      _expectCentred(tester, id, where: '320×1.3');
    }
    // The label stays 20 pt below the card top at this size too.
    expect(
      _rangeLabel(tester).top - _rangeCard(tester).top,
      moreOrLessEquals(20, epsilon: _eps),
    );
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('× $scale: Atış mesafesi ⓘ keeps a 44 × 44 pt target above '
        'the box, tappable at its top edge', (tester) async {
      await _pump(tester, width: 390, textScale: scale);
      final info = tester.getRect(_rangeInfo);
      final box = tester.getRect(
        find.descendant(
          of: find.byKey(const Key('pro-shot-range')),
          matching: find.byType(TextField),
        ),
      );
      expect(info.width, greaterThanOrEqualTo(44 - 0.01));
      expect(info.height, greaterThanOrEqualTo(44 - 0.01));
      expect(info.bottom, lessThanOrEqualTo(box.top + 0.01));
      // Label → box: the compact gap (5 pt), as before.
      expect(
        box.top - _rangeLabel(tester).bottom,
        moreOrLessEquals(MenzilSpace.compactLabelGap, epsilon: _eps),
      );
      // The icon sits inside the card even if the target reaches above it.
      final icon = tester.getRect(
        find.descendant(
          of: _rangeInfo,
          matching: find.byIcon(Icons.info_outline),
        ),
      );
      expect(icon.top, greaterThanOrEqualTo(_rangeCard(tester).top));
      // A tap 2 pt below the target's top edge opens the explanation.
      await tester.tapAt(Offset(info.center.dx, info.top + 2));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Tamam'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('a tap anywhere on the 60 pt header toggles the box; the open '
      'content keeps its 14 pt bottom padding', (tester) async {
    await _pump(tester, width: 390);
    final header = _header('target');
    final r = tester.getRect(header);
    // Near the header's top edge, left of the title text.
    await tester.tapAt(Offset(r.left + 4, r.top + 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-summary-target')), findsNothing);
    final clear = find.byKey(const Key('pro-target-clear'));
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    expect(
      _boxCard(tester, 'target').bottom - tester.getRect(clear).bottom,
      moreOrLessEquals(MenzilSpace.lg, epsilon: _eps),
    );
    // Near the bottom edge of the header closes it again.
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    final r2 = tester.getRect(header);
    await tester.tapAt(Offset(r2.left + 4, r2.bottom - 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-summary-target')), findsOneWidget);
  });

  testWidgets('range error text still shows below the box', (tester) async {
    await _pump(tester, width: 390);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      ),
      '999999',
    );
    await tester.pumpAndSettle();
    final error = find.textContaining('arasında olmalı');
    expect(error, findsOneWidget);
    expect(
      tester.getRect(error).bottom,
      lessThanOrEqualTo(_rangeCard(tester).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}
