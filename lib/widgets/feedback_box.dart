import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cores.dart';

/// Caixas de feedback (sucesso / erro / aviso), equivalentes às classes
/// `.msg-sucesso`, `.msg-erro` e `.msg-alerta` do sistema web.
class FeedbackBox extends StatelessWidget {
  const FeedbackBox._({required this.texto, required this.tipo});

  final String texto;
  final TipoFeedback tipo;

  /// Caixa verde com uma mensagem de sucesso. [mensagem] pode ser nula — nesse
  /// caso nada é exibido.
  static Widget sucesso(String? mensagem) {
    if (mensagem == null || mensagem.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FeedbackBox._(texto: mensagem, tipo: TipoFeedback.sucesso),
    );
  }

  /// Caixa vermelha listando uma ou mais mensagens de erro.
  static Widget erros(List<String> mensagens) {
    if (mensagens.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FeedbackBox._(
        texto: mensagens.join('\n'),
        tipo: TipoFeedback.erro,
      ),
    );
  }

  /// Caixa âmbar com um aviso (ex.: "Sua sessão expirou").
  static Widget aviso(String? mensagem) {
    if (mensagem == null || mensagem.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FeedbackBox._(texto: mensagem, tipo: TipoFeedback.aviso),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (cor, fundo, borda, icone) = switch (tipo) {
      TipoFeedback.sucesso => (
        c.sucesso,
        c.sucessoFundo,
        c.sucessoBorda,
        Icons.check_circle_outline,
      ),
      TipoFeedback.erro => (
        c.erro,
        c.erroFundo,
        c.erroBorda,
        Icons.error_outline,
      ),
      TipoFeedback.aviso => (
        c.alerta,
        c.alertaFundo,
        c.alertaBorda,
        Icons.info_outline,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borda),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: cor, fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Variações visuais de [FeedbackBox].
enum TipoFeedback { sucesso, erro, aviso }

/// Região de feedback de uma tela: mostra o sucesso ou os erros da última ação
/// ([ResultadoOperacao]) e, quando chega um resultado novo, rola a tela até a
/// mensagem. Sem isso, em celulares o botão de enviar fica longe do topo e a
/// pessoa não percebe que algo aconteceu.
class AreaFeedback extends StatefulWidget {
  const AreaFeedback({super.key, required this.resultado});

  /// Resultado da última ação (nulo = nada a mostrar).
  final ResultadoOperacao? resultado;

  @override
  State<AreaFeedback> createState() => _AreaFeedbackState();
}

class _AreaFeedbackState extends State<AreaFeedback> {
  @override
  void didUpdateWidget(covariant AreaFeedback antigo) {
    super.didUpdateWidget(antigo);
    final novo = widget.resultado;
    final temMensagem = novo != null && (novo.temSucesso || novo.temErro);

    // `identical`: cada ação gera um resultado novo, mesmo que o texto se repita
    if (temMensagem && !identical(novo, antigo.resultado)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultado = widget.resultado;
    if (resultado == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedbackBox.sucesso(resultado.temSucesso ? resultado.mensagem : null),
        FeedbackBox.erros(resultado.erros),
      ],
    );
  }
}
