import 'package:flutter/material.dart';

import '../../tools/domain/hit_probability.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// Vuruş Olasılığı (WEZ-style): from a measured group size and a target
/// size, estimates the single-shot hit probability at a chosen range using
/// the closed-form circular-Gaussian model in [HitProbabilityEngine]. This
/// is a standalone statistics tool: it does not touch the (still gated)
/// aerodynamic drag solver and never shows a scope-adjustment instruction,
/// so it is additive to the rifle's trajectory DOPE rather than a
/// replacement.
class HitProbabilityScreen extends StatefulWidget {
  const HitProbabilityScreen({super.key});

  @override
  State<HitProbabilityScreen> createState() => _HitProbabilityScreenState();
}

class _HitProbabilityScreenState extends State<HitProbabilityScreen> {
  final _group = TextEditingController(text: '1,0');
  final _target = TextEditingController(text: '10');
  final _range = TextEditingController(text: '100');
  int _shots = HitProbabilityEngine.defaultShots;

  @override
  void dispose() {
    _group.dispose();
    _target.dispose();
    _range.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final group = _parse(_group);
    final target = _parse(_target);
    final range = _parse(_range);
    final valid =
        group != null &&
        group > 0 &&
        target != null &&
        target > 0 &&
        range != null &&
        range > 0;

    double? probability;
    double? maxRange80;
    if (valid) {
      probability = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: group,
        targetDiameterCm: target,
        rangeM: range,
        shots: _shots,
      );
      maxRange80 = HitProbabilityEngine.maxRangeForProbability(
        groupDiameterMoa: group,
        targetDiameterCm: target,
        probability: 0.8,
        shots: _shots,
      );
    }

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Vuruş Olasılığı'),
      body: MenzilPage(
        children: [
          const MenzilSectionHeader(
            '1 · Grup ve hedef',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          const MenzilNotice(
            tone: MenzilNoticeTone.info,
            message:
                'Grup çapı, atış kağıdında ÖLÇTÜĞÜNÜZ gerçek dağılımdır (tüfek+mühimmat+nişancı dahil). '
                'Rüzgâr veya namlu hızı sapması burada ayrıca eklenmez; onlar zaten ölçülen grubun içindedir.',
          ),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('wez-group'),
                controller: _group,
                label: 'Grup çapı',
                unit: 'MOA',
                helperText: 'Ör. 1,0 MOA',
                info: HitProbabilityFieldInfo.group,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              MenzilSelect<int>(
                key: const Key('wez-shots'),
                label: 'Gruptaki atış sayısı',
                initialValue: _shots,
                info: HitProbabilityFieldInfo.shots,
                items: [
                  for (var n = 2; n <= 10; n++)
                    DropdownMenuItem(value: n, child: Text('$n atış')),
                ],
                onChanged: (v) => setState(
                  () => _shots = v ?? HitProbabilityEngine.defaultShots,
                ),
              ),
              MenzilInput(
                key: const Key('wez-target'),
                controller: _target,
                label: 'Hedef çapı',
                unit: 'cm',
                helperText: 'Ör. vurulacak bölge',
                info: HitProbabilityFieldInfo.target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              MenzilInput(
                key: const Key('wez-range'),
                controller: _range,
                label: 'Menzil',
                unit: 'm',
                info: HitProbabilityFieldInfo.range,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          if (valid) ...[
            const MenzilSectionHeader(
              '2 · Sonuç',
              padding: EdgeInsets.only(
                top: MenzilSpace.md,
                bottom: MenzilSpace.sm,
              ),
            ),
            MenzilMetricGrid(
              columns: 2,
              metrics: [
                MenzilMetric(
                  'Vuruş olasılığı',
                  ToolFormat.dec(probability! * 100, 0),
                  '%',
                ),
                MenzilMetric(
                  '%80 için maks. menzil',
                  maxRange80 == null ? '—' : ToolFormat.dec(maxRange80, 0),
                  maxRange80 == null ? null : 'm',
                ),
              ],
            ),
            const SizedBox(height: MenzilSpace.sm),
            Text(
              'Model: dağılımın dairesel ve Gauss olduğu kabul edilir; grup çapı atış sayısına '
              'göre sigmaya çevrilir (5 atışta grup çapı ≈ 3,07 sigma). Basitleştirilmiş bir '
              'tahmindir — gerçek atış sonuçlarının yerini tutmaz.',
              style: MenzilType.caption(c.ink2),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: MenzilSpace.md),
              child: Text(
                'Üç alanı da pozitif bir sayı ile doldurun.',
                style: MenzilType.caption(c.ink2),
              ),
            ),
        ],
      ),
    );
  }
}

/// ⓘ texts of the Vuruş Olasılığı fields (owner rule, 2026-10-07).
abstract final class HitProbabilityFieldInfo {
  static const group =
      'Kâğıtta ölçtüğünüz grubun çapı: en uzak iki deliğin merkezleri arası, '
      'MOA olarak. 100 m’de 1 MOA ≈ 2,9 cm. Örnek: 100 m’de 2,9 cm’lik grup '
      '= 1,0 MOA.';
  static const shots =
      'Grubu kaç atışla attığınız. Aynı çapta grup, daha çok atışla '
      'atıldıysa tüfek daha isabetlidir. Örnek: 5 atış.';
  static const target =
      'Vurmak istediğiniz bölgenin çapı (öldürücü bölge, gong veya halka). '
      'Örnek: 10 cm.';
  static const range = 'Hedefe olan mesafe. Telemetre ile ölçün. Örnek: 100 m.';
}
