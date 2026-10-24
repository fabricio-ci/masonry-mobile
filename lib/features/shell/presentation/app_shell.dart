import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masonryv2/core/routing/app_routes.dart';
import 'package:masonryv2/core/theme/app_colors.dart';
import 'package:masonryv2/core/theme/tokens.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:material_ui/material_ui.dart';

/// Moldura das telas autenticadas: barra superior e menu lateral, como no
/// app legado.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppRoutes.titleFor(location))),
      drawer: AppDrawer(location: location),
      body: SafeArea(child: child),
    );
  }
}

class _DrawerEntry {
  const _DrawerEntry(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

/// Itens entram aqui conforme cada módulo for implementado.
const _entries = [_DrawerEntry(AppRoutes.home, 'Início', Icons.home_outlined)];

class AppDrawer extends ConsumerWidget {
  const AppDrawer({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(
            nome: session is AuthSignedIn ? session.user?.nome : null,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (final entry in _entries)
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text(entry.label),
                    selected: entry.route == location,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(entry.route);
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Fazer logout'),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do aplicativo?'),
        content: const Text('Você precisará entrar novamente com seu login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

/// Cabeçalho do obreiro no menu (degradê ardósia do legado). Foto, CIM, grau
/// e potência entram quando o perfil existir na API.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.nome});

  final String? nome;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final nome = this.nome;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.header, colors.headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSizes.avatar / 2,
                backgroundColor: colors.onHeader,
                child: Icon(
                  Icons.person,
                  size: AppSizes.avatar * 0.6,
                  color: colors.header,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  nome ?? 'Obreiro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onHeader,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
