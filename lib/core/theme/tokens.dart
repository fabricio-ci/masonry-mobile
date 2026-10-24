import 'package:material_ui/material_ui.dart';

/// Tokens de design do app. Único lugar onde valores visuais crus (cores,
/// espaçamentos, raios) são definidos; telas e componentes usam o tema ou
/// estas constantes, nunca literais.
///
/// Paleta extraída das telas do app legado (WinDev). Onde a cor original não
/// atingia contraste WCAG AA (4,5:1) com texto branco, foi escurecida mantendo
/// o matiz; o valor legado fica registrado ao lado.
abstract final class AppPalette {
  /// Barra superior e navegação inferior do legado.
  static const charcoal = Color(0xFF333333);

  /// Azul dos botões. Legado: #3897F1 (3,1:1 com branco, reprovado em AA).
  static const blue = Color(0xFF1C6FCB);
  static const blueLegacy = Color(0xFF3897F1);

  /// Teal dos interruptores do legado (#008375).
  static const teal = Color(0xFF008375);

  /// Dourado do brasão da GLOMARON, escurecido para uso em texto.
  static const gold = Color(0xFF8C6A1F);
  static const goldLight = Color(0xFFD9B66A);

  /// Magenta do botão de excluir do legado (#CF0E69).
  static const magenta = Color(0xFFCF0E69);

  /// Ardósia do cabeçalho do obreiro (perfil e menu lateral).
  static const slate = Color(0xFF5F6C74);
  static const slateDark = Color(0xFF465259);

  /// Laranja de destaque do legado ("1 documento"), escurecido para texto.
  static const orange = Color(0xFFA65C00);

  static const green = Color(0xFF2E7D32);

  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F5F6);
  static const outline = Color(0xFFC4C7CA);
}

/// Escala de espaçamento (múltiplos de 4).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Margem padrão do conteúdo de uma tela.
  static const EdgeInsets page = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppSizes {
  /// Alvo de toque mínimo (Material e WCAG 2.5.8).
  static const double minTouchTarget = 48;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 48;
  static const double avatar = 64;
  static const double maxContentWidth = 560;
}
