import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versão do app para exibir ao usuário, por exemplo `1.0.0 (1)`. Vem do
/// `version` do pubspec (ou de `--build-name`/`--build-number`).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});
