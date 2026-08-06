import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/topbar.dart';

/// Gestão de sensores — equivalente a gestao_sensores.php.
class GestaoSensoresScreen extends StatefulWidget {
  const GestaoSensoresScreen({super.key});

  @override
  State<GestaoSensoresScreen> createState() => _GestaoSensoresScreenState();
}

class _GestaoSensoresScreenState extends State<GestaoSensoresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  TipoSensor? _tipo;
  StatusSensor _status = StatusSensor.ativo;

  String? _mensagem;
  List<String> _erros = [];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _localizacaoCtrl.dispose();
    super.dispose();
  }

  void _cadastrar() {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    final resultado = app.cadastrarSensor(
      nome: _nomeCtrl.text,
      tipo: _tipo,
      localizacao: _localizacaoCtrl.text,
      status: _status,
    );
    setState(() {
      _mensagem = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
    });
    if (resultado.temSucesso) {
      _formKey.currentState!.reset();
      _nomeCtrl.clear();
      _localizacaoCtrl.clear();
      setState(() {
        _tipo = null;
        _status = StatusSensor.ativo;
      });
    }
  }

  void _alternarStatus(int id) {
    final app = context.read<AppState>();
    final resultado = app.alternarStatusSensor(id);
    setState(() {
      _mensagem = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sensores = app.sensores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Sensores'),
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
                    'Gestão de Sensores',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_mensagem != null) FeedbackBox.sucesso(_mensagem),
                  if (_erros.isNotEmpty) FeedbackBox.erros(_erros),
                  if (app.ehAdmin)
                    SectionCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adicionar Novo Sensor',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: TextFormField(
                                    controller: _nomeCtrl,
                                    maxLength: 100,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do sensor',
                                      hintText: 'Ex: Sensor Galpão A',
                                      counterText: '',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().length < 3)
                                            ? 'Mínimo 3 caracteres.'
                                            : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 220,
                                  child: DropdownButtonFormField<TipoSensor>(
                                    value: _tipo,
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo',
                                    ),
                                    items: TipoSensor.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.label),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(() => _tipo = v),
                                    validator: (v) =>
                                        v == null ? 'Selecione um tipo.' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: TextFormField(
                                    controller: _localizacaoCtrl,
                                    maxLength: 150,
                                    decoration: const InputDecoration(
                                      labelText: 'Localização',
                                      hintText: 'Ex: Setor B, linha 3',
                                      counterText: '',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: DropdownButtonFormField<StatusSensor>(
                                    value: _status,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                    ),
                                    items: StatusSensor.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.label),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(
                                      () => _status = v ?? StatusSensor.ativo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _cadastrar,
                              child: const Text('Cadastrar Sensor'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sensores Cadastrados',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (sensores.isEmpty)
                          const Text(
                            'Nenhum sensor cadastrado.',
                            style: TextStyle(
                              color: AppColors.textoSuave,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('ID')),
                                const DataColumn(label: Text('Nome')),
                                const DataColumn(label: Text('Tipo')),
                                const DataColumn(label: Text('Localização')),
                                const DataColumn(label: Text('Status')),
                                const DataColumn(label: Text('Cadastrado em')),
                                if (app.ehAdmin)
                                  const DataColumn(label: Text('Ação')),
                              ],
                              rows: sensores
                                  .map(
                                    (s) => DataRow(
                                      cells: [
                                        DataCell(Text('${s.id}')),
                                        DataCell(Text(s.nome)),
                                        DataCell(Text(s.tipo.label)),
                                        DataCell(
                                          Text(s.localizacao ?? '—'),
                                        ),
                                        DataCell(
                                          StatusBadge(
                                            texto: s.status.label,
                                            positivo:
                                                s.status == StatusSensor.ativo,
                                          ),
                                        ),
                                        DataCell(
                                          Text(dataFmt.format(s.criadoEm)),
                                        ),
                                        if (app.ehAdmin)
                                          DataCell(
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _alternarStatus(s.id),
                                              child: Text(
                                                s.status == StatusSensor.ativo
                                                    ? 'Desativar'
                                                    : 'Ativar',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  NavRodape(
                    links: [
                      NavRodapeLink(
                        'Consulta somente leitura →',
                        () => context.go('/sensores/listar'),
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
