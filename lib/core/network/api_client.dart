import 'package:dio/dio.dart';

import 'package:masonryv2/core/network/auth_interceptor.dart';
import 'package:masonryv2/core/storage/token_storage.dart';

/// Cliente HTTP da API REST (`<apiBaseUrl>/api/v1/`). Os caminhos das
/// requisições são relativos e sem barra inicial, ex.: `auth/me`.
///
/// Sem interceptor de log de propósito: corpo e headers levam token e senha.
Dio createApiClient({
  required String apiBaseUrl,
  required TokenStorage storage,
  required RefreshTokens refresh,
  required SessionExpiredCallback onSessionExpired,
  HttpClientAdapter? adapter,
}) {
  final base = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  final dio = Dio(
    BaseOptions(
      baseUrl: '$base/api/v1/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      storage: storage,
      refresh: refresh,
      onSessionExpired: onSessionExpired,
    ),
  );
  return dio;
}
