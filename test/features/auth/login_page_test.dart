import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masonryv2/core/config/app_version_provider.dart';
import 'package:masonryv2/core/network/api_exception.dart';
import 'package:masonryv2/core/theme/app_theme.dart';
import 'package:masonryv2/features/auth/data/auth_providers.dart';
import 'package:masonryv2/features/auth/domain/auth_state.dart';
import 'package:masonryv2/features/auth/domain/auth_user.dart';
import 'package:masonryv2/features/auth/presentation/login_page.dart';
import 'package:material_ui/material_ui.dart';

/// Login controlado pelo teste: responde [result] ou lança [error].
class _FakeAuth extends AuthStateNotifier {
  _FakeAuth(this._initial);

  final AuthState _initial;
  ApiException? error;
  final calls = <(String, String)>[];

  @override
  AuthState build() => _initial;

  @override
  Future<AuthUser> login({required String login, required String senha}) async {
    calls.add((login, senha));
    final error = this.error;
    if (error != null) throw error;
    const user = AuthUser(obreiroId: 1, nome: 'Fulano');
    state = const AuthSignedIn(user);
    return user;
  }
}

void main() {
  late _FakeAuth auth;

  Future<void> pumpLogin(
    WidgetTester tester, {
    AuthState initial = const AuthSignedOut(),
  }) async {
    auth = _FakeAuth(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => auth),
          appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  final loginField = find.widgetWithText(TextFormField, 'Login');
  final senhaField = find.widgetWithText(TextFormField, 'Senha');
  final acessar = find.widgetWithText(FilledButton, 'Acessar');

  Future<void> fill(WidgetTester tester, String login, String senha) async {
    await tester.enterText(loginField, login);
    await tester.enterText(senhaField, senha);
  }

  bool hasFocus(WidgetTester tester, Finder field) => tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;

  testWidgets('mostra identidade e versão do app', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Versão: 1.0.0 (1)'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Brasão da Grande Loja')),
      findsOneWidget,
    );
  });

  testWidgets('campos vazios não enviam e focam o primeiro com erro', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(acessar);
    await tester.pumpAndSettle();

    expect(find.text('Informe seu login.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(hasFocus(tester, loginField), isTrue);
    expect(auth.calls, isEmpty);

    await tester.enterText(loginField, 'fulano');
    await tester.tap(acessar);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, senhaField), isTrue);
    expect(auth.calls, isEmpty);
  });

  testWidgets('envia login sem espaços e a senha como digitada', (
    tester,
  ) async {
    await pumpLogin(tester);
    await fill(tester, '  fulano ', ' s3nha ');
    await tester.tap(acessar);
    await tester.pumpAndSettle();

    expect(auth.calls, [('fulano', ' s3nha ')]);
    expect(auth.state, isA<AuthSignedIn>());
  });

  testWidgets('ação de concluir do teclado na senha envia', (tester) async {
    await pumpLogin(tester);
    await fill(tester, 'fulano', 'x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(auth.calls, hasLength(1));
  });

  testWidgets('401 mostra credenciais inválidas e limpa a senha', (
    tester,
  ) async {
    await pumpLogin(tester);
    auth.error = const UnauthorizedException('Invalid credentials');
    await fill(tester, 'fulano', 'errada');
    await tester.tap(acessar);
    await tester.pumpAndSettle();

    expect(find.text('Login ou senha inválidos.'), findsOneWidget);
    expect(find.text('Invalid credentials'), findsNothing);
    final senha = tester.widget<TextFormField>(senhaField);
    expect(senha.controller!.text, isEmpty);
    expect(hasFocus(tester, senhaField), isTrue);
  });

  testWidgets('403 mostra a mensagem da API', (tester) async {
    await pumpLogin(tester);
    auth.error = const ForbiddenException('Cadastro inativo.');
    await fill(tester, 'fulano', 'x');
    await tester.tap(acessar);
    await tester.pumpAndSettle();
    expect(find.text('Cadastro inativo.'), findsOneWidget);
  });

  testWidgets('sem rede mostra mensagem de conexão', (tester) async {
    await pumpLogin(tester);
    auth.error = const NetworkException();
    await fill(tester, 'fulano', 'x');
    await tester.tap(acessar);
    await tester.pumpAndSettle();
    expect(find.text(const NetworkException().message), findsOneWidget);
  });

  testWidgets('429 bloqueia o botão até o Retry-After passar', (tester) async {
    await pumpLogin(tester);
    auth.error = const TooManyRequestsException(
      'Muitas tentativas.',
      retryAfter: Duration(seconds: 2),
    );
    await fill(tester, 'fulano', 'x');
    await tester.tap(acessar);
    await tester.pump();

    expect(find.text('Muitas tentativas.'), findsOneWidget);
    final bloqueado = find.widgetWithText(FilledButton, 'Aguarde 2 s');
    expect(bloqueado, findsOneWidget);
    expect(tester.widget<FilledButton>(bloqueado).onPressed, isNull);

    await tester.tap(bloqueado);
    await tester.pump(const Duration(seconds: 1));
    expect(find.widgetWithText(FilledButton, 'Aguarde 1 s'), findsOneWidget);
    expect(auth.calls, hasLength(1));

    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<FilledButton>(acessar).onPressed, isNotNull);
  });

  testWidgets('sessão que caiu sozinha mostra o motivo até nova tentativa', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      initial: const AuthSignedOut(message: 'Sua sessão expirou.'),
    );
    expect(find.text('Sua sessão expirou.'), findsOneWidget);

    auth.error = const UnauthorizedException('x');
    await fill(tester, 'fulano', 'x');
    await tester.tap(acessar);
    await tester.pumpAndSettle();
    expect(find.text('Sua sessão expirou.'), findsNothing);
  });

  testWidgets('alterna a visibilidade da senha', (tester) async {
    await pumpLogin(tester);
    EditableText senha() => tester.widget<EditableText>(
      find.descendant(of: senhaField, matching: find.byType(EditableText)),
    );

    expect(senha().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(senha().obscureText, isFalse);
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pump();
    expect(senha().obscureText, isTrue);
  });

  testWidgets('alvos de toque têm ao menos 48dp', (tester) async {
    await pumpLogin(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
