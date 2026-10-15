part of 'scope_dial_view.dart';

// Hesap dökümü: kule ve retikül sayılarının adım adım hesabı.
//
// Modül ayrımı (owner, 2026-10-15): scope_dial_view.dart'tan aynen
// taşındı.

extension _ScopeWorkings on ScopeDialView {
  /// Step-by-step working of the turret and reticle numbers, so the user
  /// can follow every value on the scope.
  Widget _workings(
    BuildContext context,
    double dialedUp,
    double dialedRight,
    ({double up, double right})? impact,
  ) {
    final c = MenzilColors.of(context);
    final req = requiredUp;
    String f(double v) => ScopeDialView._fmt(v);
    String len(double angle) {
      final m = ScopeDialMath.linearAtRange(angle.abs(), rangeM, unit);
      return metric
          ? '${(m * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
          : '${(m * 39.3700787).toStringAsFixed(1).replaceAll('.', ',')} in';
    }

    final lines = <String>[];
    final r = toDisplayRange(rangeM).round();
    lines.add(
      '1 $unitLabel, $r $distanceUnit mesafede = ${len(1)}'
      '${switch (unit) {
        AngularUnit.mrad => '  (mesafe(m) / 10 cm)',
        AngularUnit.moa => '  (mesafe(m) × 0,02909 cm)',
        AngularUnit.smoa => '  (100 yd\'de 1 inç)',
      }}',
    );
    lines.add(
      unit == AngularUnit.smoa
          ? '1 SMOA = 0,27778 MRAD = 0,955 MOA'
          : '1 MOA = 0,29089 MRAD · 1 MRAD = 3,43775 MOA',
    );
    final tRad = targetRadius;
    if (tRad != null) {
      final d = metric
          ? '${(targetDiameterM * 100).toStringAsFixed(0).replaceAll('.', ',')} cm'
          : '${(targetDiameterM * 39.3700787).toStringAsFixed(1).replaceAll('.', ',')} in';
      lines.add(
        'Hedef halkası Ø$d = ${f(tRad * 2)} $unitLabel; gerçek boyutunda '
        'çizilir, bir çizgi aralığından küçükse o boyutta gösterilir. İki '
        'parmakla büyüt, çift dokunuşla geri dön. Göz '
        'düğmesi yazıları gizler. Çapını Pro → İsabet olasılığı → Hedef '
        'çapı\'ndan değiştirebilirsiniz.',
      );
    }
    if (inclineDeg.round() != 0) {
      final horizontal = toDisplayRange(
        rangeM * math.cos(inclineDeg * math.pi / 180),
      );
      lines.add(
        'Tüfek eğimi ∠${inclineDeg.round()}°: düşüş eğik mesafe ($r '
        '$distanceUnit) boyunca eğime göre hesaplandı; yatay mesafe '
        '${horizontal.round()} $distanceUnit.',
      );
    }
    if (cantDeg.round() != 0) {
      lines.add(
        'Dürbün eğimi ${cantDeg.abs().round()}° '
        '${cantDeg > 0 ? 'sağa' : 'sola'}: ${firearm ? 'mermi' : 'saçma'} '
        'yatık tarafa ve aşağı '
        'kayar; kule değerleri yatık dürbünün kendi eksenlerinde verildi.',
      );
    }
    if (req != null) {
      final other = ScopeDialMath.convert(req, unit, otherUnit);
      lines.add(
        'Gereken yükseliş: ${len(req)} → ${f(req.abs())} $unitLabel '
        '(${f(other.abs())} $otherUnitLabel) ${req >= 0 ? 'U' : 'D'}',
      );
      final clicks = ScopeDialMath.clicksFor(req, clickValue);
      lines.add(
        'Klik = ${f(req.abs())} / ${_dc(clickValue)} = ${clicks.abs()} klik '
        '${req >= 0 ? 'U' : 'D'}',
      );
      final otherClick = ScopeDialMath.standardClick(otherUnit);
      final otherClicks = ScopeDialMath.clicksFor(other, otherClick);
      lines.add(
        'Karşılaştırma: aynı düzeltme ${_dc(otherClick)} $otherUnitLabel klikli '
        'kulede ${otherClicks.abs()} klik',
      );
      if (requiredRight.abs() > 1e-9) {
        final w = ScopeDialMath.clicksFor(requiredRight, clickValue);
        lines.add(
          'Gereken yan: ${f(requiredRight.abs())} $unitLabel → '
          '${w.abs()} klik ${requiredRight >= 0 ? 'R' : 'L'}',
        );
      }
    }
    lines.add(
      'Kulede: $elevationClicks × ${_dc(clickValue)} = ${f(dialedUp)} $unitLabel · '
      '$windageClicks × ${_dc(clickValue)} = ${f(dialedRight)} $unitLabel',
    );
    if (impact != null) {
      lines.add(
        'Kalan = kule − gereken = ${f(impact.up)} $unitLabel dikey, '
        '${f(impact.right)} $unitLabel yatay',
      );
    }
    if (ffp) {
      lines.add(
        'FFP: retikül görüntüyle birlikte büyür; 1 çizgi her büyütmede '
        '1 $unitLabel. Tutuş = kalan.',
      );
    } else {
      final sub = subtension;
      lines.add(
        'SFP: retikül yalnız ${ScopeDialView._trim(calibrationMag)}x büyütmede doğru. '
        '1 çizgi = ${ScopeDialView._trim(calibrationMag)} / ${ScopeDialView._trim(currentMag)} = '
        '${sub.toStringAsFixed(3).replaceAll('.', ',')} $unitLabel.',
      );
      if (impact != null) {
        lines.add(
          'Retikülde tutuş = kalan / ${sub.toStringAsFixed(3).replaceAll('.', ',')} = '
          '${f(impact.up.abs() / sub)} çizgi '
          '${impact.up <= 0 ? 'aşağıdaki' : 'yukarıdaki'} işaret',
        );
      }
    }
    return Column(
      key: ScopeDialKeys.workings,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hesap dökümü', style: MenzilType.heading(c.ink, size: 17)),
        const SizedBox(height: MenzilSpace.xxs),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              l,
              // Hedef page: justified (owner, 2026-10-13).
              textAlign: TextAlign.justify,
              style: MenzilType.caption(c.ink2),
            ),
          ),
      ],
    );
  }
}

/// [v] with a decimal comma and no trailing ",0" (0,1 · 0,25 · 1).
String _dc(num v) =>
    (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString()).replaceAll('.', ',');
