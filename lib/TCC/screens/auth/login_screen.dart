import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/feedback_box.dart';

/// Tela de autenticação — equivalente a index.php.
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
    });

    final app = context.read<AppState>();
    final resultado = await app.login(_loginCtrl.text, _senhaCtrl.text);

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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sistema de Monitoramento Industrial v2.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textoSuave,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.fundoCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borda),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaria.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: AppColors.primaria,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'autenticação',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        if (_erro != null) FeedbackBox.erros([_erro!]),
                        const Text(
                          'Identificação do Usuário',
                          style: TextStyle(
                            color: AppColors.textoSuave,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _loginCtrl,
                          decoration: const InputDecoration(
                            hintText: 'usuario.nome',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o login.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Credencial de Acesso',
                          style: TextStyle(
                            color: AppColors.textoSuave,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _senhaCtrl,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _senhaVisivel
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textoSuave,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel),
                            ),
                          ),
                          onFieldSubmitted: (_) => _autenticar(),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Informe a senha.'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _carregando ? null : _autenticar,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _carregando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('AUTENTICAR ACESSO'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
