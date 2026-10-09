import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Campo de seleção (lista suspensa) com o visual dos demais campos do app.
///
/// É um widget CONTROLADO: sempre exibe o [valor] recebido, então mudanças
/// feitas por código (ex.: "Limpar filtros") aparecem na hora. Substitui o
/// `DropdownButtonFormField(value: ...)`, descontinuado no Flutter atual.
///
/// Para validação em formulários, envolva-o em um `FormField` e repasse
/// `state.errorText` em [erro] (veja a tela de gestão de sensores).
class CampoSelecao<T> extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.itens,
    required this.onChanged,
    this.dica,
    this.erro,
  });

  /// Rótulo exibido acima do campo.
  final String rotulo;

  /// Valor selecionado (null = nada selecionado).
  final T? valor;

  final List<DropdownMenuItem<T>> itens;
  final ValueChanged<T?>? onChanged;

  /// Texto mostrado quando [valor] é nulo (ex.: "— selecione —").
  final String? dica;

  /// Mensagem de erro de validação (borda e texto vermelhos).
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: rotulo,
        errorText: erro,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          isDense: true,
          items: itens,
          onChanged: onChanged,
          hint: dica == null
              ? null
              : Text(dica!, style: TextStyle(color: c.textoFraco)),
          icon: Icon(Icons.keyboard_arrow_down, color: c.textoSuave),
          dropdownColor: c.fundoCard,
          borderRadius: BorderRadius.circular(8),
          style: TextStyle(fontFamily: 'Inter', fontSize: 14.5, color: c.texto),
        ),
      ),
    );
  }
}
