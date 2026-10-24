import 'package:dio/dio.dart';

import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/storage/token_storage.dart';

/// Troca o refresh token guardado por um par novo e o salva. Deve lançar
/// [SessionExpiredException] quando a API recusa o refresh (e já ter apagado
/// os tokens) e outro [ApiException] quando não houve resposta.
typedef RefreshTokens = Future<void> Function();

/// Avisada uma vez por refresh recusado, com a mensagem para o usuário.
typedef SessionExpiredCallback = void Function(String message);

/// Põe o Bearer nas requisições e, num 401, renova a sessão uma vez e repete
/// a requisição.
///
/// O refresh token é de uso único e rotaciona, então dois refreshes em
/// paralelo derrubariam a sessão (o segundo usaria um token já gasto). Por
/// isso o refresh é single-flight: várias requisições com 401 ao mesmo tempo
/// esperam o mesmo POST /auth/refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._storage,
    required this._refresh,
    required this._onSessionExpired,
  });

  /// `extra` de requisições públicas (login, refresh): sem Bearer e sem
  /// tentativa de refresh.
  static const skipAuth = 'auth.skip';

  /// `extra` de requisições que levam Bearer mas cujo 401 não deve disparar
  /// refresh (logout).
  static const skipRefresh = 'auth.skipRefresh';

  static const _retried = 'auth.retried';

  final Dio _dio;
  final TokenStorage _storage;
  final RefreshTokens _refresh;
  final SessionExpiredCallback _onSessionExpired;

  Future<void>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] == true) return handler.next(options);

    // Com um refresh em curso, o access guardado está para ser trocado:
    // esperar evita gastar uma ida ao servidor com um token que vai dar 401.
    final pending = _refreshing;
    if (pending != null) {
      try {
        await pending;
      } on Object {
        // Quem iniciou o refresh trata a falha; aqui só se segue em frente.
      }
    }

    final tokens = await _storage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuth] == true ||
        options.extra[skipRefresh] == true ||
        options.extra[_retried] == true) {
      return handler.next(err);
    }

    try {
      // Se o access guardado já não é o que levou 401, outro refresh
      // terminou no meio do caminho: basta repetir com o token novo.
      final current = await _storage.read();
      if (current == null || _bearerOf(options) == current.accessToken) {
        await _refreshOnce();
      }
    } on ApiException catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: err.response,
          type: err.type,
          error: e,
        ),
      );
    }

    try {
      final response = await _dio.fetch<dynamic>(
        options.copyWith(extra: {...options.extra, _retried: true}),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  Future<void> _refreshOnce() async {
    final flight = _refreshing ??= _runRefresh();
    try {
      await flight;
    } finally {
      if (identical(_refreshing, flight)) _refreshing = null;
    }
  }

  Future<void> _runRefresh() async {
    try {
      await _refresh();
    } on SessionExpiredException catch (e) {
      // Uma vez por refresh, não uma por requisição que estava esperando.
      _onSessionExpired(e.message);
      rethrow;
    }
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    return header is String && header.startsWith('Bearer ')
        ? header.substring('Bearer '.length)
        : null;
  }
}
