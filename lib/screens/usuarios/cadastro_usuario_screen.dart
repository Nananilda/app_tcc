import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../widgets/botoes.dart';
import '../../widgets/campo_senha.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/linha_campos.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';
import 'campos_acesso_usuario.dart';
import 'selecao_estoques_usuario.dart';

/// Cadastro de usuário (somente administradores) — equivale a
/// app/views/usuarios/cadastro.php.
///
/// O app só confere se os campos foram preenchidos; as demais regras (login
/// único, senha forte, confirmação) são validadas pelo servidor, que devolve a
/// lista de problemas para exibirmos no topo da tela.
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
  Set<int> _estoqueIds = {};

  ResultadoOperacao? _feedback;
  bool _enviando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório.' : null;

  Future<void> _cadastrar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    setState(() => _enviando = true);
    final resultado = await app.cadastrarUsuario(
      nome: _nomeCtrl.text,
      login: _loginCtrl.text,
      senha: _senhaCtrl.text,
      confirmar: _confirmarCtrl.text,
      tipo: _tipo,
      status: _status,
      // Só o funcionário tem vínculos; o administrador vê todos os estoques.
      estoqueIds: _tipo == TipoUsuario.admin ? const [] : _estoqueIds.toList(),
    );
    if (!mounted) return;

    setState(() {
      _enviando = false;
      _feedback = resultado;

      // Cadastro concluído: limpa o formulário para o próximo (em caso de erro
      // mantém o que foi digitado para a pessoa corrigir).
      if (resultado.temSucesso) {
        _formKey.currentState!.reset();
        _nomeCtrl.clear();
        _loginCtrl.clear();
        _senhaCtrl.clear();
        _confirmarCtrl.clear();
        _tipo = TipoUsuario.usuario;
        _status = StatusConta.ativo;
        _estoqueIds = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      secao: 'Usuários',
      larguraMaxima: 700,
      children: [
        const TituloPagina('Cadastro de Usuário'),
        AreaFeedback(resultado: _feedback),
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RotuloSecao('Dados do usuário'),
                LinhaCampos(
                  children: [
                    TextFormField(
                      controller: _nomeCtrl,
                      maxLength: 100,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        hintText: 'Ex: João da Silva',
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
                        hintText: 'joao.silva',
                        counterText: '',
                      ),
                      validator: _obrigatorio,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const RotuloSecao('Credencial de acesso'),
                LinhaCampos(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CampoSenha(
                          controller: _senhaCtrl,
                          rotulo: 'Senha *',
                          dica: 'Mín. 8 caracteres',
                          validator: _obrigatorio,
                        ),
                        const DicaCampo(
                          'Deve conter maiúscula, minúscula, número e caractere especial.',
                        ),
                      ],
                    ),
                    CampoSenha(
                      controller: _confirmarCtrl,
                      rotulo: 'Confirmar Senha *',
                      dica: 'Repita a senha',
                      validator: _obrigatorio,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const RotuloSecao('Nível de acesso'),
                CamposAcessoUsuario(
                  tipo: _tipo,
                  status: _status,
                  explicarTipo: true,
                  aoMudarTipo: (v) => setState(() => _tipo = v),
                  aoMudarStatus: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 22),
                const RotuloSecao('Estoques liberados'),
                SelecaoEstoquesUsuario(
                  tipo: _tipo,
                  selecionados: _estoqueIds,
                  aoMudar: (v) => setState(() => _estoqueIds = v),
                ),
                const SizedBox(height: 24),
                BotaoPrincipal(
                  texto: 'Cadastrar Usuário',
                  ocupado: _enviando,
                  aoPressionar: _cadastrar,
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
