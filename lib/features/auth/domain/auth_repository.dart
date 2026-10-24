import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/features/auth/domain/auth_user.dart';

/// Autenticação contra `/api/v1/auth`. Os erros são [ApiException]:
/// [UnauthorizedException] (401), [ForbiddenException] (403, mensagem da
/// API), [TooManyRequestsException] (429, com `retryAfter`),
/// [NetworkException] (sem resposta) e [SessionExpiredException].
abstract interface class AuthRepository {
  /// Entra com login e senha e guarda o par de tokens.
  Future<AuthUser> login({required String login, required String senha});

  /// Troca o refresh token guardado por um par novo e o guarda. Chamadas
  /// simultâneas viram um único POST /auth/refresh. Se a API recusar,
  /// apaga os tokens e lança [SessionExpiredException].
  Future<AuthUser> refresh();

  /// Encerra a sessão na API (melhor esforço) e sempre apaga os tokens
  /// locais, mesmo sem rede.
  Future<void> logout();

  Future<AuthUser> me();

  /// Há um par de tokens guardado (não diz se ainda é válido).
  Future<bool> hasSession();
}
