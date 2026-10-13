import 'package:flutter/material.dart';

import '../../core/beaufort.dart';
import '../../core/unit_system.dart';
import '../../ui/menzil_theme.dart';

/// "Rüzgârı gözle tahmin et" on Hava Durumu (owner, 2026-10-13): what the
/// shooter sees and the matching speed range, Beaufort forces 0–5. Display
/// only: it never writes into a box (the old Rüzgâr gözlemi select did and
/// overwrote a fetched or measured wind).
abstract final class WindGuide {
  static const title = 'Rüzgârı gözle tahmin et';

  /// One decimal with a Turkish comma; an exact zero stays "0".
  static String number(double v) =>
      v == 0 ? '0' : v.toStringAsFixed(1).replaceAll('.', ',');

  /// The guide lines, numbers from [Beaufort.classes] in m/s or mph.
  static List<String> lines({required bool metric}) => [
    for (final b in Beaufort.guideClasses)
      '${b.guide}: ${_range(b, metric)} ${metric ? 'm/s' : 'mph'}',
  ];

  static String _range(BeaufortClass b, bool metric) {
    double v(double mps) => metric ? mps : UnitSystem.mpsToMph(mps);
    return '${number(v(b.minMps))}–${number(v(b.maxMps))}';
  }
}

class WindGuideBlock extends StatelessWidget {
  final bool metric;

  const WindGuideBlock({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final lines = WindGuide.lines(metric: metric);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MenzilSpace.xxs,
        MenzilSpace.xxs,
        MenzilSpace.xxs,
        MenzilSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            WindGuide.title,
            key: const Key('wind-guide-title'),
            style: MenzilType.body(c.ink).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: MenzilSpace.xs),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: MenzilSpace.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: MenzilType.body(c.ink2)),
                  Expanded(
                    child: Text(
                      lines[i],
                      key: Key('wind-guide-line-$i'),
                      style: MenzilType.body(
                        c.ink2,
                      ).copyWith(fontFeatures: MenzilType.tabular),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
