// Pro Ayarlar explanations in a popup (owner, 2026-10-13: "Uygulamada çok
// yazı var, özellikle Pro sayfası çok karmaşık. Pro sayfasındaki açıklamalar
// popup olsun. Hedef sayfasındaki açıklamalar güzel duruyor"): no inline
// Ne? / Neden önemli? / Nasıl? block in any opened box; an ⓘ next to each
// box title opens the same texts; Hedef keeps its explanations.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/pro_section_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

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
    if (pcp) ProSectionInfo.pcpPressure,
  ],
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

Finder get _dialog => find.byType(AlertDialog);

Finder _inDialog(Finder f) => find.descendant(of: _dialog, matching: f);

/// The explanation paragraphs (Ne? / Neden önemli? / Nasıl?) in the dialog.
List<RichText> _paragraphs(WidgetTester tester) => tester
    .widgetList<RichText>(_inDialog(find.byType(RichText)))
    .where((r) => r.text.toPlainText().startsWith('Ne? '))
    .toList();

Future<void> _openInfo(WidgetTester tester, String id) async {
  final button = find.byKey(Key('pro-info-$id'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  final close = _inDialog(find.widgetWithText(TextButton, 'Kapat'));
  await tester.ensureVisible(close);
  await tester.pumpAndSettle();
  await tester.tap(close);
  await tester.pumpAndSettle();
  expect(_dialog, findsNothing);
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
        expect(_dialog, findsNothing, reason: id);
        _expectNoInlineExplanation();
      }
    });

    testWidgets('$name: each box ⓘ opens its texts and closes with Kapat', (
      tester,
    ) async {
      await _size(tester, const Size(430, 3000));
      await tester.pumpWidget(_app(profile, BallisticsView.pro));
      await tester.pumpAndSettle();
      for (final entry in _expected(pcp: pcp).entries) {
        final id = entry.key, title = _titles[id]!;
        // Next to the title, inside the header row.
        final button = find.byKey(Key('pro-info-$id'));
        expect(
          find.descendant(
            of: find.byKey(Key('pro-section-$id')),
            matching: button,
          ),
          findsOneWidget,
          reason: id,
        );
        expect(find.byTooltip('Açıklama: $title'), findsOneWidget);
        await _openInfo(tester, id);
        expect(_dialog, findsOneWidget, reason: id);
        // Opening the popup does not open the box.
        expect(find.byKey(Key('pro-summary-$id')), findsOneWidget, reason: id);
        expect(_inDialog(find.text(title)), findsOneWidget, reason: id);

        final paragraphs = _paragraphs(tester);
        expect(paragraphs, hasLength(entry.value.length), reason: id);
        for (var i = 0; i < entry.value.length; i++) {
          final e = entry.value[i];
          final text = paragraphs[i].text.toPlainText();
          // Same texts, in page order, unchanged.
          expect(text, contains('Ne? ${e.what}'), reason: e.title);
          expect(text, contains('Neden önemli? ${e.why}'), reason: e.title);
          expect(text, contains('Nasıl? ${e.how}'), reason: e.title);
          // The questions are bold (owner, 2026-10-12).
          final bold = <String>[];
          paragraphs[i].text.visitChildren((span) {
            if (span is TextSpan &&
                span.text != null &&
                span.style?.fontWeight == FontWeight.w600) {
              bold.add(span.text!.trim());
            }
            return true;
          });
          expect(bold, ['Ne?', 'Neden önemli?', 'Nasıl?'], reason: e.title);
          expect(paragraphs[i].textAlign, TextAlign.justify, reason: e.title);
          // Each title shows once: a title equal to the popup title is not
          // repeated under it (owner, 2026-10-12).
          expect(
            _inDialog(find.text(e.title)),
            findsOneWidget,
            reason: e.title,
          );
        }
        // The PCP spin drift note rides along in the Tüfek popup.
        expect(
          _inDialog(find.byKey(const Key('pro-spin-pcp-note'))),
          id == 'rifle' && pcp ? findsOneWidget : findsNothing,
          reason: id,
        );
        if (id == 'rifle' && pcp) {
          expect(
            _inDialog(find.text(ProSectionInfo.spinDriftPcpNote)),
            findsOneWidget,
          );
        }
        await _close(tester);
      }
    });
  }

  testWidgets('the ⓘ is its own VoiceOver button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.pro));
    await tester.pumpAndSettle();
    for (final MapEntry(key: id, value: title) in _titles.entries) {
      expect(
        tester.getSemantics(find.byKey(Key('pro-info-$id'))),
        containsSemantics(
          tooltip: 'Açıklama: $title',
          isButton: true,
          hasTapAction: true,
        ),
        reason: id,
      );
    }
    semantics.dispose();
  });

  testWidgets('narrow phone, text ×1.3: the popup scrolls, no overflow', (
    tester,
  ) async {
    await _size(tester, const Size(320, 568));
    await tester.pumpWidget(_app(_pcp, BallisticsView.pro, textScale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final id in _titles.keys) {
      await _openInfo(tester, id);
      expect(tester.takeException(), isNull, reason: id);
      expect(_dialog, findsOneWidget, reason: id);
      // The dialog fits the screen.
      final rect = tester.getRect(_dialog);
      expect(rect.left, greaterThanOrEqualTo(0), reason: id);
      expect(rect.right, lessThanOrEqualTo(320), reason: id);
      expect(rect.bottom, lessThanOrEqualTo(568), reason: id);
      if (id == 'rifle') {
        // The longest popup scrolls to its last line.
        final scrollable = _inDialog(find.byType(Scrollable)).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(scrollable, const Offset(0, -5000));
        await tester.pumpAndSettle();
        expect(position.pixels, position.maxScrollExtent);
        expect(tester.takeException(), isNull);
      }
      await _close(tester);
    }
  });

  testWidgets('dark theme: the popup uses the dark colours', (tester) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(
      _app(_fx, BallisticsView.pro, theme: MenzilTheme.dark()),
    );
    await tester.pumpAndSettle();
    await _openInfo(tester, 'angle');
    final dark = MenzilColors.of(tester.element(_dialog));
    for (final p in _paragraphs(tester)) {
      expect(p.text.style?.color, dark.ink2);
    }
    await _close(tester);
  });

  testWidgets('Hedef keeps its explanations; no Pro ⓘ there', (tester) async {
    await _size(tester, const Size(430, 3000));
    await tester.pumpWidget(_app(_fx, BallisticsView.shot));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.workings), findsOneWidget);
    expect(_dialog, findsNothing);
    for (final id in _titles.keys) {
      expect(find.byKey(Key('pro-info-$id')), findsNothing, reason: id);
    }
  });
}
