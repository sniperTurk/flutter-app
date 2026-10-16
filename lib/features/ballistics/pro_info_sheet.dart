import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import 'pro_section_info.dart';

/// One Ne? / Neden önemli? / Nasıl? explanation of a Pro Ayarlar box, with
/// an optional note under it (the PCP spin drift note).
class ProInfoEntry {
  final ProExplain explain;
  final String? note;
  const ProInfoEntry(this.explain, {this.note});
}

/// One field of a Pro Ayarlar box as listed under "Kutular": its label and
/// its short explanation. The boxes inside a Pro section have no ⓘ of their
/// own (owner, 2026-10-16 21:17): this list is where their text lives.
class ProInfoField {
  final String label;
  final String text;
  const ProInfoField(this.label, this.text);
}

/// Opens the explanation of a Pro Ayarlar box as a bottom sheet (owner,
/// 2026-10-13: "alttan açılan sayfa"; one information source per box: the
/// ⓘ next to the box title; owner, 2026-10-16: the fields in the box have no
/// ⓘ of their own, their texts are listed here under "Kutular"). [text] is
/// a single plain paragraph shown before the entries (Garmin saati, owner
/// 2026-10-16: one paragraph, no Ne? / Nasıl?).
Future<void> showProInfoSheet(
  BuildContext context, {
  required String title,
  required List<ProInfoEntry> entries,
  List<ProInfoField> fields = const [],
  String? text,
}) {
  final c = MenzilColors.of(context);
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    enableDrag: true,
    backgroundColor: c.surface,
    // Up to ~85 % of the screen; the Pro page stays visible, dimmed, above.
    constraints: BoxConstraints(maxHeight: height * 0.85),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ProInfoSheet(
      title: title,
      entries: entries,
      fields: fields,
      text: text,
    ),
  );
}

/// Body of the Pro explanation bottom sheet: title, the box's explanations,
/// "Kutular" (each field with its explanation) and a full-width "Kapat".
class ProInfoSheet extends StatelessWidget {
  final String title;
  final List<ProInfoEntry> entries;
  final List<ProInfoField> fields;
  final String? text;

  const ProInfoSheet({
    super.key = const Key('pro-info-sheet'),
    required this.title,
    required this.entries,
    this.fields = const [],
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final body = MenzilType.body(c.ink2).copyWith(height: 1.4);
    const bold = TextStyle(fontWeight: FontWeight.w600);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MenzilSpace.xl,
            0,
            MenzilSpace.xl,
            MenzilSpace.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: const Key('pro-info-title'),
              style: MenzilType.heading(c.ink, size: 20),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            key: const Key('pro-info-scroll'),
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.xl,
              0,
              MenzilSpace.xl,
              MenzilSpace.md,
            ),
            // Left-aligned like every ⓘ text (owner, 2026-10-13 20:28).
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.start,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (text case final text?)
                    Padding(
                      padding: const EdgeInsets.only(top: MenzilSpace.sm),
                      child: Text(
                        text,
                        key: const Key('pro-info-text'),
                        textAlign: TextAlign.start,
                        style: body,
                      ),
                    ),
                  for (final e in entries)
                    _Explanation(
                      entry: e,
                      // A title equal to the sheet title is not repeated
                      // (owner, 2026-10-12).
                      showTitle: e.explain.title != title,
                      style: body,
                      bold: bold,
                    ),
                  if (fields.isNotEmpty) ...[
                    const SizedBox(height: MenzilSpace.md),
                    Divider(height: 1, color: c.line),
                    const SizedBox(height: MenzilSpace.md),
                    Semantics(
                      header: true,
                      child: Text(
                        'Kutular',
                        key: const Key('pro-info-fields'),
                        style: MenzilType.body(
                          c.ink,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: MenzilSpace.xs),
                    for (var i = 0; i < fields.length; i++)
                      ProInfoFieldEntry(
                        index: i,
                        field: fields[i],
                        style: body,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Full-width "Kapat" in the thumb zone.
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            MenzilSpace.xl,
            MenzilSpace.sm,
            MenzilSpace.xl,
            MenzilSpace.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('pro-info-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ne? / Neden önemli? / Nasıl? of one setting as separate paragraphs, the
/// questions bold; "Nasıl?" lines starting with "•" become bullet rows.
class _Explanation extends StatelessWidget {
  final ProInfoEntry entry;
  final bool showTitle;
  final TextStyle style;
  final TextStyle bold;
  const _Explanation({
    required this.entry,
    required this.showTitle,
    required this.style,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final e = entry.explain;
    Widget question(String q, String text) => Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$q ', style: bold),
            TextSpan(text: text),
          ],
        ),
        textAlign: TextAlign.start,
        style: style,
      ),
    );
    final how = e.how.split('\n');
    return Padding(
      key: ValueKey('pro-explain-${e.title}'),
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle) ...[
            Text(
              e.title,
              style: MenzilType.body(
                c.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: MenzilSpace.xs),
          ],
          question('Ne?', e.what),
          question('Neden önemli?', e.why),
          question('Nasıl?', how.first),
          for (final line in how.skip(1))
            if (line.startsWith('•'))
              Padding(
                padding: const EdgeInsets.only(
                  left: MenzilSpace.sm,
                  bottom: MenzilSpace.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: style),
                    const SizedBox(width: MenzilSpace.sm),
                    Expanded(
                      child: Text(
                        line.substring(1).trim(),
                        textAlign: TextAlign.start,
                        style: style,
                      ),
                    ),
                  ],
                ),
              )
            else if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: MenzilSpace.xs),
                child: Text(line, textAlign: TextAlign.start, style: style),
              ),
          if (entry.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: MenzilSpace.sm),
              child: Text(
                entry.note!,
                key: const Key('pro-spin-pcp-note'),
                textAlign: TextAlign.start,
                style: MenzilType.caption(c.amberInk),
              ),
            ),
        ],
      ),
    );
  }
}

/// One "Kutular" line: the field label in bold and its explanation.
class ProInfoFieldEntry extends StatelessWidget {
  final int index;
  final ProInfoField field;
  final TextStyle style;
  const ProInfoFieldEntry({
    super.key,
    required this.index,
    required this.field,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Container(
      key: ValueKey('pro-info-field-$index'),
      margin: const EdgeInsets.only(bottom: MenzilSpace.xs),
      // Same inset as before (3 pt accent stripe + padding), so the list
      // keeps its place.
      padding: const EdgeInsets.fromLTRB(
        MenzilSpace.md + 3,
        MenzilSpace.xs,
        MenzilSpace.sm,
        MenzilSpace.xs,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${field.label}: ',
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
            TextSpan(text: field.text),
          ],
        ),
        textAlign: TextAlign.start,
        style: style,
      ),
    );
  }
}
