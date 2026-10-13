// Sistem yazısı (owner, 2026-10-13): every page uses the iPhone system font
// (San Francisco) instead of Inter; tabular (equal-width) figures stay only
// on values that change live. See docs/reports/sistem_yazisi.md.
import 'dart:io';
// ignore: unnecessary_import
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _profile = RifleProfile(
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

const _systemFamilies = {MenzilType.textFamily, MenzilType.displayFamily};

bool _hasTabular(List<FontFeature>? f) =>
    f != null && f.contains(const FontFeature.tabularFigures());

/// Every span style of [span] (root included).
List<TextStyle> _spanStyles(InlineSpan span) {
  final out = <TextStyle>[];
  span.visitChildren((s) {
    if (s.style != null) out.add(s.style!);
    return true;
  });
  return out;
}

/// Loads the bundled Inter files under the two SF proxy names, as
/// test/ekran_boyutu_test.dart does, so widths are close to the phone.
Future<void> _loadStandIn() async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('Inter-'))
      .toList();
  expect(files, isNotEmpty);
  for (final name in _systemFamilies) {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(430, 2400),
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tab(String label) => find.descendant(
  of: find.byType(MenzilBottomNavigation),
  matching: find.text(label),
);

void main() {
  setUpAll(_loadStandIn);

  group('MenzilType', () {
    const ink = Color(0xFF000000);
    final styles = <String, TextStyle>{
      'display': MenzilType.display(ink),
      'display 34': MenzilType.display(ink, size: 34),
      'number': MenzilType.number(ink),
      'number 17': MenzilType.number(ink, size: 17),
      'heading': MenzilType.heading(ink),
      'heading 18': MenzilType.heading(ink, size: 18),
      'label': MenzilType.label(ink),
      'unit': MenzilType.unit(ink),
      'body': MenzilType.body(ink),
      'caption': MenzilType.caption(ink),
    };

    test('no Inter, no condensed fallback, SF proxies by size', () {
      for (final e in styles.entries) {
        final s = e.value;
        expect(s.fontFamily, isNot('Inter'), reason: e.key);
        expect(s.fontFamily, isNot('Oswald'), reason: e.key);
        expect(s.fontFamilyFallback, isNull, reason: e.key);
        expect(
          s.fontFamily,
          s.fontSize! >= 20 ? MenzilType.displayFamily : MenzilType.textFamily,
          reason: e.key,
        );
      }
      expect(MenzilType.familyFor(19.9), MenzilType.textFamily);
      expect(MenzilType.familyFor(20), MenzilType.displayFamily);
    });

    test('proportional figures unless live', () {
      for (final e in styles.entries) {
        expect(_hasTabular(e.value.fontFeatures), isFalse, reason: e.key);
      }
      expect(_hasTabular(MenzilType.display(ink, live: true).fontFeatures), isTrue);
      expect(_hasTabular(MenzilType.number(ink, live: true).fontFeatures), isTrue);
    });

    test('weights: headings bold, values medium, labels regular', () {
      expect(MenzilType.heading(ink).fontWeight, FontWeight.w700);
      expect(MenzilType.display(ink).fontWeight, FontWeight.w700);
      expect(MenzilType.number(ink).fontWeight, FontWeight.w500);
      expect(MenzilType.label(ink).fontWeight, FontWeight.w400);
    });
  });

  test('theme: every text role and control uses the SF proxies', () {
    for (final theme in [MenzilTheme.light(), MenzilTheme.dark()]) {
      final t = theme.textTheme;
      final roles = [
        t.displayLarge, t.displayMedium, t.displaySmall,
        t.headlineLarge, t.headlineMedium, t.headlineSmall,
        t.titleLarge, t.titleMedium, t.titleSmall,
        t.bodyLarge, t.bodyMedium, t.bodySmall,
        t.labelLarge, t.labelMedium, t.labelSmall,
      ];
      for (final r in roles) {
        expect(_systemFamilies, contains(r!.fontFamily), reason: r.debugLabel);
      }
      expect(
        theme.filledButtonTheme.style!.textStyle!.resolve(<WidgetState>{})!.fontFamily,
        MenzilType.textFamily,
      );
      expect(
        theme.inputDecorationTheme.labelStyle!.fontFamily,
        MenzilType.textFamily,
      );
    }
  });

  testWidgets('Profil summary values use proportional figures', (
    tester,
  ) async {
    await _pumpHome(tester);
    final cards = find.byType(MenzilMetricCard);
    expect(cards, findsWidgets);
    final paragraphs = find.descendant(
      of: cards,
      matching: find.byType(RichText),
    );
    expect(paragraphs, findsWidgets);
    for (final e in paragraphs.evaluate()) {
      final rich = e.widget as RichText;
      for (final s in _spanStyles(rich.text)) {
        expect(
          _hasTabular(s.fontFeatures),
          isFalse,
          reason: rich.text.toPlainText(),
        );
        expect(s.fontFamily, isNot('Inter'));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hedef / Atış Çözümü live readouts keep tabular figures', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(_tab('Hedef'));
    await tester.pumpAndSettle();

    // Click/impact line under the scope.
    final impact = tester.widget<Text>(find.byKey(ScopeDialKeys.impactText));
    expect(_hasTabular(impact.style?.fontFeatures), isTrue);
    final turrets = tester.widget<Text>(find.textContaining('Kule: ').first);
    expect(_hasTabular(turrets.style?.fontFeatures), isTrue);

    // Shot distance stepper readout.
    final distance = find.descendant(
      of: find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label ?? '').startsWith('Atış mesafesi'),
      ),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.style?.fontSize ?? 0) >= 44 &&
            _hasTabular(w.style?.fontFeatures),
      ),
    );
    expect(distance, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'no overflow at 375 pt, text 1.3x, ${dark ? 'koyu' : 'açık'} tema',
      (tester) async {
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.exceptionAsString());
        try {
          await _pumpHome(
            tester,
            size: const Size(375, 667),
            textScale: 1.3,
            theme: dark ? MenzilTheme.dark() : MenzilTheme.light(),
          );
          for (final tab in [
            'Profil',
            'Hava Durumu',
            'Pro',
            'Hedef',
            'Araçlar',
          ]) {
            await tester.tap(_tab(tab));
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            final scrollables = find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            );
            final visible = scrollables.hitTestable();
            if (visible.evaluate().isNotEmpty) {
              final pos = tester.state<ScrollableState>(visible.first).position;
              while (pos.pixels < pos.maxScrollExtent - 1) {
                pos.jumpTo((pos.pixels + 500).clamp(0, pos.maxScrollExtent));
                await tester.pump();
              }
            }
            expect(errors, isEmpty, reason: '$tab: ${errors.join('\n')}');
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join('\n'));
      },
    );
  }

  testWidgets('Turkish letters lay out in the system font', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: Text(
            'ğ ş ı İ ç ö ü Ğ Ş Ç Ö Ü',
            style: MenzilType.body(const Color(0xFF000000)),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.textContaining('İ'));
    expect(text.style!.fontFamily, MenzilType.textFamily);
    expect(tester.getSize(find.textContaining('İ')).width, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
