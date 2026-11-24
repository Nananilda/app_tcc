import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/estoque.dart';
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
  final _intervaloCtrl = TextEditingController(text: '300');
  final _criticoMinCtrl = TextEditingController();
  final _atencaoMinCtrl = TextEditingController();
  final _atencaoMaxCtrl = TextEditingController();
  final _criticoMaxCtrl = TextEditingController();
  TipoSensor? _tipo;
  Estoque? _estoque;
  StatusSensor _status = StatusSensor.ativo;

  /// Sensor em edição (nulo = cadastrando um novo).
  Sensor? _editando;

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
    _intervaloCtrl.dispose();
    _criticoMinCtrl.dispose();
    _atencaoMinCtrl.dispose();
    _atencaoMaxCtrl.dispose();
    _criticoMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final app = context.read<AppState>();
    // O estoque é obrigatório no cadastro: carrega a lista junto com os sensores.
    await app.carregarEstoques();
    final resultado = await app.carregarSensores();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _feedback = resultado;
    });
  }

  /// "36,5" ou "36.5" → 36.5; vazio → nulo; inválido → [NumberFormat] nulo.
  double? _numero(TextEditingController c) {
    final texto = c.text.trim().replaceAll(',', '.');
    return texto.isEmpty ? null : double.tryParse(texto);
  }

  String? _validarLimite(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim().replaceAll(',', '.')) == null
        ? 'Número inválido.'
        : null;
  }

  LimitesDoSensor _limitesDoFormulario() => LimitesDoSensor(
    criticoMin: _numero(_criticoMinCtrl),
    atencaoMin: _numero(_atencaoMinCtrl),
    atencaoMax: _numero(_atencaoMaxCtrl),
    criticoMax: _numero(_criticoMaxCtrl),
  );

  void _limparFormulario() {
    _formKey.currentState?.reset();
    _nomeCtrl.clear();
    _localizacaoCtrl.clear();
    _intervaloCtrl.text = '300';
    _criticoMinCtrl.clear();
    _atencaoMinCtrl.clear();
    _atencaoMaxCtrl.clear();
    _criticoMaxCtrl.clear();
    _tipo = null;
    _estoque = null;
    _status = StatusSensor.ativo;
    _editando = null;
  }

  void _editar(Sensor s, List<Estoque> estoques) {
    String texto(double? v) =>
        v == null ? '' : v.toString().replaceAll('.', ',');
    setState(() {
      _editando = s;
      _nomeCtrl.text = s.nome;
      _localizacaoCtrl.text = s.localizacao ?? '';
      _intervaloCtrl.text = '${s.intervaloComunicacao}';
      _criticoMinCtrl.text = texto(s.limites.criticoMin);
      _atencaoMinCtrl.text = texto(s.limites.atencaoMin);
      _atencaoMaxCtrl.text = texto(s.limites.atencaoMax);
      _criticoMaxCtrl.text = texto(s.limites.criticoMax);
      _tipo = s.tipo;
      _status = s.status;
      _estoque = estoques.where((e) => e.id == s.estoqueId).firstOrNull;
      _feedback = null;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    final intervalo = int.tryParse(_intervaloCtrl.text.trim()) ?? 0;
    final editando = _editando;

    final resultado = editando == null
        ? await app.cadastrarSensor(
            nome: _nomeCtrl.text,
            tipo: _tipo,
            estoque: _estoque,
            localizacao: _localizacaoCtrl.text,
            status: _status,
            intervaloComunicacao: intervalo,
            limites: _limitesDoFormulario(),
          )
        : await app.atualizarSensor(
            sensorId: editando.id,
            nome: _nomeCtrl.text,
            tipo: _tipo,
            estoque: _estoque,
            localizacao: _localizacaoCtrl.text,
            status: _status,
            intervaloComunicacao: intervalo,
            limites: _limitesDoFormulario(),
          );
    if (!mounted) return;
    setState(() {
      _feedback = resultado;
      // Salvou: limpa o formulário para o próximo sensor
      if (resultado.temSucesso) _limparFormulario();
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
    final estoques = app.estoquesAtivos;
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
                TituloCartao(
                  _editando == null
                      ? 'Adicionar Novo Sensor'
                      : 'Editar sensor "${_editando!.nome}"',
                  espacoAbaixo: 16,
                ),
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
                          child: FormField<Estoque>(
                            initialValue: _estoque,
                            validator: (v) => _estoque == null
                                ? 'Selecione o estoque.'
                                : null,
                            builder: (campo) => CampoSelecao<Estoque>(
                              rotulo: 'Estoque',
                              valor: _estoque,
                              dica: estoques.isEmpty
                                  ? 'Cadastre um estoque antes'
                                  : '— selecione —',
                              erro: campo.errorText,
                              itens: [
                                for (final e in estoques)
                                  DropdownMenuItem(
                                    value: e,
                                    child: Text(e.nome),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => _estoque = v);
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
                        SizedBox(
                          width: largura(210),
                          child: TextFormField(
                            controller: _intervaloCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prazo de comunicação (s)',
                              helperText: 'De 1 a 86400 segundos',
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              return (n == null || n < 1 || n > 86400)
                                  ? 'Use de 1 a 86400.'
                                  : null;
                            },
                          ),
                        ),
                        for (final (rotulo, ctrl) in [
                          ('Crítico — mínimo', _criticoMinCtrl),
                          ('Atenção — mínimo', _atencaoMinCtrl),
                          ('Atenção — máximo', _atencaoMaxCtrl),
                          ('Crítico — máximo', _criticoMaxCtrl),
                        ])
                          SizedBox(
                            width: largura(150),
                            child: TextFormField(
                              controller: ctrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: InputDecoration(
                                labelText: rotulo,
                                helperText: 'Opcional',
                              ),
                              validator: _validarLimite,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Os limites valem para este sensor. Deixe em branco o que '
                  'não se aplica; os preenchidos seguem a ordem crescente '
                  '(crítico mín. ≤ atenção mín. ≤ atenção máx. ≤ crítico máx.).',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _salvar,
                      child: Text(
                        _editando == null
                            ? 'Cadastrar Sensor'
                            : 'Salvar alterações',
                      ),
                    ),
                    if (_editando != null)
                      OutlinedButton(
                        onPressed: () => setState(_limparFormulario),
                        child: const Text('Cancelar edição'),
                      ),
                  ],
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
                    'Estoque',
                    'Tipo',
                    'Localização',
                    'Status',
                    'Comunicação',
                    'Cadastrado em',
                    'Ação',
                  ],
                  linhas: [
                    for (final s in sensores)
                      [
                        Text('${s.id}'),
                        Text(s.nome),
                        Text(s.estoqueNome ?? '—'),
                        Text(s.tipo.label),
                        Text(s.localizacao ?? '—'),
                        StatusBadge.ativo(
                          ativo: s.status == StatusSensor.ativo,
                        ),
                        StatusBadge(
                          texto: switch (s.comunicacao) {
                            'online' => 'Online',
                            'inativo' => 'Inativo',
                            _ => 'Sem comunicação',
                          },
                          tom: s.comunicacao == 'online'
                              ? TomBadge.sucesso
                              : TomBadge.neutro,
                        ),
                        Text(dataFmt.format(s.criadoEm)),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton(
                              onPressed: () => _editar(s, estoques),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text('Editar'),
                            ),
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
