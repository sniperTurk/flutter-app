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

/// Turrets around the scope, as in ChairGun: the elevation drum sits on top
/// (its zero right above the reticle's vertical line); "L-R" slides the
/// windage drum in from the right over the scope's right edge, its zero on
/// the reticle's horizontal line. Tapping "L-R" again slides it away, so the
/// scope keeps the whole width.
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

  @override
  void didUpdateWidget(covariant _TurretBar old) {
    super.didUpdateWidget(old);
    if (widget.revealToken != old.revealToken) _windage = true;
  }

  /// Top row (owner, 2026-10-15): [empty 48][‹ 28][drum 1fr][› 28][L-R 48],
  /// 4 pt apart. The empty slot balances L-R, so the drum and its zero sit
  /// over the reticle's vertical line.
  static const double slot = 48, gap = 4, rowHeight = 84;

  /// The side turret on the 334 pt reticle of the approved design (390 pt
  /// phone). Owner, 2026-10-15 12:52: the drum box is smaller, 66 × 180 pt,
  /// while its arrows stay exactly where they were: a 74 pt wide column, the
  /// arrows 30 pt tall (74 × 30 pt hit areas) at its ends, 296 pt apart
  /// outside to outside. The box is centred between them, 28 pt from each.
  /// Everything scales with the reticle size.
  static const double designSide = 334,
      sideColumnWidth = 74,
      sideBoxWidth = 66,
      sideBoxHeight = 180,
      sideArrowHeight = 30,
      sideArrowGap = 28;

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final side = widget.side;
    final k = side / designSide;
    final columnWidth = sideColumnWidth * k;
    final columnHeight =
        (sideBoxHeight + 2 * (sideArrowHeight + sideArrowGap)) * k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: rowHeight,
          child: Row(
            children: [
              const SizedBox(width: slot + gap),
              Expanded(child: widget.elevation),
              const SizedBox(width: gap),
              Semantics(
                button: true,
                toggled: _windage,
                label: _windage
                    ? 'Rüzgâr kulesini gizle'
                    : 'Rüzgâr kulesini göster',
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: slot,
                    // A plain button like the others (owner, 2026-10-12):
                    // white on navy in Koyu, dark on light in Açık.
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
        const SizedBox(height: MenzilSpace.xs),
        Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              children: [
                Positioned.fill(child: widget.reticle),
                // Windage drum at the right edge, vertically centred on the
                // reticle so its zero meets the horizontal line; its arrows
                // sit above and below the drum box.
                Positioned(
                  right: 0,
                  top: (side - columnHeight) / 2,
                  height: columnHeight,
                  width: columnWidth,
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SlideTransition(
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
  }
}

/// A turret drum that the user drags (or steps with buttons) one click at a
/// time. Horizontal drum: dragging right dials UP. Vertical drum: dragging
/// down dials RIGHT — the numbers on the drum move toward the pointer the
/// way a real turret's markings do.
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

  /// The top drum is 78 pt tall (U/D header, values, ticks) and its arrows
  /// 28 pt wide (owner, 2026-10-15).
  static const double drumHeight = 78, arrowWidth = 28;

  /// Smallest tap area of a step arrow (HDF-2, owner 2026-10-15 22:29).
  static const double minTap = 44;
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
    final c = MenzilColors.of(context);
    final horizontal = widget.axis == Axis.horizontal;
    final drum = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: horizontal ? (_) => _carry = 0 : null,
      onHorizontalDragUpdate: horizontal ? (d) => _drag(d.delta.dx) : null,
      onVerticalDragStart: horizontal ? null : (_) => _carry = 0,
      onVerticalDragUpdate: horizontal ? null : (d) => _drag(d.delta.dy),
      child: CustomPaint(
        painter: _DrumPainter(
          colors: c,
          axis: widget.axis,
          clicks: _value,
          clickValue: widget.clickValue,
          unitLabel: widget.unitLabel,
          positiveLetter: widget.positiveLetter,
          negativeLetter: widget.negativeLetter,
          pixelsPerClick: pixelsPerClick,
        ),
        child: const SizedBox.expand(),
      ),
    );

    // Step arrows (owner, 2026-10-15): only the chevron, no box, white with
    // a thin dark edge so it shows on the light reticle and the dark card.
    // VoiceOver steps the drum through its slider actions below.
    Widget glyph(int delta, AxisDirection direction, double w, double h) =>
        SizedBox(
          width: w,
          height: h,
          child: Center(
            child: CustomPaint(
              key: ValueKey(
                '${widget.semanticName}-step-${delta > 0 ? 'plus' : 'minus'}',
              ),
              size: const Size.square(24),
              painter: TurretChevronPainter(direction),
            ),
          ),
        );

    // HDF-2 (owner, 2026-10-15 22:29 "görünüş aynı, alan büyük"; 22:31):
    // each arrow's invisible tap area is at least [minTap] pt, laid over
    // the unchanged chevron. It keeps the arrow's own [core] cell and grows
    // only toward the drum ([coreFirst]: the core comes first along
    // [axis]), never toward L-R or another control. Where it lies over the
    // top drum the drum still drags ([dragStrip]).
    Widget hit(
      int delta,
      String label, {
      required Axis axis,
      required double core,
      required bool coreFirst,
      bool dragStrip = false,
    }) {
      Widget area({bool drag = false}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => _set(_value + delta),
        onHorizontalDragStart: drag ? (_) => _carry = 0 : null,
        onHorizontalDragUpdate: drag ? (d) => _drag(d.delta.dx) : null,
        child: const SizedBox.expand(),
      );
      final coreCell = axis == Axis.horizontal
          ? SizedBox(width: core, child: area())
          : SizedBox(height: core, child: area());
      final strip = Expanded(child: area(drag: dragStrip));
      return Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Flex(
          direction: axis,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: coreFirst ? [coreCell, strip] : [strip, coreCell],
        ),
      );
    }

    final up = '${widget.semanticName} 1 klik ${widget.positiveWord}';
    final down = '${widget.semanticName} 1 klik ${widget.negativeWord}';
    final Widget body;
    if (horizontal) {
      // ‹ drum ›, 28 pt arrows 4 pt from the drum (owner, 2026-10-15).
      body = LayoutBuilder(
        builder: (context, box) {
          // Tap areas grow from the arrow's 28 pt column toward the drum,
          // so the right one ends 4 pt before L-R.
          final w = math.max(arrowWidth, math.min(minTap, box.maxWidth / 2));
          return Stack(
            children: [
              Row(
                children: [
                  glyph(1, AxisDirection.left, arrowWidth, drumHeight),
                  const SizedBox(width: _TurretBarState.gap),
                  Expanded(
                    child: SizedBox(height: drumHeight, child: drum),
                  ),
                  const SizedBox(width: _TurretBarState.gap),
                  glyph(-1, AxisDirection.right, arrowWidth, drumHeight),
                ],
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: w,
                child: hit(
                  1,
                  up,
                  axis: Axis.horizontal,
                  core: arrowWidth,
                  coreFirst: true,
                  dragStrip: true,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: w,
                child: hit(
                  -1,
                  down,
                  axis: Axis.horizontal,
                  core: arrowWidth,
                  coreFirst: false,
                  dragStrip: true,
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Long, slim drum box; the arrows sit outside it, above and below,
      // as wide as the column. The narrower box is centred under them.
      body = LayoutBuilder(
        builder: (context, box) {
          final k = box.maxWidth / _TurretBarState.sideColumnWidth;
          final arrow = _TurretBarState.sideArrowHeight * k;
          final gap = _TurretBarState.sideArrowGap * k;
          // Tap areas grow from the arrow toward the box, never into it:
          // 44 pt fits in arrow + gap down to a 254 pt reticle.
          final h = math.max(arrow, math.min(minTap, arrow + gap));
          return Stack(
            children: [
              Column(
                children: [
                  glyph(1, AxisDirection.up, box.maxWidth, arrow),
                  SizedBox(height: gap),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: _TurretBarState.sideBoxWidth * k,
                        child: DecoratedBox(
                          key: ScopeDialKeys.windageDrumBox,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.line),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: drum,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  glyph(-1, AxisDirection.down, box.maxWidth, arrow),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: h,
                child: hit(
                  1,
                  up,
                  axis: Axis.vertical,
                  core: arrow,
                  coreFirst: true,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h,
                child: hit(
                  -1,
                  down,
                  axis: Axis.vertical,
                  core: arrow,
                  coreFirst: false,
                ),
              ),
            ],
          );
        },
      );
    }

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

class _DrumPainter extends CustomPainter {
  final MenzilColors colors;
  final Axis axis;
  final int clicks;
  final double clickValue;
  final String unitLabel;
  final String positiveLetter, negativeLetter;
  final double pixelsPerClick;

  const _DrumPainter({
    required this.colors,
    required this.axis,
    required this.clicks,
    required this.clickValue,
    required this.unitLabel,
    required this.positiveLetter,
    required this.negativeLetter,
    required this.pixelsPerClick,
  });

  /// Clicks between labelled major ticks: a whole number of units (1, 2, 5,
  /// 10… mrad / MOA) far enough apart that the labels never overlap
  /// (owner, 2026-10-11: 1/2 MOA labels ran into each other).
  int get _major {
    final perUnit = math.max(1, (1 / clickValue).round());
    for (final units in const [1, 2, 5, 10, 20, 50, 100]) {
      final n = perUnit * units;
      if (n * pixelsPerClick >= 44) return n;
    }
    return perUnit * 100;
  }

  void _text(
    Canvas canvas,
    String s,
    Offset center,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w600,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: MenzilType.familyFor(size),
          fontFeatures: MenzilType.tabular,
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  String _letter(int v) =>
      v == 0 ? '' : (v > 0 ? positiveLetter : negativeLetter);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: axis == Axis.horizontal
              ? Alignment.centerLeft
              : Alignment.topCenter,
          end: axis == Axis.horizontal
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          colors: [colors.surface2, colors.line, colors.surface2],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final horizontal = axis == Axis.horizontal;
    final length = horizontal ? size.width : size.height;
    final across = horizontal ? size.height : size.width;
    final mid = length / 2;
    final tick = Paint()
      ..color = colors.ink
      ..strokeWidth = 1.2;
    final reach = (mid / pixelsPerClick).ceil() + 1;
    final label = colors.ink;
    for (var v = clicks - reach; v <= clicks + reach; v++) {
      // Values above the current setting sit before the pointer, so dragging
      // toward the pointer increases the setting.
      final p = mid - (v - clicks) * pixelsPerClick;
      final major = v % _major == 0;
      final len = major ? across * 0.30 : across * 0.16;
      if (horizontal) {
        canvas.drawLine(
          Offset(p, size.height),
          Offset(p, size.height - len),
          tick,
        );
        if (major) {
          final value = (v * clickValue).abs();
          final letter = _letter(v);
          _text(
            canvas,
            '${ScopeDialView._trim(value)}$letter',
            Offset(p, size.height * 0.40),
            label,
            15,
          );
        }
      } else {
        canvas.drawLine(Offset(0, p), Offset(len, p), tick);
        if (major) {
          final value = (v * clickValue).abs();
          final letter = _letter(v);
          _text(
            canvas,
            '${ScopeDialView._trim(value)}$letter',
            Offset(size.width * 0.62, p),
            label,
            13,
          );
        }
      }
    }
    canvas.restore();

    // Fixed pointer.
    final pointer = Paint()..color = colors.danger;
    final path = Path();
    if (horizontal) {
      path
        ..moveTo(mid - 7, size.height)
        ..lineTo(mid + 7, size.height)
        ..lineTo(mid, size.height - 11)
        ..close();
      _text(
        canvas,
        '← $positiveLetter   $unitLabel   $negativeLetter →',
        Offset(mid, 10),
        colors.ink2,
        10,
      );
    } else {
      // Inside the box, clear of its edge (owner, 2026-10-15 12:53).
      final r = SideTurretPointer.rect(size);
      path
        ..moveTo(r.left, r.top)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.right, mid)
        ..close();
      _text(canvas, '↑$positiveLetter', Offset(size.width / 2, 10), label, 11);
      _text(
        canvas,
        '$negativeLetter↓',
        Offset(size.width / 2, size.height - 10),
        label,
        11,
      );
    }
    canvas.drawPath(path, pointer);
  }

  @override
  bool shouldRepaint(covariant _DrumPainter old) =>
      old.clicks != clicks ||
      old.clickValue != clickValue ||
      old.colors != colors ||
      old.unitLabel != unitLabel;
}

/// The side turret's red pointer, in the drum box's own coordinates
/// (owner, 2026-10-15 12:53: the pointer sits fully inside the box). It
/// points at the drum's centre line, the reticle's horizontal line, from
/// [inset] pt inside the box's edge.
abstract final class SideTurretPointer {
  /// Clear space between the box's outer edge (1 pt border included) and
  /// the pointer.
  static const double inset = 5;

  /// Pointer depth (base to tip) and height, as before.
  static const double depth = 11, height = 14;

  static Rect rect(Size box) =>
      Rect.fromLTWH(inset, box.height / 2 - height / 2, depth, height);
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
