import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_theme.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/topbar.dart';

/// Menu de gestão de usuários — equivalente a gestao_usuarios.php.
class GestaoUsuariosScreen extends StatelessWidget {
  const GestaoUsuariosScreen({super.key});

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
                    'Bem-vindo à gestão de usuários',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  _MenuLink(
                    icone: '➕',
                    titulo: 'Realizar Cadastro',
                    onTap: () => context.go('/usuarios/cadastro'),
                  ),
                  const SizedBox(height: 12),
                  _MenuLink(
                    icone: '✏️',
                    titulo: 'Editar Usuário',
                    onTap: () => context.go('/usuarios/editar'),
                  ),
                  const SizedBox(height: 12),
                  _MenuLink(
                    icone: '🗑️',
                    titulo: 'Excluir Cadastro',
                    onTap: () => context.go('/usuarios/excluir'),
                  ),
                  NavRodape(
                    links: [
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

class _MenuLink extends StatelessWidget {
  final String icone;
  final String titulo;
  final VoidCallback onTap;

  const _MenuLink({
    required this.icone,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.fundoCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borda),
        ),
        child: Row(
          children: [
            Text(icone, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textoSuave,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
