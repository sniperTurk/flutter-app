import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/production_limits.dart';
import '../../tools/domain/shot_angle_math.dart';
import '../../tools/ports/tilt_provider.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'environment_field_info.dart';

/// Dürbün eğim açısı (scope cant): how far the scope is rolled about its
/// line of sight; positive = clockwise (top to the right, toward 3 o'clock).
/// Entered by hand or read from the phone held against the scope. Pops the
/// angle in degrees (0 = not used), or null when the user goes back.
class ScopeCantScreen extends StatefulWidget {
  final double initialDeg;
  const ScopeCantScreen({super.key, this.initialDeg = 0});

  static const fieldKey = ValueKey('cant-field');
  static const saveKey = ValueKey('cant-save');
  static const zeroKey = ValueKey('cant-zero');
  static const clearKey = ValueKey('cant-clear');
  static const measureKey = ValueKey('cant-measure');

  @override
  State<ScopeCantScreen> createState() => _ScopeCantScreenState();
}

class _ScopeCantScreenState extends State<ScopeCantScreen> {
  late final TextEditingController _field = TextEditingController(
    text: _format(widget.initialDeg),
  );
  StreamSubscription<TiltState>? _tilt;
  double? _live;

  static String _format(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble()
        ? r.toStringAsFixed(0)
        : r.toStringAsFixed(1).replaceAll('.', ',');
  }

  double? get _value {
    final v = double.tryParse(_field.text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite) return null;
    if (v.abs() > ProductionLimits.maxCantDeg) return null;
    return v;
  }

  void _set(double v) {
    _field.text = _format(v);
    setState(() {});
  }

  void _toggleMeasure() {
    final sub = _tilt;
    if (sub != null) {
      unawaited(sub.cancel());
      setState(() {
        _tilt = null;
        _live = null;
      });
      return;
    }
    final services = ToolsServicesScope.of(context);
    setState(() {
      _tilt = services.tilt.tilts().listen((state) {
        if (!mounted) return;
        if (state case TiltAvailable(:final gravity)) {
          final v = ShotAngleMath.cantDeg(gravity);
          if (v == null) return;
          final l = _live;
          setState(() => _live = l == null ? v : l + (v - l) * 0.2);
        }
      });
    });
  }

  @override
  void dispose() {
    unawaited(_tilt?.cancel());
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final value = _value;
    final shown = _live ?? value ?? 0;
    final error = value == null
        ? '−${ProductionLimits.maxCantDeg.toStringAsFixed(0)} ile '
              '${ProductionLimits.maxCantDeg.toStringAsFixed(0)} arasında '
              'bir derece girin.'
        : null;
    return Scaffold(
      appBar: MenzilSubPageBar(
        title: 'Dürbün eğim açısı',
        actions: [
          TextButton(
            key: ScopeCantScreen.saveKey,
            onPressed: value == null
                ? null
                : () => Navigator.of(context).pop(value),
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: MenzilPage(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: CantDialPainter(colors: c, cantDeg: shown),
            ),
          ),
          const SizedBox(height: MenzilSpace.sm),
          Text(
            '${ShotAngleMath.degrees(shown)} · ${ShotAngleMath.clock(shown)}'
            '${shown.abs() < 0.5 ? '' : (shown > 0 ? ' · sağa yatık' : ' · sola yatık')}',
            textAlign: TextAlign.center,
            style: MenzilType.number(c.ink, size: 20),
          ),
          const SizedBox(height: MenzilSpace.md),
          MenzilInput(
            key: ScopeCantScreen.fieldKey,
            controller: _field,
            label: 'Dürbün eğim açısı',
            unit: '°',
            info: EnvironmentFieldInfo.cant,
            errorText: error,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          MenzilSecondaryButton(
            key: ScopeCantScreen.measureKey,
            label: _tilt == null ? 'Telefonla ölç' : 'Ölçülen açıyı al',
            icon: Icons.screen_rotation_alt_outlined,
            expand: true,
            onPressed: _tilt == null
                ? _toggleMeasure
                : () {
                    final l = _live;
                    _toggleMeasure();
                    if (l != null) _set(l);
                  },
          ),
          if (_tilt != null)
            Padding(
              padding: const EdgeInsets.only(top: MenzilSpace.xs),
              child: Text(
                'Telefonu dik tutun ve kenarını dürbünün dikey eksenine '
                '(kule kapağına veya ray yüzeyine) dayayın.',
                style: MenzilType.caption(c.ink2),
              ),
            ),
          const SizedBox(height: MenzilSpace.md),
          MenzilPrimaryButton(
            key: ScopeCantScreen.zeroKey,
            label: '0\'a ayarla',
            onPressed: () => _set(0),
          ),
          const SizedBox(height: MenzilSpace.sm),
          MenzilSecondaryButton(
            key: ScopeCantScreen.clearKey,
            label: 'Dürbün eğimini sil',
            destructive: true,
            expand: true,
            onPressed: () => Navigator.of(context).pop(0.0),
          ),
          const SizedBox(height: MenzilSpace.xs),
          Text(
            'Dürbün eğimi silindiğinde (0°) balistik hesapta kullanılmaz.',
            textAlign: TextAlign.center,
            style: MenzilType.caption(c.ink2),
          ),
        ],
      ),
    );
  }
}

/// Clock bezel with a reticle rolled by [cantDeg] (clockwise positive).
class CantDialPainter extends CustomPainter {
  final MenzilColors colors;
  final double cantDeg;
  const CantDialPainter({required this.colors, required this.cantDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 4;
    final tick = Paint()
      ..color = colors.cyan
      ..strokeWidth = 1.2;
    for (var i = 0; i < 120; i++) {
      final a = i / 120 * 2 * math.pi;
      final long = i % 10 == 0;
      final r0 = outer - (long ? 18 : 10);
      final d = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(center + d * r0, center + d * (outer - 2), tick);
    }
    for (var h = 1; h <= 12; h++) {
      final a = h / 12 * 2 * math.pi;
      final d = Offset(math.sin(a), -math.cos(a));
      final tp = TextPainter(
        text: TextSpan(
          text: '$h',
          style: TextStyle(
            color: colors.cyanInk,
            fontSize: h % 3 == 0 ? 22 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        center + d * (outer - 34) - Offset(tp.width / 2, tp.height / 2),
      );
    }
    // Fixed 12 o'clock marker.
    final marker = Path()
      ..moveTo(center.dx, center.dy - outer + 22)
      ..lineTo(center.dx - 7, center.dy - outer + 10)
      ..lineTo(center.dx + 7, center.dy - outer + 10)
      ..close();
    canvas.drawPath(marker, Paint()..color = colors.danger);

    // Scope tube and reticle, rolled by the cant.
    final r = outer * 0.58;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(cantDeg * math.pi / 180);
    canvas.drawCircle(Offset.zero, r, Paint()..color = colors.scopeBg);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    final line = Paint()
      ..color = colors.scopeLine
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-r, 0), Offset(r, 0), line);
    canvas.drawLine(Offset(0, -r), Offset(0, r), line);
    for (var i = -4; i <= 4; i++) {
      if (i == 0) continue;
      final p = i * r / 5;
      canvas.drawLine(Offset(p, -5), Offset(p, 5), line);
      canvas.drawLine(Offset(-5, p), Offset(5, p), line);
    }
    // Elevation turret on top, windage on the right.
    final turret = Paint()..color = colors.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -r - 12), width: r * 0.7, height: 18),
        const Radius.circular(3),
      ),
      turret,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(r + 12, 0), width: 18, height: r * 0.7),
        const Radius.circular(3),
      ),
      turret,
    );
    canvas.restore();
    canvas.drawCircle(center, 4, Paint()..color = colors.danger);
  }

  @override
  bool shouldRepaint(covariant CantDialPainter old) =>
      old.cantDeg != cantDeg || old.colors != colors;
}
