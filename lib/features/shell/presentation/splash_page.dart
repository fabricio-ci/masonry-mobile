import 'package:masonryv2/core/theme/tokens.dart';
import 'package:masonryv2/core/widgets/brand_logo.dart';
import 'package:masonryv2/core/widgets/state_views.dart';
import 'package:material_ui/material_ui.dart';

/// Exibida enquanto a sessão salva é verificada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppPalette.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(),
            SizedBox(height: AppSpacing.xxl),
            AppLoading(),
          ],
        ),
      ),
    );
  }
}
