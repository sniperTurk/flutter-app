// "Profil ekle" + işareti (owner, 2026-10-14: "Profil ekle ve + işaretinin
// arasındaki boşluğu kapat ama yapışmasınlar, + işaretini soldan sağa 1
// karakter al"): the + icon starts 8 pt (about one character) further right
// than on main, and the label follows it after a 5 pt gap; icon and label
// are one group on the left. Other buttons do not change.
// See docs/reports/profil_ekle_arti.md.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

/// What the Profil page passes.
const _lead = 8.0;

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

/// Inter under the SF proxy names, as test/sistem_yazisi_test.dart does, so
/// label widths are close to the phone.
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

/// The profile page's button row (Profil ekle | Kopyala | Sil) on a page
/// [width] wide, with the page gutter on both sides.
Future<void> _pumpRow(
  WidgetTester tester, {
  required double width,
  required double lead,
  double textScale = 1.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? MenzilTheme.dark() : MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        // A scrolling page, as on the Profil tab (unbounded height).
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.gutter),
          children: [
            Row(
              children: [
                Expanded(
                  child: MenzilPrimaryButton(
                    key: const Key('ekle'),
                    label: 'Profil ekle',
                    icon: Icons.add,
                    amber: true,
                    oneLine: true,
                    iconLead: lead,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: MenzilSpace.sm),
                Expanded(
                  child: MenzilSecondaryButton(
                    key: const Key('kopyala'),
                    label: 'Kopyala',
                    icon: Icons.copy_outlined,
                    expand: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: MenzilSpace.sm),
                Expanded(
                  child: MenzilSecondaryButton(
                    key: const Key('sil'),
                    label: 'Sil',
                    icon: Icons.delete_outline,
                    destructive: true,
                    expand: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

class _Shot {
  final Rect button, icon, text, kopyala, sil, kopyalaText, silText;

  /// The label's own (unscaled) width; [text] is what is drawn.
  final double naturalWidth;
  _Shot(
    this.button,
    this.icon,
    this.text,
    this.kopyala,
    this.sil,
    this.kopyalaText,
    this.silText,
    this.naturalWidth,
  );
}

_Shot _measure(WidgetTester tester) => _Shot(
  tester.getRect(find.byKey(const Key('ekle'))),
  tester.getRect(find.byIcon(Icons.add)),
  tester.getRect(find.text('Profil ekle')),
  tester.getRect(find.byKey(const Key('kopyala'))),
  tester.getRect(find.byKey(const Key('sil'))),
  tester.getRect(find.text('Kopyala')),
  tester.getRect(find.text('Sil')),
  tester.getSize(find.text('Profil ekle')).width,
);

void _expectRect(Rect a, Rect b, String what) {
  for (final pair in [
    [a.left, b.left],
    [a.top, b.top],
    [a.right, b.right],
    [a.bottom, b.bottom],
  ]) {
    expect(pair[0], closeTo(pair[1], 0.5), reason: '$what $a vs $b');
  }
}

void main() {
  setUpAll(_loadStandIn);

  // 320 = iPhone SE (1st) / narrow, 375 = SE 2/3, 393 = iPhone 15/16,
  // 430 = Pro Max, 700 = iPad-like width.
  const widths = [320.0, 375.0, 393.0, 430.0, 700.0];
  const scales = [1.0, 1.3];

  for (final dark in [false, true]) {
    for (final scale in scales) {
      for (final width in widths) {
        testWidgets('Profil ekle: + one character right, label follows: '
            '${width.toInt()} pt, ×$scale, ${dark ? 'koyu' : 'açık'}', (
          tester,
        ) async {
          // Main today: padding 2, icon at the left edge, label centred.
          await _pumpRow(
            tester,
            width: width,
            lead: 0,
            textScale: scale,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final before = _measure(tester);
          expect(before.icon.left, closeTo(before.button.left + 2, 0.5));

          await _pumpRow(
            tester,
            width: width,
            lead: _lead,
            textScale: scale,
            dark: dark,
          );
          expect(tester.takeException(), isNull, reason: 'overflow');
          final after = _measure(tester);

          // Icon: about one character (8 pt) right of main, same size/height.
          final moved = after.icon.left - before.icon.left;
          expect(moved, closeTo(_lead, 0.5));
          expect(after.icon.size, before.icon.size);
          expect(after.icon.top, closeTo(before.icon.top, 0.5));

          // Label right after the icon: close, never touching.
          final gap = after.text.left - after.icon.right;
          expect(gap, greaterThanOrEqualTo(4 - 0.01));
          expect(gap, lessThanOrEqualTo(6 + 0.01));
          expect(gap, closeTo(MenzilPrimaryButton.iconLabelGap, 0.5));

          // One line, inside the button (right padding 14 kept).
          expect(after.text.height, lessThan(after.button.height));
          expect(
            after.text.right,
            lessThanOrEqualTo(after.button.right - 14 + 0.5),
          );
          // Full size when it fits, shrunk to the space only when not.
          final room = after.button.width - 2 - 14 - _lead - 20 - 5;
          if (after.naturalWidth <= room) {
            expect(after.text.width, closeTo(after.naturalWidth, 0.5));
          } else {
            expect(after.text.width, closeTo(room, 0.5));
          }

          // The button and Kopyala / Sil unchanged.
          _expectRect(after.button, before.button, 'Profil ekle düğmesi');
          _expectRect(after.kopyala, before.kopyala, 'Kopyala');
          _expectRect(after.sil, before.sil, 'Sil');
          _expectRect(after.kopyalaText, before.kopyalaText, 'Kopyala yazı');
          _expectRect(after.silText, before.silText, 'Sil yazı');

          // ignore: avoid_print
          print(
            'PROFIL_EKLE|${width.toInt()}|x$scale|${dark ? 'koyu' : 'acik'}'
            '|buton=${after.button.width.toStringAsFixed(1)}'
            '|arti_sol_once=${(before.icon.left - before.button.left).toStringAsFixed(1)}'
            '|arti_sol_sonra=${(after.icon.left - after.button.left).toStringAsFixed(1)}'
            '|yazi_sol_once=${(before.text.left - before.button.left).toStringAsFixed(1)}'
            '|yazi_sol_sonra=${(after.text.left - after.button.left).toStringAsFixed(1)}'
            '|bosluk_once=${(before.text.left - before.icon.right).toStringAsFixed(1)}'
            '|bosluk_sonra=${gap.toStringAsFixed(1)}'
            '|yazi_gen=${after.text.width.toStringAsFixed(1)}/${after.naturalWidth.toStringAsFixed(1)}',
          );
        });
      }
    }
  }

  // Owner, 2026-10-15 12:49: the Profil page's Profil ekle is text only
  // (no "+"), so nothing in the app passes iconLead any more; the button's
  // own iconLead layout is still covered above.
  test('no page passes iconLead (Profil ekle has no +)', () {
    final src = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final users = [
      for (final f in src)
        if (f.readAsStringSync().contains('iconLead:')) f.path,
    ];
    expect(users, isEmpty);
  });

  for (final scale in scales) {
    testWidgets('Profil page at 320 pt, ×$scale: no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 1400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(_profile);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          darkTheme: MenzilTheme.dark(),
          themeMode: ThemeMode.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: HomeScreen(
            profileStore: store,
            activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ekle = find.widgetWithText(MenzilPrimaryButton, 'Profil ekle');
      expect(ekle, findsOneWidget);
      // Text only since 2026-10-15 (owner): no icon, label inside the
      // button on one line.
      final button = tester.getRect(ekle);
      expect(
        find.descendant(of: ekle, matching: find.byType(Icon)),
        findsNothing,
      );
      final text = tester.getRect(
        find.descendant(of: ekle, matching: find.text('Profil ekle')),
      );
      expect(text.left, greaterThanOrEqualTo(button.left - 0.5));
      expect(text.right, lessThanOrEqualTo(button.right + 0.5));
      expect(text.height, lessThan(button.height));
      expect(button.right, lessThanOrEqualTo(320));
    });
  }
}
