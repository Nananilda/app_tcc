import 'package:flutter/material.dart';

import '../theme/cores.dart';

/// Tabela de dados com o visual do app (cabeçalho em caixa-alta, linhas com
/// divisória, rolagem horizontal em telas estreitas). Equivale às `<table>` do
/// sistema web.
///
/// ```dart
/// TabelaDados(
///   colunas: ['ID', 'Nome'],
///   linhas: [[Text('1'), Text('Sensor A')]],
/// )
/// ```
class TabelaDados extends StatelessWidget {
  const TabelaDados({
    super.key,
    required this.colunas,
    required this.linhas,
    this.centralizar = const {},
  });

  /// Títulos das colunas (exibidos em caixa-alta).
  final List<String> colunas;

  /// Cada item é uma linha: um widget por coluna, na mesma ordem de [colunas].
  final List<List<Widget>> linhas;

  /// Índices das colunas numéricas, que ficam alinhadas à direita.
  final Set<int> centralizar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;

    return LayoutBuilder(
      builder: (context, restricoes) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // A tabela ocupa pelo menos a largura do cartão
              constraints: BoxConstraints(minWidth: restricoes.maxWidth),
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
                columnSpacing: 28,
                horizontalMargin: 16,
                dividerThickness: 1,
                border: TableBorder(
                  horizontalInside: BorderSide(color: c.borda),
                ),
                columns: [
                  for (var i = 0; i < colunas.length; i++)
                    DataColumn(
                      label: Text(colunas[i].toUpperCase()),
                      numeric: centralizar.contains(i),
                    ),
                ],
                rows: [
                  for (final linha in linhas)
                    DataRow(
                      cells: [for (final celula in linha) DataCell(celula)],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
