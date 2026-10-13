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

  /// The link under the Rüzgâr card that opens the guide (owner,
  /// 2026-10-13 19:49: a popup, not an inline block).
  static const linkLabel = 'Rüzgâr tahmini nasıl yapılır?';

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

  /// Opens the guide the same way a field ⓘ opens its text
  /// ([MenzilInfoButton]'s AlertDialog), with a Kapat action.
  static Future<void> show(BuildContext context, {required bool metric}) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('wind-guide-dialog'),
          title: const Text(title, key: Key('wind-guide-title')),
          content: SingleChildScrollView(child: WindGuideLines(metric: metric)),
          actions: [
            TextButton(
              key: const Key('wind-guide-close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
}

/// The six guide lines, left-aligned, one bullet each.
class WindGuideLines extends StatelessWidget {
  final bool metric;

  const WindGuideLines({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final lines = WindGuide.lines(metric: metric);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: MenzilSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: MenzilType.body(c.ink2)),
                Expanded(
                  child: Text(
                    lines[i],
                    key: Key('wind-guide-line-$i'),
                    textAlign: TextAlign.left,
                    style: MenzilType.body(
                      c.ink,
                    ).copyWith(fontFeatures: MenzilType.tabular),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Link-style button between the Rüzgâr card and "Pro Ayarlara Geç"; the
/// guide itself opens in a popup (owner, 2026-10-13 19:49).
class WindGuideLink extends StatelessWidget {
  final bool metric;

  const WindGuideLink({super.key, required this.metric});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: const Key('wind-guide-link'),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => WindGuide.show(context, metric: metric),
        child: const Text(WindGuide.linkLabel),
      ),
    ),
  );
}
