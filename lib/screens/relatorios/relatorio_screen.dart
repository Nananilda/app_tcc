import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/leitura.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/linha_campos.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tabela_dados.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Relatório de qualidade ambiental — equivale a relatorio_qualidade.php.
///
/// Filtra por sensor, período e faixa de valores. O resumo estatístico
/// (média/mínimo/máximo) é calculado pelo banco sobre TODAS as leituras do
/// filtro; a tabela detalhada mostra as mais recentes.
class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  static const _porPagina = 50;
  int _estoqueId = 0; // 0 = todos

  TipoSensor? _sensor;
  DateTime _dataIni = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dataFim = DateTime.now();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  RelatorioResultado _resultado = RelatorioResultado.vazio;
  String? _erro;
  bool _carregando = false;

  final _numero = NumberFormat('#,##0.00', 'pt_BR');

  @override
  void initState() {
    super.initState();
    context.read<AppState>().carregarEstoques();
    WidgetsBinding.instance.addPostFrameCallback((_) => _filtrar());
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  /// Com [acrescentar], busca a PRÓXIMA página e soma à tabela atual.
  Future<void> _filtrar({bool acrescentar = false}) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final pagina = acrescentar ? _resultado.pagina + 1 : 1;
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));

    final resposta = await context.read<AppState>().carregarRelatorio(
      _dataIni,
      _dataFim,
      sensor: _sensor,
      valorMin: min,
      valorMax: max,
      estoqueId: _estoqueId == 0 ? null : _estoqueId,
      pagina: pagina,
      porPagina: _porPagina,
    );

    if (!mounted) return;
    setState(() {
      if (resposta.ok) {
        final novo = resposta.dados!;
        _resultado = acrescentar
            ? RelatorioResultado(
                leituras: [..._resultado.leituras, ...novo.leituras],
                resumo: novo.resumo,
                total: novo.total,
                totalAlertas: novo.totalAlertas,
                pagina: novo.pagina,
                porPagina: novo.porPagina,
                segundosForaLimites: novo.segundosForaLimites,
              )
            : novo;
      }
      _erro = resposta.erro;
      _carregando = false;
    });
  }

  bool _exportando = false;

  /// Baixa TODOS os registros do filtro (não só a página) e abre o
  /// compartilhamento/salvamento do sistema.
  Future<void> _exportar(String formato) async {
    setState(() {
      _exportando = true;
      _erro = null;
    });
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
    final resposta = await context.read<AppState>().exportarRelatorio(
      formato,
      _dataIni,
      _dataFim,
      sensor: _sensor,
      valorMin: min,
      valorMax: max,
      estoqueId: _estoqueId == 0 ? null : _estoqueId,
    );
    if (!mounted) return;
    if (!resposta.ok) {
      setState(() {
        _exportando = false;
        _erro = resposta.erro;
      });
      return;
    }
    final nome = 'relatorio-akron.$formato';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              resposta.dados!,
              mimeType: formato == 'pdf' ? 'application/pdf' : 'text/csv',
              name: nome,
            ),
          ],
          fileNameOverrides: [nome],
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível compartilhar o arquivo.');
    }
    if (mounted) setState(() => _exportando = false);
  }

  void _limparFiltros() {
    setState(() {
      _sensor = null;
      _estoqueId = 0;
      _dataIni = DateTime.now().subtract(const Duration(days: 7));
      _dataFim = DateTime.now();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
    _filtrar();
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final selecionado = await showDatePicker(
      context: context,
      initialDate: inicio ? _dataIni : _dataFim,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: inicio ? 'Data inicial' : 'Data final',
    );
    if (selecionado == null) return;
    setState(() {
      // O período nunca fica invertido: a outra ponta acompanha a escolhida
      if (inicio) {
        _dataIni = selecionado;
        if (_dataFim.isBefore(_dataIni)) {
          _dataFim = _dataIni;
        }
      } else {
        _dataFim = selecionado;
        if (_dataIni.isAfter(_dataFim)) {
          _dataIni = _dataFim;
        }
      }
    });
    _filtrar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final dataFmt = DateFormat('dd/MM/yyyy');
    final dataHoraFmt = DateFormat('dd/MM/yyyy HH:mm');
    final leituras = _resultado.leituras;
    final resumo = _resultado.resumo;

    return TelaPadrao(
      secao: 'Relatórios',
      children: [
        const TituloPagina('Relatório de Qualidade Ambiental'),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        FeedbackBox.erros([?_erro]),

        // ── Filtros ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RotuloSecao('Filtros'),
              LayoutBuilder(
                builder: (context, restricoes) {
                  final sensor = CampoSelecao<TipoSensor?>(
                    rotulo: 'Sensor',
                    valor: _sensor,
                    dica: '— Todos —',
                    itens: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Todos —'),
                      ),
                      for (final t in TipoSensor.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(t.rotuloComUnidade),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _sensor = v);
                      _filtrar();
                    },
                  );
                  final estoque = CampoSelecao<int>(
                    rotulo: 'Estoque',
                    valor: _estoqueId,
                    itens: [
                      const DropdownMenuItem(value: 0, child: Text('— Todos —')),
                      for (final e in context.watch<AppState>().estoques)
                        DropdownMenuItem(value: e.id, child: Text(e.nome)),
                    ],
                    onChanged: (v) {
                      setState(() => _estoqueId = v ?? 0);
                      _filtrar();
                    },
                  );
                  final de = _CampoData(
                    rotulo: 'De',
                    texto: dataFmt.format(_dataIni),
                    aoTocar: () => _selecionarData(inicio: true),
                  );
                  final ate = _CampoData(
                    rotulo: 'Até',
                    texto: dataFmt.format(_dataFim),
                    aoTocar: () => _selecionarData(inicio: false),
                  );
                  final minimo = TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Valor mín.'),
                    onSubmitted: (_) => _filtrar(),
                  );
                  final maximo = TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Valor máx.'),
                    onSubmitted: (_) => _filtrar(),
                  );

                  // Celular: sensor em linha própria e os demais campos em pares
                  if (restricoes.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        estoque,
                        const SizedBox(height: 16),
                        sensor,
                        const SizedBox(height: 16),
                        LinhaCampos(larguraMinima: 0, children: [de, ate]),
                        const SizedBox(height: 16),
                        LinhaCampos(
                          larguraMinima: 0,
                          children: [minimo, maximo],
                        ),
                      ],
                    );
                  }

                  // Computador: tudo em uma linha (quebra se faltar espaço)
                  return Wrap(
                    spacing: 14,
                    runSpacing: 16,
                    children: [
                      SizedBox(width: 230, child: estoque),
                      SizedBox(width: 230, child: sensor),
                      SizedBox(width: 160, child: de),
                      SizedBox(width: 160, child: ate),
                      SizedBox(width: 120, child: minimo),
                      SizedBox(width: 120, child: maximo),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _filtrar,
                    child: const Text('Filtrar'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _limparFiltros,
                    child: const Text('Limpar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportando ? null : () => _exportar('csv'),
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('Exportar CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportando ? null : () => _exportar('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Exportar PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Resumo estatístico ──
        if (resumo.isNotEmpty) ...[
          const TituloCartao('Resumo do período', espacoAbaixo: 10),
          SectionCard(
            padding: EdgeInsets.zero,
            child: TabelaDados(
              colunas: const [
                'Sensor',
                'Leituras',
                'Média',
                'Mínimo',
                'Máximo',
                'Fora dos limites',
              ],
              centralizar: const {1, 2, 3, 4, 5},
              linhas: [
                for (final r in resumo)
                  [
                    Text(r.tipo.rotuloComUnidade),
                    Text('${r.total}'),
                    Text(_numero.format(r.media)),
                    Text(_numero.format(r.minimo)),
                    Text(_numero.format(r.maximo)),
                    Text('${r.foraLimites}'),
                  ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Alertas no período: ${_resultado.totalAlertas}'
              '${_resultado.segundosForaLimites > 0 ? " · Tempo estimado fora dos limites: ${Duration(seconds: _resultado.segundosForaLimites).inMinutes} min" : ""}',
              style: TextStyle(color: c.textoSuave, fontSize: 13),
            ),
          ),
        ],

        // ── Leituras detalhadas ──
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Leituras detalhadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '(${leituras.length} de ${_resultado.total} registros)',
                style: TextStyle(color: c.textoSuave, fontSize: 13),
              ),
            ],
          ),
        ),
        if (leituras.isEmpty)
          const TextoVazio(
            'Nenhuma leitura encontrada com os filtros aplicados.',
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: TabelaDados(
                  colunas: const ['Sensor', 'Valor', 'Data/Hora'],
                  linhas: [
                    for (final l in leituras)
                      [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.sensorTipo.rotuloComUnidade),
                            if (l.sensorNome != null)
                              Text(
                                l.estoqueNome == null
                                    ? l.sensorNome!
                                    : '${l.sensorNome} · ${l.estoqueNome}',
                                style: TextStyle(
                                  color: c.textoSuave,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        Text(_numero.format(l.valor)),
                        Text(dataHoraFmt.format(l.lidoEm)),
                      ],
                  ],
                ),
              ),
            ),
          ),

        if (_resultado.temMaisPaginas)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton(
              onPressed: _carregando ? null : () => _filtrar(acrescentar: true),
              child: const Text('Carregar mais leituras'),
            ),
          ),
        NavRodape(
          links: [
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Campo que exibe uma data e abre o calendário ao ser tocado.
class _CampoData extends StatelessWidget {
  const _CampoData({
    required this.rotulo,
    required this.texto,
    required this.aoTocar,
  });

  final String rotulo;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      hint: 'Toque para alterar a data',
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: c.textoSuave,
            ),
          ),
          child: Text(texto, style: TextStyle(color: c.texto)),
        ),
      ),
    );
  }
}
