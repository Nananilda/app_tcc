import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/topbar.dart';

/// Excluir usuário — equivalente a app/views/usuarios/excluir.php.
class ExcluirUsuarioScreen extends StatefulWidget {
  const ExcluirUsuarioScreen({super.key});

  @override
  State<ExcluirUsuarioScreen> createState() => _ExcluirUsuarioScreenState();
}

class _ExcluirUsuarioScreenState extends State<ExcluirUsuarioScreen> {
  final _buscaCtrl = TextEditingController();
  Usuario? _usuarioEncontrado;
  String? _sucesso;
  List<String> _erros = [];

  void _buscar() {
    final app = context.read<AppState>();
    if (_buscaCtrl.text.trim().isEmpty) {
      setState(() {
        _erros = ['Digite um login para buscar.'];
        _usuarioEncontrado = null;
        _sucesso = null;
      });
      return;
    }
    final usuario = app.buscarUsuarioPorLogin(_buscaCtrl.text);
    setState(() {
      _sucesso = null;
      if (usuario == null) {
        _erros = ['Usuário não encontrado com este login.'];
        _usuarioEncontrado = null;
      } else if (usuario.id == app.usuarioLogado?.id) {
        _erros = ['Você não pode excluir seu próprio usuário.'];
        _usuarioEncontrado = null;
      } else {
        _erros = [];
        _usuarioEncontrado = usuario;
      }
    });
  }

  Future<void> _confirmarExclusao() async {
    final usuario = _usuarioEncontrado;
    if (usuario == null) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fundoCard,
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o usuário "${usuario.login}"? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.erro),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;
    if (!mounted) return;

    final app = context.read<AppState>();
    final resultado = app.excluirUsuario(usuario.id);
    setState(() {
      _sucesso = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
      if (resultado.temSucesso) {
        _usuarioEncontrado = null;
        _buscaCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Usuários'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Excluir Cadastro',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_sucesso != null) FeedbackBox.sucesso(_sucesso),
                  if (_erros.isNotEmpty) FeedbackBox.erros(_erros),
                  SectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buscaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Buscar por login',
                              hintText: 'Ex: joao.silva',
                            ),
                            onSubmitted: (_) => _buscar(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _buscar,
                          child: const Text('Buscar'),
                        ),
                      ],
                    ),
                  ),
                  if (_usuarioEncontrado != null)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _usuarioEncontrado!.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '@${_usuarioEncontrado!.login} · '
                                      '${_usuarioEncontrado!.tipo.label}',
                                      style: const TextStyle(
                                        color: AppColors.textoSuave,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                texto: _usuarioEncontrado!.status.label,
                                positivo: _usuarioEncontrado!.status ==
                                    StatusConta.ativo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.erro,
                              foregroundColor: const Color(0xFF240007),
                            ),
                            onPressed: _confirmarExclusao,
                            child: const Text('Excluir usuário'),
                          ),
                        ],
                      ),
                    ),
                  NavRodape(
                    links: [
                      NavRodapeLink(
                        '← Gestão de cadastro',
                        () => context.go('/usuarios'),
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
