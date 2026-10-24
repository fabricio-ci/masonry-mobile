import 'package:dio/dio.dart';

import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/network/auth_interceptor.dart';
import 'package:masonryv2/core/storage/token_storage.dart';
import 'package:masonryv2/features/auth/domain/auth_repository.dart';
import 'package:masonryv2/features/auth/domain/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._dio, required this._storage});

  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthUser>? _refreshing;

  static final _public = Options(extra: {AuthInterceptor.skipAuth: true});

  @override
  Future<AuthUser> login({required String login, required String senha}) async {
    final data = await _send(
      () => _dio.post<Object?>(
        'auth/login',
        data: {'login': login, 'senha': senha},
        options: _public,
      ),
    );
    return _saveSession(data);
  }

  @override
  Future<AuthUser> refresh() async {
    final flight = _refreshing ??= _refresh();
    try {
      return await flight;
    } finally {
      if (identical(_refreshing, flight)) _refreshing = null;
    }
  }

  Future<AuthUser> _refresh() async {
    final tokens = await _storage.read();
    if (tokens == null) throw const SessionExpiredException();
    try {
      final data = await _send(
        () => _dio.post<Object?>(
          'auth/refresh',
          data: {'refresh_token': tokens.refreshToken},
          options: _public,
        ),
      );
      return await _saveSession(data);
    } on UnauthorizedException {
      // Refresh gasto, expirado ou revogado (ex.: troca de senha).
      await _storage.clear();
      throw const SessionExpiredException();
    } on ForbiddenException catch (e) {
      // Cadastro inativado: a mensagem da API explica o motivo.
      await _storage.clear();
      throw SessionExpiredException(e.message);
    }
    // Sem resposta (rede, 5xx): os tokens ficam. Se o servidor chegou a
    // rotacionar, o próximo refresh dá 401 e aí a sessão cai.
  }

  @override
  Future<void> logout() async {
    if (await _storage.read() == null) return;
    try {
      await _dio.post<void>(
        'auth/logout',
        options: Options(extra: {AuthInterceptor.skipRefresh: true}),
      );
    } on DioException {
      // Melhor esforço: sem rede, a sessão no servidor expira sozinha.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<AuthUser> me() async {
    final data = await _send(() => _dio.get<Object?>('auth/me'));
    return AuthUser(obreiroId: _int(data, 'obreiro_id'));
  }

  @override
  Future<bool> hasSession() async => await _storage.read() != null;

  Future<AuthUser> _saveSession(Map<String, dynamic> data) async {
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    if (access is! String || refresh is! String) {
      throw const UnexpectedApiException('Resposta inválida do servidor.');
    }
    final user = AuthUser(
      obreiroId: _int(data, 'obreiro_id'),
      nome: data['nome'] is String ? data['nome'] as String : null,
    );
    // Sempre o par novo: o refresh anterior já não vale mais.
    await _storage.save(TokenPair(accessToken: access, refreshToken: refresh));
    return user;
  }

  static int _int(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! int) {
      throw const UnexpectedApiException('Resposta inválida do servidor.');
    }
    return value;
  }

  static Future<Map<String, dynamic>> _send(
    Future<Response<Object?>> Function() request,
  ) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const UnexpectedApiException('Resposta inválida do servidor.');
    }
    return data;
  }
}
