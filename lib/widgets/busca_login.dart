import 'package:flutter/material.dart';

import 'botoes.dart';
import 'section_card.dart';

/// Cartão "Buscar por login" das telas Editar e Excluir usuário (passo 1 do
/// fluxo). Enviar pelo teclado (Enter) equivale a tocar em "Buscar".
class BuscaLoginCard extends StatelessWidget {
  const BuscaLoginCard({
    super.key,
    required this.controller,
    required this.aoBuscar,
    this.buscando = false,
  });

  final TextEditingController controller;
  final VoidCallback aoBuscar;

  /// Verdadeiro enquanto a consulta ao servidor está em andamento.
  final bool buscando;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final campo = TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Login do usuário a buscar',
              hintText: 'Digite o login do usuário',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onSubmitted: (_) => aoBuscar(),
          );
          final botao = BotaoPrincipal(
            texto: 'Buscar',
            ocupado: buscando,
            aoPressionar: aoBuscar,
          );

          // Em telas estreitas o botão fica abaixo do campo
          if (restricoes.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [campo, const SizedBox(height: 12), botao],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: campo),
              const SizedBox(width: 12),
              // 52 = altura do campo de texto: o botão fica alinhado a ele
              SizedBox(height: 52, child: botao),
            ],
          );
        },
      ),
    );
  }
}
