part of 'scope_dial_view.dart';

// Kuleler: üst (yükseklik) kule, yan (rüzgâr) kule, L-R düğmesi ve
// "Kuleleri kur" | "Kuleleri sıfırla" satırı.
//
// Modül ayrımı (owner, 2026-10-15): scope_dial_view.dart'tan aynen
// taşındı.

extension _ScopeTurretButtons on ScopeDialView {
  /// "Kuleleri kur" | "Kuleleri sıfırla" under the scope, one line each.
  Widget _turretButtons() {
    final req = requiredUp;
    return Builder(
      builder: (context) {
        // Owner, 2026-10-10: the button of the turrets' current state
        // turns orange — the solution dialled, or both at zero.
        final rawElev = req == null
            ? null
            : ScopeDialMath.clicksFor(req, clickValue);
        final rawWind = ScopeDialMath.clicksFor(requiredRight, clickValue);
        final solElev = rawElev
            ?.clamp(-_downClicks, maxElevationClicks)
            .toInt();
        final solWind = rawWind
            .clamp(-maxWindageClicks, maxWindageClicks)
            .toInt();
        // The turrets hold what the button dials (owner, 2026-10-11:
        // pressing it must turn it orange). When the solution is
        // beyond the turret travel the button dials the limit and
        // says so; the warning below names the missing clicks.
        final dialled =
            solElev != null &&
            elevationClicks == solElev &&
            windageClicks == solWind;
        final atLimit = dialled && (solElev != rawElev || solWind != rawWind);
        final atZero = elevationClicks == 0 && windageClicks == 0;
        // Owner, 2026-10-11: at the zero distance the solution is 0
        // clicks, so both states would be true at once. Only the
        // turrets' button turns orange; the solution button says
        // nothing needs dialling.
        final noClicks = dialled && !atLimit && atZero;
        return Row(
          children: [
            Expanded(
              child: MenzilSecondaryButton(
                key: ScopeDialKeys.dialSolution,
                label: noClicks
                    ? 'Çözüm: 0 klik'
                    : !dialled
                    // Owner, 2026-10-15: "Kuleleri kur" | "Kuleleri sıfırla" on
                    // one line; the label never wraps (it shrinks instead).
                    ? 'Kuleleri kur'
                    : atLimit
                    ? 'Kule sınırına kuruldu'
                    : 'Çözüm kulelere kuruldu',
                expand: true,
                twoLines: true,
                active: dialled && !noClicks,
                onPressed: req == null || (dialled && !atLimit)
                    ? null
                    : () {
                        onElevationChanged(solElev!);
                        onWindageChanged(solWind);
                        onSolutionDialed?.call();
                      },
              ),
            ),
            const SizedBox(width: MenzilSpace.sm),
            Expanded(
              // Owner, 2026-10-11: opening the page must not show
              // either button selected; the reset button turns
              // orange only after the user presses it.
              child: _ResetTurretsButton(
                atZero: atZero,
                noClicks: noClicks,
                onReset: () {
                  onElevationChanged(0);
                  onWindageChanged(0);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Turret size (owner, 2026-10-18 01:25): ChairGun's turret almost one to
/// one. Its drum is 199 × 60 pt on a 402 pt screen, so 194 × 58 pt on a
/// 390 pt phone. Both turrets are the same drum; the side one is the top one
/// turned 90°. The drum scales with the screen width but is never thinner
/// than [minThickness].
abstract final class ScopeTurretGeometry {
  static const double designScreenWidth = 390,
      designLength = 194,
      designThickness = 58,
      minThickness = 44;

  /// Each end of a drum holds a step chevron (owner, 2026-10-17 21:07: the
  /// step arrows are inside the drum). Its tap area is this long along the
  /// drum and as thick as the drum, clear of the three values.
  static const double arrowTap = 44;

  /// The darker trapezoid mount under the top drum: its height as a share
  /// of the drum's thickness, its top and bottom widths as shares of the
  /// drum's length.
  static const double mountHeightShare = 0.22,
      mountTopShare = 0.42,
      mountBottomShare = 0.58;

  /// Length × thickness of the drum on a [screenWidth] pt wide screen, as
  /// the top drum lies. The side drum is the same size, turned.
  static Size drum(double screenWidth) {
    final k = screenWidth / designScreenWidth;
    return Size(
      math.max(3 * arrowTap, designLength * k),
      math.max(minThickness, designThickness * k),
    );
  }

  static double mountHeight(double thickness) => thickness * mountHeightShare;

  /// Side drum: the values sit across its thickness between the ticks (on
  /// the left) and the unit column (on the right), centred at
  /// [sideValuesCentreShare].
  static const double sideValuesLeftShare = 0.27, sideValuesRightShare = 0.80;
  static const double sideValuesCentreShare =
      (sideValuesLeftShare + sideValuesRightShare) / 2;
}

/// Turrets around the scope, as in ChairGun: the elevation drum sits on top,
/// centred on the reticle's vertical line and joined to the scope by its
/// mount; "L-R" slides the windage drum in from the right, its right edge on
/// the reticle's right edge and its zero on the horizontal line. Tapping
/// "L-R" again slides it away, so the scope keeps the whole width.
class _TurretBar extends StatefulWidget {
  final Widget elevation, windage, reticle;
  final double side;

  /// A change opens the windage drum (after "Kuleleri kur").
  final int revealToken;
  const _TurretBar({
    required this.revealToken,
    required this.elevation,
    required this.windage,
    required this.reticle,
    required this.side,
  });

  @override
  State<_TurretBar> createState() => _TurretBarState();
}

class _TurretBarState extends State<_TurretBar> {
  bool _windage = false;

  /// The round L-R button at the right end of the top row, and the least
  /// room kept between it and the top drum.
  static const double toggleSize = 48, toggleGap = 4;

  @override
  void didUpdateWidget(covariant _TurretBar old) {
    super.didUpdateWidget(old);
    if (widget.revealToken != old.revealToken) _windage = true;
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final side = widget.side;
    final drum = ScopeTurretGeometry.drum(MediaQuery.sizeOf(context).width);
    final thickness = drum.height;
    final mount = ScopeTurretGeometry.mountHeight(thickness);
    return LayoutBuilder(
      builder: (context, box) {
        // Never longer than the reticle, nor into the L-R button (the top
        // drum is centred, so L-R's room is kept on both sides). Both
        // drums get the same length.
        final room = box.maxWidth - 2 * (toggleSize + toggleGap);
        final length = math.min(drum.width, math.min(side, room));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: thickness + mount,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: thickness,
                    height: mount,
                    child: CustomPaint(
                      painter: _TurretMountPainter(
                        topWidth: length * ScopeTurretGeometry.mountTopShare,
                        bottomWidth:
                            length * ScopeTurretGeometry.mountBottomShare,
                      ),
                    ),
                  ),
                  Positioned(
                    left: (box.maxWidth - length) / 2,
                    top: 0,
                    width: length,
                    height: thickness,
                    child: widget.elevation,
                  ),
                  Positioned(
                    right: 0,
                    top: math.max(0, (thickness - toggleSize) / 2),
                    width: toggleSize,
                    height: toggleSize,
                    child: Semantics(
                      button: true,
                      toggled: _windage,
                      label: _windage
                          ? 'Rüzgâr kulesini gizle'
                          : 'Rüzgâr kulesini göster',
                      child: ExcludeSemantics(
                        // A plain button like the others (owner,
                        // 2026-10-12): white on navy in Koyu, dark on light
                        // in Açık.
                        child: Material(
                          key: ScopeDialKeys.turretToggle,
                          color: c.surface,
                          shape: CircleBorder(side: BorderSide(color: c.line)),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _windage = !_windage),
                            child: Center(
                              child: Text(
                                'L-R',
                                style: TextStyle(
                                  color: c.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: SizedBox.square(
                dimension: side,
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.reticle),
                    // Windage drum: right edge on the reticle's right edge,
                    // vertically centred so its zero meets the horizontal
                    // line.
                    Positioned(
                      right: 0,
                      top: (side - length) / 2,
                      height: length,
                      width: thickness,
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

/// The top turret's darker trapezoid mount, centred, narrow under the drum
/// and wider where it meets the scope.
class _TurretMountPainter extends CustomPainter {
  final double topWidth, bottomWidth;

  const _TurretMountPainter({
    required this.topWidth,
    required this.bottomWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const d = MenzilColors.dark;
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx - topWidth / 2, 0)
      ..lineTo(cx + topWidth / 2, 0)
      ..lineTo(cx + bottomWidth / 2, size.height)
      ..lineTo(cx - bottomWidth / 2, size.height)
      ..close();
    final rect = Rect.fromLTWH(
      cx - bottomWidth / 2,
      0,
      bottomWidth,
      size.height,
    );
    final dark = Color.lerp(d.bg, Colors.black, 0.45)!;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, d.bg, dark],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TurretMountPainter old) =>
      old.topWidth != topWidth || old.bottomWidth != bottomWidth;
}

/// A turret drum that the user drags (or steps with its end chevrons) one
/// click at a time. Horizontal drum: dragging right dials UP. Vertical drum:
/// dragging down dials RIGHT — the markings on the drum move toward the
/// pointer the way a real turret's do.
class _TurretDrum extends StatefulWidget {
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final int maxClicks;

  /// Travel on the negative side; null = [maxClicks].
  final int? maxNegativeClicks;
  final String positiveLetter, negativeLetter;
  final String semanticName, positiveWord, negativeWord;
  final ValueChanged<int> onChanged;

  const _TurretDrum({
    super.key,
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.maxClicks,
    this.maxNegativeClicks,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.semanticName,
    required this.positiveWord,
    required this.negativeWord,
    required this.onChanged,
  });

  @override
  State<_TurretDrum> createState() => _TurretDrumState();
}

class _TurretDrumState extends State<_TurretDrum> {
  static const double pixelsPerClick = 9;
  double _carry = 0;

  /// The value last handed to [onChanged] that the parent has not built
  /// yet. Two drag updates may arrive before a rebuild; the click sound
  /// counts against this value so it never clicks for a step twice.
  int? _sent;

  @override
  void initState() {
    super.initState();
    // Loaded before the first click so it is not late (owner, 2026-10-15
    // 23:30: klik sesi).
    TurretClickSound.instance.preload();
  }

  @override
  void didUpdateWidget(covariant _TurretDrum old) {
    super.didUpdateWidget(old);
    _sent = null;
  }

  /// Every user step (arrow tap, drum drag, VoiceOver adjust) comes here;
  /// programmatic moves ("Kuleleri kur", "Kuleleri sıfırla", auto-set,
  /// profile change) reach the drum through [clicks] and never do. One
  /// click sound per click step actually turned (owner, 2026-10-15 23:30
  /// and 23:31); at the travel limit the turret stops and so do the clicks.
  void _set(int value) {
    final v = value
        .clamp(
          -(widget.maxNegativeClicks ?? widget.maxClicks),
          widget.maxClicks,
        )
        .toInt();
    final shown = _sent ?? widget.clicks;
    for (var i = (v - shown).abs(); i > 0; i--) {
      TurretClickSound.instance.click();
    }
    if (v != shown) {
      _sent = v;
      widget.onChanged(v);
    }
  }

  /// The drum's current value: the one last sent, else the parent's.
  /// Every user step builds on it (owner, 2026-10-16 20:42: "Dürbün
  /// kulelerinin klikleri çevirme hızı ile aynı değil"). A fast drag sends
  /// several updates before the parent rebuilds; counting from the stale
  /// [_TurretDrum.clicks] lost those steps (count and sound) while the
  /// finger's travel was already used up.
  int get _value => _sent ?? widget.clicks;

  /// Every [pixelsPerClick] of finger travel is one click. At the travel
  /// limit the travel beyond it is dropped, so turning back answers at once.
  void _drag(double delta) {
    final base = _value;
    final total = _carry + delta;
    final steps = (total / pixelsPerClick).truncate();
    _carry = total - steps * pixelsPerClick;
    final target = base + steps;
    if ((total > 0 && target >= widget.maxClicks) ||
        (total < 0 &&
            target <= -(widget.maxNegativeClicks ?? widget.maxClicks))) {
      _carry = 0;
    }
    if (steps != 0) _set(target);
  }

  String _valueText() {
    final angle = (widget.clicks * widget.clickValue)
        .abs()
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    if (widget.clicks == 0) return '${widget.semanticName} sıfırda';
    final word = widget.clicks > 0 ? widget.positiveWord : widget.negativeWord;
    return '${widget.clicks.abs()} klik $word, $angle ${widget.unitLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;

    // Drag handlers along the drum's own axis; the chevron areas use them
    // too, so a drag that starts on a chevron still turns the drum.
    Widget dragArea({VoidCallback? onTap, required Widget child}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: onTap,
          onHorizontalDragStart: horizontal ? (_) => _carry = 0 : null,
          onHorizontalDragUpdate: horizontal ? (d) => _drag(d.delta.dx) : null,
          onVerticalDragStart: horizontal ? null : (_) => _carry = 0,
          onVerticalDragUpdate: horizontal ? null : (d) => _drag(d.delta.dy),
          child: child,
        );

    final up = '${widget.semanticName} 1 klik ${widget.positiveWord}';
    final down = '${widget.semanticName} 1 klik ${widget.negativeWord}';

    final body = LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final length = horizontal ? size.width : size.height;
        final thickness = horizontal ? size.height : size.width;
        final tap = math.min(ScopeTurretGeometry.arrowTap, length / 3);
        final s = thickness / ScopeTurretGeometry.designThickness;
        final glyph = 14 * s;
        // Chevron centres: top drum ‹ left / › right on the values row;
        // side drum ^ top / v bottom in the values column, below "↑ R" and
        // above "L ↓".
        final Offset plusAt, minusAt;
        if (horizontal) {
          plusAt = Offset(tap / 2, thickness / 2);
          minusAt = Offset(length - tap / 2, thickness / 2);
        } else {
          final x = _DrumPainter.sideValuesCentre(thickness);
          plusAt = Offset(x, tap * 0.62);
          minusAt = Offset(x, length - tap * 0.62);
        }
        Widget chevron(
          int delta,
          AxisDirection direction,
          Offset at,
        ) => Positioned(
          left: at.dx - glyph / 2,
          top: at.dy - glyph / 2,
          width: glyph,
          height: glyph,
          child: IgnorePointer(
            child: CustomPaint(
              key: ValueKey(
                '${widget.semanticName}-step-${delta > 0 ? 'plus' : 'minus'}',
              ),
              size: Size.square(glyph),
              painter: TurretChevronPainter(direction),
            ),
          ),
        );
        // HDF-2: each chevron's tap area is at least 44 × 44 pt; it covers
        // the drum's end, never the three values in the middle.
        Widget hit(int delta, String label, {required bool start}) {
          final area = Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: dragArea(
              onTap: () => _set(_value + delta),
              child: const SizedBox.expand(),
            ),
          );
          return horizontal
              ? Positioned(
                  left: start ? 0 : null,
                  right: start ? null : 0,
                  top: 0,
                  bottom: 0,
                  width: tap,
                  child: area,
                )
              : Positioned(
                  top: start ? 0 : null,
                  bottom: start ? null : 0,
                  left: 0,
                  right: 0,
                  height: tap,
                  child: area,
                );
        }

        return SizedBox.expand(
          key: horizontal ? null : ScopeDialKeys.windageDrumBox,
          child: Stack(
            children: [
              Positioned.fill(
                child: dragArea(
                  child: CustomPaint(
                    painter: _DrumPainter(
                      axis: widget.axis,
                      clicks: _value,
                      clickValue: widget.clickValue,
                      unitLabel: widget.unitLabel,
                      positiveLetter: widget.positiveLetter,
                      negativeLetter: widget.negativeLetter,
                      pixelsPerClick: pixelsPerClick,
                      arrowTap: tap,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              chevron(
                1,
                horizontal ? AxisDirection.left : AxisDirection.up,
                plusAt,
              ),
              chevron(
                -1,
                horizontal ? AxisDirection.right : AxisDirection.down,
                minusAt,
              ),
              hit(1, up, start: true),
              hit(-1, down, start: false),
            ],
          ),
        );
      },
    );

    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticName,
      value: _valueText(),
      increasedValue: '${widget.clicks + 1}',
      decreasedValue: '${widget.clicks - 1}',
      onIncrease: () => _set(_value + 1),
      onDecrease: () => _set(_value - 1),
      child: body,
    );
  }
}

/// ChairGun's turret drum in the navy palette (owner, 2026-10-18 01:25:
/// only the colours are ours). Top drum, top to bottom: "← U · unit · D →",
/// the previous (dimmed) / CURRENT (bold, larger) / next (dimmed) values,
/// then the ticks with the red index at the bottom centre pointing up. The
/// side drum is the same turned 90°: ticks and the red index on the left,
/// the values next to them, the unit written down the right side, "↑ R" at
/// the top end and "L ↓" at the bottom end. The colours are the dark
/// (navy) theme's in both app themes, like the light scope inside.
class _DrumPainter extends CustomPainter {
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final String positiveLetter, negativeLetter;
  final double pixelsPerClick;

  /// Length of each end's chevron tap area; the values stay between them.
  final double arrowTap;

  const _DrumPainter({
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.pixelsPerClick,
    required this.arrowTap,
  });

  static MenzilColors get palette => MenzilColors.dark;

  /// Value sizes on the 58 pt design drum: current 22 pt, neighbours 18 pt.
  static const double currentSize = 22, neighbourSize = 18;

  /// Side drum: the values sit between the ticks and the unit column.
  static double sideValuesLeft(double thickness) =>
      thickness * ScopeTurretGeometry.sideValuesLeftShare;
  static double sideValuesRight(double thickness) =>
      thickness * ScopeTurretGeometry.sideValuesRightShare;
  static double sideValuesCentre(double thickness) =>
      thickness * ScopeTurretGeometry.sideValuesCentreShare;

  /// Clicks between long ticks: a whole number of units (1, 2, 5, 10…
  /// mrad / MOA) far enough apart to read.
  int get _major {
    final perUnit = math.max(1, (1 / clickValue).round());
    for (final units in const [1, 2, 5, 10, 20, 50, 100]) {
      final n = perUnit * units;
      if (n * pixelsPerClick >= 44) return n;
    }
    return perUnit * 100;
  }

  String _letter(int v) =>
      v == 0 ? '' : (v > 0 ? positiveLetter : negativeLetter);

  /// The angle of [v] clicks: up to three decimals, trailing zeros dropped,
  /// decimal comma (0,25 · 1,1 · 0,125 · 3).
  String _number(int v) {
    var t = (v * clickValue).abs().toStringAsFixed(3);
    t = t.replaceFirst(RegExp(r'0+$'), '');
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    return t.replaceAll('.', ',');
  }

  TextPainter _value(int v, double size, Color color, FontWeight weight) {
    TextStyle style(double fs) => TextStyle(
      fontFamily: MenzilType.familyFor(fs),
      fontFeatures: MenzilType.tabular,
      color: color,
      fontSize: fs,
      fontWeight: weight,
      height: 1.0,
    );
    final letter = _letter(v);
    return TextPainter(
      text: TextSpan(
        text: _number(v),
        style: style(size),
        children: [
          if (letter.isNotEmpty)
            TextSpan(text: letter, style: style(size * 0.72)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _label(
    Canvas canvas,
    String s,
    Offset center,
    Color color,
    double size, {
    double align = 0.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: MenzilType.familyFor(size),
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width * align, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = palette;
    final horizontal = axis == Axis.horizontal;
    final length = horizontal ? size.width : size.height;
    final thickness = horizontal ? size.height : size.width;
    final s = thickness / ScopeTurretGeometry.designThickness;
    final mid = length / 2;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(6 * s));

    // Cylinder: dark at both ends, a lighter band in the middle.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
          end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
          colors: [d.bg, d.surface2, d.line, d.surface2, d.bg],
          stops: const [0, 0.28, 0.5, 0.72, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    // Ticks across the length: long at the whole units, short between.
    // Values above the current setting sit before the index, so dragging
    // toward the index increases the setting.
    final longTick = Paint()
      ..color = d.ink
      ..strokeWidth = 1.4 * s;
    final shortTick = Paint()
      ..color = d.ink2
      ..strokeWidth = 1.0 * s;
    final reach = (mid / pixelsPerClick).ceil() + 1;
    for (var v = clicks - reach; v <= clicks + reach; v++) {
      final p = mid - (v - clicks) * pixelsPerClick;
      final major = v % _major == 0;
      final len = thickness * (major ? 0.26 : 0.13);
      final paint = major ? longTick : shortTick;
      if (horizontal) {
        canvas.drawLine(
          Offset(p, size.height),
          Offset(p, size.height - len),
          paint,
        );
      } else {
        canvas.drawLine(Offset(0, p), Offset(len, p), paint);
      }
    }

    // Values: previous / CURRENT / next, the current one centred on the
    // index line. They shrink together only when they would not fit
    // between the chevron areas.
    final previous = clicks + 1, next = clicks - 1;
    var cur = _value(clicks, currentSize * s, d.ink, FontWeight.w700);
    var prev = _value(previous, neighbourSize * s, d.ink2, FontWeight.w600);
    var nxt = _value(next, neighbourSize * s, d.ink2, FontWeight.w600);
    final gap = 6 * s;
    final free = length - 2 * arrowTap - 4 * s;
    double fit;
    if (horizontal) {
      final need = cur.width + 2 * gap + 2 * math.max(prev.width, nxt.width);
      fit = math.min(1.0, free / need);
    } else {
      final across = sideValuesRight(thickness) - sideValuesLeft(thickness);
      final wide = math.max(cur.width, math.max(prev.width, nxt.width));
      final need = cur.height + 2 * gap + 2 * math.max(prev.height, nxt.height);
      fit = math.min(1.0, math.min(across / wide, free / need));
    }
    if (fit < 1) {
      cur = _value(clicks, currentSize * s * fit, d.ink, FontWeight.w700);
      prev = _value(previous, neighbourSize * s * fit, d.ink2, FontWeight.w600);
      nxt = _value(next, neighbourSize * s * fit, d.ink2, FontWeight.w600);
    }
    final g = gap * fit;
    if (horizontal) {
      final y = thickness / 2;
      final n = math.max(prev.width, nxt.width);
      final step = cur.width / 2 + g + n / 2;
      void at(TextPainter tp, double x) =>
          tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      at(cur, mid);
      at(prev, mid - step);
      at(nxt, mid + step);
    } else {
      final x = sideValuesCentre(thickness);
      final n = math.max(prev.height, nxt.height);
      final step = cur.height / 2 + g + n / 2;
      void at(TextPainter tp, double y) =>
          tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      at(cur, mid);
      at(prev, mid - step);
      at(nxt, mid + step);
    }

    // Header: "← U · unit · D →" on top; on the side drum "↑ R" and "L ↓"
    // at the ends and the unit written down the right side.
    final header = 10 * s;
    if (horizontal) {
      final y = thickness * 0.15;
      _label(
        canvas,
        '← $positiveLetter',
        Offset(6 * s, y),
        d.ink2,
        header,
        align: 0,
      );
      _label(canvas, unitLabel, Offset(mid, y), d.ink2, header);
      _label(
        canvas,
        '$negativeLetter →',
        Offset(length - 6 * s, y),
        d.ink2,
        header,
        align: 1,
      );
    } else {
      _label(
        canvas,
        '↑ $positiveLetter',
        Offset(thickness / 2, arrowTap * 0.22),
        d.ink2,
        header,
      );
      _label(
        canvas,
        '$negativeLetter ↓',
        Offset(thickness / 2, length - arrowTap * 0.22),
        d.ink2,
        header,
      );
      canvas.save();
      canvas.translate(thickness - 8 * s, mid);
      canvas.rotate(math.pi / 2);
      _label(canvas, unitLabel, Offset.zero, d.ink2, header);
      canvas.restore();
    }
    canvas.restore();

    // Edge of the drum.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = d.line,
    );

    // Fixed red index on the zero line.
    final r = horizontal ? TurretIndex.top(size) : TurretIndex.side(size);
    final path = Path();
    if (horizontal) {
      path
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.center.dx, r.top)
        ..close();
    } else {
      path
        ..moveTo(r.left, r.top)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.right, r.center.dy)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = d.danger);
  }

  @override
  bool shouldRepaint(covariant _DrumPainter old) =>
      old.clicks != clicks ||
      old.clickValue != clickValue ||
      old.axis != axis ||
      old.arrowTap != arrowTap ||
      old.unitLabel != unitLabel;
}

/// The red index triangles, in the drum's own coordinates. Top drum: base
/// on the bottom edge, pointing up at the reticle's vertical line. Side
/// drum: base on the left edge, pointing right at the horizontal line.
/// Sizes are for the 58 pt design drum and scale with its thickness.
abstract final class TurretIndex {
  static const double width = 12, depth = 10, inset = 1;

  static Rect top(Size drum) {
    final s = drum.height / ScopeTurretGeometry.designThickness;
    return Rect.fromLTWH(
      drum.width / 2 - width * s / 2,
      drum.height - inset * s - depth * s,
      width * s,
      depth * s,
    );
  }

  static Rect side(Size drum) {
    final s = drum.width / ScopeTurretGeometry.designThickness;
    return Rect.fromLTWH(
      inset * s,
      drum.height / 2 - width * s / 2,
      depth * s,
      width * s,
    );
  }
}

/// "Kuleleri sıfırla". It is shown as selected only after the user pressed
/// it, so a freshly opened page has neither button selected.
class _ResetTurretsButton extends StatefulWidget {
  const _ResetTurretsButton({
    required this.atZero,
    required this.noClicks,
    required this.onReset,
  });

  final bool atZero;
  final bool noClicks;
  final VoidCallback onReset;

  @override
  State<_ResetTurretsButton> createState() => _ResetTurretsButtonState();
}

class _ResetTurretsButtonState extends State<_ResetTurretsButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(_ResetTurretsButton old) {
    super.didUpdateWidget(old);
    if (!widget.atZero) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.atZero && _pressed;
    return MenzilSecondaryButton(
      key: ScopeDialKeys.reset,
      label: !shown
          ? 'Kuleleri sıfırla'
          : widget.noClicks
          ? 'Kuleler sıfırda'
          : 'Kuleler sıfırlandı',
      expand: true,
      twoLines: true,
      active: shown,
      onPressed: shown
          ? null
          : () {
              setState(() => _pressed = true);
              if (!widget.atZero) widget.onReset();
            },
    );
  }
}

/// A turret step arrow (owner, 2026-10-15): only the chevron, white with a
/// thin dark edge, so it reads on the light reticle and on the dark card.
class TurretChevronPainter extends CustomPainter {
  final AxisDirection direction;

  const TurretChevronPainter(this.direction);

  static const Color fill = Colors.white;

  /// The reticle's dark line colour (#0F2230).
  static Color get edge => MenzilColors.light.scopeLine;

  @override
  void paint(Canvas canvas, Size size) {
    // The design's 16-unit chevron: arms 4 units long either side.
    final u = size.shortestSide / 16;
    final c = size.center(Offset.zero);
    final (Offset a, Offset tip, Offset b) = switch (direction) {
      AxisDirection.up => (
        c + Offset(-4 * u, 2 * u),
        c + Offset(0, -2 * u),
        c + Offset(4 * u, 2 * u),
      ),
      AxisDirection.down => (
        c + Offset(-4 * u, -2 * u),
        c + Offset(0, 2 * u),
        c + Offset(4 * u, -2 * u),
      ),
      AxisDirection.left => (
        c + Offset(2 * u, -4 * u),
        c + Offset(-2 * u, 0),
        c + Offset(2 * u, 4 * u),
      ),
      AxisDirection.right => (
        c + Offset(-2 * u, -4 * u),
        c + Offset(2 * u, 0),
        c + Offset(-2 * u, 4 * u),
      ),
    };
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(b.dx, b.dy);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, stroke(edge, 4.2 * u))
      ..drawPath(path, stroke(fill, 2 * u));
  }

  @override
  bool shouldRepaint(covariant TurretChevronPainter old) =>
      old.direction != direction;
}
