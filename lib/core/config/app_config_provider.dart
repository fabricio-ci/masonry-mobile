import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masonryv2/core/config/app_config.dart';

/// Configuração do ambiente. Sobrescrita em `main` com o valor do build.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider não configurado.'),
);
