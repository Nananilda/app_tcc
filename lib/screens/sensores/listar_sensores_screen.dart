import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tabela_dados.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Consulta somente leitura de sensores — equivale a listar_sensores.php.
class ListarSensoresScreen extends StatefulWidget {
  const ListarSensoresScreen({super.key});

  @override
  State<ListarSensoresScreen> createState() => _ListarSensoresScreenState();
}

class _ListarSensoresScreenState extends State<ListarSensoresScreen> {
  bool _carregando = true;
  List<String> _erros = [];

  /// Toque no link "Gestão de Sensores" do texto de apoio (descartado em dispose).
  late final TapGestureRecognizer _irParaGestao;

  @override
  void initState() {
    super.initState();
    _irParaGestao = TapGestureRecognizer()
      ..onTap = () => context.go('/sensores/gestao');
    _carregar();
  }

  @override
  void dispose() {
    _irParaGestao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final resultado = await context.read<AppState>().carregarSensores();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erros = resultado.erros;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = context.cores;
    final sensores = app.sensores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    return TelaPadrao(
      secao: 'Sensores',
      aoAtualizar: _carregar,
      children: [
        const TituloPagina('Consulta de Sensores'),
        // O link para a Gestão só aparece para admin — usuário comum não tem acesso a ela.
        if (app.ehAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: c.textoSuave, fontSize: 14),
                children: [
                  const TextSpan(
                    text:
                        'Lista somente leitura. Para cadastrar ou alterar sensores, acesse a ',
                  ),
                  TextSpan(
                    text: 'Gestão de Sensores',
                    style: TextStyle(
                      color: c.link,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _irParaGestao,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'Lista somente leitura dos sensores cadastrados.',
              style: TextStyle(color: c.textoSuave, fontSize: 14),
            ),
          ),
        FeedbackBox.erros(_erros),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        SectionCard(
          padding: sensores.isEmpty
              ? const EdgeInsets.all(22)
              : EdgeInsets.zero,
          child: sensores.isEmpty
              ? const TextoVazio('Nenhum sensor cadastrado.')
              : TabelaDados(
                  colunas: const [
                    'ID',
                    'Nome',
                    'Tipo',
                    'Localização',
                    'Status',
                    'Cadastrado em',
                  ],
                  linhas: [
                    for (final s in sensores)
                      [
                        Text('${s.id}'),
                        Text(s.nome),
                        Text(s.tipo.label),
                        Text(s.localizacao ?? '—'),
                        StatusBadge.ativo(
                          ativo: s.status == StatusSensor.ativo,
                        ),
                        Text(dataFmt.format(s.criadoEm)),
                      ],
                  ],
                ),
        ),
        NavRodape(
          links: [
            NavRodapeLink('Ver gráficos →', () => context.go('/graficos')),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}
