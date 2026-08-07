import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Um link exibido no rodapé de navegação (ex: "← Voltar ao painel").
class NavRodapeLink {
  final String texto;
  final VoidCallback onTap;

  const NavRodapeLink(this.texto, this.onTap);
}

/// Rodapé de navegação entre telas relacionadas — equivalente ao bloco
/// `<div class="nav-rodape">` presente nas views PHP originais.
class NavRodape extends StatelessWidget {
  final List<NavRodapeLink> links;

  const NavRodape({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: links
            .map(
              (l) => InkWell(
                onTap: l.onTap,
                child: Text(
                  l.texto,
                  style: const TextStyle(
                    color: AppColors.primaria,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
