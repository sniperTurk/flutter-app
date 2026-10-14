// Araçlar > Gizlilik politikası (App Review 5.1.1(i), owner 2026-10-14):
// one tap from the Araçlar tab, the built-in Turkish policy opens offline,
// left-aligned, no "Web'de aç" button, no overflow on a 320 pt phone with
// text scale 1.3.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/guide/privacy_policy_content.dart';
import 'package:sniper_turk/features/guide/privacy_policy_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _knownSentence =
    'Uygulama bir hesap yardımcısıdır; sonuçlar gerçek atışla '
    'doğrulanmalıdır.';

Future<void> _pumpPolicy(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  String webUrl = '',
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: PrivacyPolicyScreen(webUrl: webUrl),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Araçlar tab: Gizlilik politikası opens the built-in policy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: MemoryProfileStore(),
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Araçlar'));
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('tool-privacy-policy'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.text('Gizlilik politikası')),
      findsOneWidget,
    );
    // Right under Kullanım rehberi, the last entry of the hub.
    expect(
      tester.getTopLeft(tile).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('tool-usage-guide'))).dy,
      ),
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.text(PrivacyPolicyContent.heading), findsOneWidget);
    final sentence = find.text(_knownSentence);
    await tester.ensureVisible(sentence);
    expect(sentence, findsOneWidget);
    expect(find.textContaining("Web'de aç"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty PRIVACY_POLICY_URL: no web button or address', (
    tester,
  ) async {
    await _pumpPolicy(tester, size: const Size(390, 844));
    expect(privacyPolicyUrl, isEmpty);
    expect(find.textContaining("Web'de aç"), findsNothing);
    expect(find.byKey(const Key('privacy-policy-web-address')), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a set URL is shown as text, still without a web button', (
    tester,
  ) async {
    await _pumpPolicy(
      tester,
      size: const Size(390, 844),
      webUrl: 'https://example.org/gizlilik',
    );
    final address = find.byKey(const Key('privacy-policy-web-address'));
    await tester.ensureVisible(address);
    expect(address, findsOneWidget);
    expect(
      tester.widget<SelectableText>(address).data,
      'Web adresi: https://example.org/gizlilik',
    );
    expect(find.textContaining("Web'de aç"), findsNothing);
  });

  testWidgets('every paragraph is left-aligned in the system font', (
    tester,
  ) async {
    await _pumpPolicy(tester, size: const Size(390, 30000));
    final page = find.byKey(const Key('privacy-policy-page'));
    final paragraphs = find.descendant(
      of: page,
      matching: find.byType(RichText),
    );
    var long = 0;
    for (final element in paragraphs.evaluate()) {
      final render = element.renderObject! as RenderParagraph;
      final text = render.text.toPlainText();
      if (text.length < 60) continue;
      long++;
      expect(render.textAlign, TextAlign.start, reason: text);
      expect(render.text.style?.fontFamily, MenzilType.textFamily);
      expect(
        (render.text.style?.fontWeight ?? FontWeight.w400).value,
        lessThan(FontWeight.w600.value),
        reason: text,
      );
    }
    final expected = PrivacyPolicyContent.sections.fold<int>(
      0,
      (sum, s) => sum + s.paragraphs.where((p) => p.length >= 60).length,
    );
    expect(long, greaterThanOrEqualTo(expected));
    expect(find.text(_knownSentence), findsOneWidget);
  });

  testWidgets('320 pt wide, text scale 1.3: no overflow', (tester) async {
    await _pumpPolicy(tester, size: const Size(320, 568), textScale: 1.3);
    expect(tester.takeException(), isNull);
    final scrollable = find.byType(Scrollable).first;
    for (final section in PrivacyPolicyContent.sections) {
      final card = find.byKey(Key('privacy-policy-${section.title}'));
      await tester.scrollUntilVisible(card, 300, scrollable: scrollable);
      expect(tester.takeException(), isNull, reason: section.title);
      // Cards stay inside the 320 pt screen.
      final rect = tester.getRect(card);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
  });
}
