import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/topbar.dart';

/// Editar usuário — equivalente a app/views/usuarios/editar.php.
class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _buscaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  TipoUsuario _tipo = TipoUsuario.usuario;
  StatusConta _status = StatusConta.ativo;

  Usuario? _usuarioEncontrado;
  bool _buscaRealizada = false;
  String? _sucesso;
  List<String> _erros = [];

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _nomeCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  bool _buscando = false;
  bool _salvando = false;

  Future<void> _buscar() async {
    if (_buscaCtrl.text.trim().isEmpty) {
      setState(() {
        _erros = ['Digite um login para buscar.'];
        _usuarioEncontrado = null;
        _buscaRealizada = true;
        _sucesso = null;
      });
      return;
    }
    setState(() => _buscando = true);
    final app = context.read<AppState>();
    final usuario = await app.buscarUsuarioPorLogin(_buscaCtrl.text);
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _buscaRealizada = true;
      _sucesso = null;
      if (usuario == null) {
        _erros = ['Usuário não encontrado com este login.'];
        _usuarioEncontrado = null;
      } else {
        _erros = [];
        _usuarioEncontrado = usuario;
        _nomeCtrl.text = usuario.nome;
        _loginCtrl.text = usuario.login;
        _tipo = usuario.tipo;
        _status = usuario.status;
        _senhaCtrl.clear();
        _confirmarCtrl.clear();
      }
    });
  }

  Future<void> _atualizar() async {
    if (_usuarioEncontrado == null) return;
    setState(() => _salvando = true);
    final app = context.read<AppState>();
    final resultado = await app.atualizarUsuario(
      id: _usuarioEncontrado!.id,
      nome: _nomeCtrl.text,
      login: _loginCtrl.text,
      tipo: _tipo,
      status: _status,
      senha: _senhaCtrl.text,
      confirmarSenha: _confirmarCtrl.text,
    );
    if (!mounted) return;
    Usuario? atualizado = _usuarioEncontrado;
    if (resultado.temSucesso) {
      atualizado = await app.buscarUsuarioPorLogin(_loginCtrl.text);
    }
    if (!mounted) return;
    setState(() {
      _sucesso = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
      _salvando = false;
      if (resultado.temSucesso) {
        _usuarioEncontrado = atualizado;
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
                    'Editar Usuário',
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
                          onPressed: _buscando ? null : _buscar,
                          child: _buscando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Buscar'),
                        ),
                      ],
                    ),
                  ),
                  if (_usuarioEncontrado != null)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Editando usuário #${_usuarioEncontrado!.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nomeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _loginCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Login',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _senhaCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Nova senha (opcional)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _confirmarCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar nova senha',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<TipoUsuario>(
                                  value: _tipo,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                  ),
                                  items: TipoUsuario.values
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _tipo = v ?? TipoUsuario.usuario,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: DropdownButtonFormField<StatusConta>(
                                  value: _status,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                  ),
                                  items: StatusConta.values
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _status = v ?? StatusConta.ativo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _salvando ? null : _atualizar,
                            child: _salvando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar alterações'),
                          ),
                        ],
                      ),
                    )
                  else if (_buscaRealizada)
                    const SizedBox.shrink(),
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
