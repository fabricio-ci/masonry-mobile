# Masonry (app)

App Flutter do Masonry (gestão maçônica), sucessor do app WinDev Mobile `MasonryV2`.
Fala somente com a API REST [masonry-mobile-api](https://github.com/fabricio-ci/masonry-mobile-api).

- Bundle / applicationId: `br.org.glomaron.masonryv2` (flavor dev: `br.org.glomaron.masonryv2.dev`)
- Plataformas: Android e iOS (iOS mínimo 15.0)
- Pacote Dart: `masonryv2`

## Requisitos

- Flutter stable (desenvolvido com 3.47 / Dart 3.13)
- API local rodando (ver README da API): `http://localhost:8002/docs`

## Ambientes (flavors)

A URL da API e o ambiente vêm de `config/<flavor>.json`, passados com `--dart-define-from-file`.

| Flavor | Arquivo              | Android                                   | HTTP sem TLS |
|--------|----------------------|-------------------------------------------|--------------|
| dev    | `config/dev.json`    | `br.org.glomaron.masonryv2.dev`, "Masonry DEV" | liberado     |
| prod   | `config/prod.json`   | `br.org.glomaron.masonryv2`, "Masonry"    | bloqueado    |

`config/dev.json` aponta para `http://10.0.2.2:8002` (a máquina host vista pelo emulador Android).
Para aparelho físico ou simulador iOS, crie `config/dev.local.json` (ignorado pelo git) com o IP da LAN
ou `http://localhost:8002` e use esse arquivo no lugar.

Em prod o app recusa subir se `API_BASE_URL` estiver vazia ou não for HTTPS. A URL de produção ainda
não foi definida.

## Rodando

```
flutter pub get
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

Build de produção (Android):

```
flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json
```

No VS Code, as configurações de execução estão em `.vscode/launch.json`.

### iOS

Os flavors nativos do iOS (schemes do Xcode) ainda não foram criados porque exigem um Mac. Por
enquanto o iOS roda sem `--flavor`, só com `--dart-define-from-file`. O `Info.plist` libera HTTP apenas
para a rede local (`NSAllowsLocalNetworking`); domínios públicos continuam exigindo HTTPS.

## Qualidade

```
flutter analyze
flutter test --dart-define-from-file=config/dev.json
```

`analysis_options.yaml` é estrito (strict-casts/inference/raw-types, sem `print`). Não registre em log
tokens, senhas, conteúdo de voto ou dados pessoais.

## Estrutura

Feature-first: `lib/core/` (config, rede, tema, roteamento) e `lib/features/<feature>/{data,domain,presentation}`.

### Tema, navegação e componentes

- **Material desacoplado:** no Flutter 3.47 o Material saiu do framework. Importe sempre
  `package:material_ui/material_ui.dart`, nunca `package:flutter/material.dart` (misturar os dois
  quebra `Theme` e as páginas do go_router).
- **Tokens:** `lib/core/theme/tokens.dart` é o único lugar com cores, espaçamentos, raios e tamanhos
  crus. A paleta vem do app legado; onde a cor original não passava em contraste AA ela foi
  escurecida (o teste `test/core/theme/app_theme_test.dart` garante 4,5:1). Cores semânticas extras
  (aviso, sucesso, cabeçalho do obreiro) ficam em `AppColors` (`context.appColors`).
- **Rotas:** `lib/core/routing/`. O guard (`sessionRedirect`) observa o `authStateProvider`: sessão em
  verificação vai para `/splash`, sem sessão vai para `/login?from=<destino>` e, após o login, volta
  ao destino. Telas autenticadas ficam dentro do `ShellRoute` (barra superior + menu lateral).
- **Estados de tela:** `lib/core/widgets/state_views.dart` traz `AppLoading`, `AppEmptyState`,
  `AppErrorState` e `AsyncValueView` (nunca mostra a exceção crua ao usuário).
