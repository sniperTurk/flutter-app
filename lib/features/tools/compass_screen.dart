import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tools/domain/compass_math.dart';
import '../../tools/ports/heading_provider.dart';
import '../../tools/state/compass_controller.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Pusula: large 360° dial, degrees and direction. Never shows a made-up
/// heading: without a sensor reading the dial is replaced by a state message.
class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  CompassController? _controller;

  /// Below this accuracy (degrees) the reading is considered poor.
  static const _poorAccuracyDeg = 25.0;

  @override
  void initState() {
    super.initState();
    // Portrait only while the compass is open: the iOS plugin adds ±90° to
    // the heading in landscape, which would also hide its invalid (negative)
    // readings from the adapter's check.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = ToolsServicesScope.of(context);
      _controller = CompassController(provider: services.heading)..start();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _openSettings() =>
      ToolsServicesScope.of(context).location.openSettings();

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Pusula'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = MenzilColors.of(context);
          final degrees = controller.degrees;
          final state = controller.state;
          final accuracy = controller.accuracyDeg;
          return MenzilPage(
            children: [
              if (degrees == null)
                _unavailable(context, state)
              else ...[
                Semantics(
                  liveRegion: false,
                  label:
                      'Pusula. ${CompassMath.wholeDegrees(degrees)} derece, '
                      '${CompassMath.cardinal16Spoken(degrees)} yönü.',
                  child: ExcludeSemantics(
                    child: _CompassDial(degrees: degrees),
                  ),
                ),
                const SizedBox(height: MenzilSpace.md),
                // The dial label above already speaks the full Turkish name; the
                // big visible text must not be read a second time as bare letters.
                ExcludeSemantics(
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: '${CompassMath.wholeDegrees(degrees)}°',
                        style: MenzilType.display(c.ink, size: 64),
                        children: [
                          TextSpan(
                            text: '  ${CompassMath.cardinal16(degrees)}',
                            style: MenzilType.heading(c.amberInk, size: 34),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MenzilSpace.md),
                if (accuracy != null && accuracy > _poorAccuracyDeg)
                  const MenzilNotice(
                    tone: MenzilNoticeTone.warning,
                    title: 'Kalibrasyon gerekli',
                    message:
                        'Sensör doğruluğu düşük. Telefonu havada 8 şeklinde hareket ettirin; '
                        'metal ve mıknatıslardan uzak durun.',
                  ),
              ],
              const MenzilNotice(
                tone: MenzilNoticeTone.info,
                message:
                    'Yön telefonun üst kenarının baktığı sensör yönünü gösterir. Kuzey referansı (gerçek veya manyetik) '
                    'bu uygulamada cihazda doğrulanmamıştır; bu nedenle derece değeri gerçek kuzey olarak '
                    'etiketlenmez. Konum servisleri kapalıysa yön geçersiz olabilir. Doğruluk cihaz '
                    'sensörüne bağlıdır. Pusula atış hesabına otomatik aktarılmaz.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _unavailable(BuildContext context, HeadingState state) {
    final reason = switch (state) {
      HeadingUnavailable(:final reason) => reason,
      _ => HeadingUnavailableReason.noData,
    };
    final message = switch (reason) {
      HeadingUnavailableReason.noSensor =>
        'Bu cihazda pusula sensörü bulunamadı.',
      HeadingUnavailableReason.noData =>
        'Pusula verisi bekleniyor. Veri gelmiyorsa konum servislerinin açık olduğunu '
            'kontrol edin. Simülatörde pusula sensörü yoktur.',
      HeadingUnavailableReason.error =>
        'Pusula okunamadı. Uygulamayı yeniden açıp tekrar deneyin.',
      HeadingUnavailableReason.noReference =>
        'Yön sağlayıcısı geçersiz bir referans değeri döndürdü. Bu, konum servisleri kapalıyken veya '
            'konum izni yokken olabilir (cihazda doğrulanmadı). Konum ayarlarını kontrol edip pusulayı '
            'yeniden açın.',
    };
    return SizedBox(
      height: 360,
      child: MenzilStateMessage(
        icon: Icons.explore_off_outlined,
        message: message,
        action: MenzilSecondaryButton(
          label: 'Ayarlar\'ı aç',
          onPressed: _openSettings,
          expand: false,
        ),
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final double degrees;
  const _CompassDial({required this.degrees});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.sizeOf(context).height;
        final side = math.min(
          constraints.maxWidth,
          math.max(240.0, screenH * 0.5),
        );
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: CustomPaint(
              painter: _DialPainter(degrees: degrees, colors: c),
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double degrees;
  final MenzilColors colors;
  const _DialPainter({required this.degrees, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 18;
    canvas.drawCircle(center, r, Paint()..color = colors.scopeBg);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = colors.ink,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // The card rotates opposite to the heading so N points toward the sensor's
    // north reference.
    canvas.rotate(-degrees * math.pi / 180);

    final minor = Paint()
      ..color = colors.scopeDim
      ..strokeWidth = 1.5;
    final major = Paint()
      ..color = colors.ink
      ..strokeWidth = 3;
    for (var a = 0; a < 360; a += 5) {
      final isMajor = a % 30 == 0;
      final len = isMajor ? r * 0.10 : (a % 10 == 0 ? r * 0.06 : r * 0.035);
      canvas.save();
      canvas.rotate(a * math.pi / 180);
      canvas.drawLine(
        Offset(0, -r + 2),
        Offset(0, -r + 2 + len),
        isMajor ? major : minor,
      );
      canvas.restore();
    }

    void label(
      String text,
      double angle, {
      required double size,
      required Color color,
      required double radius,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.rotate(angle * math.pi / 180);
      canvas.translate(0, -radius);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Turkish cardinal letters: K kuzey, D doğu, G güney, B batı.
    const names = <int, String>{0: 'K', 90: 'D', 180: 'G', 270: 'B'};
    for (final e in names.entries) {
      label(
        e.value,
        e.key.toDouble(),
        size: r * 0.17,
        color: e.key == 0 ? colors.amberInk : colors.ink,
        radius: r * 0.74,
      );
    }
    const inter = <int, String>{45: 'KD', 135: 'GD', 225: 'GB', 315: 'KB'};
    for (final e in inter.entries) {
      label(
        e.value,
        e.key.toDouble(),
        size: r * 0.09,
        color: colors.ink2,
        radius: r * 0.74,
      );
    }
    for (var a = 30; a < 360; a += 30) {
      if (a % 90 == 0) continue;
      label(
        '$a',
        a.toDouble(),
        size: r * 0.07,
        color: colors.ink2,
        radius: r * 0.56,
      );
    }
    canvas.restore();

    // Fixed lubber line (the direction the phone points to).
    final lubber = Path()
      ..moveTo(center.dx, center.dy - r + 4)
      ..lineTo(center.dx - 9, center.dy - r - 12)
      ..lineTo(center.dx + 9, center.dy - r - 12)
      ..close();
    canvas.drawPath(lubber, Paint()..color = colors.amber);
    canvas.drawCircle(center, 5, Paint()..color = colors.ink);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.degrees != degrees || old.colors != colors;
}
