import 'dart:async';

import 'package:flutter/material.dart';

import '../../tools/domain/shot_angle_math.dart';
import '../../tools/ports/camera_service.dart';
import '../../tools/ports/tilt_provider.dart';
import '../../tools/tools_services.dart';

/// Tüfek eğimi ölçümü: the back camera shows the target behind a crosshair
/// and the accelerometer gives the angle of the camera's line of sight
/// above (+) or below (−) the horizontal. "OK" returns the angle in degrees.
///
/// Like field apps, the screen works without the camera too (black
/// background): only the accelerometer is needed for the angle.
class InclineMeasureScreen extends StatefulWidget {
  const InclineMeasureScreen({super.key});

  static const okKey = ValueKey('incline-ok');
  static const zeroKey = ValueKey('incline-set-zero');
  static const angleKey = ValueKey('incline-angle');

  @override
  State<InclineMeasureScreen> createState() => _InclineMeasureScreenState();
}

class _InclineMeasureScreenState extends State<InclineMeasureScreen> {
  StreamSubscription<TiltState>? _tilt;
  CameraSession? _camera;
  bool _started = false;
  bool _noSensor = false;

  /// Smoothed raw reading and the user's "Set 0°" offset.
  double? _raw;
  double _offset = 0;

  double? get _angle {
    final r = _raw;
    return r == null ? null : ShotAngleMath.relative(r, _offset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final services = ToolsServicesScope.of(context);
    _tilt = services.tilt.tilts().listen((state) {
      if (!mounted) return;
      switch (state) {
        case TiltAvailable(:final gravity):
          final v = ShotAngleMath.inclineDeg(gravity);
          if (v == null) return;
          setState(() {
            _noSensor = false;
            // Light low-pass filter: steadier digits, no visible lag.
            final r = _raw;
            _raw = r == null ? v : r + (v - r) * 0.2;
          });
        case TiltUnavailable():
          setState(() => _noSensor = true);
      }
    });
    unawaited(_openCamera(services.camera));
  }

  Future<void> _openCamera(CameraService camera) async {
    try {
      final s = await camera.open();
      if (!mounted) {
        await s.dispose();
        return;
      }
      setState(() => _camera = s);
    } catch (_) {
      // No camera (Simulator, permission refused): the angle still works.
    }
  }

  @override
  void dispose() {
    unawaited(_tilt?.cancel());
    final s = _camera;
    _camera = null;
    if (s != null) unawaited(s.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = _angle;
    const glow = [Shadow(color: Colors.white54, blurRadius: 12)];
    TextStyle style(double size, {FontWeight w = FontWeight.w600}) => TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: w,
      shadows: glow,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera != null)
            Positioned.fill(child: _camera!.buildPreview(context)),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _Crosshair())),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text('Tüfek eğimi açısı, derece', style: style(22)),
                Semantics(
                  liveRegion: true,
                  label: angle == null
                      ? 'Eğim ölçülüyor'
                      : 'Eğim ${ShotAngleMath.degrees(angle)}',
                  child: ExcludeSemantics(
                    child: Text(
                      angle == null ? '—' : ShotAngleMath.degrees(angle),
                      key: InclineMeasureScreen.angleKey,
                      style: style(72, w: FontWeight.w700),
                    ),
                  ),
                ),
                if (_noSensor)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bu cihazda ivmeölçer okunamıyor; eğimi elle girin.',
                      textAlign: TextAlign.center,
                      style: style(15),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Telefonu dik tutun, arka kamerayı hedefe çevirin; '
                    'artıyı hedefe yerleştirip OK\'a basın. Yukarı atış +, '
                    'aşağı atış −.',
                    textAlign: TextAlign.center,
                    style: style(15, w: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: InclineMeasureScreen.zeroKey,
                  onPressed: _raw == null
                      ? null
                      : () => setState(() => _offset = _raw!),
                  child: Text('Set 0°', style: style(30)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('İptal', style: style(30)),
                      ),
                      TextButton(
                        key: InclineMeasureScreen.okKey,
                        onPressed: angle == null
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pop((angle * 10).round() / 10),
                        child: Text('OK', style: style(30)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Crosshair extends CustomPainter {
  const _Crosshair();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.32;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r, p);
    canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), p);
    canvas.drawLine(c - Offset(0, r), c + Offset(0, r), p);
    canvas.drawCircle(c, 3, Paint()..color = Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant _Crosshair oldDelegate) => false;
}
