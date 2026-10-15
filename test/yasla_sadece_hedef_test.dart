// Owner, 2026-10-13: "İki yana yaslamayı kaldır, çünkü artık açıklamaları
// popup içine aldık; sadece Hedef sayfasında sağa sola yaslı olsun yazılar."
// Text is left-aligned everywhere except the Hedef page.
import 'package:flutter/material.dart';
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

const _long =
    'Bu uyarı birkaç satıra yayılacak kadar uzun bir cümledir; kelimeler '
    'arasında iki yana yaslamanın açtığı büyük boşluklar görünmemelidir, '
    'metin sola yaslı akmalıdır.';

/// The alignment a [Text] is actually painted with (its own value or the
/// inherited DefaultTextStyle, resolved by Flutter into the RichText).
TextAlign _painted(WidgetTester tester, Finder text) => tester
    .widget<RichText>(
      find.descendant(of: text, matching: find.byType(RichText)).first,
    )
    .textAlign;

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _page(List<Widget> children, {bool justify = false}) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: MenzilPage(justify: justify, children: children),
  ),
);

void main() {
  testWidgets('Profil summary values are left-aligned, not justified', (
    tester,
  ) async {
    await _pumpHome(tester);
    // The app opens on Profil.
    final scopeCard = find.byKey(const Key('profile-summary-scope'));
    expect(scopeCard, findsOneWidget);
    final painted = tester
        .widgetList<RichText>(
          find.descendant(of: scopeCard, matching: find.byType(RichText)),
        )
        .toList();
    expect(painted, isNotEmpty);
    for (final r in painted) {
      expect(r.textAlign, TextAlign.start, reason: r.text.toPlainText());
    }
    // The Profil page itself no longer justifies by default.
    final page = tester.widget<MenzilPage>(
      find.ancestor(of: scopeCard, matching: find.byType(MenzilPage)).first,
    );
    expect(page.justify, isFalse);
  });

  testWidgets('Hedef page explanation paragraphs stay justified', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Hedef'));
    await tester.pumpAndSettle();
    final page = tester.widget<MenzilPage>(
      find
          .ancestor(
            of: find.byKey(ScopeDialKeys.reticle),
            matching: find.byType(MenzilPage),
          )
          .first,
    );
    expect(page.justify, isTrue);
    // Readout paragraph under the scope.
    expect(
      _painted(tester, find.textContaining('Kırmızı sayılar:')),
      TextAlign.justify,
    );
    // "Hesap dökümü" lines (closed by default since 2026-10-15: open it).
    await tester.ensureVisible(find.byKey(ScopeDialKeys.workingsToggle));
    await tester.tap(find.byKey(ScopeDialKeys.workingsToggle));
    await tester.pumpAndSettle();
    final workings = find.descendant(
      of: find.byKey(ScopeDialKeys.workings),
      matching: find.byType(Text),
    );
    expect(workings.evaluate().length, greaterThan(1));
    for (final e in workings.evaluate().skip(1)) {
      expect((e.widget as Text).textAlign, TextAlign.justify);
    }
  });

  testWidgets('MenzilNotice message is left-aligned', (tester) async {
    await tester.pumpWidget(_page([const MenzilNotice(message: _long)]));
    expect(_painted(tester, find.text(_long)), TextAlign.start);
    // Even inside a justified page a notice stays left-aligned.
    await tester.pumpWidget(
      _page([const MenzilNotice(message: _long)], justify: true),
    );
    expect(_painted(tester, find.text(_long)), TextAlign.start);
  });

  testWidgets('MenzilPage paragraphs: start by default, justify on request', (
    tester,
  ) async {
    await tester.pumpWidget(_page([const Text(_long)]));
    expect(_painted(tester, find.text(_long)), TextAlign.start);
    await tester.pumpWidget(_page([const Text(_long)], justify: true));
    expect(_painted(tester, find.text(_long)), TextAlign.justify);
  });

  for (final illustrated in [false, true]) {
    testWidgets('ⓘ popup text is left-aligned (illustration: $illustrated)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page([
          MenzilInfoButton(
            title: 'Bilgi',
            text: _long,
            illustration: illustrated
                ? const SizedBox(width: 40, height: 40)
                : null,
          ),
        ], justify: true),
      );
      await tester.tap(find.byType(MenzilInfoButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_painted(tester, find.text(_long)), TextAlign.start);
    });
  }
}
