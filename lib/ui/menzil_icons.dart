import 'package:flutter/material.dart';

/// Line glyphs used by the top bar and the bottom navigation. They are drawn
/// on the same 24×24 grid with a 2-unit stroke as the reference design so the
/// icon weight matches the text weight on every page.
enum MenzilGlyph { brand, shot, table, environment, pro, profile, tools }

class MenzilIcon extends StatelessWidget {
  final MenzilGlyph glyph;
  final double size;
  final Color? color;

  const MenzilIcon(this.glyph, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.black;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GlyphPainter(glyph, resolved)),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final MenzilGlyph glyph;
  final Color color;

  const _GlyphPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s, s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);

    switch (glyph) {
      case MenzilGlyph.brand:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        line(12, 1.5, 12, 7.5);
        line(12, 16.5, 12, 22.5);
        line(1.5, 12, 7.5, 12);
        line(16.5, 12, 22.5, 12);
      case MenzilGlyph.shot:
        canvas.drawCircle(const Offset(12, 12), 7, p);
        line(12, 2, 12, 7);
        line(12, 17, 12, 22);
        line(2, 12, 7, 12);
        line(17, 12, 22, 12);
      case MenzilGlyph.table:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 4, 18, 16),
            const Radius.circular(2),
          ),
          p,
        );
        line(3, 10, 21, 10);
        line(3, 15, 21, 15);
        line(9, 4, 9, 20);
      case MenzilGlyph.environment:
        final wind = Path()
          ..moveTo(3, 9)
          ..lineTo(14, 9)
          ..arcToPoint(
            const Offset(11, 6),
            radius: const Radius.circular(3),
            largeArc: true,
            clockwise: false,
          )
          ..moveTo(3, 14)
          ..lineTo(18, 14)
          ..arcToPoint(
            const Offset(15, 17),
            radius: const Radius.circular(3),
            largeArc: true,
          )
          ..moveTo(3, 19)
          ..lineTo(10, 19);
        canvas.drawPath(wind, p);
      case MenzilGlyph.pro:
        // Protractor: ground line, sight line and the angle arc between
        // them (Pro: incline, cant, Coriolis).
        line(3, 20, 21, 20);
        line(3, 20, 17, 5);
        canvas.drawArc(
          const Rect.fromLTWH(-5, 12, 16, 16),
          -0.82,
          0.82,
          false,
          p,
        );
        canvas.drawCircle(const Offset(19, 11.5), 1.6, p); // degree mark
      case MenzilGlyph.profile:
        final bullet = Path()
          ..moveTo(9, 21)
          ..lineTo(9, 10)
          ..cubicTo(9, 7, 10.2, 4.5, 12, 3)
          ..cubicTo(13.8, 4.5, 15, 7, 15, 10)
          ..lineTo(15, 21);
        canvas.drawPath(bullet, p);
        line(9, 21, 15, 21);
        line(9, 14, 15, 14);
      case MenzilGlyph.tools:
        line(4, 7, 13, 7);
        line(17, 7, 20, 7);
        line(4, 17, 7, 17);
        line(11, 17, 20, 17);
        canvas.drawCircle(const Offset(15, 7), 2.2, p);
        canvas.drawCircle(const Offset(9, 17), 2.2, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
