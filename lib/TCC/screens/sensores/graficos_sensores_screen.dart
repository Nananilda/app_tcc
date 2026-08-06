import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/leitura.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/topbar.dart';

const _periodos = <int, String>{
  6: '6 h',
  12: '12 h',
  24: '24 h',
  48: '48 h',
  168: '7 dias',
};

/// Gráficos de sensores — equivalente a graficos_sensores.php.
/// Atualiza os dados periodicamente para simular o AJAX em tempo real
/// do chart.js original (iniciarAtualizacaoTempoReal).
class GraficosSensoresScreen extends StatefulWidget {
  const GraficosSensoresScreen({super.key});

  @override
  State<GraficosSensoresScreen> createState() => _GraficosSensoresScreenState();
}

class _GraficosSensoresScreenState extends State<GraficosSensoresScreen> {
  TipoSensor _sensor = TipoSensor.temperatura;
  int _horas = 24;
  List<Leitura> _leituras = [];
  Timer? _timer;
  DateTime? _atualizadoEm;

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

  void _atualizar() {
    final app = context.read<AppState>();
    setState(() {
      _leituras = app.gerarLeituras(_sensor, _horas);
      _atualizadoEm = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final horaFmt = DateFormat('HH:mm');
    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Gráficos'),
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
                    'Gráficos de Sensores',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: DropdownButtonFormField<TipoSensor>(
                          value: _sensor,
                          decoration:
                              const InputDecoration(labelText: 'Sensor'),
                          items: TipoSensor.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text('${t.label} (${t.unidade})'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _sensor = v);
                            _atualizar();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<int>(
                          value: _horas,
                          decoration:
                              const InputDecoration(labelText: 'Período'),
                          items: _periodos.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_sensor.label} — últimas $_horas h',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sucessoFundo,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.sucesso,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _atualizadoEm == null
                                  ? 'tempo real'
                                  : 'tempo real · ${horaFmt.format(_atualizadoEm!)}',
                              style: const TextStyle(
                                color: AppColors.sucesso,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: SizedBox(
                      height: 320,
                      child: _leituras.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhuma leitura encontrada para este sensor no período selecionado.',
                                style: TextStyle(color: AppColors.textoSuave),
                              ),
                            )
                          : _GraficoLinha(
                              leituras: _leituras,
                              unidade: _sensor.unidade,
                            ),
                    ),
                  ),
                  Text(
                    'Total de leituras: ${_leituras.length}',
                    style: const TextStyle(
                      color: AppColors.textoSuave,
                      fontSize: 12.5,
                    ),
                  ),
                  NavRodape(
                    links: [
                      NavRodapeLink(
                          'Ver alertas →', () => context.go('/alertas')),
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

class _GraficoLinha extends StatelessWidget {
  final List<Leitura> leituras;
  final String unidade;

  const _GraficoLinha({required this.leituras, required this.unidade});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (int i = 0; i < leituras.length; i++)
        FlSpot(i.toDouble(), leituras[i].valor),
    ];
    final valores = leituras.map((l) => l.valor).toList();
    final minY = valores.reduce((a, b) => a < b ? a : b);
    final maxY = valores.reduce((a, b) => a > b ? a : b);
    final margem = ((maxY - minY).abs() * 0.15).clamp(0.5, double.infinity);

    final horaFmt = DateFormat('HH:mm');

    return LineChart(
      LineChartData(
        minY: minY - margem,
        maxY: maxY + margem,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.borda, strokeWidth: 1),
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
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
              reservedSize: 28,
              interval: (leituras.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= leituras.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    horaFmt.format(leituras[i].lidoEm),
                    style: const TextStyle(
                      color: AppColors.textoSuave,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.fundoCardAlt,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(2)} $unidade',
                    const TextStyle(color: AppColors.texto),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primaria,
            barWidth: 2.4,
            dotData: FlDotData(show: leituras.length <= 30),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaria.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
