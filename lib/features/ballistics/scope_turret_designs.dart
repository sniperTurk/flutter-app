part of 'scope_dial_view.dart';

// Kule tasarım seçenekleri (owner, 2026-10-17 21:17: "Bu tasarımları sen
// görev aç, 5 tane hazırlasın, tasarım eklentisi").
//
// DESIGN-ONLY. The shipped app never builds a [TurretStyleScope], so
// [TurretStyleScope.designOf] is null and the turrets are drawn exactly as
// before. Only the design screenshots (integration_test/
// kule_secenekleri_screens_test.dart) and their widget test wrap the app in
// a scope to draw one of the five options with the real turret widgets.
//
// Hard rules shared by every option (owner, 2026-10-17 21:07–21:16):
// - top and side turret are the same size; the side one is the top one
//   turned 90°;
// - the step arrows sit inside the drum, at its ends, in end caps of at
//   least 44 × 44 pt; the scale is clipped to the window between the caps,
//   so an arrow never covers a value or a label;
// - everything scales with the reticle (k = side / 334); the top turret
//   never grows into the "L-R" button, so on a narrow phone both turrets
//   shrink together and keep their shape.

/// Which turret look to draw. [current] is the shipped turret.
enum TurretStyle {
  current,
  secenek1,
  secenek2,
  secenek3,
  secenek4,
  secenek5;

  /// The option's design, null for the shipped turret.
  TurretDesign? get design => switch (this) {
    TurretStyle.current => null,
    TurretStyle.secenek1 => TurretDesign.secenek1,
    TurretStyle.secenek2 => TurretDesign.secenek2,
    TurretStyle.secenek3 => TurretDesign.secenek3,
    TurretStyle.secenek4 => TurretDesign.secenek4,
    TurretStyle.secenek5 => TurretDesign.secenek5,
  };
}

/// Design-only switch: draws the turrets below it in [style]. Not used by
/// the app.
class TurretStyleScope extends InheritedWidget {
  final TurretStyle style;

  const TurretStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  /// The design to draw, or null for the shipped turret.
  static TurretDesign? designOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TurretStyleScope>()
      ?.style
      .design;

  @override
  bool updateShouldNotify(TurretStyleScope old) => old.style != style;
}

/// How a step arrow looks inside its end cap.
enum TurretArrowLook {
  /// The shipped white chevron with a thin dark edge, no cap of its own.
  chevron,

  /// A small filled triangle behind a hairline divider.
  triangle,

  /// A raised key-like cap with a chevron on it.
  key,

  /// Knurled grip with a filled triangle on it.
  knurl,

  /// A ring with a chevron inside it.
  ring,
}

/// How the drum body is shaded.
enum TurretShading {
  /// The shipped gradient along the drum (surface2 → line → surface2).
  gradient,

  /// One flat tone with a hairline border.
  flat,

  /// A darker scale window sunk between raised end keys.
  recessed,

  /// Gunmetal cylinder: dark edges, a light band along the middle.
  metal,

  /// Navy body with a light scale window, like the scope's own field.
  lightWindow,
}

/// One turret design option. Lengths are design points on the 334 pt
/// reticle of a 390 pt phone; [TurretDesign.geometry] scales them.
class TurretDesign {
  final int number;
  final String name;

  /// Drum length and thickness (top turret: width × height).
  final double length, thickness;

  /// End cap length along the drum (the arrow's own cell).
  final double cap;
  final double radius;
  final TurretArrowLook arrow;
  final TurretShading shading;

  /// Size of the drum's numbers (top turret; the side one is 2 pt smaller).
  final double numberSize;

  /// Labelled ticks are at least this far apart, in pt.
  final double majorSpacing;

  /// A half-length tick halfway between labelled ticks.
  final bool midTicks;

  const TurretDesign({
    required this.number,
    required this.name,
    required this.length,
    required this.thickness,
    required this.cap,
    required this.radius,
    required this.arrow,
    required this.shading,
    required this.numberSize,
    required this.majorSpacing,
    this.midTicks = false,
  });

  /// 1 — the main session's draft: 230 × 72, chevrons inside.
  static const secenek1 = TurretDesign(
    number: 1,
    name: 'Taslak',
    length: 230,
    thickness: 72,
    cap: 40,
    radius: 12,
    arrow: TurretArrowLook.chevron,
    shading: TurretShading.gradient,
    numberSize: 15,
    majorSpacing: 44,
  );

  /// 2 — slim and long, filled triangles, denser labels.
  static const secenek2 = TurretDesign(
    number: 2,
    name: 'İnce',
    length: 230,
    thickness: 60,
    cap: 36,
    radius: 8,
    arrow: TurretArrowLook.triangle,
    shading: TurretShading.flat,
    numberSize: 12,
    majorSpacing: 36,
    midTicks: true,
  );

  /// 3 — short and thick, key-like end caps, large numbers.
  static const secenek3 = TurretDesign(
    number: 3,
    name: 'Tuşlu',
    length: 220,
    thickness: 80,
    cap: 46,
    radius: 16,
    arrow: TurretArrowLook.key,
    shading: TurretShading.recessed,
    numberSize: 17,
    majorSpacing: 54,
  );

  /// 4 — gunmetal cylinder, knurled grips at the ends.
  static const secenek4 = TurretDesign(
    number: 4,
    name: 'Metal',
    length: 226,
    thickness: 68,
    cap: 40,
    radius: 6,
    arrow: TurretArrowLook.knurl,
    shading: TurretShading.metal,
    numberSize: 14,
    majorSpacing: 44,
    midTicks: true,
  );

  /// 5 — light scale window in a navy body, ring buttons.
  static const secenek5 = TurretDesign(
    number: 5,
    name: 'Pencere',
    length: 216,
    thickness: 76,
    cap: 44,
    radius: 14,
    arrow: TurretArrowLook.ring,
    shading: TurretShading.lightWindow,
    numberSize: 15,
    majorSpacing: 44,
  );

  static const all = [secenek1, secenek2, secenek3, secenek4, secenek5];

  /// Smallest tap area of a step arrow (HDF-2).
  static const double minTap = 44;

  /// Drum size on a reticle of [side] pt in a turret row [rowWidth] pt
  /// wide. It scales with k = side / 334 and never reaches into the "L-R"
  /// slot (48 pt + 4 pt gap each side of the centred drum); the thickness
  /// never drops below [minTap], so the arrows stay 44 × 44 pt.
  ({double length, double thickness}) geometry(double side, double rowWidth) {
    const slot = _TurretBarState.slot + _TurretBarState.gap;
    final k = side / _TurretBarState.designSide;
    final s = math.max(0.0, math.min(k, (rowWidth - 2 * slot) / length));
    return (length: length * s, thickness: math.max(minTap, thickness * s));
  }

  /// End cap length for a drum drawn [drumLength] pt long.
  double capFor(double drumLength) =>
      math.max(minTap, cap * drumLength / length);

  /// Number and tick colour.
  Color ink(MenzilColors c) => switch (shading) {
    TurretShading.metal => c.drumInk,
    TurretShading.lightWindow => MenzilColors.light.scopeLine,
    _ => c.ink,
  };

  /// Secondary text (the U/D – unit header).
  Color ink2(MenzilColors c) => switch (shading) {
    TurretShading.metal => c.drumInk.withValues(alpha: 0.75),
    TurretShading.lightWindow => MenzilColors.light.ink2,
    _ => c.ink2,
  };

  /// The red index mark.
  Color index(MenzilColors c) => shading == TurretShading.lightWindow
      ? MenzilColors.light.danger
      : c.danger;

  /// The drum body (caps and window together).
  BoxDecoration shell(MenzilColors c, Axis axis, double r) {
    final horizontal = axis == Axis.horizontal;
    final along = (
      horizontal ? Alignment.centerLeft : Alignment.topCenter,
      horizontal ? Alignment.centerRight : Alignment.bottomCenter,
    );
    final across = (
      horizontal ? Alignment.topCenter : Alignment.centerLeft,
      horizontal ? Alignment.bottomCenter : Alignment.centerRight,
    );
    final radius = BorderRadius.circular(r);
    return switch (shading) {
      TurretShading.gradient => BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.line),
        gradient: LinearGradient(
          begin: along.$1,
          end: along.$2,
          colors: [c.surface2, c.line, c.surface2],
        ),
      ),
      TurretShading.flat => BoxDecoration(
        borderRadius: radius,
        color: c.surface2,
        border: Border.all(color: c.line),
      ),
      TurretShading.recessed => BoxDecoration(
        borderRadius: radius,
        color: c.surface,
        border: Border.all(color: c.line),
      ),
      TurretShading.metal => BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.drumDark),
        gradient: LinearGradient(
          begin: across.$1,
          end: across.$2,
          // A darker highlight than drumLight keeps the light numbers
          // readable on the middle band.
          colors: [
            c.drumDark,
            Color.lerp(c.drumDark, c.drumLight, 0.55)!,
            c.drumDark,
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      TurretShading.lightWindow => BoxDecoration(
        borderRadius: radius,
        color: c.surface,
        border: Border.all(color: c.line),
      ),
    };
  }
}

extension _TurretBarDesign on _TurretBarState {
  /// The turret row and reticle for a design option: the top drum centred
  /// over the reticle's vertical line, "L-R" at the row's right end, and the
  /// side drum (same size, turned 90°) on the reticle's right edge,
  /// vertically centred on its horizontal line.
  Widget designBuild(BuildContext context, TurretDesign design) {
    final c = MenzilColors.of(context);
    final side = widget.side;
    return LayoutBuilder(
      builder: (context, box) {
        final g = design.geometry(side, box.maxWidth);
        final rowHeight = math.max(g.thickness, _TurretBarState.slot);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: rowHeight,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: g.length,
                      height: g.thickness,
                      child: widget.elevation,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: (rowHeight - _TurretBarState.slot) / 2,
                    child: toggle(c),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MenzilSpace.xs),
            Center(
              child: SizedBox.square(
                dimension: side,
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.reticle),
                    Positioned(
                      right: 0,
                      top: (side - g.length) / 2,
                      width: g.thickness,
                      height: g.length,
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              SlideTransition(
                                position: Tween(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                          child: _windage
                              ? KeyedSubtree(
                                  key: const ValueKey('windage-open'),
                                  child: widget.windage,
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('windage-closed'),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension _TurretDrumDesign on _TurretDrumState {
  /// The drum of a design option: [cap | window | cap] along the drum. The
  /// caps are the step arrows (tap only); the window drags exactly like the
  /// shipped drum and is the only place the scale is drawn.
  Widget designBody(
    BuildContext context,
    TurretDesign design, {
    required String upLabel,
    required String downLabel,
  }) {
    final c = MenzilColors.of(context);
    final horizontal = widget.axis == Axis.horizontal;
    return LayoutBuilder(
      builder: (context, box) {
        final length = horizontal ? box.maxWidth : box.maxHeight;
        final cap = design.capFor(length);
        final r = design.radius * length / design.length;

        Widget capCell(int delta) {
          final AxisDirection direction = horizontal
              ? (delta > 0 ? AxisDirection.left : AxisDirection.right)
              : (delta > 0 ? AxisDirection.up : AxisDirection.down);
          final cell = Tooltip(
            message: delta > 0 ? upLabel : downLabel,
            excludeFromSemantics: true,
            child: GestureDetector(
              key: ValueKey(
                '${widget.semanticName}-cap-${delta > 0 ? 'plus' : 'minus'}',
              ),
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () => _set(_value + delta),
              child: CustomPaint(
                key: ValueKey(
                  '${widget.semanticName}-step-${delta > 0 ? 'plus' : 'minus'}',
                ),
                painter: _TurretCapPainter(
                  design: design,
                  colors: c,
                  axis: widget.axis,
                  direction: direction,
                  start: delta > 0,
                  letter: horizontal
                      ? null
                      : (delta > 0
                            ? widget.positiveLetter
                            : widget.negativeLetter),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
          return horizontal
              ? SizedBox(width: cap, child: cell)
              : SizedBox(height: cap, child: cell);
        }

        final window = GestureDetector(
          key: horizontal ? null : ScopeDialKeys.windageDrumBox,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: horizontal ? (_) => _carry = 0 : null,
          onHorizontalDragUpdate: horizontal ? (d) => _drag(d.delta.dx) : null,
          onVerticalDragStart: horizontal ? null : (_) => _carry = 0,
          onVerticalDragUpdate: horizontal ? null : (d) => _drag(d.delta.dy),
          child: CustomPaint(
            painter: _DesignDrumPainter(
              design: design,
              colors: c,
              axis: widget.axis,
              clicks: _value,
              clickValue: widget.clickValue,
              unitLabel: widget.unitLabel,
              positiveLetter: widget.positiveLetter,
              negativeLetter: widget.negativeLetter,
              pixelsPerClick: _TurretDrumState.pixelsPerClick,
            ),
            child: const SizedBox.expand(),
          ),
        );

        return DecoratedBox(
          decoration: design.shell(c, widget.axis, r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: Flex(
              direction: widget.axis,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                capCell(1),
                Expanded(child: window),
                capCell(-1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One end cap of a design drum: its own background (per option) and the
/// step arrow centred in it.
class _TurretCapPainter extends CustomPainter {
  final TurretDesign design;
  final MenzilColors colors;
  final Axis axis;
  final AxisDirection direction;

  /// True for the cap at the drum's start (left / top).
  final bool start;

  /// The side drum's direction letter (R / L), drawn beside the arrow so
  /// the scale window keeps its full length; null on the top drum, whose
  /// U / D letters are in the window's header.
  final String? letter;

  const _TurretCapPainter({
    required this.design,
    required this.colors,
    required this.axis,
    required this.direction,
    required this.start,
    this.letter,
  });

  bool get _horizontal => axis == Axis.horizontal;

  /// Thickness of the drum (across it).
  double _across(Size s) => _horizontal ? s.height : s.width;

  /// Hairline between the cap and the window.
  void _divider(Canvas canvas, Size size, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    final inset = _across(size) * 0.18;
    if (_horizontal) {
      final x = start ? size.width - 0.5 : 0.5;
      canvas.drawLine(Offset(x, inset), Offset(x, size.height - inset), p);
    } else {
      final y = start ? size.height - 0.5 : 0.5;
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), p);
    }
  }

  /// Filled triangle pointing in [direction], [w] pt across its base.
  Path _triangle(Offset c, double w) {
    final h = w * 0.62;
    return switch (direction) {
      AxisDirection.left =>
        Path()
          ..moveTo(c.dx - h / 2, c.dy)
          ..lineTo(c.dx + h / 2, c.dy - w / 2)
          ..lineTo(c.dx + h / 2, c.dy + w / 2)
          ..close(),
      AxisDirection.right =>
        Path()
          ..moveTo(c.dx + h / 2, c.dy)
          ..lineTo(c.dx - h / 2, c.dy - w / 2)
          ..lineTo(c.dx - h / 2, c.dy + w / 2)
          ..close(),
      AxisDirection.up =>
        Path()
          ..moveTo(c.dx, c.dy - h / 2)
          ..lineTo(c.dx - w / 2, c.dy + h / 2)
          ..lineTo(c.dx + w / 2, c.dy + h / 2)
          ..close(),
      AxisDirection.down =>
        Path()
          ..moveTo(c.dx, c.dy + h / 2)
          ..lineTo(c.dx - w / 2, c.dy - h / 2)
          ..lineTo(c.dx + w / 2, c.dy - h / 2)
          ..close(),
    };
  }

  /// Open chevron pointing in [direction], [w] pt across.
  Path _chevron(Offset c, double w) {
    final h = w / 2;
    return switch (direction) {
      AxisDirection.left =>
        Path()
          ..moveTo(c.dx + h / 2, c.dy - w / 2)
          ..lineTo(c.dx - h / 2, c.dy)
          ..lineTo(c.dx + h / 2, c.dy + w / 2),
      AxisDirection.right =>
        Path()
          ..moveTo(c.dx - h / 2, c.dy - w / 2)
          ..lineTo(c.dx + h / 2, c.dy)
          ..lineTo(c.dx - h / 2, c.dy + w / 2),
      AxisDirection.up =>
        Path()
          ..moveTo(c.dx - w / 2, c.dy + h / 2)
          ..lineTo(c.dx, c.dy - h / 2)
          ..lineTo(c.dx + w / 2, c.dy + h / 2),
      AxisDirection.down =>
        Path()
          ..moveTo(c.dx - w / 2, c.dy - h / 2)
          ..lineTo(c.dx, c.dy + h / 2)
          ..lineTo(c.dx + w / 2, c.dy - h / 2),
    };
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final letter = this.letter;
    // With a letter the arrow moves left of centre and the letter sits on
    // its right, both inside the cap.
    final centre = letter == null
        ? size.center(Offset.zero)
        : Offset(size.width * 0.38, size.height / 2);
    final small = letter == null
        ? math.min(size.width, size.height)
        : math.min(size.height, size.width * 0.6);
    final across = letter == null ? _across(size) : small;
    switch (design.arrow) {
      case TurretArrowLook.chevron:
        // The shipped chevron, as drawn beside the drum today.
        final glyph = Size.square(math.min(24.0, small * 0.6));
        canvas.save();
        canvas.translate(
          centre.dx - glyph.width / 2,
          centre.dy - glyph.height / 2,
        );
        TurretChevronPainter(direction).paint(canvas, glyph);
        canvas.restore();
      case TurretArrowLook.triangle:
        _divider(canvas, size, c.line);
        canvas.drawPath(
          _triangle(centre, math.min(16.0, across * 0.3)),
          Paint()..color = c.ink,
        );
      case TurretArrowLook.key:
        // A raised key: lighter top face, darker lower edge, inset 4 pt.
        final face = RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(4),
          Radius.circular(design.radius * 0.6),
        );
        canvas.drawRRect(
          face,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.line, c.surface2],
            ).createShader(face.outerRect),
        );
        canvas.drawRRect(face, _stroke(c.ink2.withValues(alpha: 0.45), 1));
        canvas.drawPath(
          _chevron(centre, math.min(16.0, small * 0.36)),
          _stroke(c.ink, 2.6),
        );
      case TurretArrowLook.knurl:
        // Fine grip lines across the drum, then a filled triangle with a
        // dark edge on top.
        final grip = Paint()..strokeWidth = 1;
        for (
          var t = 3.0;
          t < (_horizontal ? size.width : size.height);
          t += 3
        ) {
          grip.color = (t ~/ 3).isEven
              ? c.drumLight.withValues(alpha: 0.55)
              : c.drumDark.withValues(alpha: 0.8);
          if (_horizontal) {
            canvas.drawLine(Offset(t, 0), Offset(t, size.height), grip);
          } else {
            canvas.drawLine(Offset(0, t), Offset(size.width, t), grip);
          }
        }
        _divider(canvas, size, c.drumDark);
        final tri = _triangle(centre, math.min(18.0, across * 0.32));
        canvas
          ..drawPath(tri, _stroke(c.drumDark, 3))
          ..drawPath(tri, Paint()..color = c.drumInk);
      case TurretArrowLook.ring:
        final r = math.min(17.0, small * 0.4);
        canvas.drawCircle(centre, r, Paint()..color = c.surface2);
        canvas.drawCircle(centre, r, _stroke(c.ink2, 1.5));
        canvas.drawPath(_chevron(centre, r * 0.9), _stroke(c.ink, 2.2));
    }
    if (letter != null) {
      final ink = switch (design.shading) {
        TurretShading.metal => c.drumInk,
        _ => c.ink,
      };
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            fontFamily: MenzilType.familyFor(13),
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          size.width * 0.76 - tp.width / 2,
          size.height / 2 - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TurretCapPainter old) =>
      old.design != design ||
      old.colors != colors ||
      old.direction != direction ||
      old.axis != axis ||
      old.letter != letter;
}

/// The scale window of a design drum: ticks, numbers, the U/D – unit header
/// (top drum) and the red index mark.
/// Same information as the shipped [_DrumPainter], drawn only inside the
/// window, so the end caps never cover any of it.
class _DesignDrumPainter extends CustomPainter {
  final TurretDesign design;
  final MenzilColors colors;
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final String positiveLetter, negativeLetter;
  final double pixelsPerClick;

  const _DesignDrumPainter({
    required this.design,
    required this.colors,
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.pixelsPerClick,
  });

  /// Clicks between labelled ticks: a whole number of units, at least
  /// [TurretDesign.majorSpacing] pt apart. In a short window (a narrow
  /// phone) the spacing drops to what still leaves one whole label in view
  /// wherever the drum stands: at most [length] − [label] pt, never under
  /// [label] pt, so labels do not run into each other.
  int _major(double length, double label) {
    final perUnit = math.max(1, (1 / clickValue).round());
    final steps = [
      for (final units in const [1, 2, 5, 10, 20, 50, 100]) perUnit * units,
    ];
    final wanted = steps.firstWhere(
      (n) => n * pixelsPerClick >= design.majorSpacing,
      orElse: () => steps.last,
    );
    if (wanted * pixelsPerClick <= length - label) return wanted;
    // Half units (0,5 mrad) only as a fallback for short windows.
    final fallback = [
      if (perUnit.isEven && perUnit > 1) perUnit ~/ 2,
      ...steps,
    ];
    final fitting = fallback.where(
      (n) =>
          n * pixelsPerClick <= length - label && n * pixelsPerClick >= label,
    );
    return fitting.isEmpty ? wanted : fitting.last;
  }

  /// Draws [s] centred on [center]; shrinks it to [maxWidth] if needed.
  /// With [within], a label that would not fit whole inside it is left out,
  /// so the window never shows a number cut in half at its ends.
  void _text(
    Canvas canvas,
    String s,
    Offset center,
    Color color,
    double size, {
    double? maxWidth,
    Rect? within,
    FontWeight weight = FontWeight.w600,
  }) {
    TextPainter layout(double fontSize) => TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: MenzilType.familyFor(fontSize),
          fontFeatures: MenzilType.tabular,
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var tp = layout(size);
    if (maxWidth != null && tp.width > maxWidth && tp.width > 0) {
      tp = layout(size * maxWidth / tp.width);
    }
    final topLeft = center - Offset(tp.width / 2, tp.height / 2);
    if (within != null) {
      final r = topLeft & Size(tp.width, tp.height);
      final fits =
          r.left >= within.left &&
          r.top >= within.top &&
          r.right <= within.right &&
          r.bottom <= within.bottom;
      if (!fits) return;
    }
    tp.paint(canvas, topLeft);
  }

  String _letter(int v) =>
      v == 0 ? '' : (v > 0 ? positiveLetter : negativeLetter);

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = axis == Axis.horizontal;
    var rect = Offset.zero & size;
    final c = colors;

    // Window background.
    switch (design.shading) {
      case TurretShading.recessed:
        canvas.drawRect(rect, Paint()..color = c.bg);
        // Inner shade along both long edges: the window sits lower.
        final shade = horizontal
            ? [Alignment.topCenter, Alignment.bottomCenter]
            : [Alignment.centerLeft, Alignment.centerRight];
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: shade[0],
              end: shade[1],
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.25),
              ],
              stops: const [0, 0.18, 0.82, 1],
            ).createShader(rect),
        );
      case TurretShading.lightWindow:
        rect = rect.deflate(5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()..color = MenzilColors.scopeBgDim,
        );
      case TurretShading.gradient:
      case TurretShading.flat:
      case TurretShading.metal:
        break;
    }

    final ink = design.ink(c);
    final length = horizontal ? rect.width : rect.height;
    final across = horizontal ? rect.height : rect.width;
    final mid = length / 2;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(design.shading == TurretShading.lightWindow ? 8 : 0),
      ),
    );
    canvas.translate(rect.left, rect.top);

    final tick = Paint()
      ..color = ink
      ..strokeWidth = 1.2;
    final reach = (mid / pixelsPerClick).ceil() + 1;
    // Room a label needs along the drum (width on the top drum, height on
    // the side one), with a small margin.
    final major = _major(length, horizontal ? 34 : 24);
    final numberSize = horizontal ? design.numberSize : design.numberSize - 2;
    for (var v = clicks - reach; v <= clicks + reach; v++) {
      // Values above the current setting sit before the pointer, so dragging
      // toward the pointer increases the setting (as the shipped drum).
      final p = mid - (v - clicks) * pixelsPerClick;
      final isMajor = v % major == 0;
      final isMid = design.midTicks && !isMajor && v % major == major ~/ 2;
      final len = across * (isMajor ? 0.30 : (isMid ? 0.22 : 0.15));
      if (horizontal) {
        canvas.drawLine(Offset(p, across), Offset(p, across - len), tick);
      } else {
        canvas.drawLine(Offset(0, p), Offset(len, p), tick);
      }
      if (isMajor) {
        final text =
            '${ScopeDialView._trim((v * clickValue).abs())}'
            '${_letter(v)}';
        _text(
          canvas,
          text,
          horizontal ? Offset(p, across * 0.47) : Offset(across * 0.62, p),
          ink,
          numberSize,
          within: Rect.fromLTWH(
            0,
            0,
            horizontal ? length : across,
            horizontal ? across : length,
          ).deflate(1),
        );
      }
    }

    // Header of the top drum. The side drum's R / L letters are in its
    // end caps, beside the arrows.
    if (horizontal) {
      _text(
        canvas,
        '← $positiveLetter   $unitLabel   $negativeLetter →',
        Offset(mid, across * 0.15),
        design.ink2(c),
        10,
        maxWidth: length - 6,
      );
    }
    canvas.restore();

    // Fixed red index mark, on the window's centre line.
    final pointer = Paint()..color = design.index(c);
    final path = Path();
    if (horizontal) {
      final b = rect.bottom, x = rect.left + mid;
      path
        ..moveTo(x - 7, b)
        ..lineTo(x + 7, b)
        ..lineTo(x, b - 11)
        ..close();
    } else {
      final y = rect.top + mid;
      final l = rect.left + SideTurretPointer.inset;
      path
        ..moveTo(l, y - SideTurretPointer.height / 2)
        ..lineTo(l, y + SideTurretPointer.height / 2)
        ..lineTo(l + SideTurretPointer.depth, y)
        ..close();
    }
    canvas.drawPath(path, pointer);
  }

  @override
  bool shouldRepaint(covariant _DesignDrumPainter old) =>
      old.clicks != clicks ||
      old.clickValue != clickValue ||
      old.colors != colors ||
      old.unitLabel != unitLabel ||
      old.design != design;
}
