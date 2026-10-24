import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:masonryv2/core/storage/token_storage.dart';

class FakeResponse {
  const FakeResponse(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

typedef FakeHandler = Future<FakeResponse> Function(RequestOptions options);

/// Adapter do dio que responde com [handler] em vez de ir à rede.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = await handler(options);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final h in response.headers.entries) h.key: [h.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  TokenPair? tokens;

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> save(TokenPair tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

/// Simula as rotas de auth da API, com refresh de uso único que rotaciona o
/// par, e uma rota protegida `dados`.
class FakeAuthServer {
  FakeAuthServer({
    this.access = 'access-1',
    this.refresh = 'refresh-1',
    this.refreshDelay = const Duration(milliseconds: 30),
  });

  String access;
  String refresh;
  Duration refreshDelay;
  int _generation = 1;

  /// Quando definido, o refresh responde isto em vez de rotacionar.
  FakeResponse? refreshFailure;

  /// Quando definido, o refresh falha sem resposta (rede).
  bool refreshNetworkError = false;

  late final adapter = FakeAdapter(handle);

  static String? bearer(RequestOptions o) {
    final h = o.headers['Authorization'];
    return h is String ? h.replaceFirst('Bearer ', '') : null;
  }

  static const unauthorized = FakeResponse(
    401,
    {'detail': 'Token inválido ou expirado'},
    {'www-authenticate': 'Bearer'},
  );

  Future<FakeResponse> handle(RequestOptions o) async {
    switch (o.path) {
      case 'auth/refresh':
        await Future<void>.delayed(refreshDelay);
        if (refreshNetworkError) {
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'sem rede',
          );
        }
        if (refreshFailure != null) return refreshFailure!;
        final body = o.data as Map<String, dynamic>;
        if (body['refresh_token'] != refresh) return unauthorized;
        _generation++;
        access = 'access-$_generation';
        refresh = 'refresh-$_generation';
        return FakeResponse(200, _tokens());
      case 'dados':
        return bearer(o) == access
            ? const FakeResponse(200, {'ok': true})
            : unauthorized;
      case 'auth/me':
        return bearer(o) == access
            ? const FakeResponse(200, {'obreiro_id': 42})
            : unauthorized;
      case 'auth/logout':
        return bearer(o) == access ? const FakeResponse(204) : unauthorized;
    }
    return const FakeResponse(404, {'detail': 'Not Found'});
  }

  Map<String, Object?> _tokens() => {
    'access_token': access,
    'refresh_token': refresh,
    'token_type': 'bearer',
    'expires_in': 900,
    'obreiro_id': 42,
    'nome': 'Fulano',
  };
}
