import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/botoes.dart';
import '../../widgets/busca_login.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Excluir usuário (somente administradores) — equivale a
/// app/views/usuarios/excluir.php.
///
/// Fluxo em três etapas, para evitar exclusões acidentais:
///   1. buscar o usuário pelo login;
///   2. conferir os dados e pedir para continuar;
///   3. confirmar ("Sim, excluir usuário") — só então a exclusão é feita.
/// O administrador não pode excluir a própria conta.
class ExcluirUsuarioScreen extends StatefulWidget {
  const ExcluirUsuarioScreen({super.key});

  @override
  State<ExcluirUsuarioScreen> createState() => _ExcluirUsuarioScreenState();
}

class _ExcluirUsuarioScreenState extends State<ExcluirUsuarioScreen> {
  final _buscaCtrl = TextEditingController();

  /// Usuário encontrado na etapa 1 (nulo = nada a mostrar).
  Usuario? _usuario;

  /// Verdadeiro na etapa 3 (quadro vermelho de confirmação).
  bool _confirmando = false;

  ResultadoOperacao? _feedback;
  bool _buscando = false;
  bool _excluindo = false;

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  /// Volta ao início do fluxo (campo de busca vazio, sem usuário selecionado).
  void _recomecar() {
    _buscaCtrl.clear();
    setState(() {
      _usuario = null;
      _confirmando = false;
    });
  }

  // ── Etapa 1: buscar ──────────────────────────────────────────────────────
  Future<void> _buscar() async {
    if (_buscando) return;
    if (_buscaCtrl.text.trim().isEmpty) {
      setState(() {
        _usuario = null;
        _confirmando = false;
        _feedback = const ResultadoOperacao(
          erros: ['Digite um login para buscar.'],
        );
      });
      return;
    }

    final app = context.read<AppState>();
    setState(() => _buscando = true);
    final resposta = await app.buscarUsuarioPorLogin(_buscaCtrl.text);
    if (!mounted) return;

    setState(() {
      _buscando = false;
      _confirmando = false;
      _usuario = null;
      final encontrado = resposta.dados;

      if (!resposta.ok) {
        _feedback = ResultadoOperacao(erros: [resposta.erro!]);
      } else if (encontrado == null) {
        _feedback = const ResultadoOperacao(
          erros: ['Usuário não encontrado com este login.'],
        );
      } else if (encontrado.id == app.usuarioLogado?.id) {
        _feedback = const ResultadoOperacao(
          erros: ['Você não pode desativar sua própria conta.'],
        );
      } else {
        _feedback = null;
        _usuario = encontrado;
      }
    });
  }

  // ── Etapa 3: excluir ─────────────────────────────────────────────────────
  Future<void> _excluir() async {
    final alvo = _usuario;
    if (alvo == null || _excluindo) return;

    final app = context.read<AppState>();
    setState(() => _excluindo = true);
    final resultado = await app.excluirUsuario(alvo.id);
    if (!mounted) return;

    setState(() {
      _excluindo = false;
      _feedback = resultado;
      if (resultado.temSucesso) {
        _usuario = null;
        _confirmando = false;
        _buscaCtrl.clear();
      }
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
          'Desativar Usuário',
          subtitulo: 'Busque um usuário pelo login e exclua seu cadastro.',
        ),
        AreaFeedback(resultado: _feedback),

        // Etapa 1: busca
        BuscaLoginCard(
          controller: _buscaCtrl,
          buscando: _buscando,
          aoBuscar: _buscar,
        ),

        // Etapas 2 e 3 mostram os mesmos dados; mudam só o quadro e os botões
        if (usuario != null)
          SectionCard(
            corBorda: _confirmando ? c.erro : null,
            cor: _confirmando
                ? Color.alphaBlend(c.erroFundo, c.fundoCard)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TituloCartao(
                  _confirmando ? 'Confirmar exclusão' : 'Usuário encontrado',
                ),
                if (_confirmando)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Você está prestes a desativar a conta do seguinte usuário. O histórico é preservado e a conta deixa de acessar o sistema:',
                    ),
                  ),
                _DadosDoUsuario(usuario: usuario),
                const SizedBox(height: 20),
                if (_confirmando) ...[
                  Text(
                    'Esta ação é irreversível!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.erro,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    BotaoPerigo(
                      texto: _confirmando
                          ? 'Sim, desativar usuário'
                          : 'Continuar para exclusão',
                      ocupado: _excluindo,
                      aoPressionar: _confirmando
                          ? _excluir
                          : () => setState(() => _confirmando = true),
                    ),
                    OutlinedButton(
                      onPressed: _excluindo ? null : _recomecar,
                      child: Text(_confirmando ? 'Não, cancelar' : 'Cancelar'),
                    ),
                  ],
                ),
              ],
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

/// Tabela "campo: valor" com os dados do usuário (ID, nome, login, tipo, status).
class _DadosDoUsuario extends StatelessWidget {
  const _DadosDoUsuario({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;

    Widget linha(String rotulo, Widget valor, {bool ultima = false}) {
      return MergeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: ultima ? BorderSide.none : BorderSide(color: c.borda),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  rotulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.textoSuave,
                  ),
                ),
              ),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: valor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borda)),
      ),
      child: Column(
        children: [
          linha('ID', Text('${usuario.id}')),
          linha('Nome', Text(usuario.nome)),
          linha('Login', Text(usuario.login)),
          linha('Tipo', Text(usuario.tipo.label)),
          linha(
            'Status',
            StatusBadge.ativo(ativo: usuario.status == StatusConta.ativo),
            ultima: true,
          ),
        ],
      ),
    );
  }
}
