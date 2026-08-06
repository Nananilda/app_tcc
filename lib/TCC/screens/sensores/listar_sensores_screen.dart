import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/sensor.dart';
import '../../state/app_state.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/topbar.dart';

/// Consulta somente leitura de sensores — equivalente a listar_sensores.php.
class ListarSensoresScreen extends StatelessWidget {
  const ListarSensoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sensores = app.sensores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: const Topbar(titulo: 'IndustrialOS — Sensores'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consulta de Sensores',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Lista somente leitura. Para cadastrar ou '
                              'alterar sensores, acesse a ',
                        ),
                        TextSpan(
                          text: 'Gestão de Sensores',
                          style: const TextStyle(
                            color: AppColors.primaria,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go('/sensores/gestao'),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: sensores.isEmpty
                        ? const Text(
                            'Nenhum sensor cadastrado.',
                            style: TextStyle(
                              color: AppColors.textoSuave,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Localização')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Cadastrado em')),
                              ],
                              rows: sensores
                                  .map(
                                    (s) => DataRow(
                                      cells: [
                                        DataCell(Text('${s.id}')),
                                        DataCell(Text(s.nome)),
                                        DataCell(Text(s.tipo.label)),
                                        DataCell(Text(s.localizacao ?? '—')),
                                        DataCell(
                                          StatusBadge(
                                            texto: s.status.label,
                                            positivo:
                                                s.status == StatusSensor.ativo,
                                          ),
                                        ),
                                        DataCell(
                                          Text(dataFmt.format(s.criadoEm)),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                  NavRodape(
                    links: [
                      NavRodapeLink(
                        'Ver gráficos →',
                        () => context.go('/graficos'),
                      ),
                      NavRodapeLink(
                        '← Voltar ao painel',
                        () => context.go('/painel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
