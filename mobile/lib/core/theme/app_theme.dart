import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Single source of truth tema aplikasi MainGa?.
/// Identitas visual Hitam, Putih, dan Lime Green (aturan 60-30-10),
/// dengan elevasi berbasis tone step alih-alih border dan bayangan ramai.
class AppTheme {
  AppTheme._();

  // Backward compatibility alias ke AppColors
  static const Color background = AppColors.bg;
  static const Color surface = AppColors.surface;
  static const Color surfaceElevated = AppColors.surfaceElevated;
  static const Color surfaceHighlight = AppColors.surfaceHighlight;
  static const Color primary = AppColors.primary;
  static const Color primaryAccent = AppColors.primaryLight;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;
  static const Color border = AppColors.border;
  static const Color borderFocused = AppColors.borderFocused;
  static const Color inputBackground = AppColors.inputBackground;
  static const Color error = AppColors.error;
  static const Color success = AppColors.success;
  static const Color ratingStar = AppColors.ratingStar;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      primaryColor: AppColors.primary,
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.textPrimary.withValues(alpha: 0.05),
      highlightColor: AppColors.textPrimary.withValues(alpha: 0.04),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        error: AppColors.error,
        onError: AppColors.textPrimary,
      ),
      textTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        toolbarTextStyle: AppTypography.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        labelStyle: AppTypography.bodyMedium,
        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        iconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgBorderRadius,
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.5),
          overlayColor: AppColors.onPrimary.withValues(alpha: 0.08),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.fullBorderRadius,
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.onPrimary),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.fullBorderRadius,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(50),
          overlayColor: AppColors.textPrimary.withValues(alpha: 0.06),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.fullBorderRadius,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          overlayColor: AppColors.textPrimary.withValues(alpha: 0.06),
          minimumSize: const Size(48, 48),
          textStyle: AppTypography.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.white,
        disabledColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.fullBorderRadius,
        ),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheetBorderRadius,
        ),
        titleTextStyle: AppTypography.titleLarge,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        modalBackgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: AppColors.transparent,
        modalBarrierColor: AppColors.black.withValues(alpha: 0.6),
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        dragHandleColor: AppColors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTopBorderRadius,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: AppSpacing.listPadding,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceElevated,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
        trackHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        actionTextColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorderRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: AppRadius.smBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        textStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surfaceElevated,
        linearTrackColor: AppColors.surfaceElevated,
      ),
    );
  }
}
