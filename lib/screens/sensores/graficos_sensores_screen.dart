import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

/// Gráfico de linha das leituras (cores vindas do tema claro/escuro).
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
    final leituras = serie.pontos;
    final spots = [
      for (var i = 0; i < leituras.length; i++)
        FlSpot(i.toDouble(), leituras[i].valor),
    ];
    final valores = leituras.map((l) => l.valor);
    final menor = valores.reduce((a, b) => a < b ? a : b);
    final maior = valores.reduce((a, b) => a > b ? a : b);

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

    return LineChart(
      LineChartData(
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
              interval: (leituras.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= leituras.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    rotuloX.format(leituras[i].lidoEm),
                    textAlign: TextAlign.center,
                    style: estiloEixo,
                  ),
                );
              },
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
                      text: rotuloDica.format(leituras[toque.x.toInt()].lidoEm),
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
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: c.graficoLinha,
            barWidth: 2.4,
            dotData: FlDotData(show: leituras.length <= 30),
            belowBarData: BarAreaData(show: true, color: c.graficoArea),
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
