import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Etiqueta colorida para status binário (ativo/inativo, resolvido/pendente
/// etc). [positivo] controla a cor: verde quando true, vermelho quando false.
class StatusBadge extends StatelessWidget {
  final String texto;
  final bool positivo;

  const StatusBadge({super.key, required this.texto, required this.positivo});

  @override
  Widget build(BuildContext context) {
    final cor = positivo ? AppColors.sucesso : AppColors.erro;
    final fundo = positivo ? AppColors.sucessoFundo : AppColors.erroFundo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
