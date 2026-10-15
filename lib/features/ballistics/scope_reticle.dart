part of 'scope_dial_view.dart';

// Retikül: iki parmakla büyütülen retikül alanı ve retikül çizimi.
//
// Modül ayrımı (owner, 2026-10-15): scope_dial_view.dart'tan aynen
// taşındı.

/// The reticle square with two-finger zoom (owner, 2026-10-10, like the
/// reference video): pinching enlarges the whole view — lines, marks, target
/// and numbers together — about its centre; a double tap returns to 1×.
/// The eye button hides the numbers so only the reticle and target remain.
class _ReticleViewport extends StatefulWidget {
  final double side;
  final ScopeReticlePainter Function(double zoom, bool showLabels) builder;

  const _ReticleViewport({required this.side, required this.builder});

  @override
  State<_ReticleViewport> createState() => _ReticleViewportState();
}

class _ReticleViewportState extends State<_ReticleViewport> {
  static const maxZoom = 8.0;
  double _zoom = 1, _startZoom = 1;
  bool _labels = true;

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    Widget chip({
      required Key key,
      required String tooltip,
      required Widget child,
      required VoidCallback onTap,
    }) => Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface.withValues(alpha: 0.85),
        shape: const StadiumBorder(),
        child: InkWell(
          key: key,
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: child,
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: widget.side,
      child: Stack(
        children: [
          SizedBox.square(
            key: ScopeDialKeys.reticle,
            dimension: widget.side,
            child: GestureDetector(
              onScaleStart: (_) => _startZoom = _zoom,
              onScaleUpdate: (d) {
                if (d.pointerCount < 2) return;
                final z = (_startZoom * d.scale).clamp(1.0, maxZoom);
                if ((z - _zoom).abs() > 1e-3) setState(() => _zoom = z);
              },
              onDoubleTap: () => setState(() => _zoom = 1),
              child: CustomPaint(painter: widget.builder(_zoom, _labels)),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: chip(
              key: ScopeDialKeys.labelsToggle,
              tooltip: _labels ? 'Yazıları gizle' : 'Yazıları göster',
              onTap: () => setState(() => _labels = !_labels),
              child: Icon(
                _labels ? Icons.visibility_outlined : Icons.visibility_off,
                size: 20,
                color: c.ink2,
              ),
            ),
          ),
          if (_zoom > 1.01)
            Positioned(
              right: 0,
              top: 0,
              child: chip(
                key: ScopeDialKeys.zoomReset,
                tooltip: 'Yakınlaştırmayı sıfırla',
                onTap: () => setState(() => _zoom = 1),
                child: Text(
                  '${_zoom.toStringAsFixed(1).replaceAll('.', ',')}× ✕',
                  style: MenzilType.caption(
                    c.ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reticle with hold marks, range labels for each mark and the point of
/// impact for the current turret setting. Marks are drawn in the scope's
/// angular unit: mil-dots every 1 mrad, or hashes every 2 MOA.
class ScopeReticlePainter extends CustomPainter {
  final MenzilColors colors;

  /// Physical extent of the reticle pattern, in reticle units: marks run to
  /// 80 % of it and the thick posts start at 82 %.
  final double halfField;

  /// Reticle units between the centre and the edge of the view (FFP: grows
  /// and shrinks with magnification; SFP: fixed).
  final double reticleHalfField;

  /// True angle between the centre and the edge of the view; the point of
  /// impact is drawn on this scale.
  final double trueHalfField;

  /// Radius of the ring target as a true angle (same unit as
  /// [trueHalfField]); drawn on the true scale behind the reticle so it grows
  /// with magnification. Null: no target.
  final double? targetRadius;

  /// Reticle roll in degrees (+ clockwise); the target is not rolled.
  final double cantDeg;
  final double markStep;
  final String unitLabel;
  final double? impactUp;
  final double? impactRight;
  final List<(double, String)> holdLabels;
  final List<(double, String)> windLabels;
  final String headline;
  final String? opticLine;
  final String? sfpNote;

  /// The scope's own reticle (owner, 2026-10-10); null = plain marks.
  final ReticleSpec? reticle;

  /// View (turret) units per reticle unit, e.g. 0.2909 for a MOA reticle on
  /// MRAD turrets.
  final double reticleToView;

  /// Two-finger view zoom (1 = none): everything inside the ring enlarges
  /// about the centre.
  final double zoom;

  /// False: the eye button hid every number; only reticle, target and
  /// impact are drawn.
  final bool showLabels;

  const ScopeReticlePainter({
    this.zoom = 1,
    this.showLabels = true,
    required this.colors,
    required this.halfField,
    double? reticleHalfField,
    double? trueHalfField,
    this.targetRadius,
    this.cantDeg = 0,
    this.opticLine,
    this.sfpNote,
    required this.markStep,
    required this.unitLabel,
    required this.impactUp,
    required this.impactRight,
    required this.holdLabels,
    this.windLabels = const [],
    required this.headline,
    this.reticle,
    this.reticleToView = 1,
  }) : reticleHalfField = reticleHalfField ?? halfField,
       trueHalfField = trueHalfField ?? halfField;

  /// On-screen radius of the target for a view of [radius] px.
  static double targetRadiusPx({
    required double radius,
    required double trueHalfField,
    required double targetRadius,
  }) => targetRadius * radius / trueHalfField;

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color color,
    double size, {
    bool alignLeft = false,
    FontWeight weight = FontWeight.w600,
    Color? halo,
  }) {
    if (halo != null) {
      final edge = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: MenzilType.familyFor(size),
            fontFeatures: MenzilType.tabular,
            fontSize: size,
            fontWeight: weight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeJoin = StrokeJoin.round
              ..color = halo,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final edx = alignLeft ? 0.0 : edge.width / 2;
      edge.paint(canvas, at - Offset(edx, edge.height / 2));
    }
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
    final dx = alignLeft ? 0.0 : tp.width / 2;
    tp.paint(canvas, at - Offset(dx, tp.height / 2));
  }

  /// Size of [s] drawn by [_text].
  static Size _measure(String s, double size, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: MenzilType.familyFor(size),
          fontFeatures: MenzilType.tabular,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.size;
  }

  /// Draws [r] centred on [c]; [k] = px per reticle unit. The reticle's own
  /// numbers are left out where they would overprint a hold or wind label
  /// ([reserved], owner rule: no label over another).
  void _drawSpec(
    Canvas canvas,
    ReticleSpec r,
    Offset c,
    double radius,
    double k,
    void Function(Offset a, Offset b, double width) line,
    Color halo,
    Color ink,
    Size size,
    List<Rect> reserved,
  ) {
    // Line thicknesses from the data when known, else the drawing default.
    final lw = r.lineWidth;
    final pw = r.postWidth;
    final fine = lw == null ? 1.4 : (lw * k).clamp(0.8, 4.0).toDouble();
    final postW = pw == null ? 7.0 : (pw * k).clamp(2.0, 14.0).toDouble();
    final posts = r.postsStart;
    final postPx = posts == null ? radius : math.min(radius, posts * k);
    // A floating centre leaves a gap around the centre, kept inside the
    // first mark so every mark stays on its line.
    final gap = r.floatingCenter
        ? (r.hashStep > 0 ? r.hashStep * k * 0.5 : 6.0)
              .clamp(2.0, 10.0)
              .toDouble()
        : 0.0;
    const arms = [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)];
    for (final d in arms) {
      line(c + d * gap, c + d * postPx, fine);
    }
    if (posts != null) {
      for (final d in arms) {
        line(c + d * postPx, c + d * radius, postW);
      }
    }
    final dot = Paint()..color = ink;
    final dotHalo = Paint()..color = halo;
    void drawDot(Offset at, double rPx) {
      canvas.drawCircle(at, rPx + 1.0, dotHalo);
      canvas.drawCircle(at, rPx, dot);
    }

    final numFont = math.max(8.0, size.shortestSide * 0.03);
    void number(double v, Offset at) {
      final s = v % 1 == 0
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1).replaceAll('.', ',');
      final m = _measure(s, numFont, FontWeight.w500);
      final box = Rect.fromCenter(
        center: at,
        width: m.width + 2,
        height: m.height,
      );
      if (reserved.any((b) => b.overlaps(box))) return;
      _text(canvas, s, at, ink, numFont, weight: FontWeight.w500, halo: halo);
    }

    switch (r.family) {
      case ReticleFamily.duplex:
        break;
      case ReticleFamily.milDot:
        {
          final rPx = math.max(1.6, math.min(4.0, 0.12 * k));
          void dots(double extent, Offset dir) {
            for (var i = 1; i * r.hashStep <= extent + 1e-9; i++) {
              drawDot(c + dir * (i * r.hashStep * k), rPx);
            }
          }

          dots(r.extentH, const Offset(1, 0));
          dots(r.extentH, const Offset(-1, 0));
          dots(r.extentUp, const Offset(0, -1));
          dots(r.extentDown, const Offset(0, 1));
        }
      case ReticleFamily.hash:
      case ReticleFamily.tree:
        {
          final step = r.hashStep;
          if (step > 0) {
            // Skip marks closer than ~3 px (low FFP power): keep majors only.
            final dense = step * k < 3;
            bool major(double v) =>
                r.majorEvery > 0 &&
                ((v / r.majorEvery) - (v / r.majorEvery).round()).abs() < 1e-6;
            void marks(double extent, Offset dir, Offset across) {
              for (var i = 1; i * step <= extent + 1e-9; i++) {
                final v = i * step;
                final big = major(v);
                if (dense && !big) continue;
                final len =
                    (big ? 7.0 : 3.5) * math.min(1.0, step * k / 4 + 0.5);
                final at = c + dir * (v * k);
                line(at - across * len, at + across * len, 1.0);
                final ne = r.numbersEvery;
                if (ne != null &&
                    ne > 0 &&
                    ((v / ne) - (v / ne).round()).abs() < 1e-6) {
                  final off = len + numFont * 0.8;
                  // The reticle's own numbers move to the free side of the
                  // line when wind labels (above the horizontal line) or
                  // range labels (right of the lower vertical line) are
                  // shown (owner, 2026-10-11: "25.7" ran into "10").
                  final windAbove = showLabels && windLabels.isNotEmpty;
                  final holdRight =
                      showLabels && holdLabels.isNotEmpty && dir.dy > 0;
                  number(
                    v,
                    dir.dx != 0
                        ? (windAbove
                              ? at + Offset(0, off)
                              : at - Offset(0, off))
                        : (holdRight
                              ? at - Offset(off + numFont * 0.4, 0)
                              : at + Offset(off + numFont * 0.4, 0)),
                  );
                }
              }
            }

            marks(r.extentH, const Offset(1, 0), const Offset(0, 1));
            marks(r.extentH, const Offset(-1, 0), const Offset(0, 1));
            marks(r.extentUp, const Offset(0, -1), const Offset(1, 0));
            marks(r.extentDown, const Offset(0, 1), const Offset(1, 0));
          }
          if (r.family == ReticleFamily.tree) {
            final rPx = math.max(1.0, math.min(2.4, 0.08 * k));
            for (final row in r.tree) {
              final y = c.dy + row.y * k;
              final ds = row.dotStep;
              if (row.halfWidth == 0) {
                // A single dot on the vertical line (e.g. Nightforce NP-2DD).
                drawDot(Offset(c.dx, y), rPx);
                continue;
              }
              if (ds == null) {
                // Spacing not given: only the row's known ends are drawn.
                drawDot(Offset(c.dx + row.halfWidth * k, y), rPx);
                drawDot(Offset(c.dx - row.halfWidth * k, y), rPx);
                continue;
              }
              if (ds * k < 3) continue;
              for (var i = 1; i * ds <= row.halfWidth + 1e-9; i++) {
                final x = i * ds * k;
                drawDot(Offset(c.dx + x, y), rPx);
                drawDot(Offset(c.dx - x, y), rPx);
              }
            }
          }
        }
    }
    if (r.centerDot) drawDot(c, 2.2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    // px per reticle unit (marks) and px per true unit (impact).
    final scale = radius / reticleHalfField;
    final trueScale = radius / trueHalfField;
    final ink = colors.scopeLine;

    canvas.drawCircle(center, radius, Paint()..color = colors.scopeBg);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Two-finger zoom: everything inside the ring enlarges about the centre.
    if (zoom > 1) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(zoom);
      canvas.translate(-center.dx, -center.dy);
    }

    // Everything of the reticle (lines, marks, labels on marks, impact) is
    // in the scope's own axes: roll it by the cant about the centre.
    void roll() {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(cantDeg * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);
    }

    // A thin background-coloured edge (halo) under every reticle line, mark
    // and label keeps them readable over the target (owner, 2026-10-09).
    final halo = colors.scopeBg.withValues(alpha: 0.85);
    void line(Offset a, Offset b, double width) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = halo
          ..strokeWidth = width + 2.4,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ink
          ..strokeWidth = width,
      );
    }

    // Target and point of impact, drawn before the reticle so every line,
    // mark and number stays on top (owner's reference, 2026-10-11). The
    // target sits around the point of impact: turning the turrets moves both
    // together; the green aim point stays at the crosshair. Grey outer ring,
    // yellow band, grey centre, thin grey outlines and a grey cross. True
    // size, but never smaller than one reticle mark.
    {
      final up = impactUp;
      final right = impactRight;
      roll();
      final poi = up != null && right != null
          ? center + Offset(right * trueScale, -up * trueScale)
          : center;
      final tr = targetRadius;
      if (tr != null && tr > 0) {
        final px = math.max(
          targetRadiusPx(
            radius: radius,
            trueHalfField: trueHalfField,
            targetRadius: tr,
          ),
          markStep * scale,
        );
        final edge = Paint()
          ..color = colors.paperRing
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, 1 / zoom);
        canvas.drawCircle(poi, px, Paint()..color = colors.paperRingSoft);
        canvas.drawCircle(poi, px * 0.66, Paint()..color = colors.paperFace);
        canvas.drawCircle(
          poi,
          px * 0.33,
          Paint()..color = colors.paperRingSoft,
        );
        for (final f in const [1.0, 0.66, 0.33]) {
          canvas.drawCircle(poi, px * f, edge);
        }
        canvas.drawLine(poi - Offset(px, 0), poi + Offset(px, 0), edge);
        canvas.drawLine(poi - Offset(0, px), poi + Offset(0, px), edge);
      }
      if (up != null &&
          right != null &&
          (poi - center).distance <= (radius - 14) / zoom) {
        canvas.drawCircle(poi, 5, Paint()..color = colors.scopeImpact);
      }
      canvas.restore();
    }

    const fine = 1.4;
    final postStart = halfField * 0.82 * scale;
    roll();
    final spec = reticle;
    // Dot radius of the plain marks; hold labels sit right of it.
    final dotR = math.max(
      1.5,
      math.min(size.shortestSide * 0.011, markStep * scale * 0.12),
    );

    // Range labels next to each hold mark (positive mark = below centre).
    // When the marks crowd together (FFP at low power) every n-th is kept.
    // They are laid out before the reticle so its own numbers keep clear
    // of them.
    final gap = markStep * scale;
    final stride = gap <= 0 ? 1 : math.max(1, (16 / gap).ceil());
    final holdFont = math.max(10.0, size.shortestSide * 0.042);
    final holdYs = <double>[];
    final holds = <(String, Offset)>[];
    final reserved = <Rect>[];
    for (final (mark, label)
        in showLabels ? holdLabels : const <(double, String)>[]) {
      if ((mark / markStep).round() % stride != 0) continue;
      final y = center.dy + mark * scale;
      holdYs.add(y);
      final at = Offset(center.dx + dotR + 6, y);
      holds.add((label, at));
      final m = _measure(label, holdFont, FontWeight.w500);
      reserved.add(Rect.fromLTWH(at.dx, y - m.height / 2, m.width, m.height));
    }

    // Crosswind speed above each horizontal mark, mirrored left and right.
    // Keep at least ~38 px between crosswind labels (they are wider than the
    // hold numbers); when marks crowd together every n-th is kept.
    final windGap = windLabels.isEmpty ? 0.0 : windLabels.first.$1 * scale;
    final windStride = windGap <= 0 ? 1 : math.max(1, (38 / windGap).ceil());
    final windFont = math.max(9.0, size.shortestSide * 0.036);
    final windY = center.dy - dotR - 11;
    // A hold number right of the vertical line sharing the wind labels' row
    // would be overprinted (owner, 2026-10-10: "532" ran into "5.0").
    final holdInRow = holdYs.any(
      (y) => (y - windY).abs() < (holdFont + windFont) / 2 + 1,
    );
    final holdRight = dotR + 6 + holdFont * 2.0;
    final winds = <(String, Offset)>[];
    for (final (i, (mark, label))
        in (showLabels ? windLabels : const <(double, String)>[]).indexed) {
      if ((i + 1) % windStride != 0) continue;
      if (mark * scale > postStart) continue;
      for (final side in const [-1.0, 1.0]) {
        if (side > 0 &&
            holdInRow &&
            mark * scale - windFont * label.length * 0.3 < holdRight) {
          continue;
        }
        final at = Offset(center.dx + side * mark * scale, windY);
        winds.add((label, at));
        final m = _measure(label, windFont, FontWeight.w500);
        reserved.add(
          Rect.fromCenter(center: at, width: m.width, height: m.height),
        );
      }
    }

    if (spec != null) {
      _drawSpec(
        canvas,
        spec,
        center,
        radius,
        scale * reticleToView,
        line,
        halo,
        ink,
        size,
        reserved,
      );
    } else {
      // Fine crosshair.
      line(
        Offset(center.dx - postStart, center.dy),
        Offset(center.dx + postStart, center.dy),
        fine,
      );
      line(
        Offset(center.dx, center.dy - postStart),
        Offset(center.dx, center.dy + postStart),
        fine,
      );
      // Thick posts.
      const directions = [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
      ];
      for (final d in directions) {
        line(center + d * postStart, center + d * radius, 7);
      }

      // Marks.
      final steps = (halfField * 0.8 / markStep).floor();
      final dot = Paint()..color = ink;
      final dotHalo = Paint()..color = halo;
      for (var i = -steps; i <= steps; i++) {
        if (i == 0) continue;
        final p = i * markStep * scale;
        if (unitLabel.toLowerCase() == 'mrad') {
          for (final at in [center + Offset(p, 0), center + Offset(0, p)]) {
            canvas.drawCircle(at, dotR + 1.2, dotHalo);
            canvas.drawCircle(at, dotR, dot);
          }
        } else {
          final long =
              (i % 5 == 0 ? 9.0 : 5.0) * math.min(1.0, markStep * scale / 12);
          line(center + Offset(p, -long), center + Offset(p, long), fine);
          line(center + Offset(-long, p), center + Offset(long, p), fine);
        }
      }
    }
    canvas.drawCircle(center, 2.5, Paint()..color = colors.ok);

    for (final (label, at) in holds) {
      _text(
        canvas,
        label,
        at,
        colors.danger,
        holdFont,
        alignLeft: true,
        weight: FontWeight.w500,
        halo: halo,
      );
    }
    for (final (label, at) in winds) {
      _text(
        canvas,
        label,
        at,
        colors.amberInk,
        windFont,
        weight: FontWeight.w500,
        halo: halo,
      );
    }

    canvas.restore(); // roll
    // Headline and scale legend (hidden with the eye button).
    if (showLabels) {
      _text(
        canvas,
        headline,
        Offset(center.dx - radius * 0.48, center.dy + radius * 0.36),
        colors.cyanInk,
        math.max(11.0, size.shortestSide * 0.045),
      );
      _text(
        canvas,
        'aralık: ${markStep.toStringAsFixed(0)} $unitLabel',
        Offset(center.dx - radius * 0.48, center.dy + radius * 0.50),
        colors.cyanInk,
        math.max(10.0, size.shortestSide * 0.036),
      );
      final optic = opticLine;
      if (optic != null) {
        _text(
          canvas,
          optic,
          Offset(center.dx - radius * 0.48, center.dy - radius * 0.50),
          colors.cyanInk,
          math.max(10.0, size.shortestSide * 0.038),
        );
      }
      final note = sfpNote;
      if (note != null) {
        _text(
          canvas,
          note,
          Offset(center.dx - radius * 0.48, center.dy - radius * 0.38),
          colors.amberInk,
          math.max(10.0, size.shortestSide * 0.036),
        );
      }
    }

    // Point of impact (scope axes, so rolled with the reticle).
    roll();
    final up = impactUp;
    final right = impactRight;
    if (up != null && right != null) {
      var poi = center + Offset(right * trueScale, -up * trueScale);
      final offset = poi - center;
      // Zoomed in, the arrow still sits at the visible edge.
      final limit = (radius - 14) / zoom;
      final outside = offset.distance > limit;
      if (outside) {
        poi = center + offset / offset.distance * limit;
      }
      Paint stroke(Color c, double w) => Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = w;
      // Inside the field the ring is drawn under the reticle (above).
      if (outside) {
        // Off-field: an arrow at the edge pointing toward the impact.
        final dir = offset / offset.distance;
        final normal = Offset(-dir.dy, dir.dx);
        final tip = poi + dir * 10;
        final arrow = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((poi + normal * 9).dx, (poi + normal * 9).dy)
          ..lineTo((poi - normal * 9).dx, (poi - normal * 9).dy)
          ..close();
        canvas.drawPath(arrow, Paint()..color = colors.scopeImpact);
        canvas.drawPath(arrow, stroke(halo, 1.5));
        // How far out it is, written just inside the arrow.
        final far = math.sqrt(up * up + right * right);
        _text(
          canvas,
          '${far.toStringAsFixed(far >= 10 ? 0 : 1).replaceAll('.', ',')} $unitLabel',
          poi - dir * 30,
          colors.scopeImpact,
          math.max(11.0, size.shortestSide * 0.04),
          weight: FontWeight.w700,
          halo: halo,
        );
      }
    }
    canvas.restore(); // roll
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant ScopeReticlePainter old) =>
      old.impactUp != impactUp ||
      old.impactRight != impactRight ||
      old.headline != headline ||
      old.colors != colors ||
      old.unitLabel != unitLabel ||
      old.halfField != halfField ||
      old.reticleHalfField != reticleHalfField ||
      old.trueHalfField != trueHalfField ||
      old.targetRadius != targetRadius ||
      old.cantDeg != cantDeg ||
      old.opticLine != opticLine ||
      old.sfpNote != sfpNote ||
      old.zoom != zoom ||
      old.showLabels != showLabels ||
      old.reticle != reticle ||
      old.reticleToView != reticleToView ||
      !_sameLabels(old.holdLabels, holdLabels) ||
      !_sameLabels(old.windLabels, windLabels);

  static bool _sameLabels(List<(double, String)> a, List<(double, String)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
