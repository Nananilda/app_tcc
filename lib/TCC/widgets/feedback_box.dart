import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Caixas de feedback (sucesso / erro), equivalentes às classes
/// .msg-sucesso / .msg-erro do CSS original (public/assets/css/style.css).
class FeedbackBox extends StatelessWidget {
  final String texto;
  final bool erro;

  const FeedbackBox._({required this.texto, required this.erro});

  /// Caixa verde com uma mensagem de sucesso. [mensagem] pode ser nulo —
  /// nesse caso o widget não é exibido (retorna [SizedBox.shrink]).
  static Widget sucesso(String? mensagem) {
    if (mensagem == null || mensagem.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FeedbackBox._(texto: mensagem, erro: false),
    );
  }

  /// Caixa vermelha listando uma ou mais mensagens de erro.
  static Widget erros(List<String> mensagens) {
    if (mensagens.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FeedbackBox._(texto: mensagens.join('\n'), erro: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = erro ? AppColors.erro : AppColors.sucesso;
    final fundo = erro ? AppColors.erroFundo : AppColors.sucessoFundo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            erro ? Icons.error_outline : Icons.check_circle_outline,
            color: cor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: cor, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
