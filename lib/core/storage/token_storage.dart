import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par de tokens da sessão. Os dois são opacos (não são JWT): o app só os
/// guarda e reenvia, nunca tenta ler o conteúdo.
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  // Sem os valores: o objeto pode acabar em log ou mensagem de erro.
  @override
  String toString() => 'TokenPair(***)';
}

/// Onde o par de tokens fica guardado entre execuções do app.
abstract interface class TokenStorage {
  Future<TokenPair?> read();

  /// Grava o par inteiro. O refresh token rotaciona a cada uso, então o par
  /// é sempre substituído junto, nunca só o access.
  Future<void> save(TokenPair tokens);

  Future<void> clear();
}

/// [TokenStorage] no Keychain (iOS) / Keystore (Android), com cópia em
/// memória para não ir ao armazenamento seguro a cada requisição.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';

  final FlutterSecureStorage _storage;
  TokenPair? _cache;
  bool _loaded = false;

  @override
  Future<TokenPair?> read() async {
    if (_loaded) return _cache;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    _cache = access != null && refresh != null
        ? TokenPair(accessToken: access, refreshToken: refresh)
        : null;
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> save(TokenPair tokens) async {
    _cache = tokens;
    _loaded = true;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
