import 'package:flutter/material.dart';

import 'topbar.dart';

/// Moldura comum às telas autenticadas: topbar + área rolável centralizada com
/// largura máxima. Evita repetir o mesmo Scaffold/SafeArea/ScrollView/Center/
/// ConstrainedBox em cada tela (equivale ao `.container` do sistema web).
class TelaPadrao extends StatelessWidget {
  const TelaPadrao({
    super.key,
    required this.children,
    this.secao,
    this.larguraMaxima = 1000,
    this.aoAtualizar,
  });

  /// Conteúdo da tela, de cima para baixo.
  final List<Widget> children;

  /// Seção mostrada na topbar (ex.: 'Gráficos').
  final String? secao;

  /// Largura máxima do conteúdo (1000 para telas de dados, 700 para formulários).
  final double larguraMaxima;

  /// Se informado, habilita "puxar para atualizar".
  final Future<void> Function()? aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final margem = largura < 720 ? 14.0 : 24.0;

    Widget conteudo = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(margem, 26, margem, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: larguraMaxima),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );

    if (aoAtualizar != null) {
      conteudo = RefreshIndicator(onRefresh: aoAtualizar!, child: conteudo);
    }

    return Scaffold(
      appBar: Topbar(secao: secao),
      body: SafeArea(child: conteudo),
    );
  }
}
