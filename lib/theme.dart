import 'package:flutter/material.dart';

/// The web app's palette (src/app/globals.css): forest green with an amber accent.
class Brand {
  static const green = Color(0xFF1B7059);
  static const greenLight = Color(0xFF3FA587);
  static const amber = Color(0xFFF8A020);
  static const ink = Color(0xFF1E3A31);
  static const muted = Color(0xFFEEF4F1);
  static const mutedInk = Color(0xFF5B6F67);
  static const border = Color(0xFFDCE7E2);
  static const background = Color(0xFFFBFCFB);
  static const danger = Color(0xFFC8372D);

  // Dark mode: true black with neutral greys (no green tint); green/amber only as accents.
  static const darkBackground = Color(0xFF000000);
  static const darkCard = Color(0xFF121212);
  static const darkMuted = Color(0xFF1F1F1F);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkInk = Color(0xFFF2F2F2);
  static const darkMutedInk = Color(0xFFA3A3A3);
  static const darkDanger = Color(0xFFE5675C);

  /// Balance colours: who pays / who gets money back.
  static Color pays(BuildContext c) => Theme.of(c).colorScheme.error;
  static Color getsBack(BuildContext c) => Theme.of(c).colorScheme.primary;
}

const _radius = 10.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? Brand.greenLight : Brand.green,
    onPrimary: dark ? const Color(0xFF0A0A0A) : Colors.white,
    secondary: Brand.amber,
    onSecondary: Brand.ink,
    tertiary: Brand.amber,
    onTertiary: Brand.ink,
    error: dark ? Brand.darkDanger : Brand.danger,
    onError: Colors.white,
    surface: dark ? Brand.darkCard : Colors.white,
    onSurface: dark ? Brand.darkInk : Brand.ink,
    onSurfaceVariant: dark ? Brand.darkMutedInk : Brand.mutedInk,
    surfaceContainerHighest: dark ? Brand.darkMuted : Brand.muted,
    surfaceContainerHigh: dark ? Brand.darkMuted : Brand.muted,
    surfaceContainer: dark ? Brand.darkMuted : Brand.muted,
    surfaceContainerLow: dark ? Brand.darkCard : Colors.white,
    outline: dark ? Brand.darkBorder : Brand.border,
    outlineVariant: dark ? Brand.darkBorder : Brand.border,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide(color: scheme.outline),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? Brand.darkBackground : Brand.background,
    dividerColor: scheme.outline,
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? Brand.darkBackground : Brand.background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius + 4),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: dark ? Brand.darkBackground : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
      errorBorder: border.copyWith(borderSide: BorderSide(color: scheme.error)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(44, 44), shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: shape,
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      height: 64,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(_radius - 2),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius + 4)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
  );
}
