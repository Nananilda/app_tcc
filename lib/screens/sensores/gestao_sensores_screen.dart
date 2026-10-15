import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tabela_dados.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Gestão de sensores — equivale a gestao_sensores.php.
///
/// Exclusiva de administradores: cadastra novos sensores e ativa/desativa os
/// existentes (o servidor também recusa essas ações para usuários comuns).
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

  ResultadoOperacao? _feedback;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _localizacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final resultado = await context.read<AppState>().carregarSensores();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _feedback = resultado;
    });
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    final resultado = await context.read<AppState>().cadastrarSensor(
      nome: _nomeCtrl.text,
      tipo: _tipo,
      localizacao: _localizacaoCtrl.text,
      status: _status,
    );
    if (!mounted) return;
    setState(() {
      _feedback = resultado;
      // Cadastrou: limpa o formulário para o próximo sensor
      if (resultado.temSucesso) {
        _formKey.currentState!.reset();
        _nomeCtrl.clear();
        _localizacaoCtrl.clear();
        _tipo = null;
        _status = StatusSensor.ativo;
      }
    });
  }

  Future<void> _alternarStatus(int id) async {
    final resultado = await context.read<AppState>().alternarStatusSensor(id);
    if (!mounted) return;
    setState(() => _feedback = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sensores = app.sensores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    // Segunda camada de proteção: mesmo que a rota seja alcançada de algum
    // jeito, usuário comum nunca vê o formulário/ações de gestão.
    if (!app.ehAdmin) {
      return const TelaPadrao(
        secao: 'Sensores',
        larguraMaxima: 700,
        children: [TituloPagina('Gestão de Sensores'), _AcessoRestrito()],
      );
    }

    return TelaPadrao(
      secao: 'Sensores',
      aoAtualizar: _carregar,
      children: [
        const TituloPagina('Gestão de Sensores'),
        AreaFeedback(resultado: _feedback),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],

        // ── Cadastro de novo sensor ──
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloCartao('Adicionar Novo Sensor', espacoAbaixo: 16),
                LayoutBuilder(
                  builder: (context, restricoes) {
                    // Celular: os campos ocupam a largura toda, um sob o outro
                    final estreito = restricoes.maxWidth < 560;
                    double largura(double ideal) =>
                        estreito ? restricoes.maxWidth : ideal;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 18,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SizedBox(
                          width: largura(250),
                          child: TextFormField(
                            controller: _nomeCtrl,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Nome do sensor',
                              hintText: 'Ex: Sensor Galpão A',
                              counterText: '',
                            ),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Mínimo 3 caracteres.'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: largura(210),
                          // FormField liga o campo de seleção à validação do Form
                          child: FormField<TipoSensor>(
                            initialValue: _tipo,
                            validator: (v) =>
                                v == null ? 'Selecione um tipo.' : null,
                            builder: (campo) => CampoSelecao<TipoSensor>(
                              rotulo: 'Tipo',
                              valor: _tipo,
                              dica: '— selecione —',
                              erro: campo.errorText,
                              itens: [
                                for (final t in TipoSensor.values)
                                  DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => _tipo = v);
                                campo.didChange(v);
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: largura(240),
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
                          width: largura(160),
                          child: CampoSelecao<StatusSensor>(
                            rotulo: 'Status',
                            valor: _status,
                            itens: [
                              for (final s in StatusSensor.values)
                                DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                            ],
                            onChanged: (v) => setState(
                              () => _status = v ?? StatusSensor.ativo,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _cadastrar,
                  child: const Text('Cadastrar Sensor'),
                ),
              ],
            ),
          ),
        ),

        // ── Lista de sensores ──
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: TituloCartao('Sensores Cadastrados'),
              ),
              if (sensores.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: TextoVazio('Nenhum sensor cadastrado.'),
                )
              else
                TabelaDados(
                  colunas: const [
                    'ID',
                    'Nome',
                    'Tipo',
                    'Localização',
                    'Status',
                    'Cadastrado em',
                    'Ação',
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
                        OutlinedButton(
                          onPressed: () => _alternarStatus(s.id),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            s.status == StatusSensor.ativo
                                ? 'Desativar'
                                : 'Ativar',
                          ),
                        ),
                      ],
                  ],
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
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Aviso exibido a quem não é administrador e chegou à tela de gestão.
class _AcessoRestrito extends StatelessWidget {
  const _AcessoRestrito();

  @override
  Widget build(BuildContext context) {
    return FeedbackBox.aviso(
      'Acesso restrito a administradores. Use a Consulta de Sensores para visualização.',
    );
  }
}
