import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/wind_clock.dart';
import '../../ui/menzil_theme.dart';

/// Clock face under the Rüzgâr yönü box (owner, 2026-10-11): the shooter is
/// in the centre facing 12 (the target). Nothing is pre-selected: tapping
/// the hour the wind comes from writes it into the box, and only a value
/// the user chose (tapped or typed) is highlighted with an arrow.
class WindClockPicker extends StatelessWidget {
  /// The box's hour when it holds a valid 1…12, else null.
  final int? hour;
  final ValueChanged<int> onChanged;

  /// Right of the line under the dial: when the direction was set
  /// ("14.10.2026 14:55"), or today's date before any direction (owner,
  /// 2026-10-14). Null shows nothing there.
  final String? dateText;

  const WindClockPicker({
    super.key,
    this.hour,
    required this.onChanged,
    this.dateText,
  });

  /// "Saat 3 yönünde" (owner, 2026-10-14).
  static String hourText(int h) => 'Saat $h yönünde';

  static ValueKey<String> hourKey(int h) => ValueKey('wind-clock-$h');

  /// Shown in the Rüzgâr yönü ⓘ (no helper text under fields).
  static const instruction =
      'Rüzgâr hangi yönden geliyorsa kadranda o saate dokunun; değer Rüzgâr '
      'yönü kutusuna girilir. Hedef saat 12 yönünde.';

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final h = hour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A small left-aligned title directly above the dial (owner,
        // 2026-10-14).
        Padding(
          padding: const EdgeInsets.only(bottom: MenzilSpace.xs),
          child: Text(
            'Rüzgâr yönü',
            key: const ValueKey('wind-clock-title'),
            textAlign: TextAlign.start,
            style: MenzilType.label(c.ink),
          ),
        ),
        Center(
          child: SizedBox.square(
            dimension: 236,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest.shortestSide;
                final center = Offset(size / 2, size / 2);
                final r = size / 2 - 24;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ClockPainter(colors: c, hour: h),
                      ),
                    ),
                    for (var i = 1; i <= 12; i++)
                      Positioned(
                        left: center.dx + r * math.sin(i * math.pi / 6) - 22,
                        top: center.dy - r * math.cos(i * math.pi / 6) - 22,
                        width: 44,
                        height: 44,
                        child: Semantics(
                          button: true,
                          selected: i == h,
                          label: 'Saat $i, ${WindClock.side(i)}',
                          child: ExcludeSemantics(
                            child: Material(
                              key: hourKey(i),
                              // The same orange as the "…alındı" buttons
                              // (owner, 2026-10-14).
                              color: i == h
                                  ? MenzilColors.stateOrange
                                  : c.surface2,
                              shape: CircleBorder(
                                side: BorderSide(
                                  color: i == h
                                      ? MenzilColors.stateOrange
                                      : c.line,
                                ),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => onChanged(i),
                                child: Center(
                                  child: Text(
                                    '$i',
                                    style: MenzilType.number(
                                      i == h ? Colors.white : c.ink,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // ONE line: "Saat 3 yönünde" left, the time it was set right; both
        // stay on one line (they shrink instead of wrapping).
        const SizedBox(height: MenzilSpace.xs),
        Row(
          children: [
            Expanded(
              child: _OneLine(
                h == null ? '' : hourText(h),
                textKey: const ValueKey('wind-clock-label'),
                color: c.ink,
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
            const SizedBox(width: MenzilSpace.md),
            Expanded(
              child: _OneLine(
                dateText ?? '',
                textKey: const ValueKey('wind-clock-date'),
                color: c.ink2,
                alignment: AlignmentDirectional.centerEnd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One line of text that scales down instead of wrapping.
class _OneLine extends StatelessWidget {
  final String text;
  final Color color;
  final AlignmentDirectional alignment;
  final Key? textKey;
  const _OneLine(
    this.text, {
    this.textKey,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        key: textKey,
        maxLines: 1,
        softWrap: false,
        style: MenzilType.caption(color),
      ),
    ),
  );
}

class _ClockPainter extends CustomPainter {
  final MenzilColors colors;
  final int? hour;
  const _ClockPainter({required this.colors, this.hour});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 24;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Owner, 2026-10-11: nothing in the middle until an hour is chosen; a
    // centre line looked like a pre-selected 12.
    final h = hour;
    if (h == null) return; // No direction chosen yet: no arrow.
    final a = h * math.pi / 6;
    final dir = Offset(math.sin(a), -math.cos(a));
    final tail = center + dir * (r - 30);
    final tip = center + dir * 16;
    final arrow = Paint()
      ..color = MenzilColors.stateOrange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, tip, arrow);
    final base = tip + dir * 12;
    final normal = Offset(-dir.dy, dir.dx);
    final left = base + normal * 7, right = base - normal * 7;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = MenzilColors.stateOrange);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.hour != hour || old.colors != colors;
}

/// Picture for the ⓘ box: a dial with every 45° labelled (0° = from the
/// target, 90° = from the right, clockwise) and the matching clock hours of
/// the picker under the four main directions.
class WindDirectionDiagram extends StatelessWidget {
  const WindDirectionDiagram({super.key});

  static const labels = [
    '0°',
    '45°',
    '90°',
    '135°',
    '180°',
    '225°',
    '270°',
    '315°',
  ];

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return SizedBox.square(
      key: const ValueKey('wind-direction-diagram'),
      dimension: 230,
      child: CustomPaint(painter: _DiagramPainter(colors: c)),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  final MenzilColors colors;
  const _DiagramPainter({required this.colors});

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w600,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: MenzilType.familyFor(size),
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 44;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    const hours = {0: 'saat 12', 2: 'saat 3', 4: 'saat 6', 6: 'saat 9'};
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dir = Offset(math.sin(a), -math.cos(a));
      final major = i.isEven;
      canvas.drawLine(
        center + dir * (r - (major ? 12 : 8)),
        center + dir * r,
        Paint()
          ..color = colors.ink2
          ..strokeWidth = major ? 2.5 : 1.5,
      );
      final labelAt = center + dir * (r + 22);
      _text(
        canvas,
        WindDirectionDiagram.labels[i],
        labelAt,
        colors.ink,
        major ? 14 : 12,
      );
      final hour = hours[i];
      if (hour != null) {
        _text(
          canvas,
          hour,
          labelAt + const Offset(0, 14),
          colors.ink2,
          10,
          weight: FontWeight.w500,
        );
      }
    }
    // Example: wind from 90° (from the right), drawn like the picker.
    const dir = Offset(1, 0);
    final paint = Paint()
      ..color = colors.cyan
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + dir * (r - 4), paint);
    canvas.drawCircle(center + dir * (r - 4), 8, Paint()..color = colors.cyan);
    _text(canvas, 'Hedef ↑', center + Offset(0, -r * 0.45), colors.ink2, 11);
    _text(canvas, '90° = sağdan', center + Offset(0, r * 0.4), colors.ink, 12);
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter old) => old.colors != colors;
}
