/// Ambiente de execução, definido em tempo de build por
/// `--dart-define-from-file=config/<flavor>.json`.
enum Flavor { dev, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  /// Lê os valores injetados no build. Falha cedo se a URL da API não foi
  /// configurada, em vez de o app subir apontando para lugar nenhum.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

    final flavor = Flavor.values.firstWhere(
      (f) => f.name == flavorName,
      orElse: () => throw StateError('FLAVOR desconhecido: "$flavorName".'),
    );
    final uri = Uri.tryParse(apiBaseUrl);
    if (apiBaseUrl.isEmpty || uri == null || !uri.hasScheme) {
      throw StateError(
        'API_BASE_URL não configurada. Rode com '
        '--dart-define-from-file=config/${flavor.name}.json',
      );
    }
    if (flavor == Flavor.prod && uri.scheme != 'https') {
      throw StateError('Em prod a API_BASE_URL precisa ser HTTPS.');
    }
    return AppConfig(flavor: flavor, apiBaseUrl: apiBaseUrl);
  }

  final Flavor flavor;
  final String apiBaseUrl;

  bool get isDev => flavor == Flavor.dev;
}
