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
