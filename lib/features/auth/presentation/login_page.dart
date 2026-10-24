import 'package:masonryv2/core/theme/tokens.dart';
import 'package:masonryv2/core/widgets/brand_logo.dart';
import 'package:material_ui/material_ui.dart';

/// Destino do guard para quem está sem sessão. Por ora só a identidade
/// visual: o formulário (campos, `authStateProvider.login`, mensagens de
/// 401/403/429 e de sessão expirada) é uma tela à parte, ainda não feita.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Identificação',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
