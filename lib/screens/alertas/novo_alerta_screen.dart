import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/botoes.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/linha_campos.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Novo alerta (somente administradores) — equivale a
/// app/views/graficos/novo_alerta.php.
///
/// Reúne as duas formas de um alerta nascer no sistema:
///  1. MANUAL: o administrador escolhe sensor e severidade e escreve a
///     mensagem (manutenção programada, aviso da equipe, ocorrência...);
///  2. AUTOMÁTICA: ao registrar uma leitura, o servidor compara o valor com os
///     limites do tipo do sensor e cria o alerta sozinho. O formulário
///     "Registrar leitura" simula o envio de um sensor, para testar os limites.
/// A tabela do final mostra os limites em vigor (vêm do servidor).
class NovoAlertaScreen extends StatefulWidget {
  const NovoAlertaScreen({super.key});

  @override
  State<NovoAlertaScreen> createState() => _NovoAlertaScreenState();
}

class _NovoAlertaScreenState extends State<NovoAlertaScreen> {
  final _alertaFormKey = GlobalKey<FormState>();
  final _leituraFormKey = GlobalKey<FormState>();
  final _mensagemCtrl = TextEditingController();
  final _valorAlertaCtrl = TextEditingController();
  final _valorLeituraCtrl = TextEditingController();

  int? _sensorAlertaId;
  int? _sensorLeituraId;
  Severidade _severidade = Severidade.atencao;

  ResultadoOperacao? _feedbackCarga;
  ResultadoOperacao? _feedbackAlerta;
  ResultadoOperacao? _feedbackLeitura;
  bool _enviandoAlerta = false;
  bool _enviandoLeitura = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _mensagemCtrl.dispose();
    _valorAlertaCtrl.dispose();
    _valorLeituraCtrl.dispose();
    super.dispose();
  }

  /// Carrega a lista de sensores (para os seletores) e os limites dos alertas.
  Future<void> _carregar() async {
    final app = context.read<AppState>();
    final resultados = await Future.wait([
      app.carregarSensores(),
      app.carregarAlertas(),
    ]);
    if (!mounted) return;
    final comErro = resultados.where((r) => r.temErro).toList();
    setState(() => _feedbackCarga = comErro.isEmpty ? null : comErro.first);
  }

  Sensor? _sensorPorId(int? id) {
    for (final s in context.read<AppState>().sensores) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _criarAlerta() async {
    if (_enviandoAlerta || !_alertaFormKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    setState(() => _enviandoAlerta = true);
    final resultado = await app.criarAlerta(
      sensor: _sensorPorId(_sensorAlertaId),
      severidade: _severidade,
      mensagem: _mensagemCtrl.text,
      valor: _valorAlertaCtrl.text,
    );
    if (!mounted) return;

    setState(() {
      _enviandoAlerta = false;
      _feedbackAlerta = resultado;
      // Criou: limpa o formulário para o próximo (em caso de erro mantém o que
      // foi digitado para a pessoa corrigir).
      if (resultado.temSucesso) {
        _alertaFormKey.currentState!.reset();
        _mensagemCtrl.clear();
        _valorAlertaCtrl.clear();
        _sensorAlertaId = null;
        _severidade = Severidade.atencao;
      }
    });
  }

  Future<void> _registrarLeitura() async {
    if (_enviandoLeitura || !_leituraFormKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    setState(() => _enviandoLeitura = true);
    final resultado = await app.registrarLeitura(
      sensor: _sensorPorId(_sensorLeituraId),
      valor: _valorLeituraCtrl.text,
    );
    if (!mounted) return;

    setState(() {
      _enviandoLeitura = false;
      _feedbackLeitura = resultado;
      if (resultado.temSucesso) _valorLeituraCtrl.clear();
    });
  }

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório.' : null;

  /// Itens do seletor de sensor; [apenasAtivos] esconde os inativos (um sensor
  /// inativo não envia leituras, mas pode ter um alerta manual).
  List<DropdownMenuItem<int>> _itensSensor(
    List<Sensor> sensores, {
    required bool apenasAtivos,
  }) {
    return [
      for (final s in sensores)
        if (!apenasAtivos || s.status == StatusSensor.ativo)
          DropdownMenuItem(
            value: s.id,
            child: Text(
              '${s.nome} — ${s.tipo.label}'
              '${s.status == StatusSensor.ativo ? '' : ' (inativo)'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sensores = app.sensores;
    final c = context.cores;

    return TelaPadrao(
      secao: 'Alertas',
      larguraMaxima: 700,
      children: [
        const TituloPagina(
          'Novo Alerta',
          subtitulo:
              'Crie um alerta manualmente ou registre uma leitura para ver '
              'os alertas automáticos em ação.',
        ),
        AreaFeedback(resultado: _feedbackCarga),

        // ── 1) Alerta manual ──────────────────────────────────────────────
        SectionCard(
          child: Form(
            key: _alertaFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloCartao('Adicionar alerta manualmente'),
                AreaFeedback(resultado: _feedbackAlerta),
                LinhaCampos(
                  children: [
                    // FormField liga o campo de seleção à validação do Form
                    FormField<int>(
                      initialValue: _sensorAlertaId,
                      validator: (v) => _sensorAlertaId == null
                          ? 'Selecione o sensor.'
                          : null,
                      builder: (campo) => CampoSelecao<int>(
                        rotulo: 'Sensor *',
                        valor: _sensorAlertaId,
                        dica: '— selecione —',
                        erro: campo.errorText,
                        itens: _itensSensor(sensores, apenasAtivos: false),
                        onChanged: (v) {
                          setState(() => _sensorAlertaId = v);
                          campo.didChange(v);
                        },
                      ),
                    ),
                    CampoSelecao<Severidade>(
                      rotulo: 'Severidade *',
                      valor: _severidade,
                      itens: [
                        for (final s in Severidade.values)
                          DropdownMenuItem(value: s, child: Text(s.label)),
                      ],
                      onChanged: (v) =>
                          setState(() => _severidade = v ?? Severidade.atencao),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorAlertaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  maxLength: 14,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Valor medido (opcional)',
                    hintText: 'Ex: 36,5',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mensagemCtrl,
                  maxLength: 200,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem *',
                    hintText:
                        'Ex: Manutenção programada da prensa 02 amanhã às 8h',
                    helperText: '3 a 200 caracteres',
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres.'
                      : null,
                ),
                const SizedBox(height: 20),
                BotaoPrincipal(
                  texto: 'Criar alerta',
                  ocupado: _enviandoAlerta,
                  aoPressionar: _criarAlerta,
                ),
              ],
            ),
          ),
        ),

        // ── 2) Alerta automático: registrar leitura ───────────────────────
        SectionCard(
          child: Form(
            key: _leituraFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloCartao('Alertas automáticos — registrar leitura'),
                Text(
                  'Cada leitura enviada por um sensor é comparada com os '
                  'limites abaixo. Se passar de algum, o alerta é criado '
                  'sozinho (sem repetir um alerta igual que ainda esteja '
                  'pendente). Este formulário simula o envio de uma leitura, '
                  'para testar os limites.',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textoSuave,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                AreaFeedback(resultado: _feedbackLeitura),
                LinhaCampos(
                  children: [
                    FormField<int>(
                      initialValue: _sensorLeituraId,
                      validator: (v) => _sensorLeituraId == null
                          ? 'Selecione o sensor.'
                          : null,
                      builder: (campo) => CampoSelecao<int>(
                        rotulo: 'Sensor ativo *',
                        valor: _sensorLeituraId,
                        dica: '— selecione —',
                        erro: campo.errorText,
                        itens: _itensSensor(sensores, apenasAtivos: true),
                        onChanged: (v) {
                          setState(() => _sensorLeituraId = v);
                          campo.didChange(v);
                        },
                      ),
                    ),
                    TextFormField(
                      controller: _valorLeituraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      maxLength: 14,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Valor da leitura *',
                        hintText: 'Ex: 36,5',
                        counterText: '',
                      ),
                      validator: _obrigatorio,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BotaoPrincipal(
                  texto: 'Registrar leitura',
                  ocupado: _enviandoLeitura,
                  aoPressionar: _registrarLeitura,
                ),
              ],
            ),
          ),
        ),

        // ── 3) Limites em vigor ───────────────────────────────────────────
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloCartao('Limites dos alertas automáticos'),
              for (final tipo in TipoSensor.values)
                _LimitesDoTipo(
                  tipo: tipo,
                  limites: app.limitesAlerta[tipo],
                  ultimo: tipo == TipoSensor.values.last,
                ),
            ],
          ),
        ),

        NavRodape(
          links: [
            NavRodapeLink('← Voltar aos alertas', () => context.go('/alertas')),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Limites de um tipo de sensor: uma linha para "Atenção" e outra para "Crítico".
/// (Lista em vez de tabela para caber em qualquer largura de tela.)
class _LimitesDoTipo extends StatelessWidget {
  const _LimitesDoTipo({
    required this.tipo,
    required this.limites,
    required this.ultimo,
  });

  final TipoSensor tipo;
  final LimitesSensor? limites;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: ultimo ? null : Border(bottom: BorderSide(color: c.borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tipo.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final severidade in [Severidade.atencao, Severidade.critico])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge.severidade(severidade),
                    ),
                  ),
                  Expanded(
                    child: Text(limites?.faixa(severidade, tipo) ?? '—'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
