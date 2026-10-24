import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masonryv2/core/storage/token_storage.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('guarda, lê e apaga o par', () async {
    final storage = SecureTokenStorage();
    expect(await storage.read(), isNull);

    await storage.save(const TokenPair(accessToken: 'a1', refreshToken: 'r1'));
    // Instância nova: lê do armazenamento seguro, não da cópia em memória.
    final reopened = await SecureTokenStorage().read();
    expect(reopened?.accessToken, 'a1');
    expect(reopened?.refreshToken, 'r1');

    await storage.clear();
    expect(await storage.read(), isNull);
    expect(await SecureTokenStorage().read(), isNull);
  });

  test('par incompleto conta como sem sessão', () async {
    FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'a1'});
    expect(await SecureTokenStorage().read(), isNull);
  });

  test('toString não expõe os tokens', () {
    const pair = TokenPair(accessToken: 'segredo-a', refreshToken: 'segredo-r');
    expect(pair.toString(), isNot(contains('segredo')));
  });
}
