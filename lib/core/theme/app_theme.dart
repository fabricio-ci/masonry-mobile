import 'package:masonryv2/core/theme/app_colors.dart';
import 'package:masonryv2/core/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Tema Material 3 do app, montado só a partir dos tokens.
///
/// Por ora só existe o tema claro (o legado não tem modo escuro).
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.blue,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: AppPalette.blue,
          onPrimary: AppPalette.white,
          secondary: AppPalette.gold,
          onSecondary: AppPalette.white,
          secondaryContainer: AppPalette.goldLight,
          tertiary: AppPalette.teal,
          onTertiary: AppPalette.white,
          error: AppPalette.magenta,
          onError: AppPalette.white,
          surface: AppPalette.white,
          outlineVariant: AppPalette.outline,
        );
    final textTheme = _textTheme(
      Typography.material2021(platform: TargetPlatform.android).black,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppPalette.background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: const [AppColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.charcoal,
        foregroundColor: AppPalette.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppPalette.white),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppPalette.white,
        shape: RoundedRectangleBorder(),
      ),
      cardTheme: const CardThemeData(
        color: AppPalette.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
      // Interruptores em teal, como no legado.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppPalette.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppPalette.teal : null,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.charcoal,
        indicatorColor: AppPalette.white.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppPalette.white
                : AppPalette.white.withValues(alpha: 0.7),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppPalette.white
                : AppPalette.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// Hierarquia do legado: títulos e rótulos em negrito, corpo regular.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
