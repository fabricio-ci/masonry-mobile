import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masonryv2/core/config/app_config.dart';
import 'package:masonryv2/core/config/app_config_provider.dart';
import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/storage/token_storage.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';

import '../../helpers/fake_api.dart';

void main() {
  late FakeAuthServer server;
  late InMemoryTokenStorage storage;
  late ProviderContainer container;

  void setUpWith({TokenPair? tokens}) {
    server = FakeAuthServer();
    storage = InMemoryTokenStorage(tokens);
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.teste'),
        ),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    container.read(apiClientProvider).httpClientAdapter = server.adapter;
  }

  Future<AuthState> settled() async {
    container.read(authStateProvider);
    await Future<void>.delayed(Duration.zero);
    return container.read(authStateProvider);
  }

  test('sem tokens guardados termina deslogado', () async {
    setUpWith();
    expect(container.read(authStateProvider), isA<AuthUnknown>());
    expect(await settled(), isA<AuthSignedOut>());
  });

  test('com tokens guardados abre logado, sem ir à rede', () async {
    setUpWith(
      tokens: const TokenPair(accessToken: 'access-1', refreshToken: 'r'),
    );
    final state = await settled();
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).user, isNull);
    expect(server.adapter.requests, isEmpty);
  });

  test('login e logout atualizam o estado', () async {
    setUpWith();
    await settled();
    server.adapter.handler = (o) async => o.path == 'auth/login'
        ? const FakeResponse(200, {
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'token_type': 'bearer',
            'expires_in': 900,
            'obreiro_id': 42,
            'nome': 'Fulano',
          })
        : server.handle(o);

    await container
        .read(authStateProvider.notifier)
        .login(login: 'fulano', senha: 'x');
    final signedIn = container.read(authStateProvider);
    expect(signedIn, isA<AuthSignedIn>());
    expect((signedIn as AuthSignedIn).user?.nome, 'Fulano');

    await container.read(authStateProvider.notifier).logout();
    final signedOut = container.read(authStateProvider);
    expect(signedOut, isA<AuthSignedOut>());
    expect((signedOut as AuthSignedOut).message, isNull);
    expect(storage.tokens, isNull);
  });

  test('refresh recusado leva a deslogado com mensagem', () async {
    setUpWith(
      tokens: const TokenPair(accessToken: 'vencido', refreshToken: 'gasto'),
    );
    expect(await settled(), isA<AuthSignedIn>());

    final dio = container.read(apiClientProvider);
    await expectLater(
      dio.get<Object?>('dados'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<SessionExpiredException>(),
        ),
      ),
    );

    // O aviso chega ao estado por stream, num microtask seguinte.
    await Future<void>.delayed(Duration.zero);
    final state = container.read(authStateProvider);
    expect(state, isA<AuthSignedOut>());
    expect((state as AuthSignedOut).message, isNotNull);
    expect(storage.tokens, isNull);
  });
}
