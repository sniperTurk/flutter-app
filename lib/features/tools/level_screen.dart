import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tools/domain/tilt_math.dart';
import '../../tools/ports/tilt_provider.dart';
import '../../tools/state/level_controller.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Su Terazisi, laid out like a physical bubble level: a horizontal vial on
/// top, a vertical vial on the left and a round bullseye vial, all on a
/// concrete backdrop, with a bottom bar of round controls (settings, help,
/// X/Y readout with lock, sound, view). X/Y keep a 0.01° DISPLAY resolution.
/// Without an accelerometer reading it shows a state message instead of a
/// fake bubble.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  LevelController? _controller;

  static const _resolutionNotice =
      'Değerler 0,01° çözünürlükle gösterilir; bu yalnızca ekran çözünürlüğüdür, '
      'telefon ivmeölçerinin doğruluğu değildir. Titreşimi azaltmak için filtre uygulanır; '
      'bu doğruluğu artırmaz.';

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
    final services = ToolsServicesScope.of(context);
    _controller ??= LevelController(
      provider: services.tilt,
      calibrationStore: services.levelCalibration,
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
    final c = MenzilColors.of(context);
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Su Terazisi'),
      backgroundColor: c.levelBackdropDeep,
      body: CustomPaint(
        painter: _BackdropPainter(c),
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final angles = controller.angles;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  MenzilSpace.gutter,
                  MenzilSpace.xl,
                  MenzilSpace.gutter,
                  MenzilSpace.md,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: angles == null
                          ? _unavailable(controller)
                          : Semantics(
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
                    ),
                    if (angles != null) ...[
                      const SizedBox(height: MenzilSpace.md),
                      _status(context, controller, angles),
                    ],
                    const SizedBox(height: MenzilSpace.md),
                    _controlBar(context, controller, angles),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _valueText(double deg, AngleDisplayUnit unit) => switch (unit) {
    AngleDisplayUnit.degrees => '${TiltMath.format(deg)}°',
    AngleDisplayUnit.percent => TiltMath.percentText(deg),
    AngleDisplayUnit.roofPitch => TiltMath.roofPitchText(deg),
  };

  /// Level / tilted, conveyed by icon + text (never by colour alone), plus
  /// the detected pose and the active reference/calibration.
  Widget _status(
    BuildContext context,
    LevelController controller,
    TiltAngles angles,
  ) {
    final c = MenzilColors.of(context);
    final level = TiltMath.isLevel(angles);
    final calibrated = controller.calibration.bias != null;
    final notes = [
      controller.mode == TiltMode.flat ? 'Telefon düz' : 'Telefon dik',
      if (controller.locked) 'kilitli',
      if (controller.hasOffset) 'referans etkin',
      calibrated ? 'kalibre' : 'kalibre değil',
    ].join(' · ');
    final status = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level ? Icons.check_circle_outline : Icons.swap_vert,
            color: c.levelControlInk,
            size: 20,
          ),
          const SizedBox(width: MenzilSpace.xs),
          Text(
            level ? 'Seviyede' : 'Eğik',
            key: const Key('level-state'),
            style: MenzilType.heading(c.levelControlInk, size: 18),
          ),
          const SizedBox(width: MenzilSpace.md),
          Text(
            notes,
            key: const Key('level-pose'),
            style: MenzilType.caption(c.levelControlInk),
          ),
        ],
      ),
    );
    if (calibrated) return status;
    // Uncalibrated phones read ~1–2° on a flat table (camera bump plus
    // accelerometer offset); point straight at the two-step fix.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        status,
        const SizedBox(height: MenzilSpace.xs),
        Semantics(
          button: true,
          label: 'Kalibre edilmedi. Kalibrasyonu başlatmak için dokunun.',
          child: ExcludeSemantics(
            child: Material(
              color: c.levelControl,
              shape: StadiumBorder(side: BorderSide(color: c.amber)),
              child: InkWell(
                key: const Key('level-calibration-hint'),
                customBorder: const StadiumBorder(),
                onTap: () => _openSettingsSheet(context, controller),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MenzilSpace.lg,
                    vertical: MenzilSpace.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 18, color: c.amber),
                      const SizedBox(width: MenzilSpace.xs),
                      Flexible(
                        child: Text(
                          'Kalibre edilmedi · düz zeminde 1–2° sapma normaldir, '
                          'düzeltmek için dokunun',
                          style: MenzilType.caption(c.levelControlInk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlBar(
    BuildContext context,
    LevelController controller,
    TiltAngles? angles,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final button = (constraints.maxWidth * 0.145)
            .clamp(44.0, 62.0)
            .toDouble();
        const gap = MenzilSpace.sm;
        return Row(
          children: [
            _RoundButton(
              key: const Key('level-calibrate-open'),
              size: button,
              icon: Icons.center_focus_strong_outlined,
              label: 'Kalibrasyon ve ayarlar',
              onPressed: () => _openSettingsSheet(context, controller),
            ),
            const SizedBox(width: gap),
            _RoundButton(
              key: const Key('level-help'),
              size: button,
              icon: Icons.question_mark_rounded,
              label: 'Yardım',
              onPressed: () => _showHelp(context, controller),
            ),
            const SizedBox(width: gap),
            Expanded(child: _readoutPill(context, controller, angles, button)),
            const SizedBox(width: gap),
            _RoundButton(
              key: const Key('level-sound-toggle'),
              size: button,
              icon: controller.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: controller.soundEnabled
                  ? 'Seviye sesi açık, kapatmak için dokunun'
                  : 'Seviye sesi kapalı, açmak için dokunun',
              onPressed: () =>
                  controller.setSoundEnabled(!controller.soundEnabled),
            ),
            const SizedBox(width: gap),
            _RoundButton(
              key: const Key('level-view-cycle'),
              size: button,
              icon: switch (controller.viewType) {
                LevelViewType.all => Icons.dashboard_outlined,
                LevelViewType.torpedo => Icons.horizontal_rule_rounded,
                LevelViewType.bullseye => Icons.radio_button_unchecked,
              },
              label:
                  'Görünüm: ${_viewName(controller.viewType)}, değiştirmek için dokunun',
              onPressed: () => controller.setViewType(
                LevelViewType.values[(controller.viewType.index + 1) %
                    LevelViewType.values.length],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _viewName(LevelViewType v) => switch (v) {
    LevelViewType.all => 'tümü',
    LevelViewType.torpedo => 'çubuk',
    LevelViewType.bullseye => 'dairesel',
  };

  Widget _readoutPill(
    BuildContext context,
    LevelController controller,
    TiltAngles? angles,
    double height,
  ) {
    final c = MenzilColors.of(context);
    final style = MenzilType.number(c.levelControlInk, size: 17);
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: MenzilSpace.lg),
      decoration: BoxDecoration(
        color: c.levelControl,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: c.levelBezel, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Semantics(
                label: angles == null
                    ? 'Eğim verisi yok'
                    : 'X ${TiltMath.format(angles.xDeg)} derece, '
                          'Y ${TiltMath.format(angles.yDeg)} derece',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'X: ${angles == null ? '—' : _valueText(angles.xDeg, controller.unit)}',
                        key: const Key('level-x'),
                        style: style,
                      ),
                      Text(
                        'Y: ${angles == null ? '—' : _valueText(angles.yDeg, controller.unit)}',
                        key: const Key('level-y'),
                        style: style,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              key: const Key('level-lock'),
              tooltip: controller.locked ? 'Kilidi aç' : 'Kilitle',
              padding: EdgeInsets.zero,
              onPressed: angles == null ? null : controller.toggleLock,
              icon: Icon(
                controller.locked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                size: 20,
                color: c.levelControlInk.withValues(
                  alpha: controller.locked ? 1 : 0.45,
                ),
              ),
            ),
          ),
          const SizedBox(width: MenzilSpace.xxs),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context, LevelController controller) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Su Terazisi'),
        content: SingleChildScrollView(
          child: Text(
            'Telefonu ölçmek istediğiniz yüzeye koyun: düz yatırınca dairesel '
            'göz iki ekseni birden, uzun kenarı üzerinde dik tutunca üst tüp X '
            'eksenini, kısa kenarı üzerinde dik tutunca sol tüp Y eksenini '
            'gösterir. Kabarcık iki çizginin ortasındaysa yüzey seviyededir.\n\n'
            'Kalibrasyon neden gerekli: telefon sırt üstü yatınca kamera çıkıntısı '
            'bir ucu yaklaşık 1–2° kaldırır; ivmeölçerin de kendine özgü küçük bir '
            'sapması vardır. Bu yüzden kalibre edilmemiş telefon tamamen düz bir '
            'masada da 1–2° gösterebilir. Sol alttaki düğmeden iki adımlı '
            'kalibrasyonu bir kez yapın; sonuç telefona kaydedilir.\n\n'
            '$_resolutionNotice'
            '${controller.hasOffset ? '\n\nReferans ayarı etkin: değerler ayarlanan konuma göredir; bu sensör kalibrasyonu değildir.' : ''}'
            '${controller.calibration.bias != null ? '\n\nDört yüzey kalibrasyonu etkin: sabit cihaz sapması çıkarılıyor.' : ''}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _openSettingsSheet(BuildContext context, LevelController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _LevelSettingsSheet(controller: controller),
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
    // MenzilStateMessage scrolls by itself; the card only gives it a
    // readable surface on the dark backdrop.
    return MenzilCard(
      child: MenzilStateMessage(
        icon: Icons.sensors_off_outlined,
        message: message,
      ),
    );
  }
}

/// Reference, calibration, angle unit and view: everything that is not
/// needed while reading the bubble lives in this sheet.
class _LevelSettingsSheet extends StatelessWidget {
  final LevelController controller;
  const _LevelSettingsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
            final pose = controller.mode == TiltMode.flat ? 'düz' : 'dik';
            final String calStatus;
            if (cal.normal != null && cal.flipped == null) {
              calStatus =
                  '1. okuma alındı. Şimdi telefonu aynı yerde 180° çevirip '
                  '2. okumayı alın.';
            } else if (cal.normal == null && cal.flipped != null) {
              calStatus = '2. okuma alındı; 1. okumayı da alın.';
            } else if (cal.normal != null && cal.flipped != null) {
              calStatus =
                  'Kalibrasyon tamam ve telefona kaydedildi ($pose duruş).';
            } else if (cal.restored != null) {
              calStatus =
                  'Kayıtlı kalibrasyon kullanılıyor ($pose duruş). Telefon '
                  'değiştiyse yeniden yapın.';
            } else {
              calStatus = 'Bu duruş ($pose) için kalibrasyon yapılmadı.';
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dört Yüzey Kalibrasyonu',
                  style: MenzilType.heading(c.ink, size: 20),
                ),
                const SizedBox(height: MenzilSpace.xxs),
                Text(
                  'Telefonu düz bir yere koyup 1. okumayı alın, aynı yerde 180° '
                  'çevirip 2. okumayı alın. Kamera çıkıntısının ve sensörün '
                  'sapması çıkarılır; düz ve dik duruş ayrı kalibre edilir.',
                  style: MenzilType.caption(c.ink2),
                ),
                const SizedBox(height: MenzilSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-normal'),
                        expand: true,
                        label: cal.normal == null ? '1. okuma' : '1. okuma ✓',
                        onPressed: hasReading
                            ? () =>
                                  controller.captureCalibration(flipped: false)
                            : null,
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.sm),
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-calibrate-flipped'),
                        expand: true,
                        label: cal.flipped == null
                            ? '2. okuma (180°)'
                            : '2. okuma ✓',
                        onPressed: hasReading
                            ? () => controller.captureCalibration(flipped: true)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MenzilSpace.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        calStatus,
                        key: const Key('level-calibration-status'),
                        style: MenzilType.caption(c.ink),
                      ),
                    ),
                    TextButton(
                      key: const Key('level-calibrate-clear-mode'),
                      onPressed:
                          cal.bias != null ||
                              cal.normal != null ||
                              cal.flipped != null
                          ? () => controller.clearCalibration(controller.mode)
                          : null,
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
                if (controller.calibrationSaveFailed)
                  const MenzilNotice(
                    tone: MenzilNoticeTone.warning,
                    message:
                        'Kalibrasyon telefona kaydedilemedi; bu oturumda '
                        'kullanılıyor ama uygulama kapanınca silinir.',
                  ),
                const SizedBox(height: MenzilSpace.md),
                Text('Geçici referans', style: MenzilType.label(c.ink2)),
                const SizedBox(height: MenzilSpace.xs),
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        key: const Key('level-set-reference'),
                        expand: true,
                        label: 'Referansı bu konuma ayarla',
                        icon: Icons.my_location_outlined,
                        onPressed: controller.hasReading
                            ? controller.setReferenceHere
                            : null,
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
                if (controller.hasOffset) ...[
                  const SizedBox(height: MenzilSpace.sm),
                  const MenzilNotice(
                    tone: MenzilNoticeTone.info,
                    message:
                        'Referans ayarı etkin: değerler ayarlanan konuma göredir; '
                        'bu sensör kalibrasyonu değildir.',
                  ),
                ],
                const SizedBox(height: MenzilSpace.lg),
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
                const SizedBox(height: MenzilSpace.lg),
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
          },
        ),
      ),
    );
  }
}

/// Round dark control button of the bottom bar.
class _RoundButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _RoundButton({
    super.key,
    required this.size,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Tooltip(
          message: label,
          child: Material(
            color: c.levelControl,
            shape: CircleBorder(
              side: BorderSide(color: c.levelBezel, width: 2),
            ),
            elevation: 4,
            shadowColor: c.levelBezel,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Icon(icon, color: c.levelControlInk, size: size * 0.46),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal (X) vial on top, vertical (Y) vial on the left and the round
/// bullseye vial, all driven by the same two angles and updated together.
///
/// X = asin(gx/|g|), Y = asin(gy/|g|): the circle reads both axes when the
/// phone lies flat, the horizontal tube X when it stands on its long edge,
/// the vertical tube Y when it stands on its short edge. The LIQUID of all
/// three is the only green in the app ([MenzilColors.levelLiquid]); its
/// lighter and darker shades are mixed from that token, never added.
/// The on-device bubble sign convention is NOT verified without a physical iPhone.
class _VialCluster extends StatelessWidget {
  final TiltAngles angles;
  final LevelViewType viewType;
  const _VialCluster({required this.angles, this.viewType = LevelViewType.all});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = math.min(constraints.maxWidth, 460.0);
        final maxH = constraints.maxHeight;
        switch (viewType) {
          case LevelViewType.torpedo:
            // Single bar vial, carpenter's/torpedo-level style.
            final h = math.min(maxW * 0.24, maxH);
            return Center(
              child: SizedBox(
                key: const Key('level-tube-x'),
                width: maxW,
                height: h,
                child: CustomPaint(
                  painter: _TubePainter(
                    vertical: false,
                    deg: angles.xDeg,
                    colors: c,
                  ),
                ),
              ),
            );
          case LevelViewType.bullseye:
            // Single circular vial, mason's-level style.
            final d = math.min(maxW, maxH);
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
            // A square cluster: tube thickness t, gap g, circle d, with
            // t + g + d equal to the side in both directions.
            final side = math.min(maxW, maxH);
            final t = (side * 0.19).clamp(36.0, 96.0).toDouble();
            final g = (side * 0.035).clamp(6.0, 16.0).toDouble();
            final d = side - t - g;
            return Center(
              child: SizedBox.square(
                dimension: side,
                child: Column(
                  children: [
                    SizedBox(
                      key: const Key('level-tube-x'),
                      width: side,
                      height: t,
                      child: CustomPaint(
                        painter: _TubePainter(
                          vertical: false,
                          deg: angles.xDeg,
                          colors: c,
                        ),
                      ),
                    ),
                    SizedBox(height: g),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          key: const Key('level-tube-y'),
                          width: t,
                          height: d,
                          child: CustomPaint(
                            painter: _TubePainter(
                              vertical: true,
                              deg: angles.yDeg,
                              colors: c,
                            ),
                          ),
                        ),
                        SizedBox(width: g),
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

/// Shades of the single liquid token: a yellow-white top light, the liquid
/// itself and a dark lower edge, as in a lit glass vial.
Color _liquidLight(MenzilColors c) =>
    Color.lerp(Color.lerp(c.levelLiquid, c.amber, 0.35)!, c.levelGlare, 0.35)!;
Color _liquidDeep(MenzilColors c) =>
    Color.lerp(c.levelLiquid, c.levelBezel, 0.55)!;

/// Concrete backdrop: a lit centre fading to the edges plus a fixed speckle
/// pattern (deterministic, so it never shimmers between frames).
class _BackdropPainter extends CustomPainter {
  final MenzilColors colors;
  const _BackdropPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [colors.levelBackdrop, colors.levelBackdropDeep],
        ).createShader(rect),
    );
    var seed = 0x2545F491;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final count = math.min(1600, (size.width * size.height / 160).round());
    final light = Paint()..color = colors.levelGlare.withValues(alpha: 0.06);
    final dark = Paint()..color = colors.levelBezel.withValues(alpha: 0.14);
    for (var i = 0; i < count; i++) {
      final p = Offset(next() * size.width, next() * size.height);
      final r = 0.4 + next() * 1.3;
      canvas.drawCircle(p, r, next() < 0.5 ? light : dark);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.colors != colors;
}

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
    final len = vertical ? size.height : size.width;
    final thick = vertical ? size.width : size.height;
    final frame = thick * 0.08;

    // Black frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(frame)),
      Paint()..color = colors.levelBezel,
    );
    final inner = Rect.fromLTWH(
      frame,
      frame,
      size.width - 2 * frame,
      size.height - 2 * frame,
    );
    final innerR = RRect.fromRectAndRadius(inner, Radius.circular(frame * 0.6));
    canvas.save();
    canvas.clipRRect(innerR);

    // Liquid: light along the "top" edge (left edge for the vertical tube),
    // deep and dark along the opposite edge.
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: vertical ? Alignment.centerLeft : Alignment.topCenter,
          end: vertical ? Alignment.centerRight : Alignment.bottomCenter,
          colors: [
            Color.lerp(_liquidLight(colors), colors.levelGlare, 0.55)!,
            _liquidLight(colors),
            colors.levelLiquid,
            _liquidDeep(colors),
            colors.levelBezel,
          ],
          stops: const [0.0, 0.22, 0.6, 0.86, 1.0],
        ).createShader(inner),
    );

    Offset at(double along, double across) =>
        vertical ? Offset(across, along) : Offset(along, across);
    Rect span(double a0, double a1, double c0, double c1) =>
        Rect.fromPoints(at(a0, c0), at(a1, c1));

    // Glass glare: a soft band near the start and a curved shine at the end.
    canvas.drawRect(
      span(len * 0.12, len * 0.30, frame, thick * 0.55),
      Paint()..color = colors.levelGlare.withValues(alpha: 0.10),
    );
    final shine = Path();
    final e = len - frame;
    shine
      ..moveTo(at(e - len * 0.02, frame).dx, at(e - len * 0.02, frame).dy)
      ..quadraticBezierTo(
        at(e - len * 0.02, thick * 0.7).dx,
        at(e - len * 0.02, thick * 0.7).dy,
        at(e - len * 0.07, thick - frame).dx,
        at(e - len * 0.07, thick - frame).dy,
      )
      ..lineTo(
        at(e - len * 0.05, thick - frame).dx,
        at(e - len * 0.05, thick - frame).dy,
      )
      ..quadraticBezierTo(
        at(e - len * 0.005, thick * 0.7).dx,
        at(e - len * 0.005, thick * 0.7).dy,
        at(e - len * 0.005, frame).dx,
        at(e - len * 0.005, frame).dy,
      )
      ..close();
    canvas.drawPath(
      shine,
      Paint()..color = colors.levelGlare.withValues(alpha: 0.35),
    );

    // Bubble: a lens floating against the light edge, moving along the tube.
    final bubbleLen = len * 0.13;
    final bubbleThick = thick * 0.42;
    final k = len * 0.06; // px per degree
    final maxOff = len / 2 - bubbleLen / 2 - frame;
    final off = ((vertical ? -deg : deg) * k).clamp(-maxOff, maxOff).toDouble();
    final along = len / 2 + off;
    final bubble = span(
      along - bubbleLen / 2,
      along + bubbleLen / 2,
      frame - bubbleThick * 0.42,
      frame + bubbleThick * 0.58,
    );
    canvas.drawOval(
      bubble,
      Paint()
        ..shader = LinearGradient(
          begin: vertical ? Alignment.centerRight : Alignment.bottomCenter,
          end: vertical ? Alignment.centerLeft : Alignment.topCenter,
          colors: [
            Color.lerp(colors.levelLiquid, colors.levelGlare, 0.25)!,
            Color.lerp(_liquidLight(colors), colors.levelGlare, 0.6)!,
          ],
        ).createShader(bubble),
    );
    canvas.drawOval(
      bubble,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _liquidDeep(colors),
    );
    canvas.restore();

    // Centre zone: two black bars across the tube.
    final bar = Paint()..color = colors.levelBezel;
    final barW = math.max(4.0, thick * 0.1);
    for (final sign in const [-1.0, 1.0]) {
      final a = len / 2 + sign * len * 0.255;
      canvas.drawRect(span(a - barW / 2, a + barW / 2, 0, thick), bar);
    }
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
    final r = size.shortestSide / 2;
    final ri = r * 0.86;

    // Bezel with a faint lit rim.
    canvas.drawCircle(centre, r, Paint()..color = colors.levelBezel);
    canvas.drawCircle(
      centre,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.levelGlare.withValues(alpha: 0.08),
    );

    final disc = Rect.fromCircle(center: centre, radius: ri);
    canvas.save();
    canvas.clipPath(Path()..addOval(disc));

    // Glossy liquid sphere lit from the upper left.
    canvas.drawCircle(
      centre,
      ri,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            Color.lerp(_liquidLight(colors), colors.levelGlare, 0.45)!,
            _liquidLight(colors),
            colors.levelLiquid,
            Color.lerp(colors.levelLiquid, colors.levelBezel, 0.3)!,
          ],
          stops: const [0.0, 0.3, 0.75, 1.0],
        ).createShader(disc),
    );
    // Glass reflections: a broad dome highlight and swirl bands.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre + Offset(ri * 0.05, -ri * 0.38),
        width: ri * 1.25,
        height: ri * 0.85,
      ),
      Paint()..color = colors.levelGlare.withValues(alpha: 0.13),
    );
    final swirl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ri * 0.06
      ..color = colors.levelGlare.withValues(alpha: 0.08);
    for (final f in const [0.55, 0.75, 0.95]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: centre + Offset(ri * 0.25, ri * 0.15),
          radius: ri * f,
        ),
        math.pi * 0.9,
        math.pi * 0.7,
        false,
        swirl,
      );
    }
    canvas.drawCircle(
      centre + Offset(-ri * 0.18, -ri * 0.32),
      ri * 0.09,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                colors.levelGlare.withValues(alpha: 0.9),
                colors.levelGlare.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: centre + Offset(-ri * 0.18, -ri * 0.32),
                radius: ri * 0.09,
              ),
            ),
    );

    // Dotted crosshair through the centre.
    final dotted = Paint()
      ..strokeWidth = 1.2
      ..color = colors.levelBezel.withValues(alpha: 0.7);
    _dotted(canvas, centre - Offset(ri, 0), centre + Offset(ri, 0), dotted);
    _dotted(canvas, centre - Offset(0, ri), centre + Offset(0, ri), dotted);

    // Bubble clamped inside the vial.
    final bubbleR = ri * 0.13;
    final k = size.shortestSide * 0.0746;
    var dx = angles.xDeg * k;
    var dy = -angles.yDeg * k;
    final dist = math.sqrt(dx * dx + dy * dy);
    final maxDist = ri - bubbleR - 2;
    if (dist > maxDist && dist > 0) {
      dx = dx / dist * maxDist;
      dy = dy / dist * maxDist;
    }
    final bubble = Offset(centre.dx + dx, centre.dy + dy);
    final bubbleRect = Rect.fromCircle(center: bubble, radius: bubbleR);
    canvas.drawCircle(
      bubble,
      bubbleR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Color.lerp(colors.levelLiquid, colors.levelGlare, 0.35)!,
            Color.lerp(colors.levelLiquid, colors.levelBezel, 0.2)!,
            Color.lerp(colors.levelLiquid, colors.levelBezel, 0.45)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(bubbleRect),
    );
    canvas.drawCircle(
      bubble + Offset(-bubbleR * 0.35, -bubbleR * 0.4),
      bubbleR * 0.22,
      Paint()..color = colors.levelGlare.withValues(alpha: 0.75),
    );
    canvas.restore();

    // Heavy ticks from the rim inward.
    final tick = Paint()
      ..strokeWidth = math.max(3.0, r * 0.025)
      ..color = colors.levelBezel;
    final tickLen = ri * 0.33;
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      canvas.drawLine(centre + d * ri, centre + d * (ri - tickLen), tick);
    }
  }

  void _dotted(Canvas canvas, Offset a, Offset b, Paint p) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var pos = 0.0; pos < total; pos += 5) {
      canvas.drawLine(a + dir * pos, a + dir * math.min(pos + 1.6, total), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) =>
      old.angles.xDeg != angles.xDeg ||
      old.angles.yDeg != angles.yDeg ||
      old.colors != colors;
}
