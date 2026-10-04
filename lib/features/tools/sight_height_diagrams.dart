import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/sight_height_art.dart';

/// Design viewBox of the side-view illustration (Menzil "Sight Height").
const sightSideViewSize = Size(348, 262);

/// The photo-guide uses the same artwork cropped to y = 30 .. 220.
const sightPhotoGuideSize = Size(348, 190);

void _text(
  Canvas canvas,
  String text,
  Offset at, {
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w600,
  TextAlign align = TextAlign.left,
  double rotateDeg = 0,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  // SVG text: x/y is the baseline start (or middle/end by anchor).
  final dx = switch (align) {
    TextAlign.center => -tp.width / 2,
    TextAlign.right || TextAlign.end => -tp.width,
    _ => 0.0,
  };
  canvas.save();
  canvas.translate(at.dx, at.dy);
  if (rotateDeg != 0) canvas.rotate(rotateDeg * 3.141592653589793 / 180);
  tp.paint(canvas, Offset(dx, -tp.height * 0.78));
  canvas.restore();
}

Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

void _dashedV(Canvas canvas, double x, double y1, double y2, Paint p, double on, double off) {
  var y = y1;
  while (y < y2) {
    canvas.drawLine(Offset(x, y), Offset(x, (y + on).clamp(y1, y2).toDouble()), p);
    y += on + off;
  }
}

void _dashedH(Canvas canvas, double y, double x1, double x2, Paint p, double on, double off) {
  var x = x1;
  while (x < x2) {
    canvas.drawLine(Offset(x, y), Offset((x + on).clamp(x1, x2).toDouble(), y), p);
    x += on + off;
  }
}

/// Side view: rear/front, both axes, the measuring point at the scope's FRONT
/// end and the four numbered parts of the Sight Height formula.
class SightSideViewPainter extends CustomPainter {
  final MenzilColors colors;
  const SightSideViewPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / sightSideViewSize.width;
    canvas.save();
    canvas.scale(s);
    final c = colors;

    // ARKA / ÖN captions.
    _text(canvas, 'ARKA', const Offset(10, 14), size: 11, color: c.ink, weight: FontWeight.w700);
    _text(canvas, 'göz merceği', const Offset(10, 27), size: 11, color: c.ink2, weight: FontWeight.w400);
    _text(canvas, 'ÖN', const Offset(258, 14), size: 11, color: c.ink, weight: FontWeight.w700, align: TextAlign.center);
    _text(canvas, 'objektif', const Offset(258, 27), size: 11, color: c.ink2, weight: FontWeight.w400, align: TextAlign.center);
    final thin = _line(c.ink, 1);
    canvas.drawLine(const Offset(18, 31), const Offset(18, 51), thin);
    canvas.drawLine(const Offset(258, 31), const Offset(258, 45), thin);
    final head = Path()
      ..moveTo(15, 47)..lineTo(18, 52)..lineTo(21, 47)
      ..moveTo(255, 41)..lineTo(258, 46)..lineTo(261, 41);
    canvas.drawPath(head, thin);

    paintSightHeightArt(canvas);

    // Axes.
    _dashedH(canvas, 78, 0, 300, _line(c.cyan, 1.6), 7, 5);
    _dashedH(canvas, 178, 0, 344, _line(c.danger, 1.6), 7, 5);
    _text(canvas, 'dürbün ekseni', const Offset(272, 44), size: 11, color: c.cyanInk);
    canvas.drawLine(const Offset(302, 48), const Offset(292, 76), _line(c.cyanInk, 1));

    // Measuring stack at the front end of the scope.
    final stack = _line(c.cyanInk, 2);
    _dashedV(canvas, 276, 108, 166, stack, 3, 3);
    canvas.drawLine(const Offset(276, 82), const Offset(276, 104), stack);
    canvas.drawPath(Path()..moveTo(272, 86)..lineTo(276, 80)..lineTo(280, 86), stack);
    canvas.drawPath(Path()..moveTo(272, 100)..lineTo(276, 106)..lineTo(280, 100), stack);
    canvas.drawLine(const Offset(276, 111), const Offset(276, 164), stack);
    canvas.drawPath(Path()..moveTo(272, 115)..lineTo(276, 109)..lineTo(280, 115), stack);
    canvas.drawPath(Path()..moveTo(272, 160)..lineTo(276, 166)..lineTo(280, 160), stack);
    final cap = _line(c.cyanInk, 1);
    canvas.drawLine(const Offset(268, 106), const Offset(284, 106), cap);
    canvas.drawLine(const Offset(268, 169), const Offset(284, 169), cap);
    canvas.drawCircle(const Offset(276, 178), 5, Paint()..color = c.danger);
    canvas.drawCircle(const Offset(276, 178), 5, _line(c.surface, 1.5));

    // Numbered parts.
    void badge(double x, double y, String n) {
      canvas.drawCircle(Offset(x, y), 9, Paint()..color = c.cyanInk);
      _text(canvas, n, Offset(x, y + 4), size: 10.5, color: c.surface, weight: FontWeight.w700, align: TextAlign.center);
    }

    badge(296, 93, '4');
    badge(296, 137, '3');
    badge(298, 158, '2');
    badge(250, 206, '1');
    final leader = Path()
      ..moveTo(290, 163)..lineTo(280, 170)
      ..moveTo(256, 199)..lineTo(271, 183);
    canvas.drawPath(leader, _line(c.cyanInk, 1));

    // Total height.
    canvas.drawLine(const Offset(326, 82), const Offset(326, 174), _line(c.cyanInk, 2));
    final arrows = Path()
      ..moveTo(326, 78)..lineTo(321, 87)..lineTo(331, 87)..close()
      ..moveTo(326, 178)..lineTo(321, 169)..lineTo(331, 169)..close();
    canvas.drawPath(arrows, Paint()..color = c.cyanInk);
    _text(canvas, 'dürbün yüksekliği', const Offset(341, 128),
        size: 11.5, color: c.cyanInk, weight: FontWeight.w700, align: TextAlign.center, rotateDeg: -90);

    // Bottom captions.
    _text(canvas, 'ölçüm', const Offset(196, 232), size: 11, color: c.danger, align: TextAlign.center);
    _text(canvas, 'noktası', const Offset(196, 245), size: 11, color: c.danger, align: TextAlign.center);
    _text(canvas, 'namlu ekseni', const Offset(344, 212), size: 11, color: c.danger, align: TextAlign.right);
    _text(canvas, '(delik merkezi)', const Offset(344, 225),
        size: 11, color: c.danger, weight: FontWeight.w500, align: TextAlign.right);
    _text(canvas, 'namlu ağzı →', const Offset(344, 254),
        size: 11, color: c.ink, weight: FontWeight.w700, align: TextAlign.right);
    canvas.drawLine(const Offset(214, 226), const Offset(270, 182), _line(c.danger, 1.5));
    canvas.drawPath(
      Path()..moveTo(263, 183)..lineTo(271, 181)..lineTo(269, 189),
      _line(c.danger, 1.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SightSideViewPainter old) => old.colors != colors;
}

/// The same artwork cropped (y 30..220) with the three amber marks to place on
/// the photo: objective front top edge, front bottom edge, bore centre.
class SightPhotoGuidePainter extends CustomPainter {
  final MenzilColors colors;
  const SightPhotoGuidePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / sightPhotoGuideSize.width;
    canvas.save();
    canvas.scale(s);
    canvas.translate(0, -30);
    paintSightHeightArt(canvas);
    final mark = _line(colors.amber, 2.5);
    void target(double x, double y) {
      canvas.drawCircle(Offset(x, y), 7, mark);
      canvas.drawLine(Offset(x, y - 11), Offset(x, y - 5), mark);
      canvas.drawLine(Offset(x, y + 5), Offset(x, y + 11), mark);
      canvas.drawLine(Offset(x - 11, y), Offset(x - 5, y), mark);
      canvas.drawLine(Offset(x + 5, y), Offset(x + 11, y), mark);
    }

    target(264, 49);
    target(264, 107);
    target(304, 178);
    _text(canvas, 'ön üst kenar', const Offset(252, 41), size: 10.5, color: colors.amberInk, weight: FontWeight.w700, align: TextAlign.right);
    _text(canvas, 'ön alt kenar', const Offset(252, 124), size: 10.5, color: colors.amberInk, weight: FontWeight.w700, align: TextAlign.right);
    _text(canvas, 'namlu ağzı merkezi', const Offset(300, 206), size: 10.5, color: colors.amberInk, weight: FontWeight.w700, align: TextAlign.right);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SightPhotoGuidePainter old) => old.colors != colors;
}
