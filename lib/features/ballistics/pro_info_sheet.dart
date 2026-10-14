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
/// its short ⓘ text (word for word the field's own `info:`).
class ProInfoField {
  final String label;
  final String text;
  const ProInfoField(this.label, this.text);
}

/// Opens the explanation of a Pro Ayarlar box as a bottom sheet (owner,
/// 2026-10-13: "alttan açılan sayfa"; one information source per box: the
/// box ⓘ and every field ⓘ in it open this same sheet). [highlight] is the
/// index in [fields] of the field whose ⓘ was tapped; it is tinted and
/// scrolled into view.
Future<void> showProInfoSheet(
  BuildContext context, {
  required String title,
  required List<ProInfoEntry> entries,
  List<ProInfoField> fields = const [],
  int? highlight,
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
      highlight: highlight,
    ),
  );
}

/// Body of the Pro explanation bottom sheet: title, the box's explanations,
/// "Kutular" (each field with its ⓘ text) and a full-width "Kapat".
class ProInfoSheet extends StatefulWidget {
  final String title;
  final List<ProInfoEntry> entries;
  final List<ProInfoField> fields;
  final int? highlight;

  const ProInfoSheet({
    super.key = const Key('pro-info-sheet'),
    required this.title,
    required this.entries,
    this.fields = const [],
    this.highlight,
  });

  @override
  State<ProInfoSheet> createState() => _ProInfoSheetState();
}

class _ProInfoSheetState extends State<ProInfoSheet> {
  final _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.highlight != null) {
      // Bring the tapped field's entry into view once laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _highlightKey.currentContext;
        if (!mounted || target == null) return;
        // Its top (the bold label) at the top of the visible part, also when
        // the entry is taller than the view (narrow phone, large text).
        Scrollable.ensureVisible(target);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final body = MenzilType.body(c.ink2).copyWith(height: 1.4);
    const bold = TextStyle(fontWeight: FontWeight.w600);
    final hl = widget.highlight;
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
              widget.title,
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
                  for (final e in widget.entries)
                    _Explanation(
                      entry: e,
                      // A title equal to the sheet title is not repeated
                      // (owner, 2026-10-12).
                      showTitle: e.explain.title != widget.title,
                      style: body,
                      bold: bold,
                    ),
                  if (widget.fields.isNotEmpty) ...[
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
                    for (var i = 0; i < widget.fields.length; i++)
                      ProInfoFieldEntry(
                        key: i == hl ? _highlightKey : null,
                        index: i,
                        field: widget.fields[i],
                        highlighted: i == hl,
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

/// One "Kutular" line: the field label in bold and its ⓘ text. The field
/// whose ⓘ opened the sheet is tinted with a left accent.
class ProInfoFieldEntry extends StatelessWidget {
  final int index;
  final ProInfoField field;
  final bool highlighted;
  final TextStyle style;
  const ProInfoFieldEntry({
    super.key,
    required this.index,
    required this.field,
    required this.highlighted,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Semantics(
      selected: highlighted,
      child: Container(
        key: ValueKey('pro-info-field-$index'),
        margin: const EdgeInsets.only(bottom: MenzilSpace.xs),
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.md,
          MenzilSpace.xs,
          MenzilSpace.sm,
          MenzilSpace.xs,
        ),
        decoration: BoxDecoration(
          color: highlighted ? c.cyanSoft : null,
          border: Border(
            left: BorderSide(
              color: highlighted ? c.cyan : Colors.transparent,
              width: 3,
            ),
          ),
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
      ),
    );
  }
}
