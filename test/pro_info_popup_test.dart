// Pro Ayarlar explanations (owner, 2026-10-13: "Pro sayfasındaki
// açıklamalar popup olsun"; then "alttan açılan sayfa" and "iki bilgi olmaz
// kafa karıştırır"): no inline Ne? / Neden önemli? / Nasıl? block in any
// opened box; the ⓘ next to each box title AND every field ⓘ inside the box
// open the SAME bottom sheet: the box's explanations, then "Kutular" (each
// field with its ⓘ text; the tapped field highlighted). Other pages' ⓘ
// keep their popup; Hedef keeps its explanations.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/pro_info_sheet.dart';
import 'package:sniper_turk/features/ballistics/pro_section_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';

const _fxRifle = <String, dynamic>{
  'id': 'manual_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'manual_ammo_fx',
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
const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Test',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.03,
  'bcModel': 'ga',
};
const _fx = RifleProfile(
  id: 'p-fx',
  name: 'FX',
  rifleId: 'manual_rifle_fx',
  ammunitionId: 'manual_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);
const _pcp = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'manual_rifle_pcp',
  ammunitionId: 'manual_ammo_pcp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 30,
  sightHeightMm: 60,
);

const _titles = <String, String>{
  'angle': 'Açı',
  'wind': 'Rüzgâr düzeltmesi',
  'coriolis': 'Coriolis',
  'gravity': 'Yerçekimi',
  'target': 'Hareketli hedef',
  'rifle': 'Tüfek düzeltmeleri',
};

Map<String, List<ProExplain>> _expected({required bool pcp}) => {
  'angle': const [ProSectionInfo.incline, ProSectionInfo.cant],
  'wind': const [ProSectionInfo.windMax, ProSectionInfo.windZones],
  'coriolis': const [ProSectionInfo.coriolis],
  'gravity': const [ProSectionInfo.gravity],
  'target': const [ProSectionInfo.movingTarget, ProSectionInfo.hitProbability],
  'rifle': [
    ProSectionInfo.turretScale,
    ProSectionInfo.zeroOffset,
    ProSectionInfo.spinDrift,
    if (!pcp) ProSectionInfo.powder,
    // Tüp basıncı is asked on Profil (owner, 2026-10-14).
  ],
};

/// "Kutular" of each box: field label → its ⓘ text, in page order.
Map<String, Map<String, String>> _fields({required bool pcp}) => {
  'angle': {
    'Tüfek eğimi': EnvironmentFieldInfo.inclineFor(firearm: !pcp),
    'Dürbün eğimi': EnvironmentFieldInfo.cantFor(firearm: !pcp),
  },
  'wind': const {
    'En çok rüzgâr': EnvironmentFieldInfo.windMax,
    'Yol ortası': EnvironmentFieldInfo.windMid,
    'Hedefte': EnvironmentFieldInfo.windFar,
  },
  'coriolis': const {
    'Enlem': EnvironmentFieldInfo.latitude,
    'Atış yönü': EnvironmentFieldInfo.azimuth,
  },
  'gravity': const {'Yerçekimi': EnvironmentFieldInfo.gravity},
  'target': const {
    'Hedef hızı': EnvironmentFieldInfo.targetSpeed,
    'Yönü': EnvironmentFieldInfo.targetDirection,
    'Grup çapı': EnvironmentFieldInfo.group,
    'Hız farkı': EnvironmentFieldInfo.sd,
    'Hedef çapı': EnvironmentFieldInfo.targetSize,
    'Mesafe hatası': EnvironmentFieldInfo.rangeError,
    'BC hatası': EnvironmentFieldInfo.bcError,
    'Atış sayısı': EnvironmentFieldInfo.wezShotCount,
  },
  'rifle': {
    'Gerçek / yazan': EnvironmentFieldInfo.turretScale,
    'Yukarı + / aşağı −': EnvironmentFieldInfo.zeroUp,
    'Sağ + / sol −': EnvironmentFieldInfo.zeroRight,
    'Mermi uzunluğu': EnvironmentFieldInfo.bulletLength,
  },
};

/// Every explanation text of [ProSectionInfo] (none may be on the page).
const _all = [
  ProSectionInfo.incline,
  ProSectionInfo.cant,
  ProSectionInfo.windMax,
  ProSectionInfo.windZones,
  ProSectionInfo.coriolis,
  ProSectionInfo.gravity,
  ProSectionInfo.movingTarget,
  ProSectionInfo.hitProbability,
  ProSectionInfo.turretScale,
  ProSectionInfo.zeroOffset,
  ProSectionInfo.spinDrift,
  ProSectionInfo.powder,
  ProSectionInfo.pcpPressure,
];

Widget _app(
  RifleProfile profile,
  BallisticsView view, {
  ThemeData? theme,
  double textScale = 1,
}) => MaterialApp(
  theme: theme ?? MenzilTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: BallisticsScreen(profile: profile, view: view),
  ),
);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder get _sheet => find.byKey(const Key('pro-info-sheet'));

Finder _inSheet(Finder f) => find.descendant(of: _sheet, matching: f);

/// The paragraph of [question] whose plain text is "[question] [text]".
Finder _paragraph(String question, String text) => _inSheet(
  find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText() == '$question $text',
  ),
);

/// "Kutular" entries of the open sheet, in order.
List<ProInfoFieldEntry> _entries(WidgetTester tester) => tester
    .widgetList<ProInfoFieldEntry>(_inSheet(find.byType(ProInfoFieldEntry)))
    .toList();

Future<void> _tapButton(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openInfo(WidgetTester tester, String id) =>
    _tapButton(tester, find.byKey(Key('pro-info-$id')));

Future<void> _close(WidgetTester tester) async {
  final close = _inSheet(find.byKey(const Key('pro-info-close')));
  expect(
    find.descendant(of: close, matching: find.text('Kapat')),
    findsOneWidget,
  );
  await tester.tap(close);
  await tester.pumpAndSettle();
  expect(_sheet, findsNothing);
}

/// The open sheet shows [entries] (title, bold questions, bullet lines) and
/// the box's [fields], everything left-aligned; not an AlertDialog.
void _expectSheet(
  WidgetTester tester,
  String title,
  List<ProExplain> entries,
  Map<String, String> fields,
) {
  expect(_sheet, findsOneWidget, reason: title);
  expect(find.byType(BottomSheet), findsOneWidget, reason: title);
  expect(find.byType(AlertDialog), findsNothing, reason: title);
  expect(
    tester.widget<Text>(_inSheet(find.byKey(const Key('pro-info-title')))).data,
    title,
  );
  for (final e in entries) {
    final how = e.how.split('\n');
    for (final (q, text) in [
      ('Ne?', e.what),
      ('Neden önemli?', e.why),
      ('Nasıl?', how.first),
    ]) {
      final f = _paragraph(q, text);
      expect(f, findsOneWidget, reason: '${e.title} $q');
      // Questions bold (owner, 2026-10-12), each its own paragraph.
      TextSpan? first;
      tester.widget<RichText>(f).text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          first = span;
          return false;
        }
        return true;
      });
      expect(first?.text?.trim(), q, reason: '${e.title} $q');
      expect(first?.style?.fontWeight, FontWeight.w600, reason: e.title);
    }
    // "Nasıl?" steps: one line each, the "•" as its own bullet.
    for (final line in how.skip(1).where((l) => l.trim().isNotEmpty)) {
      final text = line.startsWith('•') ? line.substring(1).trim() : line;
      expect(_inSheet(find.text(text)), findsOneWidget, reason: line);
    }
    // A title equal to the sheet title is not repeated (owner, 2026-10-12).
    expect(_inSheet(find.text(e.title)), findsOneWidget, reason: e.title);
  }
  final shown = _entries(tester);
  expect(
    shown.map((f) => f.field.label).toList(),
    fields.keys.toList(),
    reason: title,
  );
  for (final f in shown) {
    // Word for word the field's own ⓘ text.
    expect(f.field.text, fields[f.field.label], reason: f.field.label);
  }
  expect(
    _inSheet(find.byKey(const Key('pro-info-fields'))),
    fields.isEmpty ? findsNothing : findsOneWidget,
  );
  // Left-aligned, not justified (owner, 2026-10-13 20:28).
  for (final r in tester.widgetList<RichText>(
    _inSheet(find.byType(RichText)),
  )) {
    expect(r.textAlign, TextAlign.start, reason: r.text.toPlainText());
  }
}

/// The field ⓘ buttons inside the open box [id] (not the box ⓘ).
Finder _fieldButtons(String id) => find.descendant(
  of: find.byKey(Key('pro-box-$id')),
  matching: find.byWidgetPredicate(
    (w) => w is MenzilInfoButton && w.key != Key('pro-info-$id'),
  ),
);

/// [entry] starts inside the visible part of the sheet's scroll view (its
/// bold label shows); when it is shorter than the view it is fully visible.
void _expectVisible(WidgetTester tester, Finder entry) {
  final view = tester.getRect(
    _inSheet(find.byKey(const Key('pro-info-scroll'))),
  );
  final r = tester.getRect(entry);
  expect(r.top, greaterThanOrEqualTo(view.top - 0.5));
  expect(r.top, lessThan(view.bottom - 20));
  if (r.height <= view.height) {
    expect(r.bottom, lessThanOrEqualTo(view.bottom + 0.5));
  }
}

void _expectNoInlineExplanation() {
  for (final q in ['Ne?', 'Neden önemli?', 'Nasıl?']) {
    expect(find.textContaining(q, findRichText: true), findsNothing, reason: q);
  }
  for (final e in _all) {
    expect(
      find.textContaining(e.what, findRichText: true),
      findsNothing,
      reason: e.title,
    );
  }
  expect(find.byKey(const Key('pro-spin-pcp-note')), findsNothing);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_fxRifle, _fxAmmo, _pcpRifle, _pcpAmmo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final pcp in [false, true]) {
    final name = pcp ? 'PCP' : 'firearm';
    final profile = pcp ? _pcp : _fx;

    testWidgets('$name: no inline explanation in any opened box', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(profile, BallisticsView.pro));
      await tester.pumpAndSettle();
      _expectNoInlineExplanation();
      for (final id in _titles.keys) {
        final header = find.byKey(Key('pro-section-$id'));
        await tester.ensureVisible(header);
        await tester.pumpAndSettle();
        await tapProHeader(tester, header);
        // The box is open (its summary hides) and shows no explanation.
        expect(find.byKey(Key('pro-summary-$id')), findsNothing, reason: id);
        expect(_sheet, findsNothing, reason: id);
        _expectNoInlineExplanation();
      }
    });

    testWidgets('$name: each box ⓘ opens its bottom sheet; Kapat closes', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(profile, BallisticsView.pro));
      await tester.pumpAndSettle();
      final fields = _fields(pcp: pcp);
      for (final entry in _expected(pcp: pcp).entries) {
        final id = entry.key, title = _titles[id]!;
        // Next to the title, inside the header row.
        expect(
          find.descendant(
            of: find.byKey(Key('pro-section-$id')),
            matching: find.byKey(Key('pro-info-$id')),
          ),
          findsOneWidget,
          reason: id,
        );
        expect(find.byTooltip('Açıklama: $title'), findsOneWidget);
        await _openInfo(tester, id);
        // Opening the sheet does not open the box.
        expect(find.byKey(Key('pro-summary-$id')), findsOneWidget, reason: id);
        _expectSheet(tester, title, entry.value, fields[id]!);
        // From the box ⓘ nothing is highlighted.
        expect(_entries(tester).where((f) => f.highlighted), isEmpty);
        // The PCP spin drift note rides along in the Tüfek sheet.
        expect(
          _inSheet(find.byKey(const Key('pro-spin-pcp-note'))),
          id == 'rifle' && pcp ? findsOneWidget : findsNothing,
          reason: id,
        );
        if (id == 'rifle' && pcp) {
          expect(
            _inSheet(find.text(ProSectionInfo.spinDriftPcpNote)),
            findsOneWidget,
          );
        }
        await _close(tester);
      }
    });

    testWidgets('$name: every field ⓘ opens its box sheet, field highlighted', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(profile, BallisticsView.pro));
      await tester.pumpAndSettle();
      final fields = _fields(pcp: pcp);
      for (final entry in _expected(pcp: pcp).entries) {
        final id = entry.key, title = _titles[id]!;
        final header = find.byKey(Key('pro-section-$id'));
        await tester.ensureVisible(header);
        await tester.pumpAndSettle();
        await tapProHeader(tester, header);
        final buttons = tester
            .widgetList<MenzilInfoButton>(_fieldButtons(id))
            .toList();
        // Every field of the box has its ⓘ and is listed under "Kutular".
        expect(
          buttons.map((b) => b.title).toList(),
          fields[id]!.keys.toList(),
          reason: id,
        );
        for (var i = 0; i < buttons.length; i++) {
          await _tapButton(tester, _fieldButtons(id).at(i));
          // The same sheet as the box ⓘ, not the old popup.
          _expectSheet(tester, title, entry.value, fields[id]!);
          final shown = _entries(tester);
          expect(
            [for (final f in shown) f.highlighted],
            [for (var j = 0; j < shown.length; j++) j == i],
            reason: buttons[i].title,
          );
          final hl = _inSheet(find.byKey(ValueKey('pro-info-field-$i')));
          final box = tester.widget<Container>(hl).decoration! as BoxDecoration;
          expect(box.color, isNotNull, reason: buttons[i].title);
          _expectVisible(tester, hl);
          await _close(tester);
        }
      }
    });
  }

  testWidgets('swipe down closes the sheet', (tester) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.pro));
    await tester.pumpAndSettle();
    await _openInfo(tester, 'target');
    expect(_sheet, findsOneWidget);
    await tester.fling(
      _inSheet(find.byKey(const Key('pro-info-title'))),
      const Offset(0, 600),
      2000,
    );
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
    // Rounded top corners, drag handle, at most ~85 % of the screen.
    await _openInfo(tester, 'rifle');
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.showDragHandle, isTrue);
    expect(sheet.enableDrag, isTrue);
    final shape = sheet.shape! as RoundedRectangleBorder;
    expect(
      (shape.borderRadius as BorderRadius).topLeft,
      const Radius.circular(20),
    );
    await _close(tester);
  });

  testWidgets('the ⓘ is its own VoiceOver button; Kapat is a button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.pro));
    await tester.pumpAndSettle();
    for (final MapEntry(key: id, value: title) in _titles.entries) {
      expect(
        tester.getSemantics(find.byKey(Key('pro-info-$id'))),
        isSemantics(
          tooltip: 'Açıklama: $title',
          isButton: true,
          hasTapAction: true,
        ),
        reason: id,
      );
    }
    await _openInfo(tester, 'angle');
    expect(
      tester.getSemantics(find.byKey(const Key('pro-info-close'))),
      isSemantics(label: 'Kapat', isButton: true, hasTapAction: true),
    );
    await _close(tester);
    semantics.dispose();
  });

  testWidgets('narrow phone, text ×1.3: the sheet scrolls, no overflow', (
    tester,
  ) async {
    const screen = Size(320, 568);
    await _size(tester, screen);
    await tester.pumpWidget(_app(_pcp, BallisticsView.pro, textScale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final id in _titles.keys) {
      await _openInfo(tester, id);
      expect(tester.takeException(), isNull, reason: id);
      expect(_sheet, findsOneWidget, reason: id);
      // The sheet fits: at most ~85 % of the screen, Kapat on screen.
      final rect = tester.getRect(find.byType(BottomSheet));
      expect(rect.left, greaterThanOrEqualTo(0), reason: id);
      expect(rect.right, lessThanOrEqualTo(screen.width), reason: id);
      expect(rect.bottom, lessThanOrEqualTo(screen.height), reason: id);
      expect(rect.height, lessThanOrEqualTo(screen.height * 0.85 + 1));
      final close = tester.getRect(find.byKey(const Key('pro-info-close')));
      expect(close.bottom, lessThanOrEqualTo(screen.height), reason: id);
      if (id == 'rifle' || id == 'target') {
        // The long sheets scroll to their last line.
        final scrollable = _inSheet(find.byType(Scrollable)).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0), reason: id);
        // Swipe up until the end (a long sheet at ×1.3 is several screens).
        for (
          var i = 0;
          i < 20 && position.pixels < position.maxScrollExtent;
          i++
        ) {
          await tester.drag(scrollable, const Offset(0, -3000));
          await tester.pumpAndSettle();
        }
        expect(position.pixels, position.maxScrollExtent, reason: id);
        expect(tester.takeException(), isNull);
      }
      await _close(tester);
    }
    // The last field of the longest sheet: highlighted and scrolled into
    // view.
    final header = find.byKey(const Key('pro-section-rifle'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tapProHeader(tester, header);
    final button = find.descendant(
      of: find.byKey(const Key('pro-bullet-length')),
      matching: find.byType(MenzilInfoButton),
    );
    await _tapButton(tester, button);
    expect(tester.takeException(), isNull);
    final last = _entries(tester).length - 1;
    expect(_entries(tester)[last].highlighted, isTrue);
    expect(_entries(tester)[last].field.label, 'Mermi uzunluğu');
    final scrollable = _inSheet(find.byType(Scrollable)).first;
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );
    _expectVisible(tester, find.byKey(ValueKey('pro-info-field-$last')));
    await _close(tester);
  });

  testWidgets('dark theme: the sheet uses the dark colours', (tester) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(
      _app(_fx, BallisticsView.pro, theme: MenzilTheme.dark()),
    );
    await tester.pumpAndSettle();
    await _openInfo(tester, 'angle');
    final dark = MenzilColors.of(tester.element(_sheet));
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      dark.surface,
    );
    final p = tester.widget<RichText>(
      _paragraph('Ne?', ProSectionInfo.incline.what),
    );
    expect(p.text.style?.color, dark.ink2);
    await _close(tester);
  });

  testWidgets('other ⓘ keep their popup: Atış mesafesi, Hava Durumu', (
    tester,
  ) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.pro));
    await tester.pumpAndSettle();
    // Outside any Pro box: the old popup.
    await _tapButton(
      tester,
      find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(MenzilInfoButton),
      ),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(_sheet, findsNothing);
    expect(find.text(EnvironmentFieldInfo.proShotRange), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tamam'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.pumpWidget(_app(_fx, BallisticsView.environment));
    await tester.pumpAndSettle();
    await _tapButton(
      tester,
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.humidity),
        matching: find.byType(MenzilInfoButton),
      ),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(EnvironmentFieldInfo.humidity), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tamam'),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Hedef keeps its explanations; no Pro ⓘ there', (tester) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.shot));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.workings), findsOneWidget);
    expect(_sheet, findsNothing);
    for (final id in _titles.keys) {
      expect(find.byKey(Key('pro-info-$id')), findsNothing, reason: id);
    }
  });
}
