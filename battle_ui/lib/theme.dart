import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing tokens
class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

/// Brand color palette - generated tonal scale (purple + neutral surfaces)
class AppColors {
  // Primary scale (soft lavender)
  static const Color primaryA0 = Color(0xFFB79CE4);
  static const Color primaryA10 = Color(0xFFBEA6E7);
  static const Color primaryA20 = Color(0xFFC5B0EA);
  static const Color primaryA30 = Color(0xFFCCBAED);
  static const Color primaryA40 = Color(0xFFD3C3F0);
  static const Color primaryA50 = Color(0xFFDACDF3);

  // Neutral surface scale (used as backgrounds)
  static const Color surfaceA0 = Color(0xFF121212);
  static const Color surfaceA10 = Color(0xFF252525);
  static const Color surfaceA20 = Color(0xFF393939);
  static const Color surfaceA30 = Color(0xFF4F4F4F);
  static const Color surfaceA40 = Color(0xFF666666);
  static const Color surfaceA50 = Color(0xFF7D7D7D);

  // Tonal surface scale (purple-tinted)
  static const Color surfaceTonalA0 = Color(0xFF201E23);
  static const Color surfaceTonalA10 = Color(0xFF333135);
  static const Color surfaceTonalA20 = Color(0xFF464449);
  static const Color surfaceTonalA30 = Color(0xFF5B595D);
  static const Color surfaceTonalA40 = Color(0xFF706F73);
  static const Color surfaceTonalA50 = Color(0xFF878588);

  // Status
  static const Color success = Color(0xFF22946E);
  static const Color successLight = Color(0xFF5BA989);
  static const Color warning = Color(0xFFA87A2A);
  static const Color warningLight = Color(0xFFBA945A);
  static const Color danger = Color(0xFF9C2121);
  static const Color dangerLight = Color(0xFFB4544C);
  static const Color info = Color(0xFF21498A);
  static const Color infoLight = Color(0xFF4B6CA2);

  // Semantic aliases used across the app
  static const Color seed = primaryA0;
  static const Color primary = primaryA0;
  static const Color secondary = primaryA20;
  static const Color tertiary = primaryA40;
  static const Color accent = warningLight;

  // Surface aliases — backgrounds use NEUTRAL surface scale per user request.
  static const Color background = surfaceA0;          // #121212 - scaffold
  static const Color surface = surfaceA10;            // #252525 - cards, sidebar
  static const Color surfaceHigh = surfaceA20;        // #393939 - inputs, chips
  static const Color surfaceHighest = surfaceA30;     // #4F4F4F - elevated overlays
  static const Color outline = surfaceA30;            // #4F4F4F
  static const Color outlineVariant = Color(0xFF2E2E2E); // subtle borders

  static const Color onSurface = Color(0xFFEDEAF2);
  static const Color onSurfaceMuted = Color(0xFFA8A2B4);

  // Logo gradient
  static const List<Color> logoGradient = [primaryA0, primaryA20, primaryA40];
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.black,
    primaryContainer: AppColors.primary.withValues(alpha: 0.18),
    onPrimaryContainer: AppColors.primaryA50,
    secondary: AppColors.secondary,
    onSecondary: Colors.black,
    secondaryContainer: AppColors.secondary.withValues(alpha: 0.16),
    onSecondaryContainer: AppColors.secondary,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.black,
    tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.16),
    onTertiaryContainer: AppColors.tertiary,
    error: AppColors.danger,
    onError: Colors.black,
    errorContainer: AppColors.danger.withValues(alpha: 0.16),
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceMuted,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surfaceHigh,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,
    scrim: Colors.black54,
    shadow: Colors.black,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: AppColors.primary,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: textTheme.labelLarge ?? const TextStyle(),
      side: const BorderSide(color: AppColors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHighest,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceHigh,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.onSurfaceMuted,
      textColor: AppColors.onSurface,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      textStyle: textTheme.bodySmall,
    ),
  );
}
