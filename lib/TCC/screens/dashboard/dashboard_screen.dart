import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/topbar.dart';

/// Painel principal — equivalente a app/views/dashboard/painel.php.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final resumo = app.obterResumoDashboard();
    final formatoHora = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: const Topbar(),
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
                    'Painel',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifique como anda a produção da empresa',
                    style: TextStyle(color: AppColors.textoSuave, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final largo = constraints.maxWidth > 620;
                      final cards = [
                        _StatCard(
                          valor:
                              '${resumo['sensoresAtivos']} / ${resumo['sensoresTotal']}',
                          label: 'Sensores ativos',
                        ),
                        _StatCard(
                          valor: '${resumo['alertasPendentes']}',
                          label: 'Alertas pendentes',
                        ),
                        _StatCard(
                          valor: formatoHora.format(
                            resumo['ultimaAtualizacao'] as DateTime,
                          ),
                          label: 'Última atualização',
                        ),
                      ];
                      if (largo) {
                        return Row(
                          children: cards
                              .map((c) => Expanded(child: c))
                              .expand((w) => [w, const SizedBox(width: 16)])
                              .toList()
                            ..removeLast(),
                        );
                      }
                      return Column(children: cards);
                    },
                  ),
                  const SizedBox(height: 28),
                  _MenuGrid(ehAdmin: app.ehAdmin),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        app.logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                    ),
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

class _StatCard extends StatelessWidget {
  final String valor;
  final String label;

  const _StatCard({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final bool ehAdmin;

  const _MenuGrid({required this.ehAdmin});

  @override
  Widget build(BuildContext context) {
    final itens = <_MenuItemData>[
      const _MenuItemData('📈', 'Gráficos de Sensores', '/graficos'),
      const _MenuItemData('⚠️', 'Alertas', '/alertas'),
      const _MenuItemData('📄', 'Relatórios', '/relatorios'),
      const _MenuItemData('🛰️', 'Gestão de Sensores', '/sensores/gestao'),
      const _MenuItemData('📋', 'Consulta de Sensores', '/sensores/listar'),
      if (ehAdmin) const _MenuItemData('👤', 'Gestão de Cadastro', '/usuarios'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itens.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, i) {
        final item = itens[i];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.rota),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fundoCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borda),
            ),
            child: Row(
              children: [
                Text(item.icone, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textoSuave,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItemData {
  final String icone;
  final String titulo;
  final String rota;

  const _MenuItemData(this.icone, this.titulo, this.rota);
}
