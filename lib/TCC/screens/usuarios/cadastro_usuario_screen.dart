import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/topbar.dart';

/// Cadastro de usuário — equivalente a app/views/usuarios/cadastro.php.
class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  TipoUsuario _tipo = TipoUsuario.usuario;
  StatusConta _status = StatusConta.ativo;

  String? _sucesso;
  List<String> _erros = [];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _cadastrar() {
    final app = context.read<AppState>();
    final resultado = app.cadastrarUsuario(
      nome: _nomeCtrl.text,
      login: _loginCtrl.text,
      senha: _senhaCtrl.text,
      confirmar: _confirmarCtrl.text,
      tipo: _tipo,
      status: _status,
    );

    setState(() {
      _sucesso = resultado.temSucesso ? resultado.mensagem : null;
      _erros = resultado.erros;
    });

    if (resultado.temSucesso) {
      _nomeCtrl.clear();
      _loginCtrl.clear();
      _senhaCtrl.clear();
      _confirmarCtrl.clear();
      setState(() {
        _tipo = TipoUsuario.usuario;
        _status = StatusConta.ativo;
      });
    }
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
                    'CADASTRO DE USUÁRIO',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (_sucesso != null) FeedbackBox.sucesso('✔ $_sucesso'),
                  if (_erros.isNotEmpty) FeedbackBox.erros(_erros),
                  SectionCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SecaoTitulo('DADOS DO USUÁRIO'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nomeCtrl,
                                  maxLength: 100,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome Completo *',
                                    hintText: 'Ex: João da Silva',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _loginCtrl,
                                  maxLength: 50,
                                  decoration: const InputDecoration(
                                    labelText: 'Login *',
                                    hintText: 'joao.silva',
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const _SecaoTitulo('CREDENCIAL DE ACESSO'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _senhaCtrl,
                                  obscureText: true,
                                  maxLength: 128,
                                  decoration: const InputDecoration(
                                    labelText: 'Senha *',
                                    hintText: 'Mín. 8 chars',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _confirmarCtrl,
                                  obscureText: true,
                                  maxLength: 128,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar Senha *',
                                    hintText: 'Repita a senha',
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const _SecaoTitulo('NÍVEL DE ACESSO'),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<TipoUsuario>(
                                      value: _tipo,
                                      decoration: const InputDecoration(
                                        labelText: 'Tipo de Usuário *',
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
                                    const SizedBox(height: 6),
                                    Text(
                                      _tipo == TipoUsuario.admin
                                          ? 'Acesso: Total — inclui gestão de usuários, sensores e configurações do sistema.'
                                          : 'Acesso: Visualização de sensores, gráficos e relatórios.',
                                      style: const TextStyle(
                                        color: AppColors.textoSuave,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: DropdownButtonFormField<StatusConta>(
                                  value: _status,
                                  decoration: const InputDecoration(
                                    labelText: 'Status da Conta *',
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
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _cadastrar,
                            child: const Text('CADASTRAR USUÁRIO'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  NavRodape(
                    links: [
                      NavRodapeLink(
                        'Voltar a gestão cadastro',
                        () => context.go('/usuarios'),
                      ),
                      NavRodapeLink(
                        'Voltar ao dashboard',
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

class _SecaoTitulo extends StatelessWidget {
  final String texto;

  const _SecaoTitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.textoSuave,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
