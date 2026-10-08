import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/wind_clock.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Clock-face wind direction picker: the shooter is in the centre facing
/// 12 (the target); tap the hour the wind comes from. An arrow shows the
/// wind blowing in from that hour.
class WindClockPicker extends StatelessWidget {
  final int hour;
  final ValueChanged<int> onChanged;
  final String? info;

  const WindClockPicker({
    super.key,
    required this.hour,
    required this.onChanged,
    this.info,
  });

  static ValueKey<String> hourKey(int h) => ValueKey('wind-clock-$h');

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Rüzgâr yönü', style: MenzilType.body(c.ink2)),
            ),
            if (info != null)
              MenzilInfoButton(
                title: 'Rüzgâr yönü',
                text: info!,
                illustration: const WindDirectionDiagram(),
              ),
          ],
        ),
        const SizedBox(height: MenzilSpace.xs),
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
                        painter: _ClockPainter(colors: c, hour: hour),
                      ),
                    ),
                    for (var h = 1; h <= 12; h++)
                      Positioned(
                        left: center.dx + r * math.sin(h * math.pi / 6) - 22,
                        top: center.dy - r * math.cos(h * math.pi / 6) - 22,
                        width: 44,
                        height: 44,
                        child: Semantics(
                          button: true,
                          selected: h == hour,
                          label: 'Saat $h, ${WindClock.side(h)}',
                          child: ExcludeSemantics(
                            child: Material(
                              key: hourKey(h),
                              color: h == hour ? c.amber : c.surface2,
                              shape: CircleBorder(
                                side: BorderSide(color: c.line),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => onChanged(h),
                                child: Center(
                                  child: Text(
                                    '$h',
                                    style: MenzilType.number(
                                      h == hour ? c.amberInk : c.ink,
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
        const SizedBox(height: MenzilSpace.xs),
        Center(
          child: Text(
            'Saat $hour · ${WindClock.side(hour)}',
            key: const ValueKey('wind-clock-label'),
            style: MenzilType.body(c.ink),
          ),
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  final MenzilColors colors;
  final int hour;
  const _ClockPainter({required this.colors, required this.hour});

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
    // Shooter facing the target (12 o'clock).
    final shooter = Paint()..color = colors.ink;
    canvas.drawCircle(center, 7, shooter);
    canvas.drawLine(
      center,
      center + Offset(0, -r * 0.45),
      Paint()
        ..color = colors.ink2
        ..strokeWidth = 2,
    );
    // Wind arrow: from the chosen hour towards the shooter.
    final a = hour * math.pi / 6;
    final dir = Offset(math.sin(a), -math.cos(a));
    final tail = center + dir * (r - 30);
    final tip = center + dir * 16;
    final arrow = Paint()
      ..color = colors.amberInk
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, tip, arrow);
    // Arrow head at the tip, its base back towards the hour.
    final base = tip + dir * 12;
    final normal = Offset(-dir.dy, dir.dx);
    final left = base + normal * 7, right = base - normal * 7;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = colors.amberInk);
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
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
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
