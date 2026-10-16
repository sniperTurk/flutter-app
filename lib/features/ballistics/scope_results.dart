part of 'scope_dial_view.dart';

// Sonuç kartları: kule okuması, vuruş noktası ve açıklama paragrafı.
//
// Modül ayrımı (owner, 2026-10-15): scope_dial_view.dart'tan aynen
// taşındı.

extension _ScopeResults on ScopeDialView {
  Widget _readout(
    BuildContext context,
    double dialedUp,
    double dialedRight,
    ({double up, double right})? impact,
  ) {
    final c = MenzilColors.of(context);
    String linear(double angle) {
      final m = ScopeDialMath.linearAtRange(angle.abs(), rangeM, unit);
      return metric
          ? '${(m * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
          : '${Units.metersToInchesDisplay(m).toStringAsFixed(1).replaceAll('.', ',')} in';
    }

    String dial(int clicks, double angle, String pos, String neg) =>
        '${clicks.abs()} klik ${clicks >= 0 ? pos : neg} '
        '(${ScopeDialView._fmt(angle.abs())} $unitLabel)';

    final impactText = impact == null
        ? 'Vuruş noktası: hesaplama bekleniyor'
        : (impact.up.abs() < clickValue / 2 &&
              impact.right.abs() < clickValue / 2)
        ? 'Vuruş noktası: artı işaretinde'
        : 'Vuruş noktası: ${linear(impact.up)} '
              '${impact.up >= 0 ? 'yukarı' : 'aşağı'} · '
              '${linear(impact.right)} ${impact.right >= 0 ? 'sağ' : 'sol'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kule: ${dial(elevationClicks, dialedUp, 'yukarı', 'aşağı')} · '
          '${dial(windageClicks, dialedRight, 'sağ', 'sol')}',
          // Clicks change live while a turret is dragged: equal-width
          // figures so the line does not jitter.
          style: MenzilType.body(
            c.ink,
          ).copyWith(fontFeatures: MenzilType.tabular),
        ),
        const SizedBox(height: MenzilSpace.xxs),
        Semantics(
          liveRegion: true,
          child: Text(
            impactText,
            key: ScopeDialKeys.impactText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: c.ink,
              fontFeatures: MenzilType.tabular,
            ),
          ),
        ),
        const SizedBox(height: MenzilSpace.xxs),
        Text(
          'Kırmızı sayılar: o noktayı hedefe tuttuğunuzda vuracağınız mesafe '
          '($distanceUnit).'
          '${windMpsPerUnit == null ? '' : ' Turuncu sayılar: bu mesafede isabeti o işarete kaydıran yan rüzgâr hızı.'}'
          '${windNote == null ? '' : ' $windNote'}'
          '${ffp ? ' FFP: retikül aralıkları her büyütmede geçerlidir.' : ' SFP: retikül aralıkları yalnız ${ScopeDialView._trim(calibrationMag)}x büyütmede geçerlidir; sayılar seçili büyütmeye göre hesaplandı.'}',
          // Hedef page paragraphs stay justified (owner, 2026-10-13: the
          // only justified page).
          textAlign: TextAlign.justify,
          style: MenzilType.caption(c.ink2),
        ),
      ],
    );
  }
}

/// Hedef: the REQUIRED turret solution at the selected range, one compact
/// line directly under the distance slider and above the reticle card:
/// "▌Üst kule 39 klik yukarı   ▌Yan kule 4 klik sağ" (owner, 2026-10-16,
/// design PR #366; replaces the big two-column row of #330). It shows what
/// the turrets must be set to ("Kuleleri kur"), not what is dialled now; no
/// calculation of its own: [requiredUp] / [requiredRight] are the scope
/// view's numbers. The angle (MRAD/MOA) stays in VoiceOver and in the
/// "Kule:" line under the scope.
class TurretSolutionRow extends StatelessWidget {
  static const rowKey = ValueKey('hedef-turret-solution');
  static const elevationKey = ValueKey('hedef-solution-elevation');
  static const windageKey = ValueKey('hedef-solution-windage');

  /// Required elevation, in [unit]; positive = up.
  final double requiredUp;

  /// Required windage, in [unit]; positive = right.
  final double requiredRight;

  /// The profile's click value, in [unit].
  final double clickValue;
  final AngularUnit unit;

  /// No wind entered: a zero side turret reads "rüzgâr yok".
  final bool windCalm;

  const TurretSolutionRow({
    required this.requiredUp,
    required this.requiredRight,
    required this.clickValue,
    required this.unit,
    required this.windCalm,
  }) : super(key: rowKey);

  static String _angle(double v) =>
      v.abs().toStringAsFixed(1).replaceAll('.', ',');

  /// "13,8 MOA yukarı"; no direction word when the angle prints as 0,0.
  String _detail(double angle, String pos, String neg) {
    final a = _angle(angle);
    final zero = a == _angle(0);
    return zero
        ? '$a ${unit.label}'
        : '$a ${unit.label} ${angle > 0 ? pos : neg}';
  }

  /// Height of the line (the design's 22 pt); larger text makes it taller.
  static const double lineHeight = 22;

  /// "yukarı" / "aşağı" / "sağ" / "sol" for a non-zero [clicks].
  static String _direction(int clicks, String pos, String neg) =>
      clicks == 0 ? '' : (clicks > 0 ? pos : neg);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final upClicks = ScopeDialMath.clicksFor(requiredUp, clickValue);
    final rightClicks = ScopeDialMath.clicksFor(requiredRight, clickValue);
    final upDetail = _detail(requiredUp, 'yukarı', 'aşağı');
    final calm = rightClicks == 0 && windCalm;
    final rightDetail = calm
        ? 'rüzgâr yok'
        : _detail(requiredRight, 'sağ', 'sol');
    // Labels 12,5 pt grey, the clicks 15 pt semibold with equal-width
    // figures (they change live with the distance).
    final word = MenzilType.label(c.ink2);
    final number = MenzilType.label(c.ink).copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      fontFeatures: MenzilType.tabular,
    );

    Widget part({
      required Key key,
      required Color accent,
      required String title,
      required int clicks,
      required String detail,
      required String direction,
    }) {
      final big = '${clicks.abs()} klik';
      return Semantics(
        key: key,
        container: true,
        label: '$title $big, $detail',
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: lineHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: accent, width: 3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  // One line, never wrapped: on a narrow screen or at a
                  // large text size it is set smaller instead.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$title ', style: word),
                          TextSpan(text: big, style: number),
                          if (direction.isNotEmpty)
                            TextSpan(text: ' $direction', style: word),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Kule çözümü',
      container: true,
      explicitChildNodes: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: part(
              key: elevationKey,
              accent: c.amber,
              title: 'Üst kule',
              clicks: upClicks,
              detail: upDetail,
              direction: _direction(upClicks, 'yukarı', 'aşağı'),
            ),
          ),
          // 12 pt between the halves, as in the design.
          const SizedBox(width: 12),
          Expanded(
            child: part(
              key: windageKey,
              accent: c.cyan,
              title: 'Yan kule',
              clicks: rightClicks,
              detail: rightDetail,
              direction: calm
                  ? 'rüzgâr yok'
                  : _direction(rightClicks, 'sağ', 'sol'),
            ),
          ),
        ],
      ),
    );
  }
}
