import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/estoque.dart';
import '../../state/app_state.dart';
import '../../widgets/botoes.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Cadastro e edição de estoque (somente administrador).
/// [id] nulo = novo estoque.
class EstoqueFormScreen extends StatefulWidget {
  const EstoqueFormScreen({super.key, this.id});

  final int? id;

  @override
  State<EstoqueFormScreen> createState() => _EstoqueFormScreenState();
}

class _EstoqueFormScreenState extends State<EstoqueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  bool _ativo = true;
  bool _salvando = false;
  bool _preenchido = false;
  ResultadoOperacao? _feedback;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    if (widget.id == null) return;
    final app = context.read<AppState>();
    if (app.estoques.isEmpty) await app.carregarEstoques();
    if (!mounted) return;
    final e = app.estoques.where((e) => e.id == widget.id).firstOrNull;
    if (e == null) {
      setState(() {
        _feedback = const ResultadoOperacao(erros: ['Estoque não encontrado.']);
      });
      return;
    }
    setState(() {
      _nomeCtrl.text = e.nome;
      _descricaoCtrl.text = e.descricao;
      _localizacaoCtrl.text = e.localizacao;
      _ativo = e.ativo;
      _preenchido = true;
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _localizacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final app = context.read<AppState>();
    final resultado = widget.id == null
        ? await app.cadastrarEstoque(
            nome: _nomeCtrl.text,
            descricao: _descricaoCtrl.text,
            localizacao: _localizacaoCtrl.text,
            ativo: _ativo,
          )
        : await app.atualizarEstoque(
            id: widget.id!,
            nome: _nomeCtrl.text,
            descricao: _descricaoCtrl.text,
            localizacao: _localizacaoCtrl.text,
            ativo: _ativo,
          );
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _feedback = resultado;
    });
    if (!resultado.temErro) context.go('/estoques');
  }

  Future<void> _desativar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar estoque'),
        content: const Text(
          'O estoque deixa de receber leituras. O histórico de sensores, '
          'leituras e alertas é preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          BotaoPerigo(
            texto: 'Desativar',
            aoPressionar: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    final resultado = await context.read<AppState>().desativarEstoque(
      widget.id!,
    );
    if (!mounted) return;
    setState(() => _feedback = resultado);
    if (!resultado.temErro) context.go('/estoques');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final novo = widget.id == null;

    if (!app.ehAdmin) {
      return TelaPadrao(
        secao: 'Estoques',
        larguraMaxima: 700,
        children: [
          const TituloPagina('Estoque'),
          FeedbackBox.aviso('Acesso restrito a administradores.'),
        ],
      );
    }

    return TelaPadrao(
      secao: 'Estoques',
      larguraMaxima: 700,
      children: [
        TituloPagina(novo ? 'Novo estoque' : 'Editar estoque'),
        AreaFeedback(resultado: _feedback),
        if (novo || _preenchido)
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nomeCtrl,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nome do estoque',
                      hintText: 'Ex: Galpão A',
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Informe um nome com pelo menos 3 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _localizacaoCtrl,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Localização',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoCtrl,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  CampoSelecao<bool>(
                    rotulo: 'Situação',
                    valor: _ativo,
                    itens: const [
                      DropdownMenuItem(value: true, child: Text('Ativo')),
                      DropdownMenuItem(value: false, child: Text('Inativo')),
                    ],
                    onChanged: (v) => setState(() => _ativo = v ?? true),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      BotaoPrincipal(
                        texto: novo ? 'Cadastrar estoque' : 'Salvar alterações',
                        ocupado: _salvando,
                        aoPressionar: _salvar,
                      ),
                      if (!novo)
                        OutlinedButton(
                          onPressed: _desativar,
                          child: const Text('Desativar estoque'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        NavRodape(
          links: [NavRodapeLink('← Estoques', () => context.go('/estoques'))],
        ),
      ],
    );
  }
}
