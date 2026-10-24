import 'package:material_ui/material_ui.dart';

/// Brasão da GLOMARON (mesmo do login do app legado).
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 120, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/brasao_glomaron.png',
      width: size,
      height: size,
      semanticLabel: 'Brasão da Grande Loja Maçônica do Estado de Rondônia',
    );
  }
}
