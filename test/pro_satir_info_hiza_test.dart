// Pro Ayarlar row grid (owner, 2026-10-16 07:59–08:08: "Bu sayfada infolar
// bence çok düzensiz duruyor", "Sayfa başlıkları da açılır menüleri
// açıyor... Kullanıcı infoları boş sanabilir", then "Tamam yap"):
// [title][ⓘ 8 pt after the text][space][summary][⌄]. The ⓘ has its own
// 44 × 44 pt target next to (never over) the title and opens only the
// explanation; the rest of the line opens and closes the box. Summaries and
// chevrons share one right edge; titles stay on one line at 390 pt.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/pro_row_header.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

class _FakeGarmin implements GarminLink {
  int selects = 0;

  @override
  Future<int?> deviceCount() async => 1;

  @override
  Stream<int> get deviceCountChanges => const Stream.empty();

  @override
  Future<bool> selectDevice() async {
    selects++;
    return true;
  }
}

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_hiza',
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
  'id': 'manual_ammo_hiza',
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
  id: 'p-hiza',
  name: 'Hiza',
  rifleId: 'manual_rifle_hiza',
  ammunitionId: 'manual_ammo_hiza',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// The six collapsible rows of the owner's screenshot, in page order.
const _titles = <String, String>{
  'angle': 'Açı',
  'wind': 'Rüzgâr düzeltmesi',
  'coriolis': 'Coriolis',
  'gravity': 'Yerçekimi',
  'target': 'Hareketli hedef',
  'rifle': 'Tüfek düzeltmeleri',
};

Widget _app({double textScale = 1}) => MaterialApp(
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

Future<_FakeGarmin> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final garmin = _FakeGarmin();
  GarminLink.instance = garmin;
  addTearDown(() => GarminLink.instance = GarminLink());
  await tester.pumpWidget(_app(textScale: textScale));
  await tester.pumpAndSettle();
  return garmin;
}

Finder _header(String id) => find.byKey(Key('pro-section-$id'));
Finder _title(String id) =>
    find.descendant(of: _header(id), matching: find.text(_titles[id]!));
Finder _info(String id) => find.byKey(Key('pro-info-$id'));
Finder _icon(String id) =>
    find.descendant(of: _info(id), matching: find.byIcon(Icons.info_outline));
Finder _summary(String id) => find.byKey(Key('pro-summary-$id'));
Finder _chevron(String id) =>
    find.descendant(of: _header(id), matching: find.byIcon(Icons.expand_more));
Finder get _sheet => find.byKey(const Key('pro-info-sheet'));

Finder get _garminTitle => find.descendant(
  of: find.byKey(const Key('tool-garmin')),
  matching: find.text('Garmin saati'),
);

/// ⓘ right after the title text, its 44 pt target not over the title.
void _expectInfoAfterTitle(WidgetTester tester, Finder title, String id) {
  final t = tester.getRect(title);
  final icon = tester.getRect(_icon(id));
  final target = tester.getRect(_info(id));
  expect(icon.left - t.right, closeTo(proInfoGap, 1), reason: id);
  expect(target.width, greaterThanOrEqualTo(44), reason: id);
  expect(target.height, greaterThanOrEqualTo(44), reason: id);
  final overlap = target.intersect(t);
  expect(
    overlap.width <= 0 || overlap.height <= 0,
    isTrue,
    reason: '$id: ⓘ target $target overlaps title $t',
  );
  // The icon sits inside its own target.
  expect(target.contains(icon.center), isTrue, reason: id);
}

/// The ⓘ explanation is open and the box stayed closed.
Future<void> _expectSheetOnly(WidgetTester tester, String id) async {
  expect(_sheet, findsOneWidget, reason: id);
  expect(_summary(id), findsOneWidget, reason: '$id stayed closed');
  await tester.tap(find.byKey(const Key('pro-info-close')));
  await tester.pumpAndSettle();
  expect(_sheet, findsNothing, reason: id);
}

/// Taps [at] and expects the box to toggle open, then closes it again.
Future<void> _expectToggles(
  WidgetTester tester,
  String id,
  Offset at,
  String where,
) async {
  expect(_summary(id), findsOneWidget, reason: '$id closed before $where');
  await tester.tapAt(at);
  await tester.pumpAndSettle();
  expect(_sheet, findsNothing, reason: '$id $where');
  expect(_summary(id), findsNothing, reason: '$id opened by $where');
  final t = tester.getCenter(_title(id));
  await tester.tapAt(t);
  await tester.pumpAndSettle();
  expect(_summary(id), findsOneWidget, reason: '$id closed again');
}

/// The test font draws every glyph a full em wide, so a 17-letter title
/// can never fit. SF cannot be bundled; like ekran_boyutu_test.dart, Inter
/// stands in for the iOS system faces so the widths are close to a phone.
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

  testWidgets('390 pt: ⓘ 8 pt after every title, one value/chevron column, '
      'single-line titles', (tester) async {
    await _pump(tester, width: 390);
    final oneLine = tester.getRect(_title('angle')).height;
    final rights = <double>[], chevrons = <double>[];
    for (final id in _titles.keys) {
      _expectInfoAfterTitle(tester, _title(id), id);
      expect(
        tester.getRect(_title(id)).height,
        closeTo(oneLine, 0.5),
        reason: '${_titles[id]} is on one line',
      );
      rights.add(tester.getRect(_summary(id)).right);
      chevrons.add(tester.getRect(_chevron(id)).right);
      // Value text right-aligned: it ends at the column, before ⌄.
      expect(
        tester.widget<Text>(_summary(id)).textAlign,
        TextAlign.right,
        reason: id,
      );
    }
    for (final r in rights) {
      expect(r, closeTo(rights.first, 0.5));
    }
    for (final r in chevrons) {
      expect(r, closeTo(chevrons.first, 0.5));
    }
    // The chevron column is the card's right content edge.
    final card = tester.getRect(find.byKey(const Key('pro-box-angle')));
    expect(card.right - chevrons.first, lessThan(24));
    // Garmin saati: the same ⓘ right after its title.
    _expectInfoAfterTitle(tester, _garminTitle, 'garmin');
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in [(320.0, 1.0), (390.0, 1.3), (320.0, 1.3)]) {
    testWidgets('$width pt, text ×$scale: no overflow, ⓘ still after the '
        'title, values still in one column', (tester) async {
      await _pump(tester, width: width, textScale: scale);
      expect(tester.takeException(), isNull);
      final rights = <double>[];
      for (final id in _titles.keys) {
        _expectInfoAfterTitle(tester, _title(id), id);
        final info = tester.getRect(_info(id));
        final chevron = tester.getRect(_chevron(id));
        expect(info.right, lessThanOrEqualTo(chevron.left + 0.5), reason: id);
        rights.add(tester.getRect(_summary(id)).right);
        // The value shortens first: a title wraps only when it would not
        // fit even with the value down to its first letter and "…".
        final oneLine = tester.getRect(_title('angle')).height;
        if (tester.getRect(_title(id)).height > oneLine + 0.5) {
          final value = tester.renderObject<RenderParagraph>(_summary(id));
          double w(String s) {
            final tp = TextPainter(
              text: TextSpan(text: s, style: value.text.style),
              textScaler: value.textScaler,
              textDirection: TextDirection.ltr,
            )..layout();
            final width = tp.width;
            tp.dispose();
            return width;
          }

          final text = value.text.toPlainText();
          final reserve = [
            w(text),
            w('${text.characters.first}…'),
          ].reduce((a, b) => a < b ? a : b);
          final title = tester
              .renderObject<RenderParagraph>(_title(id))
              .getMaxIntrinsicWidth(double.infinity);
          final row = tester.getRect(_header(id)).width;
          expect(
            title,
            greaterThan(
              row - proInfoTarget - MenzilSpace.xs - proChevronSize - reserve,
            ),
            reason: '$id wrapped while the value still had room',
          );
        }
        // Opening the box does not make the title jump to another height.
        final before = tester.getRect(_title(id)).height;
        await tester.tapAt(tester.getCenter(_chevron(id)));
        await tester.pumpAndSettle();
        expect(_summary(id), findsNothing, reason: id);
        expect(
          tester.getRect(_title(id)).height,
          closeTo(before, 0.5),
          reason: '$id title height when open',
        );
        await tester.tapAt(tester.getCenter(_title(id)));
        await tester.pumpAndSettle();
        expect(_summary(id), findsOneWidget, reason: id);
      }
      for (final r in rights) {
        expect(r, closeTo(rights.first, 0.5));
      }
      _expectInfoAfterTitle(tester, _garminTitle, 'garmin');
    });
  }

  testWidgets('a tap in the ⓘ target opens only the explanation; title, '
      'middle, value and chevron open the box', (tester) async {
    final garmin = await _pump(tester, width: 390);
    for (final id in _titles.keys) {
      final icon = tester.getCenter(_icon(id));
      await tester.tapAt(icon);
      await tester.pumpAndSettle();
      await _expectSheetOnly(tester, id);

      // The edge of the 44 pt target, 18 pt right of the icon centre.
      final edge = icon + const Offset(18, 0);
      expect(tester.getRect(_info(id)).contains(edge), isTrue, reason: id);
      await tester.tapAt(edge);
      await tester.pumpAndSettle();
      await _expectSheetOnly(tester, id);

      final info = tester.getRect(_info(id));
      final value = tester.getRect(_summary(id));
      final chevron = tester.getRect(_chevron(id));
      await _expectToggles(tester, id, tester.getCenter(_title(id)), 'title');
      await _expectToggles(
        tester,
        id,
        Offset(info.right + 4, info.center.dy),
        'middle',
      );
      await _expectToggles(
        tester,
        id,
        Offset(value.right - 4, value.center.dy),
        'value',
      );
      await _expectToggles(tester, id, chevron.center, 'chevron');
    }
    // Garmin saati: the ⓘ edge opens the explanation, not Garmin Connect.
    final g = tester.getCenter(_icon('garmin')) + const Offset(18, 0);
    expect(tester.getRect(_info('garmin')).contains(g), isTrue);
    await tester.tapAt(g);
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(garmin.selects, 0);
  });
}
