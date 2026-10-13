import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'menzil_icons.dart';
import 'menzil_theme.dart';

// ---------------------------------------------------------------------------
// Page scaffolding
// ---------------------------------------------------------------------------

/// Scrollable page body shared by every tab: centred column with the common
/// gutter, a maximum width for large screens and a keyboard-friendly scroll.
/// Every child is built eagerly (no lazy list) so form state is never lost
/// while scrolling and widgets far down the page stay addressable.
class MenzilPage extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  /// Justifies the page's paragraphs. Only the Hedef tab sets this (owner,
  /// 2026-10-13: "sadece Hedef sayfasında sağa sola yaslı olsun yazılar");
  /// every other page is left-aligned because explanations now live in ⓘ
  /// popups and justified values (Profil özeti) showed wide word gaps.
  final bool justify;

  const MenzilPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      MenzilSpace.gutter,
      MenzilSpace.md,
      MenzilSpace.gutter,
      MenzilSpace.xl,
    ),
    this.controller,
    this.justify = false,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: MenzilSpace.maxContentWidth,
        ),
        // Left-aligned everywhere; only the Hedef page is justified (owner,
        // 2026-10-13). One-line labels are unaffected either way.
        child: DefaultTextStyle.merge(
          textAlign: justify ? TextAlign.justify : TextAlign.start,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// Header for secondary routes (Katalog, Ayarlar, profile editor). Uses the
/// same bar background, border and bold title as the main top bar.
class MenzilSubPageBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const MenzilSubPageBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    // A long title ("Konum için mesafe" with larger iOS text on a 375 pt
    // phone) shrinks a little instead of ending in "…".
    title: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(title, maxLines: 1),
    ),
    actions: [
      ...actions,
      const SizedBox(width: MenzilSpace.xs),
    ],
  );
}

/// Centred loading / error / empty state.
class MenzilStateMessage extends StatelessWidget {
  final IconData? icon;
  final String message;
  final Widget? action;

  const MenzilStateMessage({
    super.key,
    this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 42, color: c.ink2),
              const SizedBox(height: MenzilSpace.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: MenzilType.body(c.ink),
            ),
            if (action != null) ...[
              const SizedBox(height: MenzilSpace.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar and bottom navigation
// ---------------------------------------------------------------------------

/// Fixed top bar: page title or "Sniper Türk" (left), a compact
/// active-profile selector and the unit / theme buttons (right).
class MenzilTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget profileSelector;

  /// Unit button; omitted when null (the app is metric only since V380).
  final String? unitLabel;
  final VoidCallback? onUnitTap;
  final String themeLabel;
  final VoidCallback? onThemeTap;

  /// False hides the "Sniper Türk" brand (shown when there is no title).
  final bool showBrand;

  /// Page title shown instead of the brand (Hava Durumu, Pro, Hedef, …).
  final String? title;

  /// Every page title this bar can show. The title slot is as wide as the
  /// widest of these (and the brand), so the profile box keeps the same left
  /// edge and width on every tab (owner, 2026-10-13: "ortadaki kutu büyüyüp
  /// küçülüyor, bu olmasın"). The current [title] is always measured too.
  final List<String> slotTitles;

  static const double height = 58;

  /// Page title size (owner, 2026-10-12: every page title the same size).
  static const double titleSize = 18;

  /// Upper limit of the title slot as a share of the bar width; past it the
  /// title scales down (FittedBox) instead of squeezing the profile box.
  static const double titleSlotMaxFraction = 0.42;

  const MenzilTopBar({
    super.key,
    required this.profileSelector,
    this.unitLabel,
    this.onUnitTap,
    required this.themeLabel,
    this.onThemeTap,
    this.showBrand = true,
    this.title,
    this.slotTitles = const [],
  });

  /// Fixed width of the title slot: the widest of [titles] (and the brand
  /// when [includeBrand]) laid out with the real styles and [textScaler],
  /// capped at [titleSlotMaxFraction] of [barWidth].
  static double titleSlotWidth({
    required double barWidth,
    required Iterable<String> titles,
    required bool includeBrand,
    required TextStyle titleStyle,
    required TextStyle brandStyle,
    required TextScaler textScaler,
    TextDirection textDirection = TextDirection.ltr,
    Locale? locale,
  }) {
    double widest = 0;
    void measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }

    for (final t in titles) {
      measure(t, titleStyle);
    }
    if (includeBrand) measure(MenzilBrand.text, brandStyle);
    final cap = barWidth * titleSlotMaxFraction;
    return math.min(widest.ceilToDouble(), cap);
  }

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Material(
        color: c.bg,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // On the narrowest phones the wordmark collapses to the
                  // reticle glyph so the profile selector keeps usable width.
                  final compact = constraints.maxWidth < 350;
                  final titleStyle = MenzilType.heading(c.ink, size: titleSize);
                  final base = DefaultTextStyle.of(context).style;
                  final slotWidth = titleSlotWidth(
                    barWidth: constraints.maxWidth,
                    titles: [...slotTitles, if (title != null) title!],
                    includeBrand: showBrand,
                    titleStyle: base.merge(titleStyle),
                    brandStyle: base.merge(MenzilBrand.style(c.ink)),
                    textScaler: MediaQuery.textScalerOf(context),
                    textDirection: Directionality.of(context),
                    locale: Localizations.maybeLocaleOf(context),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MenzilSpace.gutter,
                    ),
                    child: Row(
                      children: [
                        // Left: page title, or "Sniper Türk" on Profil, in a
                        // slot of FIXED width (owner, 2026-10-13): the slot
                        // fits the widest title of any tab, so the profile
                        // box starts at the same x and has the same width on
                        // every page. Titles stay left-aligned and scale
                        // down (FittedBox) only when the cap is hit on
                        // narrow phones or with large text.
                        SizedBox(
                          key: const Key('top-bar-title-slot'),
                          width: slotWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: title != null
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        title!,
                                        key: const Key('top-bar-title'),
                                        maxLines: 1,
                                        style: titleStyle,
                                      ),
                                    ),
                                  )
                                : showBrand
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: MenzilBrand(compact: compact),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: MenzilSpace.md),
                        Expanded(
                          child: KeyedSubtree(
                            key: const Key('top-bar-profile-slot'),
                            child: profileSelector,
                          ),
                        ),
                        const SizedBox(width: MenzilSpace.sm),
                        if (unitLabel != null) ...[
                          MenzilBarButton(
                            label: unitLabel!,
                            tooltip: 'Birim sistemi',
                            onPressed: onUnitTap,
                          ),
                          const SizedBox(width: MenzilSpace.xs),
                        ],
                        MenzilBarButton(
                          label: themeLabel,
                          tooltip: 'Tema',
                          onPressed: onThemeTap,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenzilBrand extends StatelessWidget {
  final bool compact;
  const MenzilBrand({super.key, this.compact = false});

  static const String text = 'Sniper Türk';

  /// Brand size (owner, 2026-10-13: "Sniper Türk yazısını biraz büyüt"),
  /// up from 18; page titles stay at [MenzilTopBar.titleSize].
  static const double fontSize = 20;

  static TextStyle style(Color ink) => MenzilType.heading(ink, size: fontSize);

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    // "Sniper Türk", text only (owner, 2026-10-09). On the narrowest phones
    // it scales down instead of squeezing the profile selector.
    return Semantics(
      header: true,
      label: 'Sniper Türk',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            key: const Key('top-bar-brand'),
            maxLines: 1,
            style: style(c.ink),
          ),
        ),
      ),
    );
  }
}

/// Small square-ish button used in the top bar (unit system, theme).
class MenzilBarButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  const MenzilBarButton({
    super.key,
    required this.label,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        container: true,
        button: true,
        label: '$tooltip: $label',
        child: ExcludeSemantics(
          child: Material(
            color: c.surface,
            // Same height and rounding as the profile box beside it, with
            // room above the bar's bottom line (owner, 2026-10-12).
            shape: StadiumBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenzilNavItem {
  final MenzilGlyph glyph;
  final String label;
  const MenzilNavItem(this.glyph, this.label);
}

/// Five-tab bottom navigation with the amber indicator on the active tab.
/// Sits in `Scaffold.bottomNavigationBar`, so page content is laid out above
/// it and never underneath; the home-indicator inset is padded inside.
class MenzilBottomNavigation extends StatelessWidget {
  final List<MenzilNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const MenzilBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Material(
        color: c.surface,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MenzilSpace.maxContentWidth,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onSelected(i),
                          colors: c,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final MenzilNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final MenzilColors colors;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? colors.ink : colors.ink2;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (selected)
                  FractionallySizedBox(
                    widthFactor: 0.56,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.amber,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 9, 2, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MenzilIcon(item.glyph, size: 24, color: fg),
                      const SizedBox(height: 3),
                      // With larger iOS text a fifth of a 375–393 pt phone
                      // is too narrow for "Hava Durumu" ("Hava Duru…"); the
                      // label shrinks a little instead of being cut. At the
                      // default text size nothing changes (2026-10-11).
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Containers
// ---------------------------------------------------------------------------

/// Rounded surface card with the shared border. [accent] draws the coloured
/// edge used by the result cards (amber = elevation, cyan = wind).
class MenzilCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double radius;
  final Color? background;

  /// Edge colour instead of the hairline (owner, 2026-10-12: notices on
  /// a plain card with a thin orange edge).
  final Color? borderColor;
  final EdgeInsetsGeometry margin;

  const MenzilCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MenzilSpace.lg),
    this.accent,
    this.radius = MenzilRadius.card,
    this.background,
    this.borderColor,
    this.margin = const EdgeInsets.only(bottom: MenzilSpace.md),
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final shape = BorderRadius.circular(radius);
    Widget body = Padding(padding: padding, child: child);
    if (accent != null) {
      body = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(left: 7), child: body),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: ColoredBox(color: accent!),
          ),
        ],
      );
    }
    // A Material (not a DecoratedBox) owns the card surface so ListTile /
    // SwitchListTile children paint their background and ink on this card
    // instead of tripping Flutter's "ink splashes may be invisible" assertion.
    return Padding(
      padding: margin,
      child: Material(
        color: background ?? c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(
            color: borderColor ?? c.line,
            width: MenzilSpace.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

/// Section title in the bold heading face, optional trailing widget and
/// subtitle. Marked as a header for VoiceOver.
class MenzilSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Title size; the Profil summary cards use a smaller 18 (owner,
  /// 2026-10-13: "Başlıkları biraz küçültürmüsün").
  final double size;

  const MenzilSectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.size = 22,
    this.padding = const EdgeInsets.only(
      top: MenzilSpace.sm,
      bottom: MenzilSpace.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: MenzilType.heading(c.ink, size: size),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: MenzilType.caption(c.ink2)),
          ],
        ],
      ),
    );
  }
}

enum MenzilNoticeTone { info, warning, danger }

/// Inline notice with a coloured left edge (replaces ad-hoc warning text).
class MenzilNotice extends StatelessWidget {
  final String? title;
  final String message;
  final MenzilNoticeTone tone;
  final IconData? icon;

  /// Optional ⓘ explanation shown at the end of the notice; [infoTitle]
  /// names the dialog (defaults to [title] or "Bilgi").
  final String? info;
  final String? infoTitle;

  const MenzilNotice({
    super.key,
    this.title,
    required this.message,
    this.tone = MenzilNoticeTone.info,
    this.icon,
    this.info,
    this.infoTitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    // Warnings on the plain card with a thin orange edge instead of the
    // brownish fill (owner, 2026-10-12: "gözüme güzel gözükmüyor").
    final warning = tone == MenzilNoticeTone.warning;
    final (Color bg, Color edge) = switch (tone) {
      MenzilNoticeTone.info => (c.cyanSoft, c.cyan),
      MenzilNoticeTone.warning => (c.surface, c.amber),
      MenzilNoticeTone.danger => (c.dangerSoft, c.danger),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MenzilRadius.button),
          border: warning
              ? Border.all(color: edge)
              : Border(left: BorderSide(color: edge, width: 5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: c.ink),
                const SizedBox(width: MenzilSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          title!,
                          style: MenzilType.label(c.ink).copyWith(fontSize: 14),
                        ),
                      ),
                    Text(
                      message,
                      // Left-aligned (owner, 2026-10-13: only the Hedef
                      // page is justified).
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (info != null)
                MenzilInfoButton(
                  title: infoTitle ?? title ?? 'Bilgi',
                  text: info!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible card section (advanced inputs, help text).
class MenzilAccordion extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool initiallyExpanded;
  final Widget child;

  const MenzilAccordion({
    super.key,
    required this.title,
    this.subtitle,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  State<MenzilAccordion> createState() => _MenzilAccordionState();
}

class _MenzilAccordionState extends State<MenzilAccordion> {
  late bool open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: () => setState(() => open = !open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MenzilSpace.lg,
                    vertical: MenzilSpace.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: MenzilType.heading(c.ink, size: 20),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: MenzilType.caption(c.ink2),
                              ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.expand_more, color: c.ink2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MenzilSpace.lg,
                0,
                MenzilSpace.lg,
                MenzilSpace.lg,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form controls
// ---------------------------------------------------------------------------

/// "ⓘ" next to a field label: opens a short explanation of the value to
/// enter. Project rule: every value the user types or picks gets one.
/// It stays outside the label's ExcludeSemantics so VoiceOver can reach it.
class MenzilInfoButton extends StatelessWidget {
  final String title;
  final String text;

  /// Optional picture shown above the text (e.g. the wind direction dial).
  final Widget? illustration;

  /// Optional rich content shown instead of [text] (Pro Ayarlar box
  /// explanations, owner 2026-10-13: "Pro sayfasındaki açıklamalar popup
  /// olsun").
  final Widget? body;

  /// Overrides the default "Bilgi: [title]" tooltip / VoiceOver label.
  final String? tooltip;

  /// Label of the closing action ("Tamam" for field ⓘ).
  final String closeLabel;

  /// Replaces the popup (Pro Ayarlar box ⓘ opens a bottom sheet, owner
  /// 2026-10-13).
  final VoidCallback? onPressed;
  const MenzilInfoButton({
    super.key,
    required this.title,
    this.text = '',
    this.illustration,
    this.body,
    this.tooltip,
    this.closeLabel = 'Tamam',
    this.onPressed,
  });

  /// True when a [MenzilInfoScope] above (Pro Ayarlar boxes) showed the
  /// text itself; otherwise the usual popup opens.
  bool _handledByScope(BuildContext context) {
    if (body != null) return false;
    final scope = context.getInheritedWidgetOfExactType<MenzilInfoScope>();
    return scope != null && scope.onInfo(title, text);
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    // ⓘ popups are left-aligned (owner, 2026-10-13).
    final content = body ?? Text(text, textAlign: TextAlign.start);
    return IconButton(
      tooltip: tooltip ?? 'Bilgi: $title',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      // Not compact: compact density shrinks the 44 pt minimum to 40 pt and
      // fails Apple's tap-target guideline (found in the 2026-10-08 audit).
      visualDensity: VisualDensity.standard,
      icon: Icon(Icons.info_outline, size: 18, color: c.ink2),
      onPressed:
          onPressed ??
          () {
            if (_handledByScope(context)) return;
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: illustration == null
                      ? content
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            illustration!,
                            const SizedBox(height: MenzilSpace.md),
                            content,
                          ],
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(closeLabel),
                  ),
                ],
              ),
            );
          },
    );
  }
}

/// Lets the field ⓘ buttons ([MenzilInfoButton]) below it show their text
/// somewhere other than the usual popup. [onInfo] gets the ⓘ's title and
/// text and returns true when it handled them; false falls back to the
/// popup. Used by Pro Ayarlar (owner, 2026-10-13: every field ⓘ in a box
/// opens the box's bottom sheet).
class MenzilInfoScope extends InheritedWidget {
  final bool Function(String title, String text) onInfo;
  const MenzilInfoScope({
    super.key,
    required this.onInfo,
    required super.child,
  });

  @override
  bool updateShouldNotify(MenzilInfoScope oldWidget) => false;
}

/// Label row with an optional [MenzilInfoButton] on the right.
class _LabelWithInfo extends StatelessWidget {
  final Widget label;
  final String title;
  final String? info;
  const _LabelWithInfo({
    required this.label,
    required this.title,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final text = info;
    // ⓘ sits on the right, vertically centred on the label text (owner,
    // 2026-10-09).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: label),
        // Without an ⓘ an invisible one of the same size keeps the label row
        // as tall as its neighbour's, so side-by-side fields line up (owner,
        // 2026-10-09: "Dürbün markası" sat lower than "Odak düzlemi").
        // The label keeps a small gap under its text; the same gap under the
        // ⓘ makes their centres meet.
        Padding(
          padding: const EdgeInsets.only(bottom: MenzilSpace.xxs + 1),
          child: text != null
              ? MenzilInfoButton(title: title, text: text)
              // Same size as MenzilInfoButton (constraints, density, icon),
              // but invisible, untappable and silent for VoiceOver.
              : const ExcludeSemantics(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      child: IconButton(
                        constraints: BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.standard,
                        icon: Icon(Icons.circle, size: 18),
                        onPressed: null,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Label row shared by inputs and selectors: label on the left, unit on the
/// right, constant gap to the control below.
/// Text that drops its bold weight when it needs a second line (owner,
/// 2026-10-11: a wrapped bold label or entry reads heavy). One line keeps
/// [style] as given.
class MenzilWrapText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign? textAlign;

  const MenzilWrapText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.textAlign,
  });

  @override
  State<MenzilWrapText> createState() => _MenzilWrapTextState();
}

/// Measured after layout, not with a LayoutBuilder: dialogs ask their
/// content for intrinsic sizes, which a LayoutBuilder cannot answer.
class _MenzilWrapTextState extends State<MenzilWrapText> {
  bool _wraps = false;

  void _measure(_) {
    if (!mounted) return;
    final width = context.size?.width;
    if (width == null || width <= 0) return;
    final p = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: width + 0.5);
    final wraps = p.didExceedMaxLines;
    p.dispose();
    if (wraps != _wraps) setState(() => _wraps = wraps);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final w = widget;
    return Text(
      w.text,
      maxLines: w.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: w.textAlign,
      style: _wraps ? w.style.copyWith(fontWeight: FontWeight.w400) : w.style,
    );
  }
}

class MenzilFieldLabel extends StatelessWidget {
  final String label;
  final String? unit;
  final Widget? trailing;

  const MenzilFieldLabel({
    super.key,
    required this.label,
    this.unit,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.xxs + 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: MenzilWrapText(label, style: MenzilType.label(c.ink)),
          ),
          if (unit != null) ...[
            const SizedBox(width: MenzilSpace.xs),
            Text(unit!, style: MenzilType.unit(c.ink2)),
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Text input: label row (label + unit) above a rounded, high-contrast field.
/// [semanticLabel] gives VoiceOver the full label including the unit.
class MenzilInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? unit;
  final TextInputType keyboardType;
  final String? helperText;
  final String? errorText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final Widget? labelTrailing;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  /// Explanation shown by the ⓘ button next to the label.
  final String? info;

  /// A list typed one value per line (Kronograf hızları); 1 elsewhere.
  final int minLines;
  final int maxLines;

  const MenzilInput({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.helperText,
    this.errorText,
    this.hintText,
    this.onChanged,
    this.labelTrailing,
    this.textInputAction,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.info,
    this.focusNode,
    this.minLines = 1,
    this.maxLines = 1,
  });

  String get semanticLabel => unit == null ? label : '$label ($unit)';

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelWithInfo(
            title: label,
            info: info,
            label: ExcludeSemantics(
              child: MenzilFieldLabel(
                label: label,
                unit: unit,
                trailing: labelTrailing,
              ),
            ),
          ),
          Semantics(
            label: semanticLabel,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction:
                  textInputAction ??
                  (maxLines > 1
                      ? TextInputAction.newline
                      : TextInputAction.next),
              minLines: minLines,
              maxLines: maxLines,
              onChanged: onChanged,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              scrollPadding: const EdgeInsets.only(bottom: 120),
              // Entries a bit smaller and not bold (owner, 2026-10-11).
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: c.ink,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                helperText: helperText,
                errorText: errorText,
                counterText: maxLength == null ? null : '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector with the same label row and height as [MenzilInput].
/// Uses `initialValue` (not the deprecated `value`); callers that need the
/// selection to reset when its options change must pass a changing [key].
class MenzilSelect<T> extends StatefulWidget {
  final String label;
  final String? unit;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? semanticLabel;

  /// Explanation shown by the ⓘ button next to the label.
  final String? info;

  /// Short text for the closed box, per item (same order as [items]); the
  /// open list keeps the full item text. Null shows the item itself.
  final List<String>? selectedLabels;

  /// Shown while nothing is selected (e.g. "Seçiniz").
  final String? hint;

  /// Shown under the box in the error colour (e.g. a max below the min).
  final String? errorText;

  /// The closed box fits its choice on ONE line by scaling the text down
  /// (never overflowing) instead of cutting it with "…" (owner, 2026-10-13:
  /// Kalibre in a half-width box). Needs [selectedLabels].
  final bool fitSelected;

  /// With [fitSelected]: a shorter text per item (same order as [items]),
  /// shown when the [selectedLabels] text would have to shrink below
  /// [MenzilFitText.minScale] ("Fişeğim listede yok" → "Listede yok").
  final List<String>? shortSelectedLabels;

  /// Height of each entry of the open list. Flutter's default (48) is a
  /// FIXED height: an entry that wraps onto more lines (a long cartridge in
  /// the half-width Kalibre list, which is exactly as wide as its box since
  /// #273) then spills over its neighbours and a tap on its lower lines
  /// lands on the next entry or on nothing. Null lets every entry grow to
  /// its content (still at least 48 high).
  final double? itemHeight;

  const MenzilSelect({
    super.key,
    required this.label,
    this.unit,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.semanticLabel,
    this.info,
    this.selectedLabels,
    this.hint,
    this.errorText,
    this.fitSelected = false,
    this.shortSelectedLabels,
    this.itemHeight = kMinInteractiveDimension,
  }) : assert(!fitSelected || selectedLabels != null);

  /// A list item that allows two lines (long model names) still shows one
  /// line in the closed box (owner, 2026-10-11: the second line overflowed).
  static Widget _oneLine(Widget w) => w is Text && w.data != null
      ? Text(
          w.data!,
          key: w.key,
          style: w.style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        )
      : w;

  @override
  State<MenzilSelect<T>> createState() => MenzilSelectState<T>();
}

/// A [DropdownButton] in the field decoration (a form field cannot narrow
/// its menu): the value lives here, as it did in the form field.
class MenzilSelectState<T> extends State<MenzilSelect<T>> {
  late T? _value = widget.initialValue;

  /// The value currently picked (null: "Seçiniz"); read by tests.
  T? get value => _value;

  /// The theme's outline border without the 4 pt gap it leaves for a
  /// floating label (this box has none).
  static InputBorder? _noGap(InputBorder? b) =>
      b is OutlineInputBorder ? b.copyWith(gapPadding: 0) : b;

  @override
  void didUpdateWidget(covariant MenzilSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _value = widget.initialValue;
    }
  }

  /// The closed box's text for item [i].
  Widget _closed(int i, List<DropdownMenuItem<T>> items) {
    final w = widget;
    if (w.fitSelected) {
      return MenzilFitText(
        w.selectedLabels![i],
        short: w.shortSelectedLabels?[i],
      );
    }
    return w.selectedLabels == null
        ? MenzilSelect._oneLine(items[i].child)
        : Text(w.selectedLabels![i]);
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final w = widget;
    final items = w.items;
    final t = Theme.of(context).inputDecorationTheme;
    // A value that is not one of the items shows as empty.
    final value = items.where((i) => i.value == _value).length == 1
        ? _value
        : null;
    final int? selectedIndex = value == null
        ? null
        : items.indexWhere((i) => i.value == value);
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelWithInfo(
            title: w.label,
            info: w.info,
            label: ExcludeSemantics(
              child: MenzilFieldLabel(label: w.label, unit: w.unit),
            ),
          ),
          Semantics(
            label: w.semanticLabel ?? w.label,
            child: Builder(
              builder: (context) => InputDecorator(
                // The padding is the button's own, so the whole box opens
                // the list, not only the text in its middle.
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  errorText: w.errorText,
                  errorMaxLines: 2,
                  // An outline border keeps its gapPadding (4 pt) free on
                  // both sides of the content; without it the button, and
                  // so the open list, has exactly the box's edges.
                  border: _noGap(t.border),
                  enabledBorder: _noGap(t.enabledBorder),
                  focusedBorder: _noGap(t.focusedBorder),
                  errorBorder: _noGap(t.errorBorder),
                  focusedErrorBorder: _noGap(t.focusedErrorBorder),
                  disabledBorder: _noGap(t.disabledBorder),
                ),
                isEmpty: false,
                child: DropdownButtonHideUnderline(
                  // The open list has exactly the box's left and right edge
                  // (owner, 2026-10-13: "daha büyük açılsın ama kutudan
                  // dışarı çıkmasın"). Unaligned, Flutter widens the box by
                  // 16 pt left and 24 pt right before placing the list;
                  // aligned it uses the box itself, and with no menuWidth
                  // the list is exactly as wide as the box.
                  child: ButtonTheme.fromButtonThemeData(
                    data: ButtonTheme.of(
                      context,
                    ).copyWith(alignedDropdown: true),
                    child: DropdownButton<T>(
                      // Always opens DOWNWARD (owner, 2026-10-12): Flutter
                      // places the list so the selected entry covers the box,
                      // which opened it upward for a later entry. The box
                      // therefore shows the choice as its hint and the list
                      // starts at its first entry.
                      value: null,
                      // Every list box says "Seçiniz" until something is
                      // picked (owner, 2026-10-11).
                      hint: selectedIndex == null
                          ? (w.fitSelected
                                ? DefaultTextStyle.merge(
                                    style: TextStyle(color: c.ink2),
                                    child: MenzilFitText(w.hint ?? 'Seçiniz'),
                                  )
                                : Text(
                                    w.hint ?? 'Seçiniz',
                                    style: TextStyle(color: c.ink2),
                                  ))
                          : DefaultTextStyle.merge(
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.ink),
                              child: _closed(selectedIndex, items),
                            ),
                      // List entries in regular weight (owner, 2026-10-11).
                      items: [
                        for (final it in items)
                          DropdownMenuItem<T>(
                            key: it.key,
                            value: it.value,
                            enabled: it.enabled,
                            onTap: it.onTap,
                            alignment: it.alignment,
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                              ),
                              child: it.child,
                            ),
                          ),
                      ],
                      onChanged: w.onChanged == null
                          ? null
                          : (v) {
                              setState(() => _value = v);
                              w.onChanged!(v);
                            },
                      // The closed box always shows ONE line (owner,
                      // 2026-10-09: "Normal (0 MOA)" wrapped and was cut off).
                      // With value null Flutter shows the entry whose value is
                      // null ("Seçiniz" in lists that offer it): that slot
                      // shows the current choice instead.
                      selectedItemBuilder: (context) => [
                        for (var i = 0; i < items.length; i++)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: DefaultTextStyle.merge(
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              child: () {
                                final k = items[i].value == null
                                    ? selectedIndex
                                    : i;
                                if (k == null) {
                                  return Text(
                                    w.hint ?? 'Seçiniz',
                                    style: TextStyle(color: c.ink2),
                                  );
                                }
                                return _closed(k, items);
                              }(),
                            ),
                          ),
                      ],
                      isExpanded: true,
                      isDense: true,
                      // Aligned, Flutter adds 16 pt before the text and 4 pt
                      // after the arrow, so the text still starts 16 pt and
                      // the arrow ends 16 pt inside the box, as before.
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        13,
                        12,
                        13,
                      ),
                      // A compact list, not a full-screen sheet (owner,
                      // 2026-10-11: "menüler çok büyük açılıyor").
                      menuMaxHeight: 300,
                      itemHeight: w.itemHeight,
                      borderRadius: BorderRadius.circular(MenzilRadius.input),
                      dropdownColor: c.surface,
                      icon: Icon(Icons.expand_more, color: c.ink2),
                      // Entries a bit smaller and not bold (owner, 2026-10-11).
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of text that shrinks only as much as it must to fit its width
/// (never below what fits, never overflowing, never "…"). When [text] would
/// need a scale under [minScale], [short] is shown instead (also scaled to
/// fit). Measured after layout like [MenzilWrapText]: no LayoutBuilder, so
/// dialogs that ask for intrinsic sizes still work.
class MenzilFitText extends StatefulWidget {
  final String text;
  final String? short;
  final double minScale;

  const MenzilFitText(this.text, {super.key, this.short, this.minScale = 0.8});

  @override
  State<MenzilFitText> createState() => _MenzilFitTextState();
}

class _MenzilFitTextState extends State<MenzilFitText> {
  bool _useShort = false;

  void _measure(_) {
    if (!mounted) return;
    final short = widget.short;
    final width = context.size?.width;
    if (short == null || short == widget.text || width == null || width <= 0) {
      if (_useShort) setState(() => _useShort = false);
      return;
    }
    final p = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: DefaultTextStyle.of(context).style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final useShort = p.width * widget.minScale > width + 0.5;
    p.dispose();
    if (useShort != _useShort) setState(() => _useShort = useShort);
  }

  @override
  void didUpdateWidget(covariant MenzilFitText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _useShort = false;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final shown = _useShort ? widget.short! : widget.text;
    // Full width, so the measured size is the room available, not the text.
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          shown,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          semanticsLabel: widget.text,
        ),
      ),
    );
  }
}

/// Two fields side by side on ONE row at every width and text size (owner,
/// 2026-10-13: "Namlu çıkış hızı | Kalibre", every row two boxes). Put it in
/// a [MenzilFullWidth] inside a [MenzilFieldGrid]; the columns match the
/// grid's two-column rows (same gap).
class MenzilFieldPair extends StatelessWidget {
  final Widget start;
  final Widget end;
  final double gap;

  const MenzilFieldPair({
    super.key,
    required this.start,
    required this.end,
    this.gap = MenzilSpace.md,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: start),
      SizedBox(width: gap),
      Expanded(child: end),
    ],
  );
}

/// Marks a child of [MenzilFieldGrid] that must span the full row.
class MenzilFullWidth extends StatelessWidget {
  final Widget child;
  const MenzilFullWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Responsive form grid: two columns when each column can be at least
/// [MenzilSpace.twoColumnMinWidth / 2] wide, otherwise one column. Large text
/// scaling also collapses to one column so labels never get clipped.
class MenzilFieldGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const MenzilFieldGrid({
    super.key,
    required this.children,
    this.gap = MenzilSpace.md,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoColumns =
            width >= MenzilSpace.twoColumnMinWidth && width / scale >= 300;
        // Floor to 0.01 px: a rounding excess would push the second column
        // onto a new Wrap run.
        final colWidth = twoColumns
            ? ((width - gap) / 2 * 100).floorToDouble() / 100
            : width;
        return Wrap(
          spacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: child is MenzilFullWidth ? width : colWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

/// Primary action (ink filled), full width by default.
class MenzilPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool amber;

  /// The label stays on one line and is set smaller when it does not fit
  /// (owner, 2026-10-12: "Profil ekle 2. satıra kaymasın").
  final bool oneLine;

  const MenzilPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.amber = false,
    this.oneLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final style = amber
        ? FilledButton.styleFrom(
            backgroundColor: c.amber,
            foregroundColor: MenzilColors.onAmber,
          )
        : null;
    final Widget text = oneLine
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, softWrap: false),
          )
        : Text(label);
    // One line with an icon (owner, 2026-10-12: "+ işareti sola kayacak"):
    // the icon sits at the left edge and the label takes the space it frees,
    // at the same size as the neighbouring buttons when it fits.
    if (oneLine && icon != null) {
      final b = FilledButton(
        style: (style ?? const ButtonStyle()).merge(
          FilledButton.styleFrom(
            // Icon and label nearer the left edge (owner, 2026-10-12:
            // "+ biraz daha sola kayabilir… sağda mesafe az").
            padding: const EdgeInsets.only(left: 2, right: 14),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 2),
            Expanded(child: Center(child: text)),
          ],
        ),
      );
      return expand ? SizedBox(width: double.infinity, child: b) : b;
    }
    final button = icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: text)
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: text,
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary action (outlined).
class MenzilSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool destructive;

  /// Filled orange with white text: the control's state is the current one
  /// (e.g. "Çözüm kuleye kurulu"). Stays orange when disabled.
  final bool active;

  /// The label takes at most two lines; a longer one is set smaller until it
  /// fits (owner, 2026-10-11: "Çözüm kulelere kuruldu" took three lines).
  final bool twoLines;

  /// With [twoLines]: how many lines the shrinking label may take. Side by
  /// side fetch / reset buttons use 2 so long labels fit on an iPhone SE
  /// (owner, 2026-10-12).
  final int maxLabelLines;

  const MenzilSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.destructive = false,
    this.active = false,
    this.twoLines = false,
    this.maxLabelLines = 1,
  });

  Widget _label() {
    if (!twoLines) return Text(label);
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxWidth.isFinite) return Text(label);
        final base = DefaultTextStyle.of(context).style;
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        var size = base.fontSize ?? 16;
        // One line, the font shrinking until it fits (owner, 2026-10-11:
        // no icon, no second line).
        // Two-line labels may shrink a little further (iPhone SE, 1.3×).
        final minSize = maxLabelLines > 1 ? 8.0 : 10.0;
        while (size > minSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: label,
              style: base.copyWith(fontSize: size, fontWeight: FontWeight.w400),
            ),
            textDirection: dir,
            textScaler: scaler,
            textAlign: TextAlign.center,
            locale: Localizations.maybeLocaleOf(context),
            maxLines: maxLabelLines,
            // A few pixels of slack: the painted paragraph rounds its width
            // and must not end up one glyph short (iPhone SE, 1.3×).
          )..layout(maxWidth: math.max(0, box.maxWidth - 6));
          final fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
          size -= 0.5;
        }
        if (maxLabelLines == 1) {
          // One line never wraps: below the smallest size it scales down.
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w400),
            ),
          );
        }
        return Text(
          label,
          maxLines: maxLabelLines,
          softWrap: maxLabelLines > 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          // Never bold, so the pair of dial buttons matches whether a label
          // wraps or not (owner, 2026-10-11).
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w400),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final style = active
        ? OutlinedButton.styleFrom(
            backgroundColor: MenzilColors.stateOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: MenzilColors.stateOrange,
            disabledForegroundColor: Colors.white,
            side: const BorderSide(color: MenzilColors.stateOrange),
          )
        : destructive
        ? OutlinedButton.styleFrom(
            foregroundColor: c.danger,
            side: BorderSide(color: c.danger.withValues(alpha: 0.6)),
          )
        : null;
    final button = icon == null
        ? OutlinedButton(style: style, onPressed: onPressed, child: _label())
        : OutlinedButton.icon(
            // Equal space left and right of icon + label (owner,
            // 2026-10-12: "sağda ve solda aynı boşluk kalsın").
            style: (style ?? const ButtonStyle()).merge(
              OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: _label(),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// −5 / −1 / value / +1 / +5 stepper button.
class MenzilStepButton extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool small;

  const MenzilStepButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: small ? 44 : 50,
          height: 54,
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MenzilRadius.button),
              side: BorderSide(color: c.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(MenzilRadius.button),
              onTap: onPressed,
              child: Center(
                child: Text(
                  label,
                  // Soft grey, not bright white (owner, 2026-10-12).
                  style: MenzilType.number(
                    c.ink2,
                    size: 19,
                    weight: small ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class MenzilMetric {
  final String label;
  final String value;
  final String? unit;
  const MenzilMetric(this.label, this.value, [this.unit]);
}

/// Grid of compact metric tiles separated by hairlines (speed, energy, TOF…).
class MenzilMetricGrid extends StatelessWidget {
  final List<MenzilMetric> metrics;
  final int columns;

  /// Long text values (brand / model names) take up to two readable lines
  /// instead of shrinking; every tile keeps the same height so the rows stay
  /// aligned (owner, 2026-10-11).
  final bool twoLineText;

  /// With [twoLineText]: one full-width tile above the rows (Profil cards:
  /// marka and model on one line, owner 2026-10-13).
  final MenzilMetric? lead;

  /// No hairlines between the tiles, only the card's outer border (owner,
  /// 2026-10-13: "tablo şeklinde olmasın").
  final bool plain;

  const MenzilMetricGrid({
    super.key,
    required this.metrics,
    this.columns = 3,
    this.twoLineText = false,
    this.lead,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          var cols = columns;
          if (width / scale < 330) cols = math.min(cols, 2);
          final tileWidth =
              ((width - 2 - (cols - 1)) / cols * 100).floorToDouble() / 100;
          final remainder = metrics.length % cols;
          final fillers = remainder == 0 ? 0 : cols - remainder;
          return ClipRRect(
            borderRadius: BorderRadius.circular(MenzilRadius.table),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: plain ? c.surface : c.line,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(MenzilRadius.table),
              ),
              child: twoLineText
                  ? _rows(context, cols, tileWidth)
                  : Wrap(
                      spacing: 1,
                      runSpacing: 1,
                      children: [
                        for (final m in metrics)
                          SizedBox(
                            width: tileWidth,
                            child: MenzilMetricCard(
                              metric: m,
                              twoLineText: twoLineText,
                            ),
                          ),
                        for (var i = 0; i < fillers; i++)
                          SizedBox(
                            width: tileWidth,
                            child: ColoredBox(
                              color: c.surface,
                              child: SizedBox(height: twoLineText ? 76 : 56),
                            ),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  /// Profil summary: rows whose two boxes share one height (a wrapped model
  /// name grows its row, not a single box).
  Widget _rows(BuildContext context, int cols, double tileWidth) {
    final c = MenzilColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lead != null) ...[
          MenzilMetricCard(metric: lead!, twoLineText: true),
          if (metrics.isNotEmpty) const SizedBox(height: 1),
        ],
        for (var r = 0; r < metrics.length; r += cols) ...[
          if (r > 0) const SizedBox(height: 1),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var k = 0; k < cols; k++) ...[
                  if (k > 0) const SizedBox(width: 1),
                  SizedBox(
                    width: tileWidth,
                    child: r + k < metrics.length
                        ? MenzilMetricCard(
                            metric: metrics[r + k],
                            twoLineText: true,
                          )
                        : ColoredBox(color: c.surface),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One metric tile (label above a number with unit, proportional figures).
class MenzilMetricCard extends StatelessWidget {
  final MenzilMetric metric;

  /// See [MenzilMetricGrid.twoLineText].
  final bool twoLineText;
  const MenzilMetricCard({
    super.key,
    required this.metric,
    this.twoLineText = false,
  });

  /// Profil summary size: every value as large as a wrapped model name
  /// (owner, 2026-10-11: "Tüfek model ile aynı boyda yap hepsini").
  static const double summarySize = 17;

  /// A text value: up to two lines at [summarySize], regular weight. No
  /// LayoutBuilder, so the summary rows can match their heights.
  Widget _textValue(Color ink) => Text(
    metric.value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: MenzilType.number(
      ink,
      size: summarySize,
    ).copyWith(height: 1.15, fontWeight: FontWeight.w400),
  );

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return ColoredBox(
      color: c.surface,
      child: ConstrainedBox(
        // Smaller boxes on the Profil summary (owner, 2026-10-11).
        constraints: BoxConstraints(minHeight: twoLineText ? 46 : 56),
        child: Padding(
          padding: twoLineText
              ? const EdgeInsets.fromLTRB(10, 5, 10, 6)
              : const EdgeInsets.fromLTRB(10, 7, 10, 8),
          child: Semantics(
            label: '${metric.label}: ${metric.value} ${metric.unit ?? ''}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like the value below: a long label ("%80 için maks.
                  // menzil" with larger iOS text) shrinks a little instead of
                  // being cut; at the default size nothing changes.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      metric.label,
                      maxLines: 1,
                      style: MenzilType.caption(c.ink2).copyWith(fontSize: 12),
                    ),
                  ),
                  if (twoLineText && metric.unit == null)
                    _textValue(c.ink)
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          text: metric.value,
                          style: twoLineText
                              ? MenzilType.number(
                                  c.ink,
                                  size: summarySize,
                                ).copyWith(fontWeight: FontWeight.w400)
                              : MenzilType.number(c.ink, size: 22),
                          children: [
                            if (metric.unit != null)
                              TextSpan(
                                text: ' ${metric.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink2,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Large tappable tool / navigation card: icon, title, short description,
/// chevron (or lock when disabled). Built on [ListTile] so it keeps standard
/// semantics and an `enabled` state.
class MenzilToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final Key? tileKey;

  const MenzilToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.tileKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: tileKey,
          enabled: enabled,
          onTap: enabled ? onTap : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MenzilSpace.lg,
            vertical: MenzilSpace.xxs,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? c.amberSoft : c.surface2,
              borderRadius: BorderRadius.circular(MenzilRadius.button),
            ),
            child: Icon(icon, color: enabled ? c.amberInk : c.ink2),
          ),
          title: Text(
            title,
            style: MenzilType.heading(enabled ? c.ink : c.ink2, size: 20),
          ),
          subtitle: Text(
            subtitle,
            style: MenzilType.caption(c.ink2).copyWith(fontSize: 13),
          ),
          trailing: Icon(
            enabled ? Icons.chevron_right : Icons.lock_outline,
            color: c.ink2,
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped choice chip row (platform filters etc.).
class MenzilChipGroup<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const MenzilChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Wrap(
      spacing: MenzilSpace.xs,
      runSpacing: MenzilSpace.xs,
      children: [
        for (final (value, label) in options)
          Semantics(
            button: true,
            selected: value == selected,
            child: Material(
              color: value == selected ? c.ink : c.bg,
              shape: StadiumBorder(
                side: BorderSide(color: value == selected ? c.ink : c.line),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(value),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 44,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: value == selected ? c.bg : c.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
