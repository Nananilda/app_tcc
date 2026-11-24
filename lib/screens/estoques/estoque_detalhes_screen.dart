import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/estoque.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';
import 'selos_estoque.dart';

/// Detalhes de um estoque: os três estados e os sensores que pertencem a ele.
class EstoqueDetalhesScreen extends StatefulWidget {
  const EstoqueDetalhesScreen({super.key, required this.id});

  final int id;

  @override
  State<EstoqueDetalhesScreen> createState() => _EstoqueDetalhesScreenState();
}

class _EstoqueDetalhesScreenState extends State<EstoqueDetalhesScreen> {
  ResultadoOperacao? _feedback;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final app = context.read<AppState>();
    final r1 = await app.carregarEstoques();
    final r2 = await app.carregarSensores(estoqueId: widget.id);
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _feedback = r1.temErro ? r1 : r2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final estoque = app.estoques.where((e) => e.id == widget.id).firstOrNull;
    final sensores = app.sensores.where((s) => s.estoqueId == widget.id);
    final c = context.cores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    return TelaPadrao(
      secao: 'Estoques',
      aoAtualizar: _carregar,
      children: [
        TituloPagina(estoque?.nome ?? 'Estoque'),
        AreaFeedback(resultado: _feedback),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        if (estoque == null && !_carregando)
          FeedbackBox.erros(const ['Estoque não encontrado ou sem permissão.'])
        else if (estoque != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelosEstoque(estoque: estoque),
                const SizedBox(height: 14),
                if (estoque.localizacao.isNotEmpty)
                  Text('Localização: ${estoque.localizacao}'),
                if (estoque.descricao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(estoque.descricao),
                ],
                const SizedBox(height: 6),
                Text(
                  'Sensores críticos: ${estoque.sensoresCriticos} · '
                  'em atenção: ${estoque.sensoresAtencao} · '
                  'alertas em aberto: ${estoque.alertasAtivos}',
                  style: TextStyle(color: c.textoSuave, fontSize: 13),
                ),
                if (app.ehAdmin) ...[
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.go('/estoques/${estoque.id}/editar'),
                    child: const Text('Editar estoque'),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloCartao('Sensores do estoque'),
                if (sensores.isEmpty)
                  const TextoVazio('Nenhum sensor cadastrado neste estoque.'),
                for (final s in sensores) _LinhaSensor(sensor: s, dataFmt: dataFmt),
              ],
            ),
          ),
        ],
        NavRodape(
          links: [
            NavRodapeLink('← Estoques', () => context.go('/estoques')),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

class _LinhaSensor extends StatelessWidget {
  const _LinhaSensor({required this.sensor, required this.dataFmt});

  final Sensor sensor;
  final DateFormat dataFmt;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final valor = sensor.ultimoValor == null
        ? 'Sem leituras'
        : '${NumberFormat('#,##0.##', 'pt_BR').format(sensor.ultimoValor)} ${sensor.tipo.unidade}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.nome,
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.texto),
                ),
                Text(
                  '${sensor.tipo.label}'
                  '${sensor.ultimaLeitura == null ? "" : " · ${dataFmt.format(sensor.ultimaLeitura!)}"}',
                  style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: c.texto)),
              const SizedBox(height: 3),
              StatusBadge(
                texto: switch (sensor.comunicacao) {
                  'online' => 'Online',
                  'inativo' => 'Inativo',
                  _ => 'Sem comunicação',
                },
                tom: sensor.online ? TomBadge.sucesso : TomBadge.neutro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
