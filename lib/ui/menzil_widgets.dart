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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

/// Header for secondary routes (Katalog, Ayarlar, profile editor). Uses the
/// same bar background, border and condensed title as the main top bar.
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
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// Fixed Menzil bar: brand (left), active-profile selector (centre, flexible)
/// and the unit / theme buttons (right). The brand is hidden on Profil.
class MenzilTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget profileSelector;
  final String unitLabel;
  final VoidCallback? onUnitTap;
  final String themeLabel;
  final VoidCallback? onThemeTap;

  /// False hides the Menzil wordmark (the Profil page shows no brand).
  final bool showBrand;

  static const double height = 58;

  const MenzilTopBar({
    super.key,
    required this.profileSelector,
    required this.unitLabel,
    this.onUnitTap,
    required this.themeLabel,
    this.onThemeTap,
    this.showBrand = true,
  });

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
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MenzilSpace.gutter,
                    ),
                    child: Row(
                      children: [
                        if (showBrand) ...[
                          MenzilBrand(compact: compact),
                          const SizedBox(width: MenzilSpace.sm),
                        ],
                        Expanded(child: profileSelector),
                        const SizedBox(width: MenzilSpace.sm),
                        MenzilBarButton(
                          label: unitLabel,
                          tooltip: 'Birim sistemi',
                          onPressed: onUnitTap,
                        ),
                        const SizedBox(width: MenzilSpace.xs),
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

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Semantics(
      header: true,
      label: 'Menzil',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenzilIcon(MenzilGlyph.brand, size: 22, color: c.ink),
            if (!compact) ...[
              const SizedBox(width: 7),
              Text('Menzil', style: MenzilType.heading(c.ink, size: 26)),
            ],
          ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MenzilRadius.button),
              side: BorderSide(color: c.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(MenzilRadius.button),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    widthFactor: 1,
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
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: fg,
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
  final EdgeInsetsGeometry margin;

  const MenzilCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MenzilSpace.lg),
    this.accent,
    this.radius = MenzilRadius.card,
    this.background,
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
          side: BorderSide(color: c.line, width: MenzilSpace.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

/// Section title in the condensed heading face, optional trailing widget and
/// subtitle. Marked as a header for VoiceOver.
class MenzilSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const MenzilSectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
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
                    style: MenzilType.heading(c.ink, size: 22),
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

  const MenzilNotice({
    super.key,
    this.title,
    required this.message,
    this.tone = MenzilNoticeTone.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final (Color bg, Color edge) = switch (tone) {
      MenzilNoticeTone.info => (c.cyanSoft, c.cyan),
      MenzilNoticeTone.warning => (c.amberSoft, c.amber),
      MenzilNoticeTone.danger => (c.dangerSoft, c.danger),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MenzilRadius.button),
          border: Border(left: BorderSide(color: edge, width: 5)),
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
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
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

/// Label row shared by inputs and selectors: label on the left, unit on the
/// right, constant gap to the control below.
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
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MenzilType.label(c.ink),
            ),
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
          ExcludeSemantics(
            child: MenzilFieldLabel(
              label: label,
              unit: unit,
              trailing: labelTrailing,
            ),
          ),
          Semantics(
            label: semanticLabel,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction ?? TextInputAction.next,
              onChanged: onChanged,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              scrollPadding: const EdgeInsets.only(bottom: 120),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.ink,
                fontFeatures: MenzilType.tabular,
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
class MenzilSelect<T> extends StatelessWidget {
  final String label;
  final String? unit;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? semanticLabel;

  const MenzilSelect({
    super.key,
    required this.label,
    this.unit,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MenzilSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: MenzilFieldLabel(label: label, unit: unit),
          ),
          Semantics(
            label: semanticLabel ?? label,
            child: DropdownButtonFormField<T>(
              initialValue: initialValue,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(MenzilRadius.input),
              dropdownColor: c.surface,
              icon: Icon(Icons.expand_more, color: c.ink2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
              decoration: const InputDecoration(),
            ),
          ),
        ],
      ),
    );
  }
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

  const MenzilPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.amber = false,
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
    final button = icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
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

  const MenzilSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final style = destructive
        ? OutlinedButton.styleFrom(
            foregroundColor: c.danger,
            side: BorderSide(color: c.danger.withValues(alpha: 0.6)),
          )
        : null;
    final button = icon == null
        ? OutlinedButton(style: style, onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
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
                  style: MenzilType.number(
                    small ? c.ink2 : c.ink,
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

/// Elevation / wind result card from the shot screen.
class MenzilHoldCard extends StatelessWidget {
  final String title;
  final String unit;
  final String value;
  final String line1;
  final String line2;
  final bool wind;

  const MenzilHoldCard({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    required this.line1,
    required this.line2,
    this.wind = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final titleColor = wind ? c.cyanInk : c.amberInk;
    return MenzilCard(
      accent: wind ? c.cyan : c.amber,
      radius: MenzilRadius.hold,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(11, 10, 12, 11),
      child: Semantics(
        label: '$title $value $unit. $line1. $line2.',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink2,
                    ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: MenzilType.display(c.ink, size: 56),
                ),
              ),
              Text(
                line1,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              Text(line2, style: MenzilType.caption(c.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

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

  const MenzilMetricGrid({super.key, required this.metrics, this.columns = 3});

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
                color: c.line,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(MenzilRadius.table),
              ),
              child: Wrap(
                spacing: 1,
                runSpacing: 1,
                children: [
                  for (final m in metrics)
                    SizedBox(
                      width: tileWidth,
                      child: MenzilMetricCard(metric: m),
                    ),
                  for (var i = 0; i < fillers; i++)
                    SizedBox(
                      width: tileWidth,
                      child: ColoredBox(
                        color: c.surface,
                        child: const SizedBox(height: 56),
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
}

/// One metric tile (label above a large condensed number with unit).
class MenzilMetricCard extends StatelessWidget {
  final MenzilMetric metric;
  const MenzilMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return ColoredBox(
      color: c.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
          child: Semantics(
            label: '${metric.label}: ${metric.value} ${metric.unit ?? ''}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MenzilType.caption(c.ink2).copyWith(fontSize: 12),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: metric.value,
                        style: MenzilType.number(c.ink, size: 22),
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
