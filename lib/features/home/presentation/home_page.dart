import 'package:masonryv2/core/widgets/state_views.dart';
import 'package:material_ui/material_ui.dart';

/// Início. Os totais do menu (WIN_Menu) chegam com o módulo Menu.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.dashboard_outlined,
      title: 'Bem-vindo ao Masonry',
      message: 'Os módulos do aplicativo serão liberados nas próximas versões.',
    );
  }
}
