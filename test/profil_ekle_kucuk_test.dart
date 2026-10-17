// Profiller başlığı küçültme (owner, 2026-10-17 18:42 "önerini yap"):
// on the Profil page's list header ('profiles-list-header') the "Profiller"
// heading is 20 pt (was 22, the MenzilSectionHeader default, which stays 22
// for every other header) and "Profil ekle" is a smaller amber button with a
// "+" before the text: visible height 34 pt, text 14 pt bold, 12 pt side
// padding, 9 pt corners, as wide as its content and at most half the row;
// the tap target stays ≥ 44 pt and VoiceOver reads only "Profil ekle".
// See docs/reports/profil_ekle_kucuk.md.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _one = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// Inter under the SF proxy names (as the other Profil tests), so text
/// widths are close to the phone.
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

Future<void> _pump(
  WidgetTester tester, {
  double width = 393,
  double scale = 1.0,
  ThemeMode mode = ThemeMode.dark,
}) async {
  tester.view.physicalSize = Size(width, 1600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_one);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      darkTheme: MenzilTheme.dark(),
      themeMode: mode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ProfilesScreen(
          embedded: true,
          store: store,
          activeProfileId: 'p1',
          onActivate: (_) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _add = find.byKey(const Key('profiles-add'));
final _header = find.byKey(const Key('profiles-list-header'));

/// The amber surface the user sees (the FilledButton's Material), inside
/// the transparent 44+ pt tap area.
Finder get _visible =>
    find.descendant(of: _add, matching: find.byType(Material)).first;

Finder get _label =>
    find.descendant(of: _add, matching: find.text('Profil ekle'));

Finder get _plus => find.descendant(of: _add, matching: find.text('+'));

Finder get _title =>
    find.descendant(of: _header, matching: find.text('Profiller'));

void main() {
  setUpAll(_loadStandIn);

  testWidgets('"Profiller" heading is 20 pt, bold, same colour', (
    tester,
  ) async {
    await _pump(tester);
    final header = tester.widget<MenzilSectionHeader>(
      find.ancestor(of: _title, matching: find.byType(MenzilSectionHeader)),
    );
    expect(header.size, 20);
    final style = tester.widget<Text>(_title).style!;
    expect(style.fontSize, 20);
    expect(style.fontWeight, FontWeight.w700);
    final c = MenzilColors.of(tester.element(_title));
    expect(style.color, c.ink);
  });

  test('MenzilSectionHeader default stays 22 (only this heading changes)', () {
    expect(const MenzilSectionHeader('x').size, 22);
  });

  testWidgets('Profil ekle: visible 34 pt, tap target ≥ 44, amber, 14 pt '
      'bold, 12 pt sides, 9 pt corners', (tester) async {
    await _pump(tester);
    final button = tester.widget<MenzilPrimaryButton>(_add);
    expect(button.amber, isTrue);
    expect(button.expand, isFalse);
    expect(button.oneLine, isTrue);

    final visible = tester.getRect(_visible);
    expect(visible.height, moreOrLessEquals(34, epsilon: 0.5));
    final tap = tester.getRect(_add);
    expect(tap.height, greaterThanOrEqualTo(44));
    expect(tap.width, greaterThanOrEqualTo(44));
    // The visible button sits in the middle of the tap area.
    expect(visible.center.dy, moreOrLessEquals(tap.center.dy, epsilon: 0.5));

    final material = tester.widget<Material>(_visible);
    final c = MenzilColors.of(tester.element(_add));
    expect(material.color, c.amber);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(9));

    final label = tester.widget<Text>(_label);
    final labelStyle = DefaultTextStyle.of(
      tester.element(_label),
    ).style.merge(label.style);
    expect(labelStyle.fontSize, 14);
    expect(labelStyle.fontWeight, FontWeight.w700);

    // 12 pt from the amber edge to the "+" and from the label to the edge.
    final plus = tester.getRect(_plus);
    final text = tester.getRect(_label);
    expect(plus.left - visible.left, moreOrLessEquals(12, epsilon: 0.5));
    expect(visible.right - text.right, moreOrLessEquals(12, epsilon: 0.5));
  });

  testWidgets('"+" before the text, about 17 pt, VoiceOver reads only '
      '"Profil ekle"', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(_plus, findsOneWidget);
    expect(_label, findsOneWidget);
    final plus = tester.getRect(_plus);
    final text = tester.getRect(_label);
    expect(plus.right, lessThanOrEqualTo(text.left));
    expect(text.left - plus.right, lessThan(8));
    expect(plus.center.dy, moreOrLessEquals(text.center.dy, epsilon: 1.5));
    expect(tester.widget<Text>(_plus).style!.fontSize, 17);

    expect(
      tester.getSemantics(_add),
      containsSemantics(label: 'Profil ekle', isButton: true),
    );
    expect(find.bySemanticsLabel('Profil ekle'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\+')), findsNothing);
    semantics.dispose();
  });

  testWidgets('heading and button centred on one line, button right', (
    tester,
  ) async {
    await _pump(tester);
    final title = tester.getRect(_title);
    final visible = tester.getRect(_visible);
    final header = tester.getRect(_header);
    expect(visible.left, greaterThan(title.right));
    expect(visible.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1));
    expect(visible.right, moreOrLessEquals(header.right, epsilon: 0.5));
  });

  testWidgets('opens the editor when tapped at the tap-area edge', (
    tester,
  ) async {
    await _pump(tester);
    final tap = tester.getRect(_add);
    final visible = tester.getRect(_visible);
    // Above the amber surface but inside the 44+ pt target.
    final y = (tap.top + visible.top) / 2;
    await tester.tapAt(Offset(visible.center.dx, y));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
  });

  for (final width in const [320.0, 390.0]) {
    for (final scale in const [1.0, 1.25, 1.3, 2.0, 3.0]) {
      testWidgets('${width.toInt()} pt, text ×$scale: no overflow, one '
          'line, at most half the row', (tester) async {
        await _pump(tester, width: width, scale: scale);
        expect(tester.takeException(), isNull);
        final header = tester.getRect(_header);
        final visible = tester.getRect(_visible);
        final tap = tester.getRect(_add);
        expect(visible.height, moreOrLessEquals(34, epsilon: 0.5));
        expect(tap.height, greaterThanOrEqualTo(44));
        expect(tap.right, lessThanOrEqualTo(width));
        expect(
          visible.width,
          lessThanOrEqualTo((header.width - MenzilSpace.sm) / 2 + 0.5),
        );
        for (final f in [_plus, _label]) {
          final r = tester.getRect(f);
          expect(r.left, greaterThanOrEqualTo(visible.left - 0.5));
          expect(r.right, lessThanOrEqualTo(visible.right + 0.5));
          expect(r.top, greaterThanOrEqualTo(visible.top - 0.5));
          expect(r.bottom, lessThanOrEqualTo(visible.bottom + 0.5));
        }
        final title = tester.getRect(_title);
        expect(title.right, lessThanOrEqualTo(visible.left));
        expect(title.left, greaterThanOrEqualTo(0));
        // ignore: avoid_print
        print(
          'PROFIL_EKLE_KUCUK|${width.toInt()}|x$scale'
          '|gorunen=${visible.width.toStringAsFixed(1)}x'
          '${visible.height.toStringAsFixed(1)}'
          '|dokunma=${tap.width.toStringAsFixed(1)}x'
          '${tap.height.toStringAsFixed(1)}',
        );
      });
    }
  }
}
