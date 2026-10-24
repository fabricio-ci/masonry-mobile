import 'package:flutter/material.dart';

import 'package:masonryv2/core/config/app_config.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(MasonryApp(config: config));
}

/// Raiz provisória: tema, rotas e shell chegam na tarefa #443.
class MasonryApp extends StatelessWidget {
  const MasonryApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masonry',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            config.isDev ? 'Masonry (dev)' : 'Masonry',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
