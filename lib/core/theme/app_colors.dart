import 'package:masonryv2/core/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Cores semânticas que não existem no [ColorScheme] do Material 3.
/// Acesse com `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.warning,
    required this.onWarning,
    required this.success,
    required this.onSuccess,
    required this.header,
    required this.headerEnd,
    required this.onHeader,
  });

  static const light = AppColors(
    warning: AppPalette.orange,
    onWarning: AppPalette.white,
    success: AppPalette.green,
    onSuccess: AppPalette.white,
    header: AppPalette.slate,
    headerEnd: AppPalette.slateDark,
    onHeader: AppPalette.white,
  );

  final Color warning;
  final Color onWarning;
  final Color success;
  final Color onSuccess;

  /// Cabeçalho do obreiro (degradê de [header] para [headerEnd]).
  final Color header;
  final Color headerEnd;
  final Color onHeader;

  @override
  AppColors copyWith({
    Color? warning,
    Color? onWarning,
    Color? success,
    Color? onSuccess,
    Color? header,
    Color? headerEnd,
    Color? onHeader,
  }) {
    return AppColors(
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      header: header ?? this.header,
      headerEnd: headerEnd ?? this.headerEnd,
      onHeader: onHeader ?? this.onHeader,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      header: Color.lerp(header, other.header, t)!,
      headerEnd: Color.lerp(headerEnd, other.headerEnd, t)!,
      onHeader: Color.lerp(onHeader, other.onHeader, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
