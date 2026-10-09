import 'package:flutter/material.dart';

/// Coloca campos lado a lado quando há espaço e um abaixo do outro em telas
/// estreitas — o equivalente do `.usuarios-grid` (CSS grid) do sistema web.
class LinhaCampos extends StatelessWidget {
  const LinhaCampos({
    super.key,
    required this.children,
    this.larguraMinima = 460,
    this.espaco = 16,
  });

  /// Campos da linha (cada um ocupa uma fração igual da largura).
  final List<Widget> children;

  /// Abaixo desta largura disponível, os campos passam a ficar empilhados.
  final double larguraMinima;

  /// Espaço entre os campos.
  final double espaco;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final empilhar = restricoes.maxWidth < larguraMinima;

        if (empilhar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: espaco),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: espaco),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
