// Hareketli hedef direction box label (owner, 2026-10-17 11:47–11:48,
// TestFlight 112: "Yönü" read as the rifle twist direction; "onun adını
// hedefin yönü yap"). The box is "Hedefin yönü", on one line, in the same
// row as Hedef hızı; the title ⓘ sheet names it the same way.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

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
  'id': 'manual_rifle_yon',
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
  'id': 'manual_ammo_yon',
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
  id: 'p-yon',
  name: 'Yon',
  rifleId: 'manual_rifle_yon',
  ammunitionId: 'manual_ammo_yon',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

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

Finder get _direction => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('pro-target-direction-'),
);

Future<void> _openTarget(
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
  final chevron = find.descendant(
    of: find.byKey(const Key('pro-section-target')),
    matching: find.byIcon(Icons.expand_more),
  );
  await tester.ensureVisible(chevron);
  await tester.tapAt(tester.getCenter(chevron));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('pro-summary-target')), findsNothing);
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

  for (final (width, scale) in [(390.0, 1.0), (320.0, 1.0), (320.0, 1.3)]) {
    testWidgets(
      '$width pt, text ×$scale: "Hedefin yönü" on one line, beside or '
      'under Hedef hızı, no overflow',
      (tester) async {
        await _openTarget(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(_direction, findsOneWidget);
        final label = find.descendant(
          of: _direction,
          matching: find.text('Hedefin yönü'),
        );
        expect(label, findsOneWidget);
        expect(
          find.descendant(of: _direction, matching: find.text('Yönü')),
          findsNothing,
        );
        expect(find.text('Yönü'), findsNothing);
        final speed = find.byKey(const Key('pro-target-speed'));
        final speedLabel = find.descendant(
          of: speed,
          matching: find.text('Hedef hızı'),
        );
        if (width == 390 && scale == 1) {
          // Same row: the two boxes and their labels share one top edge.
          expect(
            tester.getRect(_direction).top,
            closeTo(tester.getRect(speed).top, 0.5),
          );
          expect(
            tester.getRect(label).top,
            closeTo(tester.getRect(speedLabel).top, 0.5),
          );
          expect(
            tester.getRect(label).left,
            greaterThan(tester.getRect(speed).right),
          );
        } else {
          // Narrower than MenzilFieldGrid's two-column width (existing rule
          // for every Pro grid): the box sits right under Hedef hızı.
          expect(
            tester.getRect(_direction).top,
            greaterThan(tester.getRect(speed).bottom - 0.5),
          );
          expect(
            tester.getRect(_direction).left,
            closeTo(tester.getRect(speed).left, 0.5),
          );
        }
        // One line: as tall as the one-line Hedef hızı label.
        expect(
          tester.getRect(label).height,
          closeTo(tester.getRect(speedLabel).height, 0.5),
        );
        // Shown whole, not cut with "…".
        expect(
          tester
              .renderObject<RenderParagraph>(
                find.descendant(of: label, matching: find.byType(RichText)),
              )
              .didExceedMaxLines,
          isFalse,
        );
        // Options unchanged.
        final select = tester.widget<MenzilSelect<bool>>(_direction);
        expect(select.items.map((i) => (i.child as Text).data).toList(), [
          'Seçiniz',
          'Soldan sağa',
          'Sağdan sola',
        ]);
      },
    );
  }
  // The title ⓘ sheet entry is checked word for word in
  // pro_info_popup_test.dart ('Hedefin yönü' in the target field list).
}
