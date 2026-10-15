import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Um link exibido no rodapé de navegação (ex.: "← Voltar ao painel").
class NavRodapeLink {
  final String texto;
  final VoidCallback onTap;

  const NavRodapeLink(this.texto, this.onTap);
}

/// Rodapé de navegação entre telas relacionadas — equivale à `.nav-rodape` do
/// sistema web.
class NavRodape extends StatelessWidget {
  const NavRodape({super.key, required this.links});

  final List<NavRodapeLink> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    final c = context.cores;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borda)),
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 8,
        children: [
          for (final link in links)
            InkWell(
              onTap: link.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  link.texto,
                  style: TextStyle(
                    color: c.link,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
