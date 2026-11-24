import 'package:flutter/material.dart';

import '../../models/estoque.dart';
import '../../widgets/status_badge.dart';

/// Os TRÊS selos independentes de um estoque: condição ambiental, comunicação
/// e situação cadastral. Falha de comunicação nunca vira condição ambiental, e
/// estoque sem leituras válidas nunca aparece como "Normal".
class SelosEstoque extends StatelessWidget {
  const SelosEstoque({super.key, required this.estoque});

  final Estoque estoque;

  @override
  Widget build(BuildContext context) {
    final condicao = switch (estoque.condicao) {
      CondicaoAmbiental.normal => TomBadge.sucesso,
      CondicaoAmbiental.atencao => TomBadge.alerta,
      CondicaoAmbiental.critico => TomBadge.erro,
      CondicaoAmbiental.indisponivel => TomBadge.neutro,
    };
    final comunicacao = switch (estoque.comunicacao) {
      EstadoComunicacao.todosOnline => TomBadge.sucesso,
      EstadoComunicacao.parcial => TomBadge.alerta,
      EstadoComunicacao.semComunicacao => TomBadge.erro,
      EstadoComunicacao.semSensores => TomBadge.neutro,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        StatusBadge(
          texto: 'Condição: ${estoque.condicao.label}',
          tom: condicao,
        ),
        StatusBadge(
          texto: estoque.comunicacaoRotulo.isEmpty
              ? estoque.comunicacao.label
              : estoque.comunicacaoRotulo,
          tom: comunicacao,
        ),
        StatusBadge.ativo(ativo: estoque.ativo),
      ],
    );
  }
}
