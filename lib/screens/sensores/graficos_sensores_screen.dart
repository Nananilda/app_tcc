import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/estoque.dart';
import '../../models/leitura.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Janelas de tempo oferecidas (horas → rótulo).
const _periodos = <int, String>{
  6: '6 h',
  12: '12 h',
  24: '24 h',
  48: '48 h',
  168: '7 dias',
};

/// Gráficos de sensores — equivale a graficos_sensores.php.
///
/// Atualiza os dados a cada 15 s, como a atualização em tempo real (AJAX) do
/// sistema web.
class GraficosSensoresScreen extends StatefulWidget {
  const GraficosSensoresScreen({super.key});

  @override
  State<GraficosSensoresScreen> createState() => _GraficosSensoresScreenState();
}

class _GraficosSensoresScreenState extends State<GraficosSensoresScreen> {
  TipoSensor _sensor = TipoSensor.temperatura;
  int _horas = 24;

  /// Estoque filtrado (nulo = todos os que o usuário pode ver).
  Estoque? _estoque;
  SerieLeituras _serie = SerieLeituras.vazia;
  String? _erro;
  Timer? _timer;
  DateTime? _atualizadoEm;

  /// Número da última consulta disparada. Respostas de consultas antigas (por
  /// exemplo, de antes de a pessoa trocar o sensor) são descartadas.
  int _ultimaConsulta = 0;

  @override
  void initState() {
    super.initState();
    // A lista de estoques alimenta o filtro; a série não depende dela.
    context.read<AppState>().carregarEstoques();
    _atualizar();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _atualizar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _atualizar() async {
    final consulta = ++_ultimaConsulta;
    final resposta = await context.read<AppState>().carregarLeituras(
      _sensor,
      _horas,
      estoqueId: _estoque?.id,
    );
    if (!mounted || consulta != _ultimaConsulta) {
      return; // já existe uma consulta mais nova
    }
    setState(() {
      if (resposta.ok) _serie = resposta.dados!;
      _erro = resposta.erro;
      _atualizadoEm = DateTime.now();
    });
  }

  /// "últimas 24 h" ou "últimos 7 dias".
  String get _rotuloJanela =>
      _horas > 48 ? 'últimos ${_horas ~/ 24} dias' : 'últimas $_horas h';

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estoques = context.watch<AppState>().estoques;

    return TelaPadrao(
      secao: 'Gráficos',
      children: [
        const TituloPagina('Gráficos de Sensores'),
        Wrap(
          spacing: 16,
          runSpacing: 14,
          children: [
            SizedBox(
              width: 260,
              child: CampoSelecao<TipoSensor>(
                rotulo: 'Sensor',
                valor: _sensor,
                itens: [
                  for (final t in TipoSensor.values)
                    DropdownMenuItem(value: t, child: Text(t.rotuloComUnidade)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sensor = v);
                  _atualizar();
                },
              ),
            ),
            SizedBox(
              width: 260,
              child: CampoSelecao<Estoque>(
                rotulo: 'Estoque',
                valor: _estoque,
                dica: 'Todos os estoques',
                itens: [
                  for (final e in estoques)
                    DropdownMenuItem(value: e, child: Text(e.nome)),
                ],
                onChanged: (v) {
                  setState(() => _estoque = v);
                  _atualizar();
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: CampoSelecao<int>(
                rotulo: 'Período',
                valor: _horas,
                itens: [
                  for (final e in _periodos.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _horas = v);
                  _atualizar();
                },
              ),
            ),
          ],
        ),
        if (_estoque != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() => _estoque = null);
                _atualizar();
              },
              child: const Text('Mostrar todos os estoques'),
            ),
          ),
        const Divider(),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            Text(
              '${_sensor.label} — $_rotuloJanela',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _SeloTempoReal(atualizadoEm: _atualizadoEm),
          ],
        ),
        const SizedBox(height: 16),
        FeedbackBox.erros([?_erro]),
        SectionCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 340,
            child: _serie.pontos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma leitura registrada para este sensor no período selecionado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textoSuave),
                    ),
                  )
                : _GraficoLinha(
                    serie: _serie,
                    unidade: _sensor.unidade,
                    horas: _horas,
                  ),
          ),
        ),
        _LegendaSensores(serie: _serie),
        if (_serie.lacunas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Há ${_serie.lacunas.length} período(s) sem leituras. O gráfico '
              'não liga pontos separados por uma lacuna de comunicação.',
              style: TextStyle(color: c.textoSuave, fontSize: 12.5),
            ),
          ),
        if (_serie.sensoresDesatualizados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FeedbackBox.aviso(
              'Sem dados recentes: ${_nomesDosSensores(_serie, _serie.sensoresDesatualizados)}. '
              'O último valor desses sensores está fora do prazo de comunicação.',
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'Total de leituras: ${_serie.total}',
          style: TextStyle(color: c.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: 18),
        NavRodape(
          links: [
            NavRodapeLink('Ver alertas →', () => context.go('/alertas')),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Selo "tempo real · HH:mm" (ponto verde pulsando na versão web).
class _SeloTempoReal extends StatelessWidget {
  const _SeloTempoReal({required this.atualizadoEm});

  final DateTime? atualizadoEm;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final hora = atualizadoEm == null
        ? ''
        : ' · ${DateFormat('HH:mm').format(atualizadoEm!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.sucessoFundo,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c.sucesso,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.sucesso.withValues(alpha: 0.6),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'tempo real$hora',
            style: TextStyle(
              color: c.sucesso,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cores das linhas: a primeira vem do tema; as demais distinguem os sensores.
List<Color> _paleta(AkronCores c) => [
  c.graficoLinha,
  const Color(0xFFE08A00),
  const Color(0xFF2E9E6B),
  const Color(0xFF8E5BD6),
  const Color(0xFFD64B7A),
  const Color(0xFF3B9BC8),
];

/// Nomes (separados por vírgula) dos sensores de [ids] presentes na série.
String _nomesDosSensores(SerieLeituras serie, List<int> ids) {
  final nomes = <int, String>{
    for (final p in serie.pontos)
      if (p.sensorNome != null) p.sensorId: p.sensorNome!,
  };
  return ids.map((id) => nomes[id] ?? 'sensor $id').join(', ');
}

/// Divide a lista de um sensor em trechos contínuos: um ponto com
/// `lacunaAntes` inicia outro trecho (não se liga o que a lacuna separa).
List<List<Leitura>> _trechos(List<Leitura> pontos) {
  final trechos = <List<Leitura>>[];
  for (final p in pontos) {
    if (trechos.isEmpty || p.lacunaAntes) trechos.add([]);
    trechos.last.add(p);
  }
  return trechos;
}

/// Legenda: cor de cada linha e o sensor a que pertence.
class _LegendaSensores extends StatelessWidget {
  const _LegendaSensores({required this.serie});

  final SerieLeituras serie;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cores = _paleta(c);
    final porSensor = serie.porSensor;
    if (porSensor.length < 2) return const SizedBox.shrink();
    var i = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final entrada in porSensor.entries)
          Builder(
            builder: (_) {
              final cor = cores[(i++) % cores.length];
              final nome = entrada.value.first.sensorNome ?? 'Sensor ${entrada.key}';
              final estoque = entrada.value.first.estoqueNome;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, color: cor),
                  const SizedBox(width: 6),
                  Text(
                    estoque == null ? nome : '$nome · $estoque',
                    style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Gráfico de linha das leituras: UMA linha por sensor, eixo X em tempo real
/// (cores vindas do tema claro/escuro).
class _GraficoLinha extends StatelessWidget {
  const _GraficoLinha({
    required this.serie,
    required this.unidade,
    required this.horas,
  });

  final SerieLeituras serie;
  final String unidade;
  final int horas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cores = _paleta(c);

    // Cada trecho contínuo de cada sensor vira uma linha do gráfico.
    final trechos = <List<Leitura>>[];
    final corDoTrecho = <Color>[];
    var indiceSensor = 0;
    for (final lista in serie.porSensor.values) {
      final cor = cores[indiceSensor++ % cores.length];
      for (final t in _trechos(lista)) {
        trechos.add(t);
        corDoTrecho.add(cor);
      }
    }
    double xDe(Leitura l) => l.lidoEm.millisecondsSinceEpoch.toDouble();

    final todos = serie.pontos;
    final valores = todos.map((l) => l.valor);
    final menor = valores.reduce((a, b) => a < b ? a : b);
    final maior = valores.reduce((a, b) => a > b ? a : b);
    var minX = todos.map(xDe).reduce(math.min);
    var maxX = todos.map(xDe).reduce(math.max);
    if (maxX <= minX) maxX = minX + 60000; // um só instante: abre 1 minuto

    // Limites e intervalo do eixo Y "redondos": o mínimo e o máximo caem em
    // linhas da grade, então nenhum rótulo se sobrepõe a outro.
    final passo = _passoDoEixo(maior - menor);
    final minY = (menor / passo).floor() * passo - (menor == maior ? passo : 0);
    final maxY = (maior / passo).ceil() * passo + (menor == maior ? passo : 0);

    // Em janelas longas o eixo X mostra dia e hora; nas curtas, só a hora.
    final rotuloX = DateFormat(horas > 48 ? 'dd/MM\nHH:mm' : 'HH:mm');
    final rotuloDica = DateFormat('dd/MM HH:mm');
    final numero = NumberFormat('#,##0.##', 'pt_BR');
    final estiloEixo = TextStyle(color: c.graficoTexto, fontSize: 10.5);
    final intervaloX = (maxX - minX) / 4;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: passo,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.graficoGrade, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: passo,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                child: Text(numero.format(valor), style: estiloEixo),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: horas > 48 ? 40 : 28,
              interval: intervaloX,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  rotuloX.format(
                    DateTime.fromMillisecondsSinceEpoch(valor.toInt()),
                  ),
                  textAlign: TextAlign.center,
                  style: estiloEixo,
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.fundoCardAlt,
            getTooltipItems: (toques) => [
              for (final toque in toques)
                LineTooltipItem(
                  '${numero.format(toque.y)} $unidade\n',
                  TextStyle(
                    color: c.texto,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${trechos[toque.barIndex][toque.spotIndex].sensorNome ?? 'Sensor'}'
                          ' · ${rotuloDica.format(trechos[toque.barIndex][toque.spotIndex].lidoEm)}',
                      style: TextStyle(
                        color: c.textoSuave,
                        fontWeight: FontWeight.w400,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (var i = 0; i < trechos.length; i++)
            LineChartBarData(
              spots: [for (final l in trechos[i]) FlSpot(xDe(l), l.valor)],
              // Sem curva: suavizar sugeriria valores que ninguém mediu.
              isCurved: false,
              color: corDoTrecho[i],
              barWidth: 2.4,
              // Trecho de 1–2 pontos (isolado por lacunas) fica visível com pontos.
              dotData: FlDotData(
                show: trechos[i].length <= 2 || todos.length <= 30,
              ),
              belowBarData: BarAreaData(
                show: trechos.length == 1,
                color: c.graficoArea,
              ),
            ),
        ],
      ),
    );
  }
}

/// Intervalo "redondo" (1, 2, 5 × 10ⁿ) para que o eixo Y tenha cerca de cinco
/// divisões. [faixa] é a diferença entre o maior e o menor valor.
double _passoDoEixo(double faixa) {
  if (faixa <= 0) return 1;
  final bruto = faixa / 5;
  final potencia = math
      .pow(10, (math.log(bruto) / math.ln10).floor())
      .toDouble();
  final fracao = bruto / potencia;
  final multiplo = fracao <= 1 ? 1 : (fracao <= 2 ? 2 : (fracao <= 5 ? 5 : 10));
  return multiplo * potencia;
}
