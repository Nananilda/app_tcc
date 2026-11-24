import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';

/// Escolha dos estoques que um FUNCIONÁRIO pode consultar (cadastro e edição
/// de usuário). Administrador enxerga todos os estoques, independentemente
/// desta lista — por isso ela só aparece para o perfil Funcionário.
class SelecaoEstoquesUsuario extends StatefulWidget {
  const SelecaoEstoquesUsuario({
    super.key,
    required this.tipo,
    required this.selecionados,
    required this.aoMudar,
  });

  final TipoUsuario tipo;
  final Set<int> selecionados;
  final ValueChanged<Set<int>> aoMudar;

  @override
  State<SelecaoEstoquesUsuario> createState() =>
      _SelecaoEstoquesUsuarioState();
}

class _SelecaoEstoquesUsuarioState extends State<SelecaoEstoquesUsuario> {
  @override
  void initState() {
    super.initState();
    // O administrador logado vê todos os estoques; a lista é carregada uma vez.
    final app = context.read<AppState>();
    if (app.estoques.isEmpty) app.carregarEstoques();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (widget.tipo == TipoUsuario.admin) {
      return Text(
        'O administrador tem acesso a todos os estoques.',
        style: TextStyle(color: c.textoSuave, fontSize: 13),
      );
    }

    final estoques = context.watch<AppState>().estoques;
    if (estoques.isEmpty) {
      return Text(
        'Nenhum estoque cadastrado. Cadastre um estoque para liberar o acesso.',
        style: TextStyle(color: c.textoSuave, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in estoques)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(e.ativo ? e.nome : '${e.nome} (inativo)'),
            value: widget.selecionados.contains(e.id),
            onChanged: (marcado) {
              final novo = {...widget.selecionados};
              marcado == true ? novo.add(e.id) : novo.remove(e.id);
              widget.aoMudar(novo);
            },
          ),
        Text(
          'Sem nenhum estoque marcado, o funcionário não verá dados de estoque.',
          style: TextStyle(color: c.textoSuave, fontSize: 12.5),
        ),
      ],
    );
  }
}
