import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'privacy_policy_content.dart';

/// Web address of the published privacy policy, set at build time with
/// `--dart-define=PRIVACY_POLICY_URL=https://…`. Empty by default.
///
/// The app has no url-launch package and none is added (owner, 2026-10-14),
/// so there is no "Web'de aç" button: when set, the address is only shown
/// as selectable text under the policy.
const String privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

/// Araçlar > Gizlilik politikası (App Review 5.1.1(i), owner 2026-10-14):
/// the Turkish policy built into the app, so it opens offline. Same plain
/// layout as Kullanım rehberi: one card per section, left-aligned, system
/// font, no bold text.
class PrivacyPolicyScreen extends StatelessWidget {
  /// The published policy address; tests pass their own value.
  final String webUrl;

  const PrivacyPolicyScreen({super.key, this.webUrl = privacyPolicyUrl});

  static TextStyle _titleStyle(Color color) =>
      MenzilType.heading(color, size: 19).copyWith(fontWeight: FontWeight.w400);

  static TextStyle _textStyle(Color color) =>
      MenzilType.body(color).copyWith(fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final url = webUrl.trim();
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Gizlilik politikası'),
      body: MenzilPage(
        key: const Key('privacy-policy-page'),
        children: [
          Semantics(
            header: true,
            child: Text(
              PrivacyPolicyContent.heading,
              key: const Key('privacy-policy-heading'),
              style: _titleStyle(c.ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: MenzilSpace.xs,
              bottom: MenzilSpace.md,
            ),
            child: Text(
              PrivacyPolicyContent.updated,
              textAlign: TextAlign.start,
              style: _textStyle(c.ink2),
            ),
          ),
          for (final section in PrivacyPolicyContent.sections)
            MenzilCard(
              key: Key('privacy-policy-${section.title}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(section.title, style: _titleStyle(c.ink)),
                  ),
                  for (final paragraph in section.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(top: MenzilSpace.sm),
                      child: Text(
                        paragraph,
                        textAlign: TextAlign.start,
                        style: _textStyle(c.ink),
                      ),
                    ),
                ],
              ),
            ),
          if (url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: MenzilSpace.sm),
              child: SelectableText(
                'Web adresi: $url',
                key: const Key('privacy-policy-web-address'),
                textAlign: TextAlign.start,
                style: _textStyle(c.ink2),
              ),
            ),
        ],
      ),
    );
  }
}
