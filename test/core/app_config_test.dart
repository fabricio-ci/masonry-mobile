import 'package:flutter_test/flutter_test.dart';
import 'package:masonryv2/core/config/app_config.dart';

void main() {
  test('isDev reflete o flavor', () {
    const dev = AppConfig(
      flavor: Flavor.dev,
      apiBaseUrl: 'http://10.0.2.2:8002',
    );
    const prod = AppConfig(
      flavor: Flavor.prod,
      apiBaseUrl: 'https://api.exemplo',
    );
    expect(dev.isDev, isTrue);
    expect(prod.isDev, isFalse);
  });

  test('fromEnvironment lê o config de dev passado no flutter test', () {
    // Os testes rodam com --dart-define-from-file=config/dev.json (ver README).
    final config = AppConfig.fromEnvironment();
    expect(config.flavor, Flavor.dev);
    expect(config.apiBaseUrl, startsWith('http'));
  });
}
