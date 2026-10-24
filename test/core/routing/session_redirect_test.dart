import 'package:flutter_test/flutter_test.dart';
import 'package:masonryv2/core/routing/app_router.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';

void main() {
  String? redirect(AuthState state, String location) =>
      sessionRedirect(state, Uri.parse(location));

  group('sessão desconhecida', () {
    const state = AuthUnknown();

    test('fica na splash', () {
      expect(redirect(state, '/splash'), isNull);
    });

    test('rota protegida vai para a splash guardando o destino', () {
      expect(
        redirect(state, '/perfil?aba=docs'),
        '/splash?from=%2Fperfil%3Faba%3Ddocs',
      );
    });

    test('início vai para a splash sem from', () {
      expect(redirect(state, '/'), '/splash');
    });
  });

  group('deslogado', () {
    const state = AuthSignedOut();

    test('fica no login', () {
      expect(redirect(state, '/login'), isNull);
      expect(redirect(state, '/login?from=%2Fperfil'), isNull);
    });

    test('rota protegida vai para o login guardando o destino', () {
      expect(redirect(state, '/perfil'), '/login?from=%2Fperfil');
    });

    test('splash repassa o destino ao login', () {
      expect(
        redirect(state, '/splash?from=%2Fperfil'),
        '/login?from=%2Fperfil',
      );
      expect(redirect(state, '/splash'), '/login');
    });
  });

  group('logado', () {
    const state = AuthSignedIn();

    test('segue na rota protegida', () {
      expect(redirect(state, '/'), isNull);
      expect(redirect(state, '/perfil'), isNull);
    });

    test('rota pública vai para o início', () {
      expect(redirect(state, '/login'), '/');
      expect(redirect(state, '/splash'), '/');
    });

    test('volta ao destino guardado', () {
      expect(
        redirect(state, '/login?from=%2Fperfil%3Faba%3Ddocs'),
        '/perfil?aba=docs',
      );
    });

    test('ignora from externo ou público', () {
      expect(redirect(state, '/login?from=https%3A%2F%2Fevil.com'), '/');
      expect(redirect(state, '/login?from=%2F%2Fevil.com'), '/');
      expect(redirect(state, '/login?from=%2Flogin'), '/');
      expect(redirect(state, '/splash?from=%2Fsplash'), '/');
    });
  });
}
