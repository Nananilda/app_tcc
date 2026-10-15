import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/cores.dart';

/// Tom (cor) de um [StatusBadge].
enum TomBadge { sucesso, erro, alerta, info, neutro }

/// Etiqueta colorida em forma de pílula — equivale à classe `.badge` do web.
///
/// - [StatusBadge.ativo]: verde para ativo/resolvido, vermelho para inativo;
/// - [StatusBadge.severidade]: a COR indica a gravidade do alerta
///   (crítico = vermelho, atenção = âmbar, informativo = azul-ardósia).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.texto, required this.tom});

  /// Ativo (verde) ou inativo (vermelho).
  const StatusBadge.ativo({
    super.key,
    required bool ativo,
    String? textoAtivo,
    String? textoInativo,
  }) : texto = ativo ? (textoAtivo ?? 'Ativo') : (textoInativo ?? 'Inativo'),
       tom = ativo ? TomBadge.sucesso : TomBadge.erro;

  /// Selo de severidade de um alerta.
  StatusBadge.severidade(Severidade severidade, {super.key})
    : texto = severidade.label,
      tom = switch (severidade) {
        Severidade.critico => TomBadge.erro,
        Severidade.atencao => TomBadge.alerta,
        Severidade.info => TomBadge.info,
      };

  final String texto;
  final TomBadge tom;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (fundo, letra) = switch (tom) {
      TomBadge.sucesso => (c.sucessoFundo, c.sucesso),
      TomBadge.erro => (c.erroFundo, c.erro),
      TomBadge.alerta => (c.alertaFundo, c.alerta),
      TomBadge.info => (c.infoFundo, c.link),
      TomBadge.neutro => (c.fundoCardAlt, c.textoSuave),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: letra,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
