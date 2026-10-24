abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';

  /// Rotas acessíveis sem sessão.
  static const public = {splash, login};

  /// Títulos exibidos na barra do shell.
  static const titles = {home: 'Início'};

  static String titleFor(String location) => titles[location] ?? 'Masonry';
}
