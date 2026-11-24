import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/tema_controller.dart';
import '../../widgets/botoes.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/campo_senha.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Perfil do próprio usuário (equivale a app/views/usuarios/perfil.php):
/// nome, tema salvo na conta e troca de senha. Perfil de acesso, status e
/// estoques NÃO podem ser alterados aqui — a API recusa esses campos.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nomeCtrl = TextEditingController();
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  ResultadoOperacao? _feedbackPerfil;
  ResultadoOperacao? _feedbackSenha;
  bool _salvandoNome = false;
  bool _salvandoSenha = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.text = context.read<AppState>().usuarioLogado?.nome ?? '';
    context.read<AppState>().carregarConta();
  }

  @override
  void dispose() {
    for (final c in [_nomeCtrl, _atualCtrl, _novaCtrl, _confirmarCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarNome() async {
    setState(() => _salvandoNome = true);
    final r = await context.read<AppState>().salvarNomeDoPerfil(_nomeCtrl.text);
    if (!mounted) return;
    setState(() {
      _salvandoNome = false;
      _feedbackPerfil = r;
    });
  }

  Future<void> _trocarSenha() async {
    setState(() => _salvandoSenha = true);
    final r = await context.read<AppState>().trocarSenha(
      senhaAtual: _atualCtrl.text,
      senha: _novaCtrl.text,
      confirmarSenha: _confirmarCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _salvandoSenha = false;
      _feedbackSenha = r;
      if (!r.temErro) {
        _atualCtrl.clear();
        _novaCtrl.clear();
        _confirmarCtrl.clear();
      }
    });
  }

  Future<void> _escolherFoto() async {
    final app = context.read<AppState>();
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    final r = await app.enviarFotoDoPerfil(
      bytes: bytes,
      nomeArquivo: arquivo.name,
    );
    if (!mounted) return;
    setState(() => _feedbackPerfil = r);
  }

  Future<void> _removerFoto() async {
    final r = await context.read<AppState>().removerFotoDoPerfil();
    if (!mounted) return;
    setState(() => _feedbackPerfil = r);
  }

  Future<void> _mudarTema(String? chave) async {
    if (chave == null) return;
    final tema = context.read<TemaController>();
    final app = context.read<AppState>();
    await tema.aplicarDaConta(chave);
    final r = await app.salvarTemaDaConta(chave);
    if (!mounted) return;
    setState(() => _feedbackPerfil = r);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tema = context.watch<TemaController>();
    final usuario = app.usuarioLogado;

    return TelaPadrao(
      secao: 'Meu perfil',
      larguraMaxima: 700,
      children: [
        const TituloPagina('Meu perfil'),
        AreaFeedback(resultado: _feedbackPerfil),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloCartao('Dados da conta'),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: app.fotoPerfil == null
                        ? null
                        : MemoryImage(app.fotoPerfil!),
                    child: app.fotoPerfil == null
                        ? const Icon(Icons.person, size: 34)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      OutlinedButton(
                        onPressed: _escolherFoto,
                        child: const Text('Trocar foto'),
                      ),
                      if (app.fotoPerfil != null)
                        TextButton(
                          onPressed: _removerFoto,
                          child: const Text('Remover'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Login: ${usuario?.login ?? "—"}'),
              Text('Perfil de acesso: ${usuario?.tipo.label ?? "—"}'),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              BotaoPrincipal(
                texto: 'Salvar nome',
                ocupado: _salvandoNome,
                aoPressionar: _salvarNome,
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloCartao('Aparência'),
              CampoSelecao<String>(
                rotulo: 'Tema',
                valor: tema.chaveConta,
                itens: const [
                  DropdownMenuItem(value: 'claro', child: Text('Claro')),
                  DropdownMenuItem(value: 'escuro', child: Text('Escuro')),
                  DropdownMenuItem(
                    value: 'automatico',
                    child: Text('Automático (segue o aparelho)'),
                  ),
                ],
                onChanged: _mudarTema,
              ),
            ],
          ),
        ),
        AreaFeedback(resultado: _feedbackSenha),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloCartao('Trocar senha'),
              CampoSenha(controller: _atualCtrl, rotulo: 'Senha atual'),
              const SizedBox(height: 14),
              CampoSenha(controller: _novaCtrl, rotulo: 'Nova senha'),
              const SizedBox(height: 14),
              CampoSenha(
                controller: _confirmarCtrl,
                rotulo: 'Confirmar nova senha',
                textInputAction: TextInputAction.done,
                aoEnviar: _trocarSenha,
              ),
              const SizedBox(height: 16),
              BotaoPrincipal(
                texto: 'Trocar senha',
                ocupado: _salvandoSenha,
                aoPressionar: _trocarSenha,
              ),
            ],
          ),
        ),
        NavRodape(
          links: [NavRodapeLink('← Voltar ao painel', () => context.go('/painel'))],
        ),
      ],
    );
  }
}
