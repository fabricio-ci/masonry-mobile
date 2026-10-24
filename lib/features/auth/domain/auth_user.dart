/// Obreiro autenticado. A identidade vem do token; [nome] só chega no login
/// e no refresh (`/auth/me` devolve apenas o id).
class AuthUser {
  const AuthUser({required this.obreiroId, this.nome});

  final int obreiroId;
  final String? nome;
}
