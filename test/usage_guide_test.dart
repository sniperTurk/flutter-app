// Araçlar > Kullanım rehberi (owner draft, 2026-10-11): the tile opens the
// guide, every section is shown, and the page has no bold text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/guide/usage_guide_content.dart';
import 'package:sniper_turk/features/guide/usage_guide_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  Future<void> pumpHub(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const Scaffold(body: ToolsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Araçlar lists Kullanım rehberi last and opens the guide', (
    tester,
  ) async {
    await pumpHub(tester);
    final tile = find.byKey(const Key('tool-usage-guide'));
    expect(tile, findsOneWidget);
    expect(
      tester.getTopLeft(tile).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('tool-calculators'))).dy,
      ),
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(UsageGuideScreen), findsOneWidget);
    expect(find.text('Kullanım rehberi'), findsOneWidget);

    for (final section in UsageGuideContent.sections) {
      final title = find.text(section.title);
      await tester.scrollUntilVisible(
        title,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(title, findsOneWidget, reason: section.title);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('guide page uses no bold text', (tester) async {
    tester.view.physicalSize = const Size(430, 20000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: MenzilTheme.dark(), home: const UsageGuideScreen()),
    );
    await tester.pumpAndSettle();

    final texts = find.descendant(
      of: find.byKey(const Key('usage-guide-page')),
      matching: find.byType(Text),
    );
    final count = UsageGuideContent.sections.fold<int>(
      1 + UsageGuideContent.sections.length,
      (sum, s) => sum + s.paragraphs.length,
    );
    expect(texts, findsNWidgets(count));
    for (final element in texts.evaluate()) {
      final text = element.widget as Text;
      final weight = text.style?.fontWeight ?? FontWeight.w400;
      expect(weight.value, lessThan(FontWeight.w600.value), reason: text.data);
      expect(text.style?.fontFamily, MenzilType.family);
      if (text.data != null && text.data!.length > 60) {
        expect(text.textAlign ?? TextAlign.justify, TextAlign.justify);
      }
    }
    expect(tester.takeException(), isNull);
  });

  test('guide text: plain sentences, Sight height kept in English', () {
    final all = [
      UsageGuideContent.intro,
      for (final s in UsageGuideContent.sections) ...[s.title, ...s.paragraphs],
    ].join('\n');
    expect(all, contains('Sight height'));
    expect(all, isNot(contains('**')));
    expect(all, isNot(contains('TODO')));
    expect(
      UsageGuideContent.sections.map((s) => s.title),
      containsAllInOrder([
        'İlk profil',
        'Sıfırlama',
        'Hava Durumu',
        'Hedef ekranında atış',
        'Pro ayarlar',
        'DOPE kartı',
        'Araçlar',
      ]),
    );
  });
}
