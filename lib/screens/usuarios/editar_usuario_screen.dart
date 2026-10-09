import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/botoes.dart';
import '../../widgets/busca_login.dart';
import '../../widgets/campo_senha.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/linha_campos.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';
import 'campos_acesso_usuario.dart';

/// Editar usuário (somente administradores) — equivale a
/// app/views/usuarios/editar.php.
///
/// Dois passos na mesma tela: (1) buscar o usuário pelo login; (2) alterar
/// nome, login, perfil, status e, opcionalmente, a senha. As regras de
/// validação ficam no servidor (as mesmas do sistema web).
class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buscaCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  TipoUsuario _tipo = TipoUsuario.usuario;
  StatusConta _status = StatusConta.ativo;

  /// Usuário carregado no formulário de edição (nulo = formulário oculto).
  Usuario? _usuario;
  ResultadoOperacao? _feedback;
  bool _buscando = false;
  bool _salvando = false;

  @override
  void dispose() {
    for (final ctrl in [
      _buscaCtrl,
      _idCtrl,
      _nomeCtrl,
      _loginCtrl,
      _senhaCtrl,
      _confirmarCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório.' : null;

  /// Preenche o formulário com os dados do usuário (senha sempre em branco).
  void _preencher(Usuario usuario) {
    _usuario = usuario;
    _idCtrl.text = '${usuario.id}';
    _nomeCtrl.text = usuario.nome;
    _loginCtrl.text = usuario.login;
    _tipo = usuario.tipo;
    _status = usuario.status;
    _senhaCtrl.clear();
    _confirmarCtrl.clear();
  }

  // ── Passo 1: buscar ──────────────────────────────────────────────────────
  Future<void> _buscar() async {
    if (_buscando) return;
    if (_buscaCtrl.text.trim().isEmpty) {
      setState(
        () => _feedback = const ResultadoOperacao(
          erros: ['Digite um login para buscar.'],
        ),
      );
      return;
    }

    final app = context.read<AppState>();
    setState(() => _buscando = true);
    final resposta = await app.buscarUsuarioPorLogin(_buscaCtrl.text);
    if (!mounted) return;

    setState(() {
      _buscando = false;
      if (!resposta.ok) {
        _feedback = ResultadoOperacao(erros: [resposta.erro!]);
      } else if (resposta.dados == null) {
        _usuario = null;
        _feedback = const ResultadoOperacao(
          erros: ['Usuário não encontrado com este login.'],
        );
      } else {
        _feedback = null;
        _preencher(resposta.dados!);
      }
    });
  }

  // ── Passo 2: salvar ──────────────────────────────────────────────────────
  Future<void> _salvar() async {
    final atual = _usuario;
    if (atual == null || _salvando || !_formKey.currentState!.validate()) {
      return;
    }

    final app = context.read<AppState>();
    setState(() => _salvando = true);
    final resultado = await app.atualizarUsuario(
      id: atual.id,
      nome: _nomeCtrl.text,
      login: _loginCtrl.text,
      tipo: _tipo,
      status: _status,
      senha: _senhaCtrl.text,
      confirmarSenha: _confirmarCtrl.text,
    );

    // Gravou: recarrega do servidor o que ficou salvo (como o sistema web faz)
    Resposta<Usuario?>? recarregado;
    if (resultado.temSucesso) {
      recarregado = await app.buscarUsuarioPorLogin(_loginCtrl.text);
    }
    if (!mounted) return;

    setState(() {
      _salvando = false;
      _feedback = resultado;
      final salvo = recarregado?.dados;
      if (salvo != null) {
        _preencher(salvo);
        _buscaCtrl.text = salvo.login;
      }
      // Em caso de erro nada é limpo: o formulário continua com o que foi digitado.
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final usuario = _usuario;

    return TelaPadrao(
      secao: 'Usuários',
      larguraMaxima: 700,
      children: [
        const TituloPagina(
          'Editar Usuário',
          subtitulo: 'Busque um usuário pelo login e edite suas informações.',
        ),
        AreaFeedback(resultado: _feedback),

        // Passo 1: busca
        BuscaLoginCard(
          controller: _buscaCtrl,
          buscando: _buscando,
          aoBuscar: _buscar,
        ),

        // Passo 2: edição (aparece depois de encontrar o usuário)
        if (usuario != null)
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TituloCartao('Editar dados', espacoAbaixo: 18),
                  const RotuloSecao('Dados do usuário'),
                  LinhaCampos(
                    children: [
                      TextField(
                        controller: _idCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'ID',
                          fillColor: c.fundoCardAlt,
                        ),
                      ),
                      TextFormField(
                        controller: _nomeCtrl,
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          counterText: '',
                        ),
                        validator: _obrigatorio,
                      ),
                      TextFormField(
                        controller: _loginCtrl,
                        maxLength: 50,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Login *',
                          counterText: '',
                        ),
                        validator: _obrigatorio,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const RotuloSecao('Nova senha (opcional)'),
                  LinhaCampos(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CampoSenha(
                            controller: _senhaCtrl,
                            rotulo: 'Nova Senha',
                            dica: 'Em branco: mantém a atual',
                          ),
                          const DicaCampo(
                            'Mín. 8 caracteres, maiúscula, minúscula, número e especial.',
                          ),
                        ],
                      ),
                      CampoSenha(
                        controller: _confirmarCtrl,
                        rotulo: 'Confirmar Nova Senha',
                        dica: 'Repita a nova senha',
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const RotuloSecao('Nível de acesso'),
                  CamposAcessoUsuario(
                    tipo: _tipo,
                    status: _status,
                    dicaStatus:
                        'Usuários inativos não podem acessar o sistema.',
                    aoMudarTipo: (v) => setState(() => _tipo = v),
                    aoMudarStatus: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 24),
                  BotaoPrincipal(
                    texto: 'Salvar Alterações',
                    ocupado: _salvando,
                    aoPressionar: _salvar,
                  ),
                ],
              ),
            ),
          ),

        NavRodape(
          links: [
            NavRodapeLink(
              '← Voltar à gestão de usuários',
              () => context.go('/usuarios'),
            ),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}
