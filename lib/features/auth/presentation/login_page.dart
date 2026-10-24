import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masonryv2/core/config/app_version_provider.dart';
import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/theme/tokens.dart';
import 'package:masonryv2/core/widgets/brand_logo.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:material_ui/material_ui.dart';

/// Tela de login. Com o login aceito, o guard de rotas tira o usuário daqui
/// sozinho; a tela só cuida do formulário e das mensagens de erro.
///
/// "Lembrar ao iniciar" e "Alterar minha senha", do legado, aguardam decisão
/// do dono. A senha nunca é guardada em disco.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _senha = TextEditingController();
  final _loginFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool _senhaVisivel = false;
  bool _enviando = false;
  String? _erro;

  /// O aviso de sessão expirada some na primeira tentativa de entrar.
  bool _avisoSessaoVisto = false;

  /// 429: o botão fica bloqueado até o `Retry-After` passar.
  Timer? _bloqueio;
  int _segundosBloqueado = 0;

  @override
  void dispose() {
    _bloqueio?.cancel();
    _login.dispose();
    _senha.dispose();
    _loginFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  bool get _podeEnviar => !_enviando && _segundosBloqueado == 0;

  Future<void> _acessar() async {
    if (!_podeEnviar) return;
    setState(() {
      _erro = null;
      _avisoSessaoVisto = true;
    });
    if (!_formKey.currentState!.validate()) {
      (_login.text.trim().isEmpty ? _loginFocus : _senhaFocus).requestFocus();
      return;
    }

    setState(() => _enviando = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .login(login: _login.text.trim(), senha: _senha.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = _mensagem(e));
      switch (e) {
        case UnauthorizedException():
          _senha.clear();
          _senhaFocus.requestFocus();
        case TooManyRequestsException(:final retryAfter?):
          _bloquear(retryAfter);
        default:
          break;
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// 401 tem texto fixo: a API não diz se errou o login ou a senha, e a tela
  /// também não. Os demais erros já trazem mensagem para o usuário.
  static String _mensagem(ApiException e) => switch (e) {
    UnauthorizedException() => 'Login ou senha inválidos.',
    _ => e.message,
  };

  void _bloquear(Duration duracao) {
    _bloqueio?.cancel();
    setState(() => _segundosBloqueado = duracao.inSeconds);
    if (_segundosBloqueado == 0) return;
    _bloqueio = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _segundosBloqueado--);
      if (_segundosBloqueado <= 0) {
        timer.cancel();
        _segundosBloqueado = 0;
      }
    });
  }

  static String _tempo(int segundos) {
    if (segundos < 60) return '$segundos s';
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '${segundos ~/ 60}:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authStateProvider);
    final avisoSessao = switch (session) {
      AuthSignedOut(:final message?) when !_avisoSessaoVisto => message,
      _ => null,
    };
    final erro = _erro;
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandLogo()),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            header: true,
                            child: Text(
                              'Identificação',
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (avisoSessao != null) ...[
                            _Aviso(
                              icon: Icons.info_outline,
                              color: AppPalette.orange,
                              message: avisoSessao,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (erro != null) ...[
                            _Aviso(
                              icon: Icons.error_outline,
                              color: theme.colorScheme.error,
                              message: erro,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          TextFormField(
                            controller: _login,
                            focusNode: _loginFocus,
                            enabled: !_enviando,
                            decoration: const InputDecoration(
                              labelText: 'Login',
                            ),
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Informe seu login.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _senha,
                            focusNode: _senhaFocus,
                            enabled: !_enviando,
                            obscureText: !_senhaVisivel,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: 'Informe sua senha',
                              suffixIcon: IconButton(
                                tooltip: _senhaVisivel
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                icon: Icon(
                                  _senhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel,
                                ),
                              ),
                            ),
                            autofillHints: const [AutofillHints.password],
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => unawaited(_acessar()),
                            validator: (value) => (value ?? '').isEmpty
                                ? 'Informe sua senha.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton(
                            onPressed: _podeEnviar
                                ? () => unawaited(_acessar())
                                : null,
                            child: _enviando
                                ? const SizedBox.square(
                                    dimension: AppSizes.iconSm,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      semanticsLabel: 'Entrando',
                                    ),
                                  )
                                : Text(
                                    _segundosBloqueado > 0
                                        ? 'Aguarde '
                                              '${_tempo(_segundosBloqueado)}'
                                        : 'Acessar',
                                  ),
                          ),
                          if (version != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Versão: $version',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem em destaque acima do formulário, anunciada pelo leitor de tela.
class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: color, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
