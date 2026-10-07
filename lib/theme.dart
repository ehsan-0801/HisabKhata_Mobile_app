import 'package:flutter/material.dart';

/// The web app's palette (src/app/globals.css): teal (with a teal → cyan gradient) and an amber accent.
class Brand {
  static const teal = Color(0xFF0F766E); // teal-700
  static const tealLight = Color(0xFF14B8A6); // teal-500, dark mode
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

  /// Filled buttons and selected items: teal → cyan, like the web's --primary-gradient.
  static LinearGradient gradient(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
      ? const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  /// Balance colours: who pays / who gets money back.
  static Color pays(BuildContext c) => Theme.of(c).colorScheme.error;
  static Color getsBack(BuildContext c) => Theme.of(c).colorScheme.primary;
}

const _radius = 10.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? Brand.tealLight : Brand.teal,
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
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_radius),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide(color: scheme.outline),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? Brand.darkBackground : Brand.background,
    dividerColor: scheme.outline,
    dividerTheme: DividerThemeData(
      color: scheme.outline,
      space: 1,
      thickness: 1,
    ),
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
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: scheme.error)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: shape,
          ).copyWith(
            // Enabled buttons are painted with the teal gradient; disabled ones keep the flat grey.
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            backgroundBuilder: (context, states, child) =>
                states.contains(WidgetState.disabled)
                ? child!
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: Brand.gradient(context),
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: child,
                  ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: shape,
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: shape),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      height: 64,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(_radius - 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius + 4),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
  );
}
