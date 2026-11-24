import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/cores.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Menu da gestão de usuários (somente administradores) — equivale a
/// app/views/usuarios/gestao_usuarios.php: leva a cadastrar, editar e excluir.
class GestaoUsuariosScreen extends StatelessWidget {
  const GestaoUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      secao: 'Usuários',
      larguraMaxima: 700,
      children: [
        const TituloPagina(
          'Gestão de Usuários',
          subtitulo: 'Escolha uma das ações abaixo.',
        ),
        _ItemMenu(
          icone: Icons.person_add_alt_1_outlined,
          titulo: 'Realizar Cadastro',
          descricao: 'Criar um novo usuário no sistema.',
          aoTocar: () => context.go('/usuarios/cadastro'),
        ),
        _ItemMenu(
          icone: Icons.edit_outlined,
          titulo: 'Editar Usuário',
          descricao: 'Buscar e atualizar dados de um usuário existente.',
          aoTocar: () => context.go('/usuarios/editar'),
        ),
        _ItemMenu(
          icone: Icons.person_remove_outlined,
          titulo: 'Desativar Cadastro',
          descricao: 'Remover permanentemente um usuário.',
          aoTocar: () => context.go('/usuarios/excluir'),
        ),
        const SizedBox(height: 8),
        NavRodape(
          links: [
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Linha clicável do menu: ícone, título, descrição e seta.
class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final raio = BorderRadius.circular(10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        // A sombra e a borda ficam num Container; o Material (transparente) só
        // serve de superfície para o efeito de toque/hover do InkWell.
        child: Container(
          decoration: BoxDecoration(
            color: c.fundoCard,
            borderRadius: raio,
            border: Border.all(color: c.borda),
            boxShadow: c.sombra,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: raio,
              hoverColor: c.infoFundo,
              onTap: aoTocar,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.infoFundo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icone, color: c.link, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            descricao,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.textoSuave,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.textoFraco, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
