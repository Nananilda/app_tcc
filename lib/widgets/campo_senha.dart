import 'package:flutter/material.dart';

/// Campo de senha com botão "mostrar/ocultar". Faz parte de um `Form`
/// (aceita [validator]) e usa o mesmo visual dos demais campos do app.
class CampoSenha extends StatefulWidget {
  const CampoSenha({
    super.key,
    required this.controller,
    required this.rotulo,
    this.dica,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.aoEnviar,
  });

  final TextEditingController controller;
  final String rotulo;

  /// Texto de exemplo exibido dentro do campo vazio.
  final String? dica;

  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  /// Chamado quando a pessoa confirma pelo teclado (Enter).
  final VoidCallback? aoEnviar;

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visivel,
      maxLength: 128,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.aoEnviar == null
          ? null
          : (_) => widget.aoEnviar!(),
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: widget.dica,
        counterText: '',
        suffixIcon: IconButton(
          tooltip: _visivel ? 'Ocultar senha' : 'Mostrar senha',
          icon: Icon(
            _visivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _visivel = !_visivel),
        ),
      ),
    );
  }
}
