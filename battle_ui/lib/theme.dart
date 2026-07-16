import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';

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
  // Global dynamic state managed by ThemeProvider / MyApp
  static bool isDark = true;

  // --- Dark Mode Palette ---
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

  // --- Light Mode Palette ---
  // Primary scale (vibrant purple/lavender)
  static const Color primaryLightA0 = Color(0xFF6750A4);
  static const Color primaryLightA10 = Color(0xFF7C58C6);
  static const Color primaryLightA20 = Color(0xFF926E9E); // Muted secondary lavender
  static const Color primaryLightA40 = Color(0xFFB39EDB); // Accent light purple
  static const Color primaryLightA50 = Color(0xFFD3BFFF);

  // Neutral surface scale
  static const Color surfaceLightA0 = Color(0xFFF1EEF6);  // #F1EEF6 - scaffold background
  static const Color surfaceLightA10 = Color(0xFFFFFFFF); // #FFFFFF - cards, sidebar
  static const Color surfaceLightA20 = Color(0xFFF7F5FA); // #F7F5FA - inputs, chips, nested items
  static const Color surfaceLightA30 = Color(0xFFEBE6F0); // #EBE6F0 - elevated overlays
  static const Color surfaceLightA40 = Color(0xFFD3CDDB); // #D3CDDB - borders, divider

  static const Color onSurfaceDark = Color(0xFFEDEAF2);
  static const Color onSurfaceMutedDark = Color(0xFFA8A2B4);

  static const Color onSurfaceLight = Color(0xFF1C1A22);
  static const Color onSurfaceLightMuted = Color(0xFF534F61);

  // Shared Status Colors
  static const Color successDark = Color(0xFF22946E);
  static const Color successLightDark = Color(0xFF5BA989);
  static const Color warningDark = Color(0xFFA87A2A);
  static const Color warningLightDark = Color(0xFFBA945A);
  static const Color dangerDark = Color(0xFF9C2121);
  static const Color dangerLightDark = Color(0xFFB4544C);
  static const Color infoDark = Color(0xFF21498A);
  static const Color infoLightDark = Color(0xFF4B6CA2);

  // Light Mode Status (optimized contrast)
  static const Color successLightMode = Color(0xFF1E825F);
  static const Color warningLightMode = Color(0xFF8A621D);
  static const Color dangerLightMode = Color(0xFF901A1A);
  static const Color infoLightMode = Color(0xFF1D3E74);

  // Dynamic Getters for theme-dependent colors
  static Color get background => isDark ? surfaceA0 : surfaceLightA0;
  static Color get surface => isDark ? surfaceA10 : surfaceLightA10;
  static Color get surfaceHigh => isDark ? surfaceA20 : surfaceLightA20;
  static Color get surfaceHighest => isDark ? surfaceA30 : surfaceLightA30;
  static Color get outline => isDark ? surfaceA30 : surfaceLightA30;
  static Color get outlineVariant => isDark ? const Color(0xFF2E2E2E) : surfaceLightA40;

  static Color get onSurface => isDark ? onSurfaceDark : onSurfaceLight;
  static Color get onSurfaceMuted => isDark ? onSurfaceMutedDark : onSurfaceLightMuted;

  static Color get success => isDark ? successDark : successLightMode;
  static Color get successLight => isDark ? successLightDark : successLightDark;
  static Color get warning => isDark ? warningDark : warningLightMode;
  static Color get warningLight => isDark ? warningLightDark : warningLightDark;
  static Color get danger => isDark ? dangerDark : dangerLightMode;
  static Color get dangerLight => isDark ? dangerLightDark : dangerLightDark;
  static Color get info => isDark ? infoDark : infoLightMode;
  static Color get infoLight => isDark ? infoLightDark : infoLightDark;

  static Color get seed => isDark ? primaryA0 : primaryLightA0;
  static Color get primary => isDark ? primaryA0 : primaryLightA0;
  static Color get secondary => isDark ? primaryA20 : primaryLightA20;
  static Color get tertiary => isDark ? primaryA40 : primaryLightA40;
  static Color get accent => isDark ? warningLightDark : warningLightMode;

  // Logo gradient
  static List<Color> get logoGradient => isDark
      ? [primaryA0, primaryA20, primaryA40]
      : [primaryLightA0, primaryLightA10, primaryLightA20];
}

/// Custom Theme Extension to provide semantic status colors reactively
class StatusColors extends ThemeExtension<StatusColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color successLight;
  final Color warningLight;
  final Color dangerLight;
  final Color infoLight;
  final Color accent;

  StatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.successLight,
    required this.warningLight,
    required this.dangerLight,
    required this.infoLight,
    required this.accent,
  });

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? successLight,
    Color? warningLight,
    Color? dangerLight,
    Color? infoLight,
    Color? accent,
  }) {
    return StatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      successLight: successLight ?? this.successLight,
      warningLight: warningLight ?? this.warningLight,
      dangerLight: dangerLight ?? this.dangerLight,
      infoLight: infoLight ?? this.infoLight,
      accent: accent ?? this.accent,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

final darkStatusColors = StatusColors(
  success: AppColors.success,
  warning: AppColors.warning,
  danger: AppColors.danger,
  info: AppColors.info,
  successLight: AppColors.successLight,
  warningLight: AppColors.warningLight,
  dangerLight: AppColors.dangerLight,
  infoLight: AppColors.infoLight,
  accent: AppColors.warningLight,
);

final lightStatusColors = StatusColors(
  success: AppColors.successLightMode,
  warning: AppColors.warningLightMode,
  danger: AppColors.dangerLightMode,
  info: AppColors.infoLightMode,
  successLight: AppColors.successLight,
  warningLight: AppColors.warningLight,
  dangerLight: AppColors.dangerLight,
  infoLight: AppColors.infoLight,
  accent: AppColors.warningLightMode,
);

ThemeData buildAppTheme({bool isDark = true}) {
  final primary = isDark ? AppColors.primaryA0 : AppColors.primaryLightA10;
  final secondary = isDark ? AppColors.primaryA20 : AppColors.primaryLightA20;
  final tertiary = isDark ? AppColors.primaryA40 : AppColors.primaryLightA40;
  final background = isDark ? AppColors.surfaceA0 : AppColors.surfaceLightA0;
  final surface = isDark ? AppColors.surfaceA10 : AppColors.surfaceLightA10;
  final surfaceHigh = isDark ? AppColors.surfaceA20 : AppColors.surfaceLightA20;
  final surfaceHighest = isDark ? AppColors.surfaceA30 : AppColors.surfaceLightA30;
  final outline = isDark ? AppColors.surfaceA30 : AppColors.surfaceLightA30;
  final outlineVariant = isDark ? const Color(0xFF2E2E2E) : AppColors.surfaceLightA40;
  final onSurface = isDark ? AppColors.onSurface : AppColors.onSurfaceLight;
  final onSurfaceMuted = isDark ? AppColors.onSurfaceMuted : AppColors.onSurfaceLightMuted;
  final danger = isDark ? AppColors.danger : AppColors.dangerLightMode;

  final colorScheme = ColorScheme(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: isDark ? Colors.black : Colors.white,
    primaryContainer: primary.withValues(alpha: 0.18),
    onPrimaryContainer: isDark ? AppColors.primaryA50 : AppColors.primaryLightA0,
    secondary: secondary,
    onSecondary: isDark ? Colors.black : Colors.white,
    secondaryContainer: secondary.withValues(alpha: 0.16),
    onSecondaryContainer: secondary,
    tertiary: tertiary,
    onTertiary: isDark ? Colors.black : Colors.white,
    tertiaryContainer: tertiary.withValues(alpha: 0.16),
    onTertiaryContainer: tertiary,
    error: danger,
    onError: Colors.white,
    errorContainer: danger.withValues(alpha: 0.16),
    onErrorContainer: danger,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceMuted,
    surfaceContainerLowest: background,
    surfaceContainerLow: surface,
    surfaceContainer: surfaceHigh,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: isDark ? onSurface : AppColors.onSurface,
    onInverseSurface: isDark ? background : AppColors.background,
    inversePrimary: isDark ? primary : AppColors.primaryA0,
    scrim: Colors.black54,
    shadow: isDark ? Colors.black : Colors.black12,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    extensions: [isDark ? darkStatusColors : lightStatusColors],
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: isDark ? Colors.black : Colors.white,
        backgroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: isDark ? Colors.black : Colors.white,
        backgroundColor: primary,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceHigh,
      selectedColor: primary.withValues(alpha: 0.18),
      labelStyle: textTheme.labelLarge ?? const TextStyle(),
      side: BorderSide(color: outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      hintStyle: TextStyle(color: onSurfaceMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: outlineVariant),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHighest,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    dividerTheme: DividerThemeData(
      color: outlineVariant,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: surfaceHigh,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: onSurfaceMuted,
      textColor: onSurface,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: surfaceHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: outlineVariant),
      ),
      textStyle: textTheme.bodySmall,
    ),
  );
}

/// Global reusable Mix styles
class AppStyles {
  static final card = BoxStyler()
    .color(AppColors.surface)
    .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.lg))
    .border(BorderMix.all(BorderSideMix(color: AppColors.outlineVariant, width: 1)));
}
