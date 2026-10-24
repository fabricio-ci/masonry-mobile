import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masonryv2/app.dart';
import 'package:masonryv2/core/config/app_config.dart';
import 'package:masonryv2/core/config/app_config_provider.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const MasonryApp(),
    ),
  );
}
