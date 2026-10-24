import 'package:masonryv2/features/auth/domain/auth_user.dart';

/// Estado da sessão, para o guard de rotas.
sealed class AuthState {
  const AuthState();
}

/// Verificando se há sessão guardada (início do app).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn([this.user]);

  /// `null` quando a sessão foi restaurada do armazenamento: o app abre sem
  /// rede, e a validade do token só é conferida na primeira chamada à API.
  final AuthUser? user;
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.message});

  /// Motivo para mostrar no login quando a sessão caiu sozinha (expirou,
  /// cadastro inativado). `null` num logout normal.
  final String? message;
}
