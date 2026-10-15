import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/tema_controller.dart';
import '../theme/cores.dart';

/// Botão que alterna entre os temas claro e escuro. Mostra o ícone da AÇÃO:
/// lua no tema claro (vai escurecer) e sol no escuro (vai clarear).
class TemaBotao extends StatelessWidget {
  const TemaBotao({super.key});

  @override
  Widget build(BuildContext context) {
    final brilho = Theme.of(context).brightness;
    final escuro = brilho == Brightness.dark;
    final c = context.cores;

    return IconButton(
      tooltip: escuro ? 'Mudar para o tema claro' : 'Mudar para o tema escuro',
      icon: Icon(
        escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 19,
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size(38, 38),
        side: BorderSide(color: c.borda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => context.read<TemaController>().alternar(brilho),
    );
  }
}
