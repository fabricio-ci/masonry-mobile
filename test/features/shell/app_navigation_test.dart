import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masonryv2/app.dart';
import 'package:masonryv2/core/config/app_config.dart';
import 'package:masonryv2/core/config/app_config_provider.dart';
import 'package:masonryv2/core/config/app_version_provider.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:masonryv2/features/auth/domain/auth_user.dart';
import 'package:masonryv2/features/auth/presentation/login_page.dart';
import 'package:masonryv2/features/home/presentation/home_page.dart';
import 'package:masonryv2/features/shell/presentation/splash_page.dart';
import 'package:material_ui/material_ui.dart';

/// Sessão controlada pelo teste, sem repositório nem rede.
class _FakeAuth extends AuthStateNotifier {
  _FakeAuth(this._initial);

  final AuthState _initial;
  int logouts = 0;

  @override
  AuthState build() => _initial;

  void set(AuthState value) => state = value;

  @override
  Future<void> logout() async {
    logouts++;
    state = const AuthSignedOut();
  }
}

void main() {
  late _FakeAuth auth;

  Future<void> pumpApp(WidgetTester tester, AuthState initial) async {
    auth = _FakeAuth(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              flavor: Flavor.dev,
              apiBaseUrl: 'http://10.0.2.2:8002',
            ),
          ),
          authStateProvider.overrideWith(() => auth),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: const MasonryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sessão em verificação mostra a splash', (tester) async {
    auth = _FakeAuth(const AuthUnknown());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://x'),
          ),
          authStateProvider.overrideWith(() => auth),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: const MasonryApp(),
      ),
    );
    // Não usa pumpAndSettle: o indicador de progresso anima sem parar.
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);

    auth.set(const AuthSignedOut());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('sem sessão vai para o login', (tester) async {
    await pumpApp(tester, const AuthSignedOut());
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Identificação'), findsOneWidget);
  });

  testWidgets('login leva ao shell com o início', (tester) async {
    await pumpApp(tester, const AuthSignedOut());
    auth.set(
      const AuthSignedIn(AuthUser(obreiroId: 1, nome: 'HUGO SILVA GALVES')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Início'), findsOneWidget);
  });

  testWidgets('menu lateral mostra o obreiro e faz logout com confirmação', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AuthSignedIn(AuthUser(obreiroId: 1, nome: 'HUGO SILVA GALVES')),
    );

    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    expect(find.text('HUGO SILVA GALVES'), findsOneWidget);

    await tester.tap(find.text('Fazer logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(auth.logouts, 0);

    await tester.tap(find.text('Fazer logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(auth.logouts, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('sessão restaurada sem nome mostra rótulo genérico', (
    tester,
  ) async {
    await pumpApp(tester, const AuthSignedIn());
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    expect(find.text('Obreiro'), findsOneWidget);
  });
}
