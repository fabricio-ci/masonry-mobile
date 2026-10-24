import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masonryv2/core/network/api_client.dart';
import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/storage/token_storage.dart';
import 'package:masonryv2/features/auth/data/auth_repository_impl.dart';

import '../../helpers/fake_api.dart';

const _tokens = TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1');

void main() {
  late FakeAdapter adapter;
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  void setUpWith(FakeHandler handler, {TokenPair? tokens}) {
    adapter = FakeAdapter(handler);
    storage = InMemoryTokenStorage(tokens);
    late final AuthRepositoryImpl repo;
    final dio = createApiClient(
      apiBaseUrl: 'http://api.teste/',
      storage: storage,
      refresh: () => repo.refresh(),
      onSessionExpired: (_) {},
      adapter: adapter,
    );
    repository = repo = AuthRepositoryImpl(dio: dio, storage: storage);
  }

  const tokenBody = {
    'access_token': 'access-2',
    'refresh_token': 'refresh-2',
    'token_type': 'bearer',
    'expires_in': 900,
    'obreiro_id': 7,
    'nome': 'Fulano de Tal',
  };

  group('login', () {
    test('guarda o par e devolve o obreiro', () async {
      setUpWith((_) async => const FakeResponse(200, tokenBody));

      final user = await repository.login(login: 'fulano', senha: 'segredo');

      expect(user.obreiroId, 7);
      expect(user.nome, 'Fulano de Tal');
      expect(storage.tokens?.accessToken, 'access-2');
      expect(storage.tokens?.refreshToken, 'refresh-2');
      final request = adapter.requests.single;
      expect(request.uri.toString(), 'http://api.teste/api/v1/auth/login');
      expect(request.method, 'POST');
      expect(request.data, {'login': 'fulano', 'senha': 'segredo'});
      expect(request.headers['Authorization'], isNull);
    });

    test('nome nulo é aceito', () async {
      setUpWith(
        (_) async => FakeResponse(
          200,
          Map<String, Object?>.of(tokenBody)..['nome'] = null,
        ),
      );

      final user = await repository.login(login: 'a', senha: 'b');

      expect(user.nome, isNull);
    });

    test('401 vira UnauthorizedException com a mensagem da API', () async {
      setUpWith(
        (_) async =>
            const FakeResponse(401, {'detail': 'Login ou senha inválidos'}),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'Login ou senha inválidos',
          ),
        ),
      );
      expect(storage.tokens, isNull);
      // Login com 401 não tenta refresh.
      expect(adapter.requests, hasLength(1));
    });

    test('403 vira ForbiddenException com a mensagem da API', () async {
      setUpWith(
        (_) async => const FakeResponse(403, {'detail': 'Cadastro inativo'}),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(
          isA<ForbiddenException>().having(
            (e) => e.message,
            'message',
            'Cadastro inativo',
          ),
        ),
      );
    });

    test('429 traz o Retry-After', () async {
      setUpWith(
        (_) async => const FakeResponse(
          429,
          {'detail': 'Muitas tentativas'},
          {'retry-after': '120'},
        ),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(
          isA<TooManyRequestsException>()
              .having((e) => e.message, 'message', 'Muitas tentativas')
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 120),
              ),
        ),
      );
    });

    test('429 sem Retry-After', () async {
      setUpWith((_) async => const FakeResponse(429, {'detail': 'Espere'}));

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(
          isA<TooManyRequestsException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            isNull,
          ),
        ),
      );
    });

    test('sem rede vira NetworkException', () async {
      setUpWith(
        (o) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'sem rede',
        ),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('timeout vira NetworkException', () async {
      setUpWith(
        (o) async => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: o,
        ),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('422 com detail em lista usa mensagem padrão', () async {
      setUpWith(
        (_) async => const FakeResponse(422, {
          'detail': [
            {'msg': 'field required'},
          ],
        }),
      );

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'status', 422)
              .having((e) => e.message, 'message', contains('HTTP 422')),
        ),
      );
    });

    test('resposta sem token é rejeitada', () async {
      setUpWith((_) async => const FakeResponse(200, {'obreiro_id': 1}));

      await expectLater(
        repository.login(login: 'a', senha: 'b'),
        throwsA(isA<UnexpectedApiException>()),
      );
      expect(storage.tokens, isNull);
    });
  });

  group('refresh', () {
    test('envia o refresh guardado e salva o par novo', () async {
      setUpWith(
        (_) async => const FakeResponse(200, tokenBody),
        tokens: _tokens,
      );

      final user = await repository.refresh();

      expect(user.obreiroId, 7);
      final request = adapter.requests.single;
      expect(request.path, 'auth/refresh');
      expect(request.data, {'refresh_token': 'refresh-1'});
      expect(request.headers['Authorization'], isNull);
      expect(storage.tokens?.refreshToken, 'refresh-2');
    });

    test('chamadas simultâneas fazem um único POST', () async {
      setUpWith((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const FakeResponse(200, tokenBody);
      }, tokens: _tokens);

      await Future.wait(List.generate(10, (_) => repository.refresh()));

      expect(adapter.requests, hasLength(1));
    });

    test('401 apaga os tokens e lança SessionExpiredException', () async {
      setUpWith(
        (_) async => const FakeResponse(401, {'detail': 'Token inválido'}),
        tokens: _tokens,
      );

      await expectLater(
        repository.refresh(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(storage.tokens, isNull);
    });

    test('sem tokens guardados lança SessionExpiredException', () async {
      setUpWith((_) async => const FakeResponse(200, tokenBody));

      await expectLater(
        repository.refresh(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('logout', () {
    test('chama a API com Bearer e apaga os tokens', () async {
      setUpWith((_) async => const FakeResponse(204), tokens: _tokens);

      await repository.logout();

      final request = adapter.requests.single;
      expect(request.path, 'auth/logout');
      expect(request.headers['Authorization'], 'Bearer access-1');
      expect(storage.tokens, isNull);
    });

    test('401 no logout não tenta refresh e apaga os tokens', () async {
      setUpWith(
        (_) async => const FakeResponse(401, {'detail': 'x'}),
        tokens: _tokens,
      );

      await repository.logout();

      expect(adapter.requests.map((r) => r.path), ['auth/logout']);
      expect(storage.tokens, isNull);
    });

    test('sem rede ainda apaga os tokens', () async {
      setUpWith(
        (o) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'sem rede',
        ),
        tokens: _tokens,
      );

      await repository.logout();

      expect(storage.tokens, isNull);
    });
  });

  test('me devolve o obreiro do token', () async {
    setUpWith(
      (_) async => const FakeResponse(200, {'obreiro_id': 42}),
      tokens: _tokens,
    );

    final user = await repository.me();

    expect(user.obreiroId, 42);
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('hasSession reflete o armazenamento', () async {
    setUpWith((_) async => const FakeResponse(204));
    expect(await repository.hasSession(), isFalse);
    storage.tokens = _tokens;
    expect(await repository.hasSession(), isTrue);
  });
}
