import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Botão principal do app. Enquanto [ocupado] é verdadeiro mostra um indicador
/// de progresso no lugar do texto e ignora novos toques (evita enviar o mesmo
/// formulário duas vezes).
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.ocupado = false,
    this.icone,
  });

  final String texto;
  final VoidCallback? aoPressionar;
  final bool ocupado;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final conteudo = ocupado
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.textoSobrePrimaria,
            ),
          )
        : (icone == null
              ? Text(texto)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 18),
                    const SizedBox(width: 8),
                    Text(texto),
                  ],
                ));

    // Ocupado: o botão perde o texto (só há o indicador), então damos um nome a ele
    return Semantics(
      label: ocupado ? '$texto — aguarde' : null,
      child: ElevatedButton(
        onPressed: ocupado ? null : aoPressionar,
        child: conteudo,
      ),
    );
  }
}

/// Botão de ação destrutiva (excluir). Vermelho, escurece ao passar o mouse —
/// equivale à classe `.btn-perigo` do sistema web.
class BotaoPerigo extends StatelessWidget {
  const BotaoPerigo({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.ocupado = false,
  });

  final String texto;
  final VoidCallback? aoPressionar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return FilledButton(
      onPressed: ocupado ? null : aoPressionar,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return c.erro.withValues(alpha: 0.4);
          }
          if (estados.contains(WidgetState.hovered) ||
              estados.contains(WidgetState.pressed)) {
            return c.erroHover;
          }
          return c.erro;
        }),
        foregroundColor: WidgetStatePropertyAll(c.textoSobreErro),
      ),
      child: ocupado
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.textoSobreErro,
              ),
            )
          : Text(texto),
    );
  }
}
