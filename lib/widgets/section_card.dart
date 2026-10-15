import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Cartão com borda arredondada e sombra suave que agrupa seções de conteúdo —
/// equivale à classe `.card` do sistema web. As cores acompanham o tema.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin = const EdgeInsets.only(bottom: 20),
    this.cor,
    this.corBorda,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Cor de fundo (opcional; padrão: fundo de cartão do tema).
  final Color? cor;

  /// Cor da borda (opcional; ex.: vermelha no quadro de exclusão).
  final Color? corBorda;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cor ?? c.fundoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corBorda ?? c.borda),
        boxShadow: c.sombra,
      ),
      child: child,
    );
  }
}
