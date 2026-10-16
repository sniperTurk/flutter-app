import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Pro Ayarlar row grid (owner, 2026-10-16 07:59–08:08: "infolar çok
/// düzensiz", "Tamam yap"): the ⓘ sits [proInfoGap] after the title text,
/// the summary and chevron end at the card's right edge, so every row's
/// values and chevrons share one column.
const double proInfoGap = 8;

/// The ⓘ tap target: 44 × 44 pt, starting exactly at the title's right
/// edge so it never covers the title text.
const double proInfoTarget = 44;

/// Chevron size and the gap before it.
const double proChevronSize = 24;
const double _chevronGap = MenzilSpace.xs;

/// The ⓘ of a Pro row: its own 44 × 44 pt tap target with the icon at its
/// left edge plus [proInfoGap]. A tap anywhere in the target opens only the
/// explanation; the row's tap handler never sees it (the inner button wins
/// the gesture arena).
Widget proRowInfoButton({
  required Key key,
  required String title,
  required VoidCallback onPressed,
}) => SizedBox(
  width: proInfoTarget,
  height: proInfoTarget,
  child: MenzilInfoButton(
    key: key,
    title: title,
    tooltip: 'Açıklama: $title',
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsetsDirectional.only(start: proInfoGap),
    onPressed: onPressed,
  ),
);

/// One Pro Ayarlar box header line:
/// [title][ⓘ][flexible space][value][⌄].
///
/// The title gets the width it needs, so it stays on one line; when space
/// runs out the value is shortened with "…" first and the title wraps only
/// as a last resort. The ⓘ always follows the title text directly.
class ProRowHeader extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final Widget? info;
  final String? value;

  /// Hides [value] (open box) while keeping its space reserved, so the
  /// title does not jump between one and two lines when the box toggles.
  final bool showValue;
  final Key? valueKey;
  final TextStyle? valueStyle;
  final IconData chevron;
  final Color chevronColor;

  const ProRowHeader({
    super.key,
    required this.title,
    required this.titleStyle,
    required this.chevron,
    required this.chevronColor,
    this.info,
    this.value,
    this.showValue = true,
    this.valueKey,
    this.valueStyle,
  });

  /// One-line width of [text] as [Text] would draw it.
  double _width(BuildContext context, String text, TextStyle? style) {
    var effective = DefaultTextStyle.of(context).style.merge(style);
    if (MediaQuery.boldTextOf(context)) {
      effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: effective),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final v = value;
        final infoWidth = info == null ? 0.0 : proInfoTarget;
        // The value may shrink down to its first letter and "…" before the
        // title has to wrap.
        final reserve = v == null || v.isEmpty
            ? 0.0
            : math.min(
                _width(context, v, valueStyle),
                _width(context, '${v.characters.first}…', valueStyle),
              );
        final titleMax = math.max(
          0.0,
          box.maxWidth - infoWidth - reserve - _chevronGap - proChevronSize,
        );
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleMax),
              child: Text(
                title,
                style: titleStyle,
                // The box ends at the text, so the ⓘ follows the text
                // even when it has to wrap.
                textWidthBasis: TextWidthBasis.longestLine,
              ),
            ),
            if (info case final i?) i,
            Expanded(
              child: v == null || !showValue
                  ? const SizedBox.shrink()
                  : Text(
                      v,
                      key: valueKey,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
            ),
            const SizedBox(width: _chevronGap),
            Icon(chevron, size: proChevronSize, color: chevronColor),
          ],
        );
      },
    );
  }
}
