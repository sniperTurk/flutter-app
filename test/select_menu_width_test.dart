// The open list of every MenzilSelect has exactly the box's left and right
// edge (owner, 2026-10-13: "daha büyük açılsın ama kutudan dışarı
// çıkmasın"); before, it was at most 260 pt wide and started 16 pt left of
// the box.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _long = 'Forester 1-5x24i Fiber SFP LPVO Coyote FDE · MRAD';
const _short = 'Forester 1-4x24';

/// The width the list had before (at most 260 pt) minus the 16 pt item
/// padding on each side: the room a long entry had.
const double _oldItemRoom = 260 - 32;

DropdownMenuItem<String> _fitted(String text) => DropdownMenuItem(
  value: text,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(text, maxLines: 1, softWrap: false),
  ),
);

Widget _select(Key key, {bool withEmpty = false}) => MenzilSelect<String>(
  key: key,
  label: 'Model',
  hint: 'Seçiniz',
  initialValue: null,
  items: [
    if (withEmpty)
      const DropdownMenuItem<String>(value: null, child: Text('Seçiniz')),
    _fitted(_short),
    _fitted(_long),
  ],
  onChanged: (_) {},
);

const _full = Key('full');
const _left = Key('left');
const _right = Key('right');

Future<void> _pump(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
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
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _select(_full, withEmpty: true),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _select(_left)),
                  const SizedBox(width: 12),
                  Expanded(child: _select(_right)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _box(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(InputDecorator));

/// The open list (Flutter's private dropdown menu widget).
final Finder _menu = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
);

Future<Rect> _open(WidgetTester tester, Key key) async {
  await tester.tap(_box(key));
  await tester.pumpAndSettle();
  expect(_menu, findsOneWidget);
  return tester.getRect(_menu);
}

Future<void> _close(WidgetTester tester) async {
  await tester.tapAt(const Offset(195, 830));
  await tester.pumpAndSettle();
  expect(_menu, findsNothing);
}

void _sameEdges(Rect menu, Rect box) {
  expect(menu.left, moreOrLessEquals(box.left, epsilon: 1), reason: 'left');
  expect(menu.right, moreOrLessEquals(box.right, epsilon: 1), reason: 'right');
  expect(menu.left, greaterThanOrEqualTo(box.left - 1));
  expect(menu.right, lessThanOrEqualTo(box.right + 1));
}

/// How much the long entry in the open list is shrunk (1: normal size).
double _longScale(WidgetTester tester) {
  final text = find.descendant(of: _menu, matching: find.text(_long));
  final fitted = find.ancestor(of: text, matching: find.byType(FittedBox));
  return tester.getSize(fitted.first).width / tester.getSize(text).width;
}

void main() {
  testWidgets('full-width box: list has the box edges, long entry larger', (
    tester,
  ) async {
    await _pump(tester);
    final box = tester.getRect(_box(_full));
    final menu = await _open(tester, _full);
    _sameEdges(menu, box);
    // "Seçiniz" is still the first entry of the open list.
    final entries = find.descendant(of: _menu, matching: find.byType(Text));
    expect(tester.widget<Text>(entries.first).data, 'Seçiniz');
    // The long entry is shrunk less than in the old 260 pt list.
    final textWidth = tester
        .getSize(find.descendant(of: _menu, matching: find.text(_long)))
        .width;
    final oldScale = (_oldItemRoom / textWidth).clamp(0.0, 1.0);
    expect(_longScale(tester), greaterThanOrEqualTo(oldScale));
    expect(_longScale(tester), greaterThan(oldScale));
    // A short entry keeps its normal size.
    final shortText = find.descendant(of: _menu, matching: find.text(_short));
    final shortFit = find.ancestor(
      of: shortText,
      matching: find.byType(FittedBox),
    );
    expect(
      tester.getSize(shortFit.first).width,
      moreOrLessEquals(tester.getSize(shortText).width, epsilon: 0.5),
    );
    await _close(tester);
  });

  testWidgets('half-width boxes: each list has its own box edges', (
    tester,
  ) async {
    await _pump(tester);
    for (final key in [_left, _right]) {
      final box = tester.getRect(_box(key));
      expect(box.width, lessThan(200));
      _sameEdges(await _open(tester, key), box);
      await _close(tester);
    }
  });

  testWidgets('large text: lists still keep to their boxes', (tester) async {
    await _pump(tester, textScale: 1.6);
    for (final key in [_full, _left, _right]) {
      final box = tester.getRect(_box(key));
      _sameEdges(await _open(tester, key), box);
      await _close(tester);
    }
  });

  testWidgets(
    'closed box unchanged: text 16 pt in, arrow 16 pt from edge (as before)',
    (tester) async {
      await _pump(tester);
      for (final key in [_full, _left, _right]) {
        final box = tester.getRect(_box(key));
        final hint = find.descendant(
          of: find.byKey(key),
          matching: find.text('Seçiniz'),
        );
        expect(
          tester.getRect(hint.first).left,
          moreOrLessEquals(box.left + 16, epsilon: 0.5),
        );
        final arrow = find.descendant(
          of: find.byKey(key),
          matching: find.byIcon(Icons.expand_more),
        );
        expect(
          tester.getRect(arrow).right,
          moreOrLessEquals(box.right - 16, epsilon: 0.5),
        );
      }
      // A picked entry shows in the closed box at the same place.
      await _open(tester, _full);
      await tester.tap(
        find.descendant(of: _menu, matching: find.text(_short)).last,
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(_box(_full));
      final shown = find.descendant(
        of: find.byKey(_full),
        matching: find.text(_short),
      );
      expect(
        tester.getRect(shown.first).left,
        moreOrLessEquals(box.left + 16, epsilon: 0.5),
      );
    },
  );
}
