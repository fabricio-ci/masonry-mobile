import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masonryv2/core/config/app_config_provider.dart';
import 'package:masonryv2/core/network/api_client.dart';
import 'package:masonryv2/core/storage/token_storage.dart';
import 'package:masonryv2/features/auth/data/auth_repository_impl.dart';
import 'package:masonryv2/features/auth/domain/auth_repository.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:masonryv2/features/auth/domain/auth_user.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

/// Cliente HTTP e repositório nascem juntos: o interceptor precisa do
/// repositório para o refresh e o repositório precisa do cliente. Montar os
/// dois no mesmo provider evita um ciclo no grafo do Riverpod.
class _AuthCore {
  _AuthCore(this.dio, this.repository, this.sessionExpired);

  final Dio dio;
  final AuthRepository repository;

  /// Mensagem a cada refresh recusado pela API.
  final Stream<String> sessionExpired;
}

final _authCoreProvider = Provider<_AuthCore>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final expired = StreamController<String>.broadcast();
  late final AuthRepositoryImpl repository;
  final dio = createApiClient(
    apiBaseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    storage: storage,
    refresh: () => repository.refresh(),
    onSessionExpired: expired.add,
  );
  repository = AuthRepositoryImpl(dio: dio, storage: storage);
  ref.onDispose(() {
    dio.close();
    unawaited(expired.close());
  });
  return _AuthCore(dio, repository, expired.stream);
});

/// Cliente da API com Bearer e refresh single-flight.
final apiClientProvider = Provider<Dio>(
  (ref) => ref.watch(_authCoreProvider).dio,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(_authCoreProvider).repository,
);

/// Estado da sessão: o guard de rotas observa este provider.
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref
        .watch(_authCoreProvider)
        .sessionExpired
        .listen(_sessionExpired);
    ref.onDispose(subscription.cancel);
    unawaited(_restore());
    return const AuthUnknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Sessão guardada abre o app direto, mesmo sem rede.
  Future<void> _restore() async {
    final hasSession = await _repository.hasSession();
    if (!ref.mounted || state is! AuthUnknown) return;
    state = hasSession ? const AuthSignedIn() : const AuthSignedOut();
  }

  /// Lança [ApiException] em caso de erro, para a tela mostrar a mensagem.
  Future<AuthUser> login({required String login, required String senha}) async {
    final user = await _repository.login(login: login, senha: senha);
    state = AuthSignedIn(user);
    return user;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthSignedOut();
  }

  /// O refresh foi recusado e os tokens já foram apagados.
  void _sessionExpired(String message) {
    state = AuthSignedOut(message: message);
  }
}
