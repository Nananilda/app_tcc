import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../widgets/campo_selecao.dart';
import '../../widgets/linha_campos.dart';
import '../../widgets/titulos.dart';

/// Par de campos "Tipo de Usuário" + "Status da Conta", comum aos formulários
/// de cadastro e de edição.
class CamposAcessoUsuario extends StatelessWidget {
  const CamposAcessoUsuario({
    super.key,
    required this.tipo,
    required this.status,
    required this.aoMudarTipo,
    required this.aoMudarStatus,
    this.explicarTipo = false,
    this.dicaStatus,
  });

  final TipoUsuario tipo;
  final StatusConta status;
  final ValueChanged<TipoUsuario> aoMudarTipo;
  final ValueChanged<StatusConta> aoMudarStatus;

  /// Mostra, sob o tipo, o que cada perfil pode fazer no sistema.
  final bool explicarTipo;

  /// Texto de apoio sob o status (opcional).
  final String? dicaStatus;

  /// O que cada perfil pode fazer — mesmo texto exibido no sistema web.
  static String descricaoDoTipo(TipoUsuario tipo) {
    return tipo == TipoUsuario.admin
        ? 'Acesso: Total — inclui gestão de usuários, sensores e configurações do sistema.'
        : 'Acesso: Visualização de sensores, gráficos e relatórios.';
  }

  @override
  Widget build(BuildContext context) {
    return LinhaCampos(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampoSelecao<TipoUsuario>(
              rotulo: 'Tipo de Usuário *',
              valor: tipo,
              itens: [
                for (final t in TipoUsuario.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => aoMudarTipo(v ?? TipoUsuario.usuario),
            ),
            if (explicarTipo) DicaCampo(descricaoDoTipo(tipo)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampoSelecao<StatusConta>(
              rotulo: 'Status da Conta *',
              valor: status,
              itens: [
                for (final s in StatusConta.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => aoMudarStatus(v ?? StatusConta.ativo),
            ),
            if (dicaStatus != null) DicaCampo(dicaStatus!),
          ],
        ),
      ],
    );
  }
}
