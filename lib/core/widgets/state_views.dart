import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masonryv2/core/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Estado de carregamento padrão das telas.
class AppLoading extends StatelessWidget {
  const AppLoading({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message ?? 'Carregando',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(message, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vazio ou de erro: ícone, título, mensagem e ação opcional.
class AppMessageState extends StatelessWidget {
  const AppMessageState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
    final actionLabel = this.actionLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSizes.iconLg,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppMessageState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    this.title = 'Não foi possível carregar',
    this.message,
    this.onRetry,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppMessageState(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: message,
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
    );
  }
}

/// Mapeia um [AsyncValue] para carregamento, erro, vazio ou dados.
///
/// O erro nunca é exibido cru (pode conter URL, token ou dado interno):
/// [errorMessage] traduz exceções conhecidas para texto do usuário.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String? Function(Object error)? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) when isEmpty?.call(value) ?? false =>
        empty ?? const AppEmptyState(title: 'Nada por aqui'),
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => AppErrorState(
        message: errorMessage?.call(error),
        onRetry: onRetry,
      ),
      _ => const AppLoading(),
    };
  }
}
