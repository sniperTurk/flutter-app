/// Beaufort wind force over land, for estimating the wind without an
/// anemometer (Ö2, docs/yeni-hesaplar-2026-10-11.md).
///
/// Speed limits are the WMO Beaufort scale (m/s, mean wind at the standard
/// 10 m height over open, level ground: WMO-No. 8, Guide to Instruments and
/// Methods of Observation, ch. 5), as printed in the MeteoSwiss Beaufort
/// table. Land descriptions are Turkish wordings of the same table's
/// "effects on land" column.
///
/// The shooter stands lower than 10 m, where the wind is usually weaker. No
/// height factor is applied: it depends on the ground roughness, which the
/// shooter cannot know, so the info text only warns about it.
class BeaufortClass {
  final int force;

  /// Short name for the closed select box (no parentheses).
  final String name;

  /// What the shooter sees around them over land.
  final String land;

  /// Short sign for the "Rüzgârı gözle tahmin et" guide on Hava Durumu
  /// (owner approved text, 2026-10-13); null = not in the guide.
  final String? guide;

  /// Speed limits of the class, m/s at 10 m.
  final double minMps, maxMps;

  const BeaufortClass({
    required this.force,
    required this.name,
    required this.land,
    required this.minMps,
    required this.maxMps,
    this.guide,
  });

  /// Middle of the class, rounded to 0.1 m/s.
  double get midMps => ((minMps + maxMps) * 5).round() / 10;
}

abstract final class Beaufort {
  /// Forces 0–7; stronger wind is no shooting weather.
  static const classes = <BeaufortClass>[
    BeaufortClass(
      force: 0,
      name: 'Sakin',
      land: 'Duman dümdüz yükselir.',
      minMps: 0,
      maxMps: 0.2,
      guide: 'Duman dümdüz yükselir',
    ),
    BeaufortClass(
      force: 1,
      name: 'Çok hafif',
      land: 'Duman hafifçe yana kayar; bayrak kıpırdamaz.',
      minMps: 0.3,
      maxMps: 1.5,
      guide: 'Duman hafifçe yana kayar',
    ),
    BeaufortClass(
      force: 2,
      name: 'Hafif',
      land: 'Rüzgâr yüzde hissedilir; yapraklar hışırdar.',
      minMps: 1.6,
      maxMps: 3.3,
      guide: 'Rüzgâr yüzde hissedilir, yapraklar hışırdar',
    ),
    BeaufortClass(
      force: 3,
      name: 'Orta',
      land: 'Yapraklar ve ince dallar durmadan kıpırdar; hafif bayrak açılır.',
      minMps: 3.4,
      maxMps: 5.4,
      guide: 'Yapraklar ve ince dallar durmadan kıpırdar',
    ),
    BeaufortClass(
      force: 4,
      name: 'Orta-kuvvetli',
      land: 'Toz ve kâğıt kalkar; küçük dallar sallanır.',
      minMps: 5.5,
      maxMps: 7.9,
      guide: 'Toz ve kâğıt kalkar, küçük dallar sallanır',
    ),
    BeaufortClass(
      force: 5,
      name: 'Kuvvetli',
      land: 'Yapraklı küçük ağaçlar sallanır; su yüzünde küçük dalgalar.',
      minMps: 8.0,
      maxMps: 10.7,
      guide: 'Küçük ağaçlar sallanır',
    ),
    BeaufortClass(
      force: 6,
      name: 'Çok kuvvetli',
      land: 'Kalın dallar sallanır; teller ıslık çalar; şemsiye zor tutulur.',
      minMps: 10.8,
      maxMps: 13.8,
    ),
    BeaufortClass(
      force: 7,
      name: 'Fırtınamsı',
      land: 'Bütün ağaçlar sallanır; rüzgâra karşı yürümek zorlaşır.',
      minMps: 13.9,
      maxMps: 17.1,
    ),
  ];

  /// Forces 0–5: the classes shown in the Hava Durumu guide.
  static Iterable<BeaufortClass> get guideClasses =>
      classes.where((b) => b.guide != null);
}
