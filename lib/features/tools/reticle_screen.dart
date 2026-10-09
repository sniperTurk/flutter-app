import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tools/domain/field_calc.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

const _decimal = TextInputType.numberWithOptions(decimal: true, signed: true);

double? _p(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.'));

/// Reticle geometry for a standard USMC-style mil-dot reticle.
///
/// Pure geometry only: what each dot spans at the entered distance, and how
/// big a target of the entered size looks through the reticle. It does NOT
/// contain a bullet-drop or wind value.
abstract final class MilDotReticle {
  /// Dots on each arm, centre to centre spacing 1 mil.
  static const dotsPerArm = 4;

  /// Dot diameter in mil: the USMC mil-dot specifies 0.25 mil (the Army
  /// variant 0.22 mil). Was 0.2 before 2026-10-09.
  static const dotDiameterMil = 0.25;

  /// Where the thick posts begin (mil from centre) and where they end.
  static const postStartMil = 5.0;
  static const postEndMil = 10.0;
}

/// ⓘ texts of the Retikül page (owner rule, 2026-10-07).
abstract final class ReticleFieldInfo {
  static const distance =
      'Hedefe olan mesafe; telemetre ile ölçün. Nokta aralığının hedefte kaç '
      'cm tuttuğu buna göre hesaplanır. Örnek: 50 m.';
  static const target =
      'Hedefin bilinen boyu veya çapı. Retikülde kaç mil kapladığını '
      'gösterir. Örnek: 4,5 cm (tipik metal silüet).';
  static const mag =
      'Dürbünün şu an ayarlı olduğu büyütme; büyütme halkasında yazar. SFP '
      'dürbünde retikül değeri büyütmeyle değişir. Örnek: 10x.';
  static const calMag =
      'SFP dürbünde retikül çizgilerinin doğru mil değerini gösterdiği '
      'büyütme; dürbün kılavuzunda yazar, çoğunlukla en yüksek büyütmedir. '
      'Örnek: 10x.';
}

class ReticleScreen extends StatefulWidget {
  const ReticleScreen({super.key});
  @override
  State<ReticleScreen> createState() => _ReticleState();
}

class _ReticleState extends State<ReticleScreen> {
  final _distance = TextEditingController(text: '50');
  final _mag = TextEditingController(text: '10');
  final _calMag = TextEditingController(text: '10');
  final _target = TextEditingController(text: '4.5');
  bool _ffp = true;

  @override
  void dispose() {
    _distance.dispose();
    _mag.dispose();
    _calMag.dispose();
    _target.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController c,
    String label,
    String unit,
    Key key, {
    String? helper,
    required String info,
  }) => MenzilInput(
    key: key,
    controller: c,
    label: label,
    unit: unit,
    helperText: helper,
    info: info,
    keyboardType: _decimal,
    onChanged: (_) => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final dist = _p(_distance);
    final mag = _p(_mag);
    final cal = _p(_calMag);
    final targetCm = _p(_target);

    final k = FieldCalc.trueMilPerReticleMil(
      firstFocalPlane: _ffp,
      mag: mag ?? 0,
      calibrationMag: _ffp ? 1 : (cal ?? 0),
    );
    final ready = dist != null && dist > 0 && k != null;
    final dotM = ready ? FieldCalc.spanM(dist, k) : null; // 1 reticle mil
    final targetMil = (ready && targetCm != null && targetCm > 0)
        ? FieldCalc.milOfSize(targetCm / 100, dist)
        : null;
    final targetReticleMil = (targetMil != null && k != null && k > 0)
        ? targetMil / k
        : null;

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Retikül (mil-dot)'),
      body: MenzilPage(
        children: [
          const MenzilSectionHeader(
            '1 · Dürbün ve hedef',
            padding: EdgeInsets.only(
              top: MenzilSpace.md,
              bottom: MenzilSpace.sm,
            ),
          ),
          _field(
            _distance,
            'Hedef mesafesi',
            'm',
            const Key('reticle-distance'),
            info: ReticleFieldInfo.distance,
          ),
          const SizedBox(height: MenzilSpace.sm),
          _field(
            _target,
            'Hedef boyu (görünen çap veya boy)',
            'cm',
            const Key('reticle-target'),
            info: ReticleFieldInfo.target,
          ),
          const SizedBox(height: MenzilSpace.sm),
          MenzilChipGroup<bool>(
            options: const [
              (true, 'FFP (ilk odak düzlemi)'),
              (false, 'SFP (ikinci odak düzlemi)'),
            ],
            selected: _ffp,
            onSelected: (v) => setState(() => _ffp = v),
          ),
          const SizedBox(height: MenzilSpace.sm),
          if (!_ffp) ...[
            _field(
              _mag,
              'Şu anki büyütme',
              'x',
              const Key('reticle-mag'),
              info: ReticleFieldInfo.mag,
            ),
            const SizedBox(height: MenzilSpace.sm),
            _field(
              _calMag,
              'Retikülün doğru olduğu büyütme',
              'x',
              const Key('reticle-cal-mag'),
              helper:
                  'Çoğu SFP dürbünde en yüksek büyütme. Dürbünün kılavuzuna bakın.',
              info: ReticleFieldInfo.calMag,
            ),
          ],
          const MenzilSectionHeader(
            '2 · Retikül görünümü',
            padding: EdgeInsets.only(
              top: MenzilSpace.md,
              bottom: MenzilSpace.sm,
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              key: const Key('reticle-canvas'),
              painter: _ReticlePainter(
                colors: MenzilColors.of(context),
                dotSpanM: dotM,
                targetReticleMil: targetReticleMil,
              ),
            ),
          ),
          const SizedBox(height: MenzilSpace.md),
          if (!ready)
            const MenzilNotice(
              tone: MenzilNoticeTone.info,
              message: 'Mesafe ve büyütme için pozitif sayı girin.',
            )
          else
            MenzilMetricGrid(
              columns: 2,
              metrics: [
                MenzilMetric(
                  '1 mil (nokta aralığı)',
                  ToolFormat.dec(dotM! * 100, 1),
                  'cm',
                ),
                MenzilMetric(
                  '0,25 mil nokta çapı',
                  ToolFormat.dec(
                    FieldCalc.spanM(dist, k * MilDotReticle.dotDiameterMil)! *
                        100,
                    1,
                  ),
                  'cm',
                ),
                if (targetMil != null) ...[
                  MenzilMetric(
                    'Hedef (gerçek)',
                    ToolFormat.dec(targetMil, 2),
                    'mil',
                  ),
                  MenzilMetric(
                    'Hedef (retikülde)',
                    ToolFormat.dec(targetReticleMil!, 2),
                    'mil',
                  ),
                ],
              ],
            ),
          const MenzilNotice(
            tone: MenzilNoticeTone.warning,
            message:
                'Bu ekran yalnızca geometridir: noktaların o mesafede kaç cm '
                'karşılık geldiğini ve hedefin retikülde nasıl göründüğünü '
                'gösterir. Düşüş veya rüzgâr değeri vermez; bunlar için '
                'havalı silah mermisine uygun doğrulanmış sürüklenme verisi '
                'gerekir ve henüz bağlı değildir.',
          ),
          const MenzilNotice(
            tone: MenzilNoticeTone.info,
            message:
                'Mesafe ölçme: mesafe (m) = hedef boyu (m) × 1000 ÷ okunan mil. '
                'Okumayı Hesaplayıcılar > Stadyametrik mesafe ölçer ile yapın.',
          ),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final MenzilColors colors;

  /// Metres covered by one reticle mil at the target distance, or null.
  final double? dotSpanM;

  /// Target size in reticle mils, or null.
  final double? targetReticleMil;

  _ReticlePainter({
    required this.colors,
    required this.dotSpanM,
    required this.targetReticleMil,
  });

  /// The field of view drawn: +/- this many reticle mils.
  static const _viewMil = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);
    final r = side / 2;
    final pxPerMil = r / _viewMil;

    final bg = Paint()..color = colors.scopeBg;
    canvas.drawCircle(c, r, bg);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));

    final line = Paint()
      ..color = colors.scopeLine
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = colors.scopeLine
      ..style = PaintingStyle.fill;

    // Target, drawn to scale behind the reticle.
    final t = targetReticleMil;
    if (t != null && t > 0) {
      final tr = t / 2 * pxPerMil;
      final tp = Paint()
        ..color = colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(c.translate(0, -2 * pxPerMil), tr, tp);
    }

    // Fine crosshair.
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), line);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), line);

    // Thick posts.
    final post = Paint()
      ..color = colors.scopeLine
      ..strokeWidth = math.max(3, pxPerMil * 0.4)
      ..style = PaintingStyle.stroke;
    const a = MilDotReticle.postStartMil;
    const b = MilDotReticle.postEndMil;
    for (final s in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(c.dx + s * a * pxPerMil, c.dy),
        Offset(c.dx + s * b * pxPerMil, c.dy),
        post,
      );
      canvas.drawLine(
        Offset(c.dx, c.dy + s * a * pxPerMil),
        Offset(c.dx, c.dy + s * b * pxPerMil),
        post,
      );
    }

    // Dots and cm labels.
    final dotR = MilDotReticle.dotDiameterMil / 2 * pxPerMil;
    for (var i = 1; i <= MilDotReticle.dotsPerArm; i++) {
      for (final s in const [-1.0, 1.0]) {
        canvas.drawCircle(Offset(c.dx + s * i * pxPerMil, c.dy), dotR, fill);
        canvas.drawCircle(Offset(c.dx, c.dy + s * i * pxPerMil), dotR, fill);
      }
      final span = dotSpanM;
      if (span != null) {
        _label(
          canvas,
          ToolFormat.dec(span * i * 100, 0),
          Offset(c.dx + i * pxPerMil, c.dy - 4),
        );
      }
    }
    canvas.restore();
    canvas.drawCircle(c, r, line);
  }

  void _label(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: colors.scopeDim, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height));
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter o) =>
      o.dotSpanM != dotSpanM ||
      o.targetReticleMil != targetReticleMil ||
      o.colors != colors;
}
