// GENERATED from the Menzil design page "Sight Height" (sh-art group, viewBox
// 348 x 262). Do not edit by hand. Equipment artwork only: annotations, axes
// and labels are drawn by the screen with MenzilColors tokens.
// ignore_for_file: prefer_const_constructors, prefer_const_declarations, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

import 'menzil_theme.dart';

const _tube = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    MenzilArt.c7C8790,
    MenzilArt.c4B555E,
    MenzilArt.c262D33,
    MenzilArt.c0E1216,
  ],
  stops: [0, 0.18, 0.55, 1],
);
const _dark = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [MenzilArt.c4A535B, MenzilArt.c1C2227, MenzilArt.c0B0E11],
  stops: [0, 0.5, 1],
);
const _rubber = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [MenzilArt.c3A4147, MenzilArt.c0B0E11],
);
const _glass = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [MenzilArt.c9FD3EC, MenzilArt.c2F6F95, MenzilArt.c173A52],
  stops: [0, 0.5, 1],
);
const _knob = RadialGradient(
  center: Alignment(-0.2, -0.3),
  radius: 0.7,
  colors: [MenzilArt.c6E7881, MenzilArt.c252C32, MenzilArt.c0E1216],
  stops: [0, 0.6, 1],
);

void _fillColor(Canvas canvas, Path p, Color c, double opacity) =>
    canvas.drawPath(p, Paint()..color = c.withValues(alpha: opacity));

void _fillGradient(Canvas canvas, Path p, Gradient g, double opacity) {
  final b = p.getBounds();
  final shader = g.createShader(b);
  canvas.drawPath(
    p,
    Paint()
      ..shader = shader
      ..color = Color.fromRGBO(255, 255, 255, opacity),
  );
}

void _strokePath(
  Canvas canvas,
  Path p,
  Color c,
  double width,
  double opacity,
  List<double>? dash,
) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = c.withValues(alpha: opacity);
  if (dash == null) {
    canvas.drawPath(p, paint);
    return;
  }
  for (final metric in p.computeMetrics()) {
    var pos = 0.0;
    var i = 0;
    while (pos < metric.length) {
      final len = dash[i % dash.length];
      if (i.isEven)
        canvas.drawPath(
          metric.extractPath(
            pos,
            (pos + len).clamp(0.0, metric.length).toDouble(),
          ),
          paint,
        );
      pos += len;
      i++;
    }
  }
}

/// Paints the rifle/scope side view in its 348 x 262 design coordinates.
void paintSightHeightArt(Canvas canvas) {
  {
    final p = Path()
      ..moveTo(6.0, 151.0)
      ..lineTo(238.0, 151.0)
      ..lineTo(238.0, 188.0)
      ..lineTo(22.0, 188.0)
      ..arcToPoint(
        Offset(6.0, 172.0),
        radius: Radius.elliptical(16.0, 16.0),
        rotation: 0.0,
        largeArc: false,
        clockwise: true,
      )
      ..close();
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()
      ..moveTo(10.0, 156.0)
      ..lineTo(236.0, 156.0);
    _strokePath(canvas, p, MenzilArt.cFFFFFF, 2.0, 0.12, null);
  }
  {
    final p = Path()..addRect(Rect.fromLTWH(18.0, 139.0, 214.0, 12.0));
    _fillColor(canvas, p, MenzilArt.c161B20, 1.0);
  }
  {
    final p = Path()
      ..moveTo(20.0, 145.0)
      ..lineTo(230.0, 145.0);
    _strokePath(canvas, p, MenzilArt.c3A444C, 9.0, 1.0, [5.0, 3.0]);
  }
  {
    final p = Path()
      ..moveTo(18.0, 139.0)
      ..lineTo(232.0, 139.0);
    _strokePath(canvas, p, MenzilArt.c5A646D, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(36, 168), radius: 6));
    _fillGradient(canvas, p, _knob, 1.0);
    _strokePath(canvas, p, MenzilArt.c0B0E11, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(140.0, 176.0, 52.0, 5.0),
          Radius.circular(2.5),
        ),
      );
    _fillColor(canvas, p, MenzilArt.c0B0E11, 0.7);
  }
  {
    final p = Path()..addRect(Rect.fromLTWH(238.0, 169.0, 64.0, 18.0));
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()
      ..moveTo(238.0, 172.0)
      ..lineTo(302.0, 172.0);
    _strokePath(canvas, p, MenzilArt.cFFFFFF, 1.5, 0.15, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(300.0, 166.0, 7.0, 24.0),
          Radius.circular(2.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..moveTo(92.0, 96.0)
      ..lineTo(114.0, 96.0)
      ..lineTo(118.0, 139.0)
      ..lineTo(88.0, 139.0)
      ..close();
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..moveTo(160.0, 96.0)
      ..lineTo(182.0, 96.0)
      ..lineTo(186.0, 139.0)
      ..lineTo(156.0, 139.0)
      ..close();
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(103, 126), radius: 3.2));
    _fillColor(canvas, p, MenzilArt.c0B0E11, 1.0);
    _strokePath(canvas, p, MenzilArt.c5A646D, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(171, 126), radius: 3.2));
    _fillColor(canvas, p, MenzilArt.c0B0E11, 1.0);
    _strokePath(canvas, p, MenzilArt.c5A646D, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..moveTo(16.0, 56.0)
      ..lineTo(46.0, 56.0)
      ..cubicTo(50.0, 56.0, 52.0, 58.0, 54.0, 61.0)
      ..lineTo(64.0, 70.0)
      ..lineTo(64.0, 86.0)
      ..lineTo(54.0, 95.0)
      ..cubicTo(52.0, 98.0, 50.0, 100.0, 46.0, 100.0)
      ..lineTo(16.0, 100.0)
      ..close();
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(7.0, 57.0, 11.0, 42.0),
          Radius.circular(4.0),
        ),
      );
    _fillGradient(canvas, p, _rubber, 1.0);
  }
  {
    final p = Path()
      ..moveTo(26.0, 57.0)
      ..lineTo(26.0, 99.0)
      ..moveTo(30.0, 57.0)
      ..lineTo(30.0, 99.0);
    _strokePath(canvas, p, MenzilArt.c0B0E11, 1.0, 0.55, null);
  }
  {
    final p = Path()
      ..moveTo(18.0, 60.0)
      ..lineTo(48.0, 60.0);
    _strokePath(canvas, p, MenzilArt.cFFFFFF, 2.0, 0.18, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(62.0, 63.0, 26.0, 30.0),
          Radius.circular(2.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..moveTo(65.0, 64.0)
      ..lineTo(65.0, 92.0)
      ..moveTo(68.0, 64.0)
      ..lineTo(68.0, 92.0)
      ..moveTo(71.0, 64.0)
      ..lineTo(71.0, 92.0)
      ..moveTo(74.0, 64.0)
      ..lineTo(74.0, 92.0)
      ..moveTo(77.0, 64.0)
      ..lineTo(77.0, 92.0)
      ..moveTo(80.0, 64.0)
      ..lineTo(80.0, 92.0)
      ..moveTo(83.0, 64.0)
      ..lineTo(83.0, 92.0)
      ..moveTo(86.0, 64.0)
      ..lineTo(86.0, 92.0);
    _strokePath(canvas, p, MenzilArt.c4A535B, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(72.0, 58.0, 7.0, 6.0),
          Radius.circular(1.5),
        ),
      );
    _fillColor(canvas, p, MenzilArt.c1C2227, 1.0);
  }
  {
    final p = Path()..addRect(Rect.fromLTWH(88.0, 67.0, 120.0, 22.0));
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()
      ..moveTo(88.0, 70.0)
      ..lineTo(208.0, 70.0);
    _strokePath(canvas, p, MenzilArt.cFFFFFF, 2.0, 0.2, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(118.0, 62.0, 32.0, 32.0),
          Radius.circular(5.0),
        ),
      );
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()..addRect(Rect.fromLTWH(122.0, 54.0, 24.0, 9.0));
    _fillColor(canvas, p, MenzilArt.c1C2227, 1.0);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(119.0, 32.0, 30.0, 23.0),
          Radius.circular(3.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..moveTo(121.0, 34.0)
      ..lineTo(147.0, 34.0);
    _strokePath(canvas, p, MenzilArt.c7C8790, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..moveTo(121.5, 37.0)
      ..lineTo(121.5, 53.0)
      ..moveTo(124.5, 37.0)
      ..lineTo(124.5, 53.0)
      ..moveTo(127.5, 37.0)
      ..lineTo(127.5, 53.0)
      ..moveTo(130.5, 37.0)
      ..lineTo(130.5, 53.0)
      ..moveTo(133.5, 37.0)
      ..lineTo(133.5, 53.0)
      ..moveTo(136.5, 37.0)
      ..lineTo(136.5, 53.0)
      ..moveTo(139.5, 37.0)
      ..lineTo(139.5, 53.0)
      ..moveTo(142.5, 37.0)
      ..lineTo(142.5, 53.0)
      ..moveTo(145.5, 37.0)
      ..lineTo(145.5, 53.0);
    _strokePath(canvas, p, MenzilArt.c4A535B, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..moveTo(134.0, 54.0)
      ..lineTo(134.0, 60.0);
    _strokePath(canvas, p, MenzilArt.cF7FAFB, 1.5, 1.0, null);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(134, 78), radius: 13));
    _fillGradient(canvas, p, _knob, 1.0);
    _strokePath(canvas, p, MenzilArt.c0B0E11, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(134, 78), radius: 13));
    _strokePath(canvas, p, MenzilArt.c4A535B, 2.5, 1.0, [1.5, 1.5]);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(134, 78), radius: 6));
    _fillColor(canvas, p, MenzilArt.c1C2227, 1.0);
    _strokePath(canvas, p, MenzilArt.c5A646D, 1.0, 1.0, null);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(92.0, 62.0, 22.0, 34.0),
          Radius.circular(6.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(160.0, 62.0, 22.0, 34.0),
          Radius.circular(6.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(98, 70), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(108, 70), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(98, 88), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(108, 88), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(166, 70), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(176, 70), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(166, 88), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset(176, 88), radius: 2));
    _fillColor(canvas, p, MenzilArt.c5A646D, 1.0);
  }
  {
    final p = Path()
      ..moveTo(206.0, 67.0)
      ..cubicTo(224.0, 67.0, 236.0, 59.0, 246.0, 52.0)
      ..lineTo(262.0, 52.0)
      ..lineTo(262.0, 104.0)
      ..lineTo(246.0, 104.0)
      ..cubicTo(236.0, 97.0, 224.0, 89.0, 206.0, 89.0)
      ..close();
    _fillGradient(canvas, p, _tube, 1.0);
  }
  {
    final p = Path()
      ..moveTo(212.0, 69.0)
      ..cubicTo(226.0, 68.0, 236.0, 62.0, 245.0, 56.0)
      ..lineTo(261.0, 56.0);
    _strokePath(canvas, p, MenzilArt.cFFFFFF, 2.0, 0.2, null);
  }
  {
    final p = Path()..addRect(Rect.fromLTWH(248.0, 51.0, 3.0, 54.0));
    _fillColor(canvas, p, MenzilArt.c0B0E11, 0.6);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(260.0, 49.0, 7.0, 58.0),
          Radius.circular(2.0),
        ),
      );
    _fillGradient(canvas, p, _dark, 1.0);
  }
  {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(266.0, 54.0, 2.5, 48.0),
          Radius.circular(1.0),
        ),
      );
    _fillGradient(canvas, p, _glass, 1.0);
  }
}
