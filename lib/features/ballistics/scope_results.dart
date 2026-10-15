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

/// Hedef: the REQUIRED turret solution at the selected range, shown big
/// directly under the distance slider and above the reticle card (owner,
/// 2026-10-15 12:50: "Hedef'te sonuç en üstte… çok haklısın"; design
/// docs/design/clean-2026-10-15/Hedef.png). It shows what the turrets must
/// be set to ("Kuleleri kur"), not what is dialled now; no calculation of
/// its own: [requiredUp] / [requiredRight] are the scope view's numbers.
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

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final upClicks = ScopeDialMath.clicksFor(requiredUp, clickValue);
    final rightClicks = ScopeDialMath.clicksFor(requiredRight, clickValue);
    final upDetail = _detail(requiredUp, 'yukarı', 'aşağı');
    final rightDetail = rightClicks == 0 && windCalm
        ? 'rüzgâr yok'
        : _detail(requiredRight, 'sağ', 'sol');

    Widget column({
      required Key key,
      required Color accent,
      required String title,
      required int clicks,
      required String detail,
    }) {
      final big = '${clicks.abs()} klik';
      return Semantics(
        key: key,
        container: true,
        label: '$title $big, $detail',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 0, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: MenzilType.label(c.ink2),
                  ),
                  // A long number on a narrow screen or at a large text
                  // size shrinks inside its column instead of overflowing.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      big,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      // Changes live with the distance: equal-width figures.
                      style: MenzilType.display(
                        c.ink,
                        size: 34,
                        live: true,
                      ).copyWith(height: 1.1),
                    ),
                  ),
                  Text(
                    detail,
                    textAlign: TextAlign.left,
                    style: MenzilType.label(
                      c.ink2,
                    ).copyWith(fontFeatures: MenzilType.tabular),
                  ),
                ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: column(
              key: elevationKey,
              accent: c.amber,
              title: 'Üst kule',
              clicks: upClicks,
              detail: upDetail,
            ),
          ),
          // 12 pt between the columns, as in the design.
          const SizedBox(width: 12),
          Expanded(
            child: column(
              key: windageKey,
              accent: c.cyan,
              title: 'Yan kule',
              clicks: rightClicks,
              detail: rightDetail,
            ),
          ),
        ],
      ),
    );
  }
}
