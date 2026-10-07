import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tools/domain/tilt_math.dart';
import '../../tools/ports/tilt_provider.dart';
import '../../tools/state/level_controller.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Su Terazisi: large circular vial, flat/upright use, X/Y readout with a
/// 0.01° DISPLAY resolution. Without an accelerometer reading it shows a
/// state message instead of a fake bubble.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  LevelController? _controller;

  @override
  void initState() {
    super.initState();
    // Portrait only while the level is open. X/Y are DEVICE-frame angles drawn
    // in screen coordinates; if the interface rotated to landscape while the
    // phone lies flat, the bubble would move 90° away from the real high side.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= LevelController(
      provider: ToolsServicesScope.of(context).tilt,
    )..start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Su Terazisi'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final angles = controller.angles;
          final bias = controller.calibration.bias;
          return MenzilPage(
            children: [
              _modeAndViewRow(context, controller),
              const SizedBox(height: MenzilSpace.md),
              if (angles == null)
                _unavailable(controller)
              else ...[
                Semantics(
                  label:
                      'Su terazisi. Yatay tüp X ${TiltMath.format(angles.xDeg)} derece, '
                      'dikey tüp Y ${TiltMath.format(angles.yDeg)} derece, '
                      'dairesel gösterge her iki eksen. '
                      '${TiltMath.isLevel(angles) ? 'Seviyede.' : 'Eğik.'}',
                  child: ExcludeSemantics(
                    child: _VialCluster(
                      angles: angles,
                      viewType: controller.viewType,
                    ),
                  ),
                ),
                const SizedBox(height: MenzilSpace.md),
                _readoutCard(context, angles, controller.unit),
                const SizedBox(height: MenzilSpace.sm),
                _unitRow(context, controller),
                const SizedBox(height: MenzilSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-lock'),
                        expand: true,
                        label: controller.locked ? 'Kilidi aç' : 'Kilitle',
                        icon: controller.locked
                            ? Icons.lock_open_outlined
                            : Icons.lock_outline,
                        onPressed: controller.toggleLock,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-set-reference'),
                        expand: true,
                        label: 'Referansı bu konuma ayarla',
                        icon: Icons.my_location_outlined,
                        onPressed: controller.setReferenceHere,
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.md),
                    MenzilSecondaryButton(
                      key: const Key('level-clear-reference'),
                      label: 'Temizle',
                      expand: false,
                      onPressed: controller.hasOffset
                          ? controller.clearReference
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-open'),
                        expand: true,
                        label: 'Dört Yüzey Kalibrasyonu',
                        icon: Icons.rule_outlined,
                        onPressed: () =>
                            _openCalibrationSheet(context, controller),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.sm),
                _soundRow(context, controller),
                const SizedBox(height: MenzilSpace.md),
                Text(
                  'Duruş otomatik algılanır: ${controller.mode == TiltMode.flat ? 'telefon düz (ekran yukarı)' : 'telefon dik'}. '
                  '${controller.locked ? 'Değerler kilitli.' : ''}',
                  key: const Key('level-pose'),
                  style: MenzilType.caption(MenzilColors.of(context).ink2),
                ),
                const SizedBox(height: MenzilSpace.md),
              ],
              MenzilNotice(
                tone: MenzilNoticeTone.info,
                message:
                    'Değerler 0,01° çözünürlükle gösterilir; bu yalnızca ekran çözünürlüğüdür, '
                    'telefon ivmeölçerinin doğruluğu değildir. Titreşimi azaltmak için filtre uygulanır; '
                    'bu doğruluğu artırmaz.'
                    '${controller.hasOffset ? '\nReferans ayarı etkin: değerler ayarlanan konuma göredir; bu sensör kalibrasyonu değildir.' : ''}'
                    '${bias != null ? '\nDört yüzey kalibrasyonu etkin: sabit cihaz sapması çıkarılıyor.' : ''}',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _readoutCard(
    BuildContext context,
    TiltAngles angles,
    AngleDisplayUnit unit,
  ) {
    final c = MenzilColors.of(context);
    final level = TiltMath.isLevel(angles);
    return MenzilCard(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _axis(
              context,
              'X · yatay tüp',
              angles.xDeg,
              'level-x',
              unit,
            ),
          ),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: _axis(
              context,
              'Y · dikey tüp',
              angles.yDeg,
              'level-y',
              unit,
            ),
          ),
          const SizedBox(width: MenzilSpace.md),
          // Status is carried by icon + text, never by colour alone.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  level ? Icons.check_circle_outline : Icons.swap_vert,
                  color: c.ink,
                ),
                Text(
                  level ? 'Seviyede' : 'Eğik',
                  key: const Key('level-state'),
                  style: MenzilType.heading(c.ink, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axis(
    BuildContext context,
    String label,
    double deg,
    String key,
    AngleDisplayUnit unit,
  ) {
    final c = MenzilColors.of(context);
    final text = switch (unit) {
      AngleDisplayUnit.degrees => '${TiltMath.format(deg)}°',
      AngleDisplayUnit.percent => TiltMath.percentText(deg),
      AngleDisplayUnit.roofPitch => TiltMath.roofPitchText(deg),
    };
    return Semantics(
      label: '$label ${TiltMath.format(deg)} derece',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: MenzilType.label(c.ink2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                key: Key(key),
                maxLines: 1,
                style: MenzilType.display(c.ink, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeAndViewRow(BuildContext context, LevelController controller) {
    final c = MenzilColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Görünüm', style: MenzilType.label(c.ink2)),
        const SizedBox(height: MenzilSpace.xs),
        MenzilChipGroup<LevelViewType>(
          options: const [
            (LevelViewType.all, 'Tümü'),
            (LevelViewType.torpedo, 'Çubuk (Torpedo)'),
            (LevelViewType.bullseye, 'Dairesel (Mastar)'),
          ],
          selected: controller.viewType,
          onSelected: controller.setViewType,
        ),
      ],
    );
  }

  Widget _unitRow(BuildContext context, LevelController controller) {
    final c = MenzilColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Açı birimi', style: MenzilType.label(c.ink2)),
        const SizedBox(height: MenzilSpace.xs),
        MenzilChipGroup<AngleDisplayUnit>(
          options: const [
            (AngleDisplayUnit.degrees, 'Derece'),
            (AngleDisplayUnit.percent, 'Yüzde (%)'),
            (AngleDisplayUnit.roofPitch, 'Çatı eğimi (n/12)'),
          ],
          selected: controller.unit,
          onSelected: controller.setUnit,
        ),
      ],
    );
  }

  Widget _soundRow(BuildContext context, LevelController controller) {
    final c = MenzilColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Seviyeye gelince sistem sesi çal',
            style: MenzilType.body(c.ink),
          ),
        ),
        Switch.adaptive(
          key: const Key('level-sound-toggle'),
          value: controller.soundEnabled,
          activeThumbColor: c.ink,
          onChanged: controller.setSoundEnabled,
        ),
      ],
    );
  }

  void _openCalibrationSheet(BuildContext context, LevelController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CalibrationSheet(controller: controller),
    );
  }

  Widget _unavailable(LevelController controller) {
    final reason = controller.unavailableReason;
    final message = switch (reason) {
      TiltUnavailableReason.noSensor => 'Bu cihazda ivmeölçer bulunamadı.',
      TiltUnavailableReason.error =>
        'Eğim sensörü okunamadı. Uygulamayı yeniden açıp tekrar deneyin.',
      null =>
        'Eğim verisi bekleniyor. Simülatörde ivmeölçer yoktur; gerçek cihazda deneyin.',
    };
    return SizedBox(
      height: 320,
      child: MenzilStateMessage(
        icon: Icons.sensors_off_outlined,
        message: message,
      ),
    );
  }
}

/// Guided two-point "flip" calibration (see [FlipCalibration]): for the
/// current [LevelController.mode], capture a reading held normally, flip
/// the phone 180° on the same surface, capture again. A full calibration
/// across both modes (flat, upright) is four captures total.
class _CalibrationSheet extends StatelessWidget {
  final LevelController controller;
  const _CalibrationSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.md,
          MenzilSpace.md,
          MenzilSpace.md,
          MenzilSpace.lg,
        ),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final c = MenzilColors.of(context);
            final cal = controller.calibration;
            final hasReading = controller.rawAngles != null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dört Yüzey Kalibrasyonu',
                  style: MenzilType.heading(c.ink, size: 20),
                ),
                const SizedBox(height: MenzilSpace.xs),
                Text(
                  'Telefon bilinen düz bir yüzeyde dururken normal konumda bir okuma, '
                  'ardından aynı yüzeyde 180° döndürülmüş hâlde ikinci bir okuma alınır. '
                  'İki okumanın ortalaması cihaza özgü sabit sapmayı temizler; bu, '
                  'sensörün işaret yönünü varsaymadan çalışan bir teknik olup gerçek '
                  'cihazda doğrulanmamış işaret kuralına bağlı değildir. '
                  'Düz ve dik duruş için ayrı ayrı yapılır (toplam dört okuma).',
                  style: MenzilType.caption(c.ink2),
                ),
                const SizedBox(height: MenzilSpace.md),
                Text(
                  'Duruş: ${controller.mode == TiltMode.flat ? 'Düz' : 'Dik'}',
                  style: MenzilType.label(c.ink2),
                ),
                const SizedBox(height: MenzilSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-normal'),
                        expand: true,
                        label: cal.normal == null
                            ? '1) Normal okuma al'
                            : '1) Normal ✓ yeniden al',
                        onPressed: hasReading
                            ? () =>
                                  controller.captureCalibration(flipped: false)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-flipped'),
                        expand: true,
                        label: cal.flipped == null
                            ? '2) 180° çevirip okuma al'
                            : '2) Çevrilmiş ✓ yeniden al',
                        onPressed: hasReading
                            ? () => controller.captureCalibration(flipped: true)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.md),
                MenzilNotice(
                  tone: cal.isComplete
                      ? MenzilNoticeTone.info
                      : MenzilNoticeTone.warning,
                  message: cal.isComplete
                      ? 'Bu duruş için kalibrasyon etkin. Değer oturum belleğinde '
                            'tutulur; uygulama yeniden başlatıldığında sıfırlanır.'
                      : 'Bu duruş için kalibrasyon tamamlanmadı (iki okuma da gerekli).',
                ),
                const SizedBox(height: MenzilSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-clear-mode'),
                        expand: true,
                        label: 'Bu duruşu temizle',
                        onPressed: () =>
                            controller.clearCalibration(controller.mode),
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.md),
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-clear-all'),
                        expand: true,
                        label: 'Tümünü temizle',
                        onPressed: controller.clearAllCalibration,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Circular vial + horizontal (X) and vertical (Y) tubes, all driven by the
/// same two angles and updated together (Claude design "Su Terazisi").
///
/// X = asin(gx/|g|), Y = asin(gy/|g|): the circle reads both axes when the
/// phone lies flat, the horizontal tube X when it stands on its long edge,
/// the vertical tube Y when it stands on its short edge. The LIQUID of all
/// three is the only green in the app ([MenzilColors.levelLiquid]).
/// The on-device bubble sign convention is NOT verified without a physical iPhone.
class _VialCluster extends StatelessWidget {
  final TiltAngles angles;
  final LevelViewType viewType;
  const _VialCluster({required this.angles, this.viewType = LevelViewType.all});

  static const _tube = 64.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.min(constraints.maxWidth, 420.0);
        switch (viewType) {
          case LevelViewType.torpedo:
            // Single bar vial, carpenter's/torpedo-level style: one large
            // horizontal tube reading the X axis.
            return Center(
              child: SizedBox(
                width: w,
                height: 120,
                child: CustomPaint(
                  key: const Key('level-tube-x'),
                  painter: _TubePainter(
                    vertical: false,
                    deg: angles.xDeg,
                    colors: c,
                  ),
                ),
              ),
            );
          case LevelViewType.bullseye:
            // Single circular vial, mason's-level style: one large bullseye
            // reading both axes at once.
            final d = math.min(w, 320.0);
            return Center(
              child: SizedBox.square(
                key: const Key('level-circle'),
                dimension: d,
                child: CustomPaint(
                  painter: _CirclePainter(angles: angles, colors: c),
                ),
              ),
            );
          case LevelViewType.all:
            final d =
                w - _tube - _gap; // circle diameter = vertical tube length
            return Center(
              child: SizedBox(
                width: w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const Key('level-tube-x'),
                      width: w,
                      height: _tube,
                      child: CustomPaint(
                        painter: _TubePainter(
                          vertical: false,
                          deg: angles.xDeg,
                          colors: c,
                        ),
                      ),
                    ),
                    const SizedBox(height: _gap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          key: const Key('level-tube-y'),
                          width: _tube,
                          height: d,
                          child: CustomPaint(
                            painter: _TubePainter(
                              vertical: true,
                              deg: angles.yDeg,
                              colors: c,
                            ),
                          ),
                        ),
                        const SizedBox(width: _gap),
                        SizedBox.square(
                          key: const Key('level-circle'),
                          dimension: d,
                          child: CustomPaint(
                            painter: _CirclePainter(angles: angles, colors: c),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}

Color _highlight(MenzilColors c) => Color.lerp(c.levelLiquid, c.surface, 0.45)!;

class _TubePainter extends CustomPainter {
  final bool vertical;
  final double deg;
  final MenzilColors colors;
  const _TubePainter({
    required this.vertical,
    required this.deg,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5, 2.5, size.width - 5, size.height - 5),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = colors.levelLiquid);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = colors.ink,
    );
    final len = vertical ? size.height : size.width;
    final thick = vertical ? size.width : size.height;
    final centre = len / 2;
    // Light strip along the tube (part of the liquid, not a new colour).
    final strip = Paint()
      ..color = _highlight(colors).withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    Offset at(double along, double across) =>
        vertical ? Offset(across, along) : Offset(along, across);
    canvas.drawLine(at(14, 14), at(len - 14, 14), strip);

    // Centre target lines either side of the bubble.
    const half = 36.0;
    final mark = Paint()
      ..color = colors.ink
      ..strokeWidth = 3;
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawLine(
        at(centre + sign * half, 6),
        at(centre + sign * half, thick - 6),
        mark,
      );
    }

    // Bubble: x grows to the right, y sign is inverted like the circle.
    const bubbleHalfLen = 28.0;
    final bubbleHalfThick = thick * 0.27;
    final k = len * 0.079; // px per degree
    var off = (vertical ? -deg : deg) * k;
    final maxOff = len / 2 - bubbleHalfLen - 8;
    off = off.clamp(-maxOff, maxOff).toDouble();
    final cx = vertical ? thick / 2 : centre + off;
    final cy = vertical ? centre + off : thick / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: vertical ? bubbleHalfThick * 2 : bubbleHalfLen * 2,
      height: vertical ? bubbleHalfLen * 2 : bubbleHalfThick * 2,
    );
    canvas.drawOval(rect, Paint()..color = colors.surface);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = colors.ink,
    );
    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = colors.ink);
  }

  @override
  bool shouldRepaint(covariant _TubePainter old) =>
      old.deg != deg || old.vertical != vertical || old.colors != colors;
}

class _CirclePainter extends CustomPainter {
  final TiltAngles angles;
  final MenzilColors colors;
  const _CirclePainter({required this.angles, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;

    canvas.drawCircle(centre, r, Paint()..color = colors.levelLiquid);

    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colors.ink.withValues(alpha: 0.55);
    _dashedLine(
      canvas,
      Offset(centre.dx - r + 4, centre.dy),
      Offset(centre.dx + r - 4, centre.dy),
      dashed,
    );
    _dashedLine(
      canvas,
      Offset(centre.dx, centre.dy - r + 4),
      Offset(centre.dx, centre.dy + r - 4),
      dashed,
    );

    final strong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = colors.ink;
    canvas.drawCircle(centre, r * 0.225, strong..strokeWidth = 2.5);
    strong.strokeWidth = 3;
    final tick = r * 0.38;
    canvas.drawLine(
      Offset(centre.dx - r, centre.dy),
      Offset(centre.dx - r + tick, centre.dy),
      strong,
    );
    canvas.drawLine(
      Offset(centre.dx + r - tick, centre.dy),
      Offset(centre.dx + r, centre.dy),
      strong,
    );
    canvas.drawLine(
      Offset(centre.dx, centre.dy - r),
      Offset(centre.dx, centre.dy - r + tick),
      strong,
    );
    canvas.drawLine(
      Offset(centre.dx, centre.dy + r - tick),
      Offset(centre.dx, centre.dy + r),
      strong,
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = colors.ink,
    );

    // Bubble clamped inside the vial.
    final bubbleR = r * 0.19;
    final k = size.shortestSide * 0.0746;
    var dx = angles.xDeg * k;
    var dy = -angles.yDeg * k;
    final dist = math.sqrt(dx * dx + dy * dy);
    final maxDist = r - bubbleR - 4;
    if (dist > maxDist && dist > 0) {
      dx = dx / dist * maxDist;
      dy = dy / dist * maxDist;
    }
    final bubble = Offset(centre.dx + dx, centre.dy + dy);
    canvas.drawCircle(bubble, bubbleR, Paint()..color = colors.surface);
    canvas.drawCircle(
      bubble,
      bubbleR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = colors.ink,
    );
    canvas.drawCircle(bubble, 2.5, Paint()..color = colors.ink);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint p) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var pos = 0.0;
    while (pos < total) {
      final end = math.min(pos + 3, total);
      canvas.drawLine(a + dir * pos, a + dir * end, p);
      pos += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) =>
      old.angles.xDeg != angles.xDeg ||
      old.angles.yDeg != angles.yDeg ||
      old.colors != colors;
}
