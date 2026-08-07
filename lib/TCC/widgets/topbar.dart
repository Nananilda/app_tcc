import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../state/app_state.dart';

/// Barra superior comum a todas as telas autenticadas: título, nome do
/// usuário logado (com selo "admin" quando aplicável) e atalho de logout.
class Topbar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;

  const Topbar({super.key, this.titulo = 'IndustrialOS'});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final usuario = app.usuarioLogado;

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.fundoCard,
      titleSpacing: 20,
      title: InkWell(
        onTap: () => context.go('/painel'),
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.texto,
          ),
        ),
      ),
      actions: [
        if (usuario != null) ...[
          Text(
            usuario.nome,
            style: const TextStyle(fontSize: 13.5, color: AppColors.texto),
          ),
          const SizedBox(width: 8),
          if (app.ehAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaria.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'admin',
                style: TextStyle(
                  color: AppColors.primaria,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textoSuave),
            onPressed: () async {
              await app.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
        const SizedBox(width: 12),
      ],
    );
  }
}
