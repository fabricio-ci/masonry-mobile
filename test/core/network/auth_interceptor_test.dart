import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masonryv2/core/network/api_client.dart';
import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/storage/token_storage.dart';
import 'package:masonryv2/features/auth/data/auth_repository_impl.dart';

import '../../helpers/fake_api.dart';

class _Harness {
  _Harness(this.server, {TokenPair? tokens})
    : storage = InMemoryTokenStorage(tokens) {
    dio = createApiClient(
      apiBaseUrl: 'http://api.teste',
      storage: storage,
      refresh: () => repository.refresh(),
      onSessionExpired: expiredMessages.add,
      adapter: server.adapter,
    );
    repository = AuthRepositoryImpl(dio: dio, storage: storage);
  }

  final FakeAuthServer server;
  final InMemoryTokenStorage storage;
  final expiredMessages = <String>[];
  late final Dio dio;
  late final AuthRepositoryImpl repository;

  int get refreshCalls => server.adapter.count('auth/refresh');

  Future<Object?> get(String path) async {
    try {
      return (await dio.get<Object?>(path)).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Access que a API já não aceita, com o refresh ainda válido.
const _expired = TokenPair(accessToken: 'vencido', refreshToken: 'refresh-1');

void main() {
  test('envia o Bearer guardado', () async {
    final server = FakeAuthServer();
    final h = _Harness(
      server,
      tokens: const TokenPair(accessToken: 'access-1', refreshToken: 'r'),
    );

    expect(await h.get('dados'), {'ok': true});
    expect(
      server.adapter.requests.single.headers['Authorization'],
      'Bearer access-1',
    );
    expect(h.refreshCalls, 0);
  });

  test('401 renova uma vez, guarda o par novo e repete a requisição', () async {
    final server = FakeAuthServer();
    final h = _Harness(server, tokens: _expired);

    expect(await h.get('dados'), {'ok': true});

    expect(h.refreshCalls, 1);
    final refreshRequest = server.adapter.requests.firstWhere(
      (r) => r.path == 'auth/refresh',
    );
    expect(refreshRequest.headers['Authorization'], isNull);
    expect(h.storage.tokens?.accessToken, 'access-2');
    expect(h.storage.tokens?.refreshToken, 'refresh-2');
    final retry = server.adapter.requests.last;
    expect(retry.path, 'dados');
    expect(retry.headers['Authorization'], 'Bearer access-2');
  });

  test('N requisições com 401 simultâneo fazem um único refresh', () async {
    const n = 20;
    final server = FakeAuthServer();
    final h = _Harness(server, tokens: _expired);

    final results = await Future.wait(List.generate(n, (_) => h.get('dados')));

    expect(results, everyElement({'ok': true}));
    expect(h.refreshCalls, 1);
    expect(h.storage.tokens?.refreshToken, 'refresh-2');
    expect(h.expiredMessages, isEmpty);
  });

  test('requisição que começa durante o refresh espera o token novo', () async {
    final server = FakeAuthServer(
      refreshDelay: const Duration(milliseconds: 100),
    );
    final h = _Harness(server, tokens: _expired);

    final first = h.get('dados');
    // Deixa o primeiro 401 chegar e o refresh começar.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final late = h.get('dados');

    expect(await Future.wait([first, late]), everyElement({'ok': true}));
    expect(h.refreshCalls, 1);
    // A segunda saiu já com o token novo, sem tomar 401.
    expect(server.adapter.count('dados'), 3);
  });

  test('401 que chega depois de outro refresh não renova de novo', () async {
    final server = FakeAuthServer();
    final h = _Harness(server, tokens: _expired);
    final baseHandler = server.handle;
    server.adapter.handler = (o) async {
      if (o.path == 'lento') {
        final sent = FakeAuthServer.bearer(o);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return sent == server.access
            ? const FakeResponse(200, {'ok': 'lento'})
            : FakeAuthServer.unauthorized;
      }
      return baseHandler(o);
    };

    final results = await Future.wait([h.get('lento'), h.get('dados')]);

    expect(results, [
      {'ok': 'lento'},
      {'ok': true},
    ]);
    expect(h.refreshCalls, 1);
  });

  test(
    'refresh recusado: todas falham, tokens apagados, aviso único',
    () async {
      final server = FakeAuthServer(refresh: 'outro');
      final h = _Harness(server, tokens: _expired);

      final results = await Future.wait(
        List.generate(
          5,
          (_) =>
              h.get('dados').then<Object?>((v) => v, onError: (Object e) => e),
        ),
      );

      expect(results, everyElement(isA<SessionExpiredException>()));
      expect(h.refreshCalls, 1);
      expect(h.storage.tokens, isNull);
      expect(h.expiredMessages, hasLength(1));
    },
  );

  test('refresh com 403 traz a mensagem da API', () async {
    final server = FakeAuthServer()
      ..refreshFailure = const FakeResponse(403, {
        'detail': 'Cadastro inativo',
      });
    final h = _Harness(server, tokens: _expired);

    await expectLater(
      h.get('dados'),
      throwsA(
        isA<SessionExpiredException>().having(
          (e) => e.message,
          'message',
          'Cadastro inativo',
        ),
      ),
    );
    expect(h.storage.tokens, isNull);
    expect(h.expiredMessages, ['Cadastro inativo']);
  });

  test('refresh sem rede mantém os tokens e não derruba a sessão', () async {
    final server = FakeAuthServer()..refreshNetworkError = true;
    final h = _Harness(server, tokens: _expired);

    await expectLater(h.get('dados'), throwsA(isA<NetworkException>()));
    expect(h.storage.tokens, same(_expired));
    expect(h.expiredMessages, isEmpty);
  });

  test('401 depois do refresh não entra em laço', () async {
    final server = FakeAuthServer();
    final h = _Harness(server, tokens: _expired);
    final baseHandler = server.handle;
    server.adapter.handler = (o) async =>
        o.path == 'negado' ? FakeAuthServer.unauthorized : baseHandler(o);

    await expectLater(h.get('negado'), throwsA(isA<UnauthorizedException>()));
    expect(h.refreshCalls, 1);
    expect(server.adapter.count('negado'), 2);
  });

  test('outros erros passam direto, sem refresh', () async {
    final server = FakeAuthServer();
    final h = _Harness(server, tokens: _expired);

    await expectLater(
      h.get('nao-existe'),
      throwsA(
        isA<HttpStatusException>().having((e) => e.statusCode, 'status', 404),
      ),
    );
    expect(h.refreshCalls, 0);
  });
}
