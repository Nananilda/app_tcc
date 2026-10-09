import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/nav_rodape.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Tela de alertas — equivale a app/views/graficos/alerta.php.
///
/// Mostra, por severidade, quantos alertas estão pendentes (cartões + gráfico
/// de barras) e o histórico recente. Administradores podem marcar alertas
/// como resolvidos.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  ResultadoOperacao? _feedback;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final resultado = await context.read<AppState>().carregarAlertas();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _feedback = resultado;
    });
  }

  Future<void> _resolver(int id) async {
    final resultado = await context.read<AppState>().resolverAlerta(id);
    if (!mounted) return;
    setState(() => _feedback = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final alertas = app.alertas;
    final contagem = app.contarAlertasPorSeveridade();

    return TelaPadrao(
      secao: 'Alertas',
      aoAtualizar: _carregar,
      children: [
        const TituloPagina('Alertas dos Sensores'),
        AreaFeedback(resultado: _feedback),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],

        // Cartões de resumo por severidade (somente alertas pendentes)
        _CartoesSeveridade(contagem: contagem),
        const SizedBox(height: 20),

        // Gráfico de barras: pendentes por severidade
        SectionCard(
          child: SizedBox(
            height: 240,
            child: Column(
              children: [
                Text(
                  'Alertas pendentes por severidade',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.cores.graficoTexto,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _GraficoSeveridade(contagem: contagem)),
              ],
            ),
          ),
        ),

        // Histórico
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloCartao('Histórico recente'),
              if (alertas.isEmpty)
                const TextoVazio('Nenhum alerta registrado.')
              else
                for (var i = 0; i < alertas.length; i++)
                  _ItemAlerta(
                    alerta: alertas[i],
                    ultimo: i == alertas.length - 1,
                    podeResolver: app.ehAdmin && !alertas[i].resolvido,
                    aoResolver: () => _resolver(alertas[i].id),
                  ),
            ],
          ),
        ),

        NavRodape(
          links: [
            NavRodapeLink(
              '← Gráficos de sensores',
              () => context.go('/graficos'),
            ),
            NavRodapeLink('← Voltar ao painel', () => context.go('/painel')),
          ],
        ),
      ],
    );
  }
}

/// Três cartões (Críticos / Atenção / Informativos) com a contagem de pendentes.
class _CartoesSeveridade extends StatelessWidget {
  const _CartoesSeveridade({required this.contagem});

  final Map<Severidade, int> contagem;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cartoes = [
      _CartaoSeveridade(
        valor: contagem[Severidade.critico] ?? 0,
        rotulo: 'Críticos',
        fundo: c.erroFundo,
        destaque: c.erro,
      ),
      _CartaoSeveridade(
        valor: contagem[Severidade.atencao] ?? 0,
        rotulo: 'Atenção',
        fundo: c.alertaFundo,
        destaque: c.alerta,
      ),
      _CartaoSeveridade(
        valor: contagem[Severidade.info] ?? 0,
        rotulo: 'Informativos',
        fundo: c.infoFundo,
        destaque: c.primaria,
      ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth > 560) {
          return Row(
            children: [
              for (var i = 0; i < cartoes.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: cartoes[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final cartao in cartoes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: cartao,
              ),
          ],
        );
      },
    );
  }
}

class _CartaoSeveridade extends StatelessWidget {
  const _CartaoSeveridade({
    required this.valor,
    required this.rotulo,
    required this.fundo,
    required this.destaque,
  });

  final int valor;
  final String rotulo;
  final Color fundo;
  final Color destaque;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    // Faixa colorida no topo: o Flutter não permite cantos arredondados com
    // bordas de cores diferentes, então a faixa é um filho recortado pelo cartão.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.borda),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: destaque),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$valor',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: c.texto,
                    ),
                  ),
                  Text(rotulo, style: TextStyle(color: c.texto)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras da contagem de alertas pendentes por severidade.
class _GraficoSeveridade extends StatelessWidget {
  const _GraficoSeveridade({required this.contagem});

  final Map<Severidade, int> contagem;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cores = {
      Severidade.critico: c.graficoCritico,
      Severidade.atencao: c.graficoAtencao,
      Severidade.info: c.graficoInfo,
    };
    final maior = contagem.values.fold<int>(0, (a, b) => a > b ? a : b);
    final estiloEixo = TextStyle(color: c.graficoTexto, fontSize: 11);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maior + 1).toDouble(),
        minY: 0,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.graficoGrade, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.fundoCardAlt,
            getTooltipItem: (grupo, indiceGrupo, haste, indiceHaste) =>
                BarTooltipItem(
                  '${Severidade.values[grupo.x].label}: ${haste.toY.toInt()}',
                  TextStyle(
                    color: c.texto,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                child: Text(valor.toInt().toString(), style: estiloEixo),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= Severidade.values.length) {
                  return const SizedBox();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(Severidade.values[i].label, style: estiloEixo),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < Severidade.values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (contagem[Severidade.values[i]] ?? 0).toDouble(),
                  color: cores[Severidade.values[i]],
                  width: 44,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Uma linha do histórico de alertas.
class _ItemAlerta extends StatelessWidget {
  const _ItemAlerta({
    required this.alerta,
    required this.ultimo,
    required this.podeResolver,
    required this.aoResolver,
  });

  final Alerta alerta;
  final bool ultimo;
  final bool podeResolver;
  final VoidCallback aoResolver;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');
    final valor = alerta.valor == null
        ? '—'
        : NumberFormat('#,##0.00', 'pt_BR').format(alerta.valor);

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            StatusBadge.severidade(alerta.severidade),
            Text(
              alerta.sensorTipo.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('— ${alerta.mensagem}'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${alerta.sensorNome ?? alerta.sensorTipo.label} | Valor: $valor | '
          '${dataFmt.format(alerta.criadoEm)} | ${alerta.resolvido ? "Resolvido" : "Pendente"}',
          style: TextStyle(color: c.textoSuave, fontSize: 12.5),
        ),
      ],
    );

    final botao = podeResolver
        ? OutlinedButton(
            onPressed: aoResolver,
            child: const Text('Marcar resolvido'),
          )
        : null;

    return Opacity(
      // Alertas já resolvidos ficam em segundo plano
      opacity: alerta.resolvido ? 0.62 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: ultimo ? null : Border(bottom: BorderSide(color: c.borda)),
        ),
        child: LayoutBuilder(
          builder: (context, restricoes) {
            if (botao == null) return conteudo;
            if (restricoes.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [conteudo, const SizedBox(height: 10), botao],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: conteudo),
                const SizedBox(width: 16),
                botao,
              ],
            );
          },
        ),
      ),
    );
  }
}
