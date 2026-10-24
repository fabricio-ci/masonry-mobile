import 'dart:io';

import 'package:dio/dio.dart';

/// Erros de chamada à API, já traduzidos para o app. [message] é a mensagem
/// para o usuário: o campo `detail` da API quando existe, senão um texto
/// padrão. Nunca contém token nem senha.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Converte o erro do dio. Erros que o próprio app já tipou (por exemplo,
  /// sessão expirada vinda do interceptor) passam direto.
  factory ApiException.fromDio(DioException e) {
    final error = e.error;
    if (error is ApiException) return error;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const UnexpectedApiException('Requisição cancelada.');
      case DioExceptionType.unknown:
        return error is IOException
            ? const NetworkException()
            : const UnexpectedApiException();
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
    }
  }

  final String message;

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final detail = _detail(response?.data);
    return switch (status) {
      401 => UnauthorizedException(detail ?? 'Não autorizado.'),
      403 => ForbiddenException(detail ?? 'Acesso negado.'),
      429 => TooManyRequestsException(
        detail ?? 'Muitas tentativas. Tente novamente mais tarde.',
        retryAfter: _retryAfter(response?.headers),
      ),
      _ => HttpStatusException(
        status,
        detail ?? 'Erro inesperado do servidor (HTTP $status).',
      ),
    };
  }

  /// `{"detail": "..."}`. Erros de validação (422) trazem uma lista em
  /// `detail`; nesse caso fica a mensagem padrão.
  static String? _detail(Object? data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
    }
    return null;
  }

  /// A API manda `Retry-After` em segundos.
  static Duration? _retryAfter(Headers? headers) {
    final seconds = int.tryParse(headers?.value('retry-after')?.trim() ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// 401: credenciais ou token inválidos.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message);
}

/// 401 numa rota autenticada depois de o refresh também falhar: o usuário
/// precisa entrar de novo. Os tokens locais já foram apagados.
final class SessionExpiredException extends ApiException {
  const SessionExpiredException([
    super.message = 'Sua sessão expirou. Entre novamente.',
  ]);
}

/// 403: por exemplo, cadastro inativo. A mensagem vem da API.
final class ForbiddenException extends ApiException {
  const ForbiddenException(super.message);
}

/// 429: muitas tentativas. [retryAfter] vem do header `Retry-After`.
final class TooManyRequestsException extends ApiException {
  const TooManyRequestsException(super.message, {this.retryAfter});

  final Duration? retryAfter;
}

/// Sem conexão, timeout ou falha de TLS: a requisição não teve resposta.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Não foi possível conectar ao servidor. '
        'Verifique sua conexão.',
  ]);
}

/// Qualquer outra resposta de erro HTTP.
final class HttpStatusException extends ApiException {
  const HttpStatusException(this.statusCode, super.message);

  final int statusCode;
}

final class UnexpectedApiException extends ApiException {
  const UnexpectedApiException([super.message = 'Erro inesperado.']);
}
