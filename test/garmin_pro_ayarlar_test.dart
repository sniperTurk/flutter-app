// Garmin saati on Pro Ayarlar (owner, 2026-10-16 01:00–01:04: "Garmin
// özelliğini Pro Ayarlar'a alalım", "Garmin isteğe bağlı deriz", ⓘ with how
// it is used, what it brings and that nothing changes without it). The row
// is the last item after Tüfek düzeltmeleri, before "Hedef'e geç", only in a
// build with the Garmin bridge; without it nothing appears and the Pro
// layout is unchanged.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/pro_section_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

class _FakeGarmin implements GarminLink {
  final int? count;
  int selects = 0;
  final changes = StreamController<int>.broadcast();

  _FakeGarmin(this.count);

  @override
  Future<int?> deviceCount() async => count;

  @override
  Stream<int> get deviceCountChanges => changes.stream;

  @override
  Future<bool> selectDevice() async {
    selects++;
    return count != null;
  }
}

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_garmin',
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
  'id': 'manual_ammo_garmin',
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
  id: 'p-garmin',
  name: 'Garmin',
  rifleId: 'manual_rifle_garmin',
  ammunitionId: 'manual_ammo_garmin',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// The owner's 01:04 wording; only "Hedef'teki" was added (the phone sends
/// the solution while Hedef is open, see docs/reports/garmin_pro_ayarlar.md).
const _infoText =
    'Hesap sonucunu (üst ve yan kule klikleri, mesafe, rüzgâr) Garmin '
    'saatinize gönderir; sonucu telefonu çıkarmadan bileğinizden okursunuz. '
    'Nasıl kullanılır: saatinize Connect IQ mağazasından SNIPER TÜRK '
    'uygulamasını yükleyin, bu satıra dokunun ve Garmin Connect\'te saatinizi '
    'seçin. Sonra Hedef\'teki her yeni hesap saate kendiliğinden gider; '
    'saatten mesafe de gönderebilirsiniz. Kullanmazsanız hiçbir ayarınız ve '
    'hesabınız değişmez.';

const _boxes = ['angle', 'wind', 'coriolis', 'gravity', 'target', 'rifle'];

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

Future<void> _size(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void _bridge(int? count) {
  GarminLink.instance = _FakeGarmin(count);
  addTearDown(() => GarminLink.instance = GarminLink());
}

/// Top of every Pro row and of the Hedef'e geç button.
Map<String, double> _tops(WidgetTester tester) => {
  for (final id in _boxes)
    id: tester.getTopLeft(find.byKey(Key('pro-box-$id'))).dy,
  'continue': tester.getTopLeft(find.byKey(const Key('pro-continue-shot'))).dy,
};

Map<String, String?> _summaries(WidgetTester tester) => {
  for (final id in _boxes)
    id: tester.widget<Text>(find.byKey(Key('pro-summary-$id'))).data,
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('the ⓘ text is the owner wording', () {
    expect(ProSectionInfo.garmin, _infoText);
  });

  testWidgets('with the bridge: last row after Tüfek düzeltmeleri, before '
      'Hedef\'e geç, with ⓘ and "isteğe bağlı"', (tester) async {
    await _size(tester, 390);
    _bridge(1);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('tool-garmin'));
    expect(row, findsOneWidget);
    final tile = tester.widget<MenzilToolTile>(find.byType(MenzilToolTile));
    final rifle = tester.getRect(find.byKey(const Key('pro-box-rifle')));
    final garmin = tester.getRect(
      find.ancestor(of: row, matching: find.byType(MenzilCard)).first,
    );
    final next = tester.getRect(find.byKey(const Key('pro-continue-shot')));
    // Card rects include their bottom margin (the Pro boxes' 8 pt gap):
    // the row follows Tüfek düzeltmeleri directly, then the usual 10 pt.
    expect(garmin.top, closeTo(rifle.bottom, 0.5));
    expect(next.top - garmin.bottom, closeTo(MenzilSpace.md, 0.5));
    final rifleMargin = tester
        .widget<MenzilCard>(find.byKey(const Key('pro-box-rifle')))
        .margin;
    expect(tile.margin, rifleMargin);
    expect(
      find.descendant(of: row, matching: find.text('Garmin saati')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.byKey(const Key('pro-info-garmin')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('isteğe bağlı')),
      findsOneWidget,
    );
    // White icon on #1B3245, like on Araçlar.
    expect(tile.plainIcon, isTrue);
    expect(MenzilToolTile.plainIconBackground, const Color(0xFF1B3245));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ⓘ opens the Pro bottom sheet with the text', (tester) async {
    await _size(tester, 390);
    _bridge(0);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final info = find.byKey(const Key('pro-info-garmin'));
    await tester.ensureVisible(info);
    await tester.pumpAndSettle();
    await tester.tap(info);
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('pro-info-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('pro-info-title'))).data,
      'Garmin saati',
    );
    final text = tester.widget<Text>(find.byKey(const Key('pro-info-text')));
    expect(text.data, _infoText);
    expect(text.textAlign, TextAlign.start);
    // One paragraph: no Ne? / Nasıl? questions, no Kutular.
    expect(find.byKey(const Key('pro-info-fields')), findsNothing);
    await tester.tap(find.byKey(const Key('pro-info-close')));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('without the bridge: nothing on Pro, layout unchanged, '
      'same summaries', (tester) async {
    await _size(tester, 390);
    _bridge(null);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tool-garmin')), findsNothing);
    expect(find.text('Garmin saati'), findsNothing);
    expect(find.text('isteğe bağlı'), findsNothing);
    expect(find.byKey(const Key('pro-info-garmin')), findsNothing);
    final without = _tops(tester);
    final summaries = _summaries(tester);
    // No space taken: Tüfek düzeltmeleri (its rect includes its 8 pt
    // margin), then the usual 10 pt before Hedef'e geç.
    final rifle = tester.getRect(find.byKey(const Key('pro-box-rifle')));
    expect(without['continue']! - rifle.bottom, closeTo(MenzilSpace.md, 0.5));

    // The same page with the bridge: every row above keeps its place and
    // no summary changes (the row is not a setting).
    await tester.pumpWidget(const SizedBox());
    _bridge(2);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tool-garmin')), findsOneWidget);
    final withRow = _tops(tester);
    for (final id in _boxes) {
      expect(withRow[id], closeTo(without[id]!, 0.5), reason: id);
    }
    expect(_summaries(tester), summaries);
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow at $width pt, text ×$scale', (tester) async {
        await _size(tester, width);
        _bridge(0);
        await tester.pumpWidget(_app(textScale: scale));
        await tester.pumpAndSettle();
        final row = find.byKey(const Key('tool-garmin'));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final card = tester.getRect(
          find.ancestor(of: row, matching: find.byType(MenzilCard)).first,
        );
        for (final key in ['pro-info-garmin', 'pro-garmin-optional']) {
          final r = tester.getRect(find.byKey(Key(key)));
          expect(r.left, greaterThanOrEqualTo(card.left), reason: key);
          expect(r.right, lessThanOrEqualTo(card.right + 0.5), reason: key);
        }
        final title = tester.getRect(find.text('Garmin saati'));
        expect(title.left, greaterThanOrEqualTo(card.left));
        // "isteğe bağlı" stays at the right end, before the chevron.
        final optional = tester.getRect(
          find.byKey(const Key('pro-garmin-optional')),
        );
        final chevron = tester.getRect(
          find.descendant(of: row, matching: find.byIcon(Icons.chevron_right)),
        );
        expect(chevron.left - optional.right, inInclusiveRange(0, 24));
        expect(card.right, lessThanOrEqualTo(width + 0.5));
      });
    }
  }
}
