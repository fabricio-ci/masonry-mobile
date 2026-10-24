import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:masonryv2/core/theme/app_colors.dart';
import 'package:masonryv2/core/theme/app_theme.dart';
import 'package:masonryv2/core/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final theme = AppTheme.light();
  final scheme = theme.colorScheme;
  final colors = theme.extension<AppColors>()!;

  test('usa Material 3 e as cores de identidade do legado', () {
    expect(theme.useMaterial3, isTrue);
    expect(scheme.primary, AppPalette.blue);
    expect(scheme.tertiary, AppPalette.teal);
    expect(scheme.error, AppPalette.magenta);
    expect(theme.appBarTheme.backgroundColor, AppPalette.charcoal);
  });

  test('pares texto/fundo atingem contraste WCAG AA (4,5:1)', () {
    final pairs = <String, (Color, Color)>{
      'primary': (scheme.onPrimary, scheme.primary),
      'secondary': (scheme.onSecondary, scheme.secondary),
      'tertiary': (scheme.onTertiary, scheme.tertiary),
      'error': (scheme.onError, scheme.error),
      'surface': (scheme.onSurface, scheme.surface),
      'appBar': (
        theme.appBarTheme.foregroundColor!,
        theme.appBarTheme.backgroundColor!,
      ),
      'warning': (colors.onWarning, colors.warning),
      'success': (colors.onSuccess, colors.success),
      'header': (colors.onHeader, colors.header),
      'headerEnd': (colors.onHeader, colors.headerEnd),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: key);
    }
  });

  test('botões respeitam o alvo de toque mínimo', () {
    final size = theme.filledButtonTheme.style!.minimumSize!.resolve({});
    expect(size!.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
  });
}
