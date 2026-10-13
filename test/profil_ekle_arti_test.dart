// "Profil ekle" + işareti (owner, 2026-10-13): only the + icon moves about two
// characters (15 pt) to the right, the label "Profil ekle" stays exactly where
// it was. The move is cut short so at least 4 pt stays between icon and
// label. See docs/reports/profil_ekle_arti.md.
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
  required double shift,
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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.gutter),
          child: Row(
            children: [
              Expanded(
                child: MenzilPrimaryButton(
                  key: const Key('ekle'),
                  label: 'Profil ekle',
                  icon: Icons.add,
                  amber: true,
                  oneLine: true,
                  iconShift: shift,
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
        ),
      ),
    ),
  );
  await tester.pump();
}

class _Shot {
  final Rect button, icon, text, kopyala, sil, kopyalaText, silText;
  _Shot(
    this.button,
    this.icon,
    this.text,
    this.kopyala,
    this.sil,
    this.kopyalaText,
    this.silText,
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
  // 430 = Pro Max, 700 = iPad-like width where the full 15 pt fits.
  const widths = [320.0, 375.0, 393.0, 430.0, 700.0];
  const scales = [1.0, 1.3];

  for (final dark in [false, true]) {
    for (final scale in scales) {
      for (final width in widths) {
        testWidgets('Profil ekle + moves, label stays: ${width.toInt()} pt, '
            '×$scale, ${dark ? 'koyu' : 'açık'}', (tester) async {
          await _pumpRow(
            tester,
            width: width,
            shift: 0,
            textScale: scale,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final before = _measure(tester);

          // Expected label position from the current layout: padding 2,
          // icon 20, gap 2, then the label centred in what is left (right
          // padding 14), set smaller when it does not fit.
          final room = before.button.width - 2 - 14 - 22;
          final shownWidth = before.text.width;
          expect(shownWidth, lessThanOrEqualTo(room + 0.5));
          final expectedTextLeft =
              before.button.left + 2 + 22 + (room - shownWidth) / 2;
          expect(before.text.left, closeTo(expectedTextLeft, 0.5));
          expect(before.icon.left, closeTo(before.button.left + 2, 0.5));

          final gapBefore = before.text.left - before.icon.right;
          final expectedShift = (gapBefore - MenzilPrimaryButton.minIconGap)
              .clamp(0.0, 15.0)
              .toDouble();

          await _pumpRow(
            tester,
            width: width,
            shift: 15,
            textScale: scale,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final after = _measure(tester);

          // The label: same place, same size, one line.
          _expectRect(after.text, before.text, 'Profil ekle yazısı');
          expect(after.text.left, closeTo(expectedTextLeft, 0.5));
          expect(
            after.text.height,
            lessThan(after.button.height),
            reason: 'one line',
          );
          // The icon: moved right by the chosen amount only.
          final moved = after.icon.left - before.icon.left;
          expect(moved, closeTo(expectedShift, 0.5));
          expect(after.icon.top, closeTo(before.icon.top, 0.5));
          if (expectedShift > 0) {
            expect(
              after.icon.right + MenzilPrimaryButton.minIconGap,
              lessThanOrEqualTo(after.text.left + 0.5),
            );
          } else {
            // No room: the icon stays put, nothing gets closer.
            expect(after.text.left - after.icon.right, closeTo(gapBefore, 0.5));
          }
          // Never past the button.
          expect(after.icon.left, greaterThanOrEqualTo(after.button.left));
          _expectRect(after.button, before.button, 'Profil ekle düğmesi');
          // Kopyala / Sil unchanged.
          _expectRect(after.kopyala, before.kopyala, 'Kopyala');
          _expectRect(after.sil, before.sil, 'Sil');
          _expectRect(after.kopyalaText, before.kopyalaText, 'Kopyala yazı');
          _expectRect(after.silText, before.silText, 'Sil yazı');

          // ignore: avoid_print
          print(
            'PROFIL_EKLE|${width.toInt()}|x$scale|${dark ? 'koyu' : 'acik'}'
            '|buton=${after.button.width.toStringAsFixed(1)}'
            '|yazi_sol=${after.text.left.toStringAsFixed(2)}'
            '|yazi_gen=${after.text.width.toStringAsFixed(1)}'
            '|bosluk_once=${gapBefore.toStringAsFixed(1)}'
            '|kayma=${moved.toStringAsFixed(1)}'
            '|bosluk_sonra=${(after.text.left - after.icon.right).toStringAsFixed(1)}',
          );
        });
      }
    }
  }

  test('only Profil ekle asks for the shift', () {
    final src = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final users = [
      for (final f in src)
        if (f.readAsStringSync().contains('iconShift:')) f.path,
    ];
    expect(users, ['lib/features/profiles/profiles_screen.dart']);
    final screen = File(
      'lib/features/profiles/profiles_screen.dart',
    ).readAsStringSync();
    expect(RegExp('iconShift:').allMatches(screen).length, 1);
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
      expect(tester.widget<MenzilPrimaryButton>(ekle).iconShift, 15);
      final button = tester.getRect(ekle);
      final icon = tester.getRect(
        find.descendant(of: ekle, matching: find.byIcon(Icons.add)),
      );
      final text = tester.getRect(
        find.descendant(of: ekle, matching: find.text('Profil ekle')),
      );
      expect(icon.left, greaterThanOrEqualTo(button.left));
      expect(text.right, lessThanOrEqualTo(button.right + 0.5));
      expect(icon.right, lessThanOrEqualTo(text.left + 0.5));
    });
  }
}
