// The closed select box rule (owner, 2026-10-17 18:03–18:05: "C:
// mühimmattaki gibi, sığdığı kadar görünür"): every select box in the app
// shows its chosen value on ONE line at the normal size, and what does not
// fit is cut with "…". Never wrapped, never scaled down; the box keeps the
// standard height.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bordered box of the field [key] (without its label row).
Rect selectBox(WidgetTester tester, String key) => tester.getRect(
  find
      .descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(InputDecorator),
      )
      .first,
);

/// Checks that the closed select [key] shows [text] on one line at 15 pt
/// (times the text scale), cut with "…" exactly when it does not fit, inside
/// the box, and that the box is [standardHeight] high (±0.5 pt). Returns
/// whether the text was cut.
bool expectClosedOneLine(
  WidgetTester tester,
  String key,
  String text, {
  required double standardHeight,
  String where = '',
}) {
  final reason = '$where [$key] "$text"';
  final scope = find.byKey(Key(key));
  final shown = find.descendant(of: scope, matching: find.text(text));
  expect(shown, findsOneWidget, reason: reason);
  final p = tester.renderObject<RenderParagraph>(shown);
  expect(p.maxLines, 1, reason: '$reason: maxLines');
  expect(p.softWrap, isFalse, reason: '$reason: softWrap');
  expect(p.overflow, TextOverflow.ellipsis, reason: '$reason: overflow');
  // The normal size, never scaled down.
  expect(p.text.style?.fontSize, 15, reason: '$reason: font size');
  expect(
    find.ancestor(
      of: shown,
      matching: find.descendant(of: scope, matching: find.byType(FittedBox)),
    ),
    findsNothing,
    reason: '$reason: scaled down',
  );
  // One line high.
  final one = TextPainter(
    text: p.text,
    textDirection: TextDirection.ltr,
    textScaler: p.textScaler,
    maxLines: 1,
  )..layout();
  expect(
    p.size.height,
    moreOrLessEquals(one.height, epsilon: 0.5),
    reason: '$reason: more than one line',
  );
  // Cut with "…" exactly when the whole text is wider than its room.
  final tooLong = one.width > p.size.width + 0.5;
  one.dispose();
  expect(p.didExceedMaxLines, tooLong, reason: '$reason: cut');
  // Inside the box, which has the standard height.
  final box = selectBox(tester, key);
  final rect = tester.getRect(shown);
  expect(rect.left, greaterThanOrEqualTo(box.left), reason: '$reason $rect');
  expect(rect.right, lessThanOrEqualTo(box.right), reason: '$reason $rect');
  expect(rect.top, greaterThanOrEqualTo(box.top), reason: '$reason $rect');
  expect(rect.bottom, lessThanOrEqualTo(box.bottom), reason: '$reason $rect');
  expect(
    box.height,
    moreOrLessEquals(standardHeight, epsilon: 0.5),
    reason: '$reason: box height $box',
  );
  return tooLong;
}
