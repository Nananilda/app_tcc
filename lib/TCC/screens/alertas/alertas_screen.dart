import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/alerta.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/topbar.dart';

/// Tela de alertas — equivalente a app/views/graficos/alerta.php.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  String? _mensagem;
  List<String> _erros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final resultado = await context.read<AppState>().carregarAlertas();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (resultado.temErro) _erros = resultado.erros;
    });
  }

  Future<void> _resolver(int id) async {
    final app = context.read<AppState>();
    final resultado = await app.resolverAlerta(id);
    if (!mounted) return;
    setState(() {
      _mensagem = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final alertas = app.alertas;
    final contagem = app.contarAlertasPorSeveridade();
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    final coresPorSeveridade = {
      Severidade.critico: AppColors.erro,
      Severidade.atencao: AppColors.alerta,
      Severidade.info: AppColors.primaria,
    };

    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Alertas'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alertas dos Sensores',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_mensagem != null) FeedbackBox.sucesso(_mensagem),
                  if (_erros.isNotEmpty) FeedbackBox.erros(_erros),
                  if (_carregando) const LinearProgressIndicator(minHeight: 2),
                  if (_carregando) const SizedBox(height: 16),

                  // Cards de resumo por severidade
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = Severidade.values
                          .map(
                            (s) => _CardSeveridade(
                              valor: contagem[s] ?? 0,
                              label: s == Severidade.info
                                  ? 'Informativos'
                                  : s == Severidade.atencao
                                      ? 'Atenção'
                                      : 'Críticos',
                              cor: coresPorSeveridade[s]!,
                            ),
                          )
                          .toList();
                      if (constraints.maxWidth > 560) {
                        return Row(
                          children: cards
                              .map((c) => Expanded(child: c))
                              .expand((w) => [w, const SizedBox(width: 14)])
                              .toList()
                            ..removeLast(),
                        );
                      }
                      return Column(children: cards);
                    },
                  ),
                  const SizedBox(height: 18),

                  // Gráfico de barras
                  SectionCard(
                    child: SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (([
                                    contagem[Severidade.critico] ?? 0,
                                    contagem[Severidade.atencao] ?? 0,
                                    contagem[Severidade.info] ?? 0,
                                  ].reduce((a, b) => a > b ? a : b)) +
                                  2)
                              .toDouble(),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppColors.borda,
                              strokeWidth: 1,
                            ),
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
                                reservedSize: 30,
                                getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: const TextStyle(
                                    color: AppColors.textoSuave,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  const labels = ['Crítico', 'Atenção', 'Info'];
                                  final i = v.toInt();
                                  if (i < 0 || i >= labels.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      labels[i],
                                      style: const TextStyle(
                                        color: AppColors.textoSuave,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < Severidade.values.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (contagem[Severidade.values[i]] ?? 0)
                                        .toDouble(),
                                    color: coresPorSeveridade[
                                        Severidade.values[i]],
                                    width: 34,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista de alertas
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico recente',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (alertas.isEmpty)
                          const Text(
                            'Nenhum alerta registrado.',
                            style: TextStyle(
                              color: AppColors.textoSuave,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ...alertas.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      StatusBadge(
                                        texto: a.severidade.label,
                                        positivo: a.resolvido,
                                      ),
                                      Text(
                                        a.sensorTipo.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '— ${a.mensagem}',
                                        style: const TextStyle(
                                          color: AppColors.texto,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Valor: ${a.valor} | ${dataFmt.format(a.criadoEm)} | '
                                    '${a.resolvido ? "Resolvido" : "Pendente"}',
                                    style: const TextStyle(
                                      color: AppColors.textoSuave,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (app.ehAdmin && !a.resolvido)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton(
                                        onPressed: () => _resolver(a.id),
                                        child: const Text('Marcar resolvido'),
                                      ),
                                    ),
                                  const Divider(height: 20),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  NavRodape(
                    links: [
                      NavRodapeLink(
                        '← Gráficos de sensores',
                        () => context.go('/graficos'),
                      ),
                      NavRodapeLink(
                        '← Voltar ao painel',
                        () => context.go('/painel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSeveridade extends StatelessWidget {
  final int valor;
  final String label;
  final Color cor;

  const _CardSeveridade({
    required this.valor,
    required this.label,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border(top: BorderSide(color: cor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textoSuave)),
        ],
      ),
    );
  }
}
