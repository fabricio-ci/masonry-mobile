import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masonryv2/core/config/app_config_provider.dart';
import 'package:masonryv2/core/routing/app_router.dart';
import 'package:masonryv2/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class MasonryApp extends ConsumerWidget {
  const MasonryApp({super.key});

  static const _locale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: config.isDev ? 'Masonry DEV' : 'Masonry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
