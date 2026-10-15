import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Título principal de uma tela (ex.: "Alertas dos Sensores").
class TituloPagina extends StatelessWidget {
  const TituloPagina(
    this.texto, {
    super.key,
    this.subtitulo,
    this.grande = false,
  });

  final String texto;

  /// Linha de apoio abaixo do título (opcional).
  final String? subtitulo;

  /// Usa a fonte maior (só o título do Painel).
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              texto,
              style: grande ? textos.headlineMedium : textos.headlineSmall,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: textos.bodyMedium?.copyWith(
                color: context.cores.textoSuave,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Título de um cartão ou de uma seção dentro da tela.
class TituloCartao extends StatelessWidget {
  const TituloCartao(this.texto, {super.key, this.espacoAbaixo = 14});

  final String texto;
  final double espacoAbaixo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: espacoAbaixo),
      child: Semantics(
        header: true,
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// Rótulo pequeno em caixa-alta que separa grupos de campos de um formulário
/// (ex.: "DADOS DO USUÁRIO") — equivale a `.usuarios-secao-titulo` no web.
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: context.cores.link,
        ),
      ),
    );
  }
}

/// Mensagem de "lista vazia" (itálico, cor suave).
class TextoVazio extends StatelessWidget {
  const TextoVazio(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        texto,
        style: TextStyle(
          color: context.cores.textoSuave,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Texto pequeno de apoio sob um campo (ex.: regras da senha).
class DicaCampo extends StatelessWidget {
  const DicaCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: context.cores.textoSuave,
          height: 1.4,
        ),
      ),
    );
  }
}
