import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Peças da identidade visual ÁKRON disponíveis como imagem.
enum PecaLogo {
  /// Escudo alado com o "A".
  simbolo('assets/images/akron_simbolo.png', 1024 / 785),

  /// Nome ÁKRON.
  nome('assets/images/akron_nome.png', 1000 / 250),

  /// Símbolo + ÁKRON + Άκρον (versão vertical completa).
  completa('assets/images/akron_logo_completa.png', 1200 / 1404);

  const PecaLogo(this.asset, this.proporcao);

  final String asset;

  /// Largura ÷ altura da imagem.
  final double proporcao;
}

/// Logo do ÁKRON.
///
/// As imagens são máscaras brancas com transparência; aqui elas são tingidas
/// com a cor da marca do tema atual ([AkronCores.marca]) — azul-ardósia no tema
/// claro e azul-ardósia claro no escuro. Informe só a [altura]; a largura segue
/// a proporção original da arte.
///
/// ```dart
/// const AkronLogo.simbolo(altura: 32)
/// const AkronLogo.completa(altura: 176)
/// ```
class AkronLogo extends StatelessWidget {
  const AkronLogo.simbolo({super.key, this.altura = 32, this.cor})
    : peca = PecaLogo.simbolo;
  const AkronLogo.nome({super.key, this.altura = 14, this.cor})
    : peca = PecaLogo.nome;
  const AkronLogo.completa({super.key, this.altura = 176, this.cor})
    : peca = PecaLogo.completa;

  final PecaLogo peca;
  final double altura;

  /// Cor fixa (opcional). Sem ela, usa a cor da marca do tema.
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'ÁKRON',
      child: ExcludeSemantics(
        child: Image.asset(
          peca.asset,
          height: altura,
          width: altura * peca.proporcao,
          fit: BoxFit.contain,
          color: cor ?? context.cores.marca,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
