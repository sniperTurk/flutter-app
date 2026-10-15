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
