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

class _Resumo {
  final TipoSensor tipo;
  final int total;
  final double media;
  final double minimo;
  final double maximo;

  _Resumo(this.tipo, this.total, this.media, this.minimo, this.maximo);
}

/// Relatório de qualidade ambiental — equivalente a relatorio_qualidade.php.
class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  TipoSensor? _sensor;
  DateTime _dataIni = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dataFim = DateTime.now();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  List<Leitura> _leituras = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _filtrar());
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _filtrar() async {
    setState(() => _carregando = true);
    final app = context.read<AppState>();
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));

    final leituras = await app.carregarRelatorio(
      _dataIni,
      _dataFim,
      sensor: _sensor,
      valorMin: min,
      valorMax: max,
    );

    if (!mounted) return;
    setState(() {
      _leituras = leituras.take(200).toList();
      _carregando = false;
    });
  }

  void _limparFiltros() {
    setState(() {
      _sensor = null;
      _dataIni = DateTime.now().subtract(const Duration(days: 7));
      _dataFim = DateTime.now();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
    _filtrar();
  }

  List<_Resumo> get _resumo {
    final porTipo = <TipoSensor, List<double>>{};
    for (final l in _leituras) {
      porTipo.putIfAbsent(l.sensorTipo, () => []).add(l.valor);
    }
    final lista = porTipo.entries.map((e) {
      final valores = e.value;
      final media = valores.reduce((a, b) => a + b) / valores.length;
      final minimo = valores.reduce((a, b) => a < b ? a : b);
      final maximo = valores.reduce((a, b) => a > b ? a : b);
      return _Resumo(e.key, valores.length, media, minimo, maximo);
    }).toList();
    lista.sort((a, b) => a.tipo.label.compareTo(b.tipo.label));
    return lista;
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final selecionado = await showDatePicker(
      context: context,
      initialDate: inicio ? _dataIni : _dataFim,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (selecionado == null) return;
    setState(() {
      if (inicio) {
        _dataIni = selecionado;
      } else {
        _dataFim = selecionado;
      }
    });
    _filtrar();
  }

  @override
  Widget build(BuildContext context) {
    final dataFmt = DateFormat('dd/MM/yyyy');
    final dataHoraFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Relatórios'),
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
                    'Relatório de Qualidade Ambiental',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_carregando) const LinearProgressIndicator(minHeight: 2),
                  if (_carregando) const SizedBox(height: 16),

                  // ── Filtros ──
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FILTROS',
                          style: TextStyle(
                            color: AppColors.textoSuave,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: 220,
                              child: DropdownButtonFormField<TipoSensor?>(
                                value: _sensor,
                                decoration:
                                    const InputDecoration(labelText: 'Sensor'),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('— Todos —'),
                                  ),
                                  ...TipoSensor.values.map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.label),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _sensor = v);
                                  _filtrar();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: InkWell(
                                onTap: () => _selecionarData(inicio: true),
                                child: InputDecorator(
                                  decoration:
                                      const InputDecoration(labelText: 'De'),
                                  child: Text(dataFmt.format(_dataIni)),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: InkWell(
                                onTap: () => _selecionarData(inicio: false),
                                child: InputDecorator(
                                  decoration:
                                      const InputDecoration(labelText: 'Até'),
                                  child: Text(dataFmt.format(_dataFim)),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _minCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Valor mín.',
                                ),
                                onSubmitted: (_) => _filtrar(),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _maxCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Valor máx.',
                                ),
                                onSubmitted: (_) => _filtrar(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),

                  // ── Resumo estatístico ──
                  if (_resumo.isNotEmpty) ...[
                    const Text(
                      'Resumo do período',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Sensor')),
                            DataColumn(label: Text('Leituras')),
                            DataColumn(label: Text('Média')),
                            DataColumn(label: Text('Mínimo')),
                            DataColumn(label: Text('Máximo')),
                          ],
                          rows: _resumo
                              .map(
                                (r) => DataRow(
                                  cells: [
                                    DataCell(Text(r.tipo.label)),
                                    DataCell(Text('${r.total}')),
                                    DataCell(
                                      Text(r.media.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Text(r.minimo.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Text(r.maximo.toStringAsFixed(2)),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],

                  // ── Leituras detalhadas ──
                  Row(
                    children: [
                      const Text(
                        'Leituras detalhadas ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _leituras.length >= 200
                            ? '(últimas 200)'
                            : '(${_leituras.length} registros)',
                        style: const TextStyle(
                          color: AppColors.textoSuave,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_leituras.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhuma leitura encontrada com os filtros aplicados.',
                        style: TextStyle(
                          color: AppColors.textoSuave,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Sensor')),
                                DataColumn(label: Text('Valor')),
                                DataColumn(label: Text('Data/Hora')),
                              ],
                              rows: _leituras
                                  .map(
                                    (l) => DataRow(
                                      cells: [
                                        DataCell(Text(l.sensorTipo.label)),
                                        DataCell(
                                          Text(l.valor.toStringAsFixed(2)),
                                        ),
                                        DataCell(
                                          Text(dataHoraFmt.format(l.lidoEm)),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  NavRodape(
                    links: [
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
