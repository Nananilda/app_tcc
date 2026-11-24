import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/estoque.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';
import 'selos_estoque.dart';

/// Lista de estoques — equivale a app/views/estoques/listar.php.
///
/// Usuário comum vê só os estoques autorizados (o servidor filtra);
/// administrador vê todos e pode cadastrar.
class EstoquesScreen extends StatefulWidget {
  const EstoquesScreen({super.key});

  @override
  State<EstoquesScreen> createState() => _EstoquesScreenState();
}

class _EstoquesScreenState extends State<EstoquesScreen> {
  ResultadoOperacao? _feedback;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final resultado = await context.read<AppState>().carregarEstoques();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _feedback = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final estoques = app.estoques;

    return TelaPadrao(
      secao: 'Estoques',
      aoAtualizar: _carregar,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const TituloPagina('Estoques'),
            if (app.ehAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/estoques/novo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo estoque'),
                ),
              ),
          ],
        ),
        AreaFeedback(resultado: _feedback),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        if (!_carregando && estoques.isEmpty)
          const TextoVazio(
            'Nenhum estoque disponível para o seu usuário. '
            'Peça a um administrador para liberar o acesso.',
          ),
        for (final e in estoques) _CartaoEstoque(estoque: e),
        NavRodape(
          links: [NavRodapeLink('← Voltar ao painel', () => context.go('/painel'))],
        ),
      ],
    );
  }
}

class _CartaoEstoque extends StatelessWidget {
  const _CartaoEstoque({required this.estoque});

  final Estoque estoque;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go('/estoques/${estoque.id}'),
      child: SectionCard(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    estoque.nome,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.texto,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textoFraco),
              ],
            ),
            if (estoque.localizacao.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  estoque.localizacao,
                  style: TextStyle(color: c.textoSuave, fontSize: 13),
                ),
              ),
            const SizedBox(height: 10),
            SelosEstoque(estoque: estoque),
            const SizedBox(height: 10),
            Text(
              'Sensores online: ${estoque.sensoresOnline} de ${estoque.sensoresAtivos} ativos'
              ' · Alertas em aberto: ${estoque.alertasAtivos}'
              '${estoque.alertasCriticosPendentes > 0 ? " (${estoque.alertasCriticosPendentes} crítico(s) pendente(s))" : ""}',
              style: TextStyle(color: c.textoSuave, fontSize: 12.5),
            ),
            if (estoque.sensoresSemComunicacaoNomes.isNotEmpty)
              Text(
                'Sem comunicação: ${estoque.sensoresSemComunicacaoNomes.join(", ")}',
                style: TextStyle(color: c.textoSuave, fontSize: 12.5),
              ),
            Text(
              estoque.ultimaLeitura == null
                  ? 'Nenhuma leitura registrada.'
                  : 'Última leitura: ${dataFmt.format(estoque.ultimaLeitura!)}',
              style: TextStyle(color: c.textoSuave, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
