import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/cores.dart';
import 'akron_logo.dart';
import 'tema_botao.dart';

/// Barra superior comum a todas as telas autenticadas: marca ÁKRON (símbolo +
/// nome + seção atual), usuário logado com seu perfil, botão de tema e "Sair".
/// Equivale à `.topbar` do sistema web.
class Topbar extends StatelessWidget implements PreferredSizeWidget {
  const Topbar({super.key, this.secao});

  /// Nome da seção exibido sob a marca (ex.: 'Alertas'). Opcional.
  final String? secao;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final usuario = app.usuarioLogado;
    final c = context.cores;
    final largura = MediaQuery.sizeOf(context).width;
    final mostrarUsuario = largura >= 720;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 62,
      titleSpacing: largura < 720 ? 14 : 24,
      backgroundColor: c.fundoCard,
      shape: Border(bottom: BorderSide(color: c.borda)),
      title: Semantics(
        button: true,
        label: 'ÁKRON — ir para o painel',
        onTap: () => context.go('/painel'),
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/painel'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AkronLogo.simbolo(altura: 32),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AkronLogo.nome(altura: 13),
                  if (secao != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      secao!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        height: 1,
                        color: c.link,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (usuario != null) ...[
          if (mostrarUsuario)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Usuário: ',
                          style: TextStyle(color: c.textoSuave),
                        ),
                        TextSpan(
                          text: usuario.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: c.texto,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    usuario.tipo.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textoFraco,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          const TemaBotao(),
          const SizedBox(width: 8),
          _BotaoSair(compacto: !mostrarUsuario),
        ],
        SizedBox(width: largura < 720 ? 10 : 20),
      ],
    );
  }
}

/// "Sair": encerra a sessão no servidor e volta ao login.
class _BotaoSair extends StatelessWidget {
  const _BotaoSair({required this.compacto});

  final bool compacto;

  Future<void> _sair(BuildContext context) async {
    final app = context.read<AppState>();
    final roteador = GoRouter.of(context);
    await app.logout();
    roteador.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (compacto) {
      return IconButton(
        tooltip: 'Sair',
        icon: const Icon(Icons.logout, size: 19),
        style: IconButton.styleFrom(
          fixedSize: const Size(38, 38),
          side: BorderSide(color: c.borda),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _sair(context),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _sair(context),
      icon: const Icon(Icons.logout, size: 17),
      label: const Text('Sair'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        foregroundColor: c.textoSuave,
        side: BorderSide(color: c.borda),
      ),
    );
  }
}
