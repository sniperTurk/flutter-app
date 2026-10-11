import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'usage_guide_content.dart';

/// Araçlar > Kullanım rehberi (owner draft, 2026-10-11): a short Turkish
/// guide to the main flows. Plain layout in the app's theme and typeface:
/// one card per section, no bold text.
class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  /// Section titles: the heading face at regular weight (no bold).
  static TextStyle titleStyle(Color color) => MenzilType.heading(
    color,
    size: 19,
  ).copyWith(fontWeight: FontWeight.w400);

  /// Paragraphs: the body face at regular weight (no bold).
  static TextStyle textStyle(Color color) =>
      MenzilType.body(color).copyWith(fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Kullanım rehberi'),
      body: MenzilPage(
        key: const Key('usage-guide-page'),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: MenzilSpace.md),
            child: Text(UsageGuideContent.intro, style: textStyle(c.ink2)),
          ),
          for (final section in UsageGuideContent.sections)
            MenzilCard(
              key: Key('usage-guide-${section.title}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(section.title, style: titleStyle(c.ink)),
                  ),
                  for (final paragraph in section.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(top: MenzilSpace.sm),
                      child: Text(paragraph, style: textStyle(c.ink)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
