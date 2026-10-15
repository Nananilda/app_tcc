import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/akron_logo.dart';
import '../../widgets/botoes.dart';
import '../../widgets/conexao_servidor.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tema_botao.dart';

/// Tela de autenticação — equivale a index.php do sistema web.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;
  String? _aviso; // ex.: "Sessão expirada. Faça login novamente."

  @override
  void initState() {
    super.initState();
    // Se o app voltou ao login porque a sessão caiu, explica o motivo uma vez.
    final app = context.read<AppState>();
    _aviso = app.avisoLogin;
    app.limparAvisoLogin();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _autenticar() async {
    if (!_formKey.currentState!.validate() || _carregando) return;

    setState(() {
      _carregando = true;
      _erro = null;
      _aviso = null;
    });

    final resultado = await context.read<AppState>().login(
      _loginCtrl.text,
      _senhaCtrl.text,
    );
    if (!mounted) return;

    if (resultado.temErro) {
      setState(() {
        _erro = resultado.erros.first;
        _carregando = false;
      });
    } else {
      setState(() => _carregando = false);
      context.go('/painel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final textos = Theme.of(context).textTheme;
    final largo = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: Container(
        // Fundo em degradê radial (muda com o tema)
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [c.loginTopo, c.loginBase],
            stops: const [0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Marca em destaque
                        AkronLogo.completa(altura: largo ? 176 : 140),
                        const SizedBox(height: 14),
                        Text(
                          'Visão de ponta a ponta para sua operação',
                          textAlign: TextAlign.center,
                          style: textos.bodyMedium?.copyWith(
                            color: c.textoSuave,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Cartão do formulário
                        SectionCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'AUTENTICAÇÃO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: c.link,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FeedbackBox.aviso(_aviso),
                                if (_erro != null) FeedbackBox.erros([_erro!]),
                                _Rotulo(
                                  'Identificação do Usuário',
                                  c.textoSuave,
                                ),
                                // O texto de exemplo ("usuario.nome") não serve de nome para leitores
                                // de tela; o Semantics dá ao campo o nome do rótulo visível acima.
                                Semantics(
                                  label: 'Identificação do usuário',
                                  child: TextFormField(
                                    controller: _loginCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'usuario.nome',
                                    ),
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    autocorrect: false,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Informe o login.'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _Rotulo('Credencial de Acesso', c.textoSuave),
                                Semantics(
                                  label: 'Senha',
                                  child: TextFormField(
                                    controller: _senhaCtrl,
                                    obscureText: !_senhaVisivel,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        tooltip: _senhaVisivel
                                            ? 'Ocultar senha'
                                            : 'Mostrar senha',
                                        icon: Icon(
                                          _senhaVisivel
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _senhaVisivel = !_senhaVisivel,
                                        ),
                                      ),
                                    ),
                                    onFieldSubmitted: (_) => _autenticar(),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Informe a senha.'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                BotaoPrincipal(
                                  texto: 'AUTENTICAR ACESSO',
                                  ocupado: _carregando,
                                  aoPressionar: _autenticar,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const ConexaoServidor(),
                        const SizedBox(height: 4),
                        Text(
                          'Acesso restrito a usuários autorizados.',
                          style: TextStyle(fontSize: 12.5, color: c.textoFraco),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (largo)
                Positioned(
                  top: 22,
                  left: 28,
                  child: Text(
                    'Sistema de Monitoramento Industrial v2.0',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textoFraco,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              const Positioned(top: 10, right: 14, child: TemaBotao()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rótulo acima de um campo de texto.
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto, this.cor);

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
