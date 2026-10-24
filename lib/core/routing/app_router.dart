import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masonryv2/core/routing/app_routes.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:masonryv2/features/auth/presentation/login_page.dart';
import 'package:masonryv2/features/home/presentation/home_page.dart';
import 'package:masonryv2/features/shell/presentation/app_shell.dart';
import 'package:masonryv2/features/shell/presentation/splash_page.dart';
import 'package:material_ui/material_ui.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<AuthState>(ref.read(authStateProvider));
  ref.listen(authStateProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => sessionRedirect(session.value, state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});

/// Guard de autenticação. Retorna para onde redirecionar, ou `null` para
/// seguir na rota pedida.
///
/// Uma rota protegida acessada sem sessão vai para o login (ou para a splash,
/// enquanto a sessão é verificada) levando o destino em `?from=`, e volta
/// para ele após o login.
String? sessionRedirect(AuthState session, Uri uri) {
  final path = uri.path;
  final isPublic = AppRoutes.public.contains(path);
  final from = _safeFrom(uri.queryParameters['from']);
  final target = isPublic ? from : uri.toString();

  String withFrom(String route) => target == null || target == AppRoutes.home
      ? route
      : Uri(path: route, queryParameters: {'from': target}).toString();

  return switch (session) {
    AuthUnknown() =>
      path == AppRoutes.splash ? null : withFrom(AppRoutes.splash),
    AuthSignedOut() =>
      path == AppRoutes.login ? null : withFrom(AppRoutes.login),
    AuthSignedIn() => isPublic ? from ?? AppRoutes.home : null,
  };
}

/// Aceita só caminhos internos, para `from` nunca apontar para fora do app
/// nem para outra rota pública (evita laço de redirecionamento).
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final path = Uri.tryParse(from)?.path;
  if (path == null || AppRoutes.public.contains(path)) return null;
  return from;
}
