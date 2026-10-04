// FontFeature lives in dart:ui; the ignore keeps analyze green if material ever re-exports it.
// ignore: unnecessary_import
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Menzil design tokens.
///
/// Every colour, radius, spacing and type value used by the UI comes from this
/// file. Screens must not hard-code their own palette; they read
/// [MenzilColors.of] (light/dark aware) and the static scales below.
@immutable
class MenzilColors extends ThemeExtension<MenzilColors> {
  /// Text/icon colour on top of an amber-filled control (both brightnesses).
  static const Color onAmber = Color(0xFF1B1200);

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color line;
  final Color amber;
  final Color amberInk;
  final Color amberSoft;
  final Color cyan;
  final Color cyanInk;
  final Color cyanSoft;
  final Color danger;
  final Color dangerSoft;
  final Color ok;
  final Color scopeBg;
  final Color scopeLine;
  final Color scopeDim;

  /// The ONLY green exception in the palette: the liquid inside the spirit
  /// level vial (Su Terazisi). Never use it for status text or other widgets.
  final Color levelLiquid;

  const MenzilColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.amber,
    required this.amberInk,
    required this.amberSoft,
    required this.cyan,
    required this.cyanInk,
    required this.cyanSoft,
    required this.danger,
    required this.dangerSoft,
    required this.ok,
    required this.scopeBg,
    required this.scopeLine,
    required this.scopeDim,
    required this.levelLiquid,
  });

  static const light = MenzilColors(
    bg: Color(0xFFE6ECEF),
    surface: Color(0xFFF7FAFB),
    surface2: Color(0xFFDBE4E9),
    ink: Color(0xFF0F2230),
    ink2: Color(0xFF465D6F),
    line: Color(0xFFBCCAD3),
    amber: Color(0xFFE9A00C),
    amberInk: Color(0xFF7A4A00),
    amberSoft: Color(0xFFF7E6BD),
    cyan: Color(0xFF1C8FB5),
    cyanInk: Color(0xFF09617F),
    cyanSoft: Color(0xFFCBE7F1),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFF6D9D6),
    ok: Color(0xFF1F7A4D),
    scopeBg: Color(0xFFF7FAFB),
    scopeLine: Color(0xFF0F2230),
    scopeDim: Color(0xFF8DA0AE),
    levelLiquid: Color(0xFF2EA862),
  );

  static const dark = MenzilColors(
    bg: Color(0xFF0B1620),
    surface: Color(0xFF122330),
    surface2: Color(0xFF1B3245),
    ink: Color(0xFFE7EFF3),
    ink2: Color(0xFF9CB1C0),
    line: Color(0xFF27425A),
    amber: Color(0xFFF5B031),
    amberInk: Color(0xFFF5B031),
    amberSoft: Color(0xFF3B2E10),
    cyan: Color(0xFF4CC3E8),
    cyanInk: Color(0xFF4CC3E8),
    cyanSoft: Color(0xFF12384A),
    danger: Color(0xFFFF8A80),
    dangerSoft: Color(0xFF43201E),
    ok: Color(0xFF5FD39B),
    scopeBg: Color(0xFF0C1A24),
    scopeLine: Color(0xFFE7EFF3),
    scopeDim: Color(0xFF5E7A8E),
    levelLiquid: Color(0xFF3FCB7C),
  );

  /// Colours for the current theme. Falls back to the light palette when a
  /// widget is pumped without the Menzil theme (for example in isolated
  /// widget tests that use a bare `MaterialApp`).
  static MenzilColors of(BuildContext context) =>
      Theme.of(context).extension<MenzilColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  MenzilColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? ink2,
    Color? line,
    Color? amber,
    Color? amberInk,
    Color? amberSoft,
    Color? cyan,
    Color? cyanInk,
    Color? cyanSoft,
    Color? danger,
    Color? dangerSoft,
    Color? ok,
    Color? scopeBg,
    Color? scopeLine,
    Color? scopeDim,
    Color? levelLiquid,
  }) =>
      MenzilColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        ink: ink ?? this.ink,
        ink2: ink2 ?? this.ink2,
        line: line ?? this.line,
        amber: amber ?? this.amber,
        amberInk: amberInk ?? this.amberInk,
        amberSoft: amberSoft ?? this.amberSoft,
        cyan: cyan ?? this.cyan,
        cyanInk: cyanInk ?? this.cyanInk,
        cyanSoft: cyanSoft ?? this.cyanSoft,
        danger: danger ?? this.danger,
        dangerSoft: dangerSoft ?? this.dangerSoft,
        ok: ok ?? this.ok,
        scopeBg: scopeBg ?? this.scopeBg,
        scopeLine: scopeLine ?? this.scopeLine,
        scopeDim: scopeDim ?? this.scopeDim,
        levelLiquid: levelLiquid ?? this.levelLiquid,
      );

  @override
  MenzilColors lerp(ThemeExtension<MenzilColors>? other, double t) {
    if (other is! MenzilColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MenzilColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      line: mix(line, other.line),
      amber: mix(amber, other.amber),
      amberInk: mix(amberInk, other.amberInk),
      amberSoft: mix(amberSoft, other.amberSoft),
      cyan: mix(cyan, other.cyan),
      cyanInk: mix(cyanInk, other.cyanInk),
      cyanSoft: mix(cyanSoft, other.cyanSoft),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      ok: mix(ok, other.ok),
      scopeBg: mix(scopeBg, other.scopeBg),
      scopeLine: mix(scopeLine, other.scopeLine),
      scopeDim: mix(scopeDim, other.scopeDim),
      levelLiquid: mix(levelLiquid, other.levelLiquid),
    );
  }
}

/// Corner radii. Cards and result boxes are large; inputs share one radius
/// so selectors and text fields line up.
abstract final class MenzilRadius {
  static const double card = 16;
  static const double hold = 18;
  static const double input = 10;
  static const double button = 12;
  static const double chip = 999;
  static const double table = 14;
}

/// 4-pt spacing scale.
abstract final class MenzilSpace {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;

  /// Horizontal page gutter.
  static const double gutter = 14;

  /// One border weight everywhere.
  static const double border = 1;

  /// Shared control height for inputs, selectors and buttons. 46 logical px
  /// keeps every control above the 44 pt iOS touch-target minimum.
  static const double control = 46;

  /// Content wider than this is centred (large phones in landscape, iPad).
  static const double maxContentWidth = 560;

  /// Below this width two-column form grids fall back to one column.
  static const double twoColumnMinWidth = 300;
}

/// Typography. Numbers and headings prefer a condensed family (Barlow
/// Condensed) when one is available on the device or bundled later through
/// pubspec `fonts:`; otherwise the platform falls back to its system face.
/// Tabular figures keep values from jittering while they change.
abstract final class MenzilType {
  static const List<String> numericFallback = [
    'Barlow Condensed',
    'Roboto Condensed',
    'Arial Narrow',
  ];
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle display(Color color, {double size = 60}) => TextStyle(
        fontFamilyFallback: numericFallback,
        fontSize: size,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: color,
        fontFeatures: tabular,
      );

  static TextStyle number(Color color, {double size = 22, FontWeight weight = FontWeight.w600}) => TextStyle(
        fontFamilyFallback: numericFallback,
        fontSize: size,
        height: 1.1,
        fontWeight: weight,
        color: color,
        fontFeatures: tabular,
      );

  static TextStyle heading(Color color, {double size = 22}) => TextStyle(
        fontFamilyFallback: numericFallback,
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle label(Color color) => TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle unit(Color color) => TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 12.5,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: color,
      );
}

/// Builds the Material theme from the tokens so that stock Material widgets
/// (dialogs, list tiles, segmented buttons, snack bars, data tables) already
/// follow the Menzil language without per-screen styling.
abstract final class MenzilTheme {
  static ThemeData light() => _build(MenzilColors.light, Brightness.light);
  static ThemeData dark() => _build(MenzilColors.dark, Brightness.dark);

  static ThemeData _build(MenzilColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.bg,
      secondary: c.amber,
      onSecondary: MenzilColors.onAmber,
      tertiary: c.cyan,
      onTertiary: c.bg,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.ink2,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surface2,
      outline: c.line,
      outlineVariant: c.line,
      primaryContainer: c.surface2,
      onPrimaryContainer: c.ink,
      secondaryContainer: c.amberSoft,
      onSecondaryContainer: c.ink,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MenzilRadius.button),
    );
    OutlineInputBorder inputBorder(Color color, [double width = MenzilSpace.border]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(MenzilRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );
    const minControl = Size(44, MenzilSpace.control);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      splashFactory: InkRipple.splashFactory,
      extensions: [c],
      appBarTheme: AppBarThemeData(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: c.line)),
        titleTextStyle: MenzilType.heading(c.ink, size: 24),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: MenzilSpace.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MenzilRadius.card),
          side: BorderSide(color: c.line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MenzilRadius.card)),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: inputBorder(c.line),
        enabledBorder: inputBorder(c.line),
        focusedBorder: inputBorder(c.cyan, 2),
        errorBorder: inputBorder(c.danger),
        focusedErrorBorder: inputBorder(c.danger, 2),
        disabledBorder: inputBorder(c.line.withValues(alpha: 0.5)),
        labelStyle: MenzilType.label(c.ink2),
        floatingLabelStyle: MenzilType.label(c.ink),
        hintStyle: MenzilType.body(c.ink2),
        helperStyle: MenzilType.caption(c.ink2),
        errorStyle: MenzilType.caption(c.danger),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          disabledBackgroundColor: c.ink.withValues(alpha: 0.3),
          disabledForegroundColor: c.bg,
          minimumSize: minControl,
          shape: controlShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: minControl,
          shape: controlShape,
          side: BorderSide(color: c.line),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.cyanInk,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.amber,
        foregroundColor: MenzilColors.onAmber,
        elevation: 0,
        shape: controlShape,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          side: WidgetStatePropertyAll(BorderSide(color: c.line)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? c.ink : c.bg,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? c.bg : c.ink2,
          ),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.surface : c.ink2,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.cyan : c.surface2,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.line),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.ink,
        inactiveTrackColor: c.surface2,
        thumbColor: c.ink,
        overlayColor: c.ink.withValues(alpha: 0.08),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.amber),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.bg, fontSize: 14.5, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MenzilRadius.button)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MenzilRadius.card),
          side: BorderSide(color: c.line),
        ),
        titleTextStyle: MenzilType.heading(c.ink, size: 22),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(MenzilRadius.card)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(c.surface)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(c.surface2),
        headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink),
        dataTextStyle: MenzilType.number(c.ink, size: 19),
        headingRowHeight: 38,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        columnSpacing: 18,
        horizontalMargin: 12,
        dividerThickness: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(color: c.bg, fontSize: 13),
      ),
    );
  }
}

/// In-memory light/dark/system choice behind the top bar's theme button.
/// Deliberately not persisted: theme is a display preference and this UI
/// pass does not add new storage keys.
class MenzilThemeController extends ValueNotifier<ThemeMode> {
  MenzilThemeController([super.value = ThemeMode.system]);

  void cycle() {
    value = switch (value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Oto',
        ThemeMode.light => 'Açık',
        ThemeMode.dark => 'Koyu',
      };
}

class MenzilThemeScope extends InheritedNotifier<MenzilThemeController> {
  const MenzilThemeScope({super.key, required MenzilThemeController controller, required super.child})
      : super(notifier: controller);

  static MenzilThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenzilThemeScope>()?.notifier;
}

/// Equipment-illustration colours (rifle / scope artwork on the Sight Height
/// page). They are part of the drawing, identical in light and dark mode, the
/// way a photo would be; they are not UI colours and must not be used for
/// text, controls or status.
abstract final class MenzilArt {
  static const Color c0B0E11 = Color(0xFF0B0E11);
  static const Color c0E1216 = Color(0xFF0E1216);
  static const Color c161B20 = Color(0xFF161B20);
  static const Color c173A52 = Color(0xFF173A52);
  static const Color c1C2227 = Color(0xFF1C2227);
  static const Color c252C32 = Color(0xFF252C32);
  static const Color c262D33 = Color(0xFF262D33);
  static const Color c2F6F95 = Color(0xFF2F6F95);
  static const Color c3A4147 = Color(0xFF3A4147);
  static const Color c3A444C = Color(0xFF3A444C);
  static const Color c4A535B = Color(0xFF4A535B);
  static const Color c4B555E = Color(0xFF4B555E);
  static const Color c5A646D = Color(0xFF5A646D);
  static const Color c6E7881 = Color(0xFF6E7881);
  static const Color c7C8790 = Color(0xFF7C8790);
  static const Color c9FD3EC = Color(0xFF9FD3EC);
  static const Color cF7FAFB = Color(0xFFF7FAFB);
  static const Color cFFFFFF = Color(0xFFFFFFFF);
}
