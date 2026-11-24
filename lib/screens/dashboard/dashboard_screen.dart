import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../models/painel.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tela_padrao.dart';
import '../../widgets/titulos.dart';

/// Painel principal — equivale a app/views/dashboard/painel.php.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ResumoPainel? _resumo;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final resposta = await context.read<AppState>().carregarResumo();
    if (!mounted) return;
    setState(() {
      _resumo = resposta.dados ?? _resumo;
      _erro = resposta.erro;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ehAdmin = context.watch<AppState>().ehAdmin;
    final resumo = _resumo;

    return TelaPadrao(
      aoAtualizar: _carregar,
      children: [
        const TituloPagina(
          'Painel',
          subtitulo: 'Verifique como anda a produção da empresa',
          grande: true,
        ),
        if (_carregando) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        if (_erro != null) ...[
          FeedbackBox.erros(['Não foi possível carregar o resumo. $_erro']),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _CartoesResumo(resumo: resumo),
        const SizedBox(height: 28),
        if (resumo != null && resumo.atuais.isNotEmpty) ...[
          _ValoresAtuais(atuais: resumo.atuais),
          const SizedBox(height: 8),
        ],
        if (resumo != null && resumo.alertasRecentes.isNotEmpty) ...[
          _AlertasRecentes(alertas: resumo.alertasRecentes),
          const SizedBox(height: 8),
        ],
        _MenuAtalhos(ehAdmin: ehAdmin),
      ],
    );
  }
}

/// Números de resumo (equivalem aos `.stat-card` do web). Irregularidade
/// ambiental e falha de comunicação são contadas SEPARADAMENTE.
class _CartoesResumo extends StatelessWidget {
  const _CartoesResumo({required this.resumo});

  final ResumoPainel? resumo;

  @override
  Widget build(BuildContext context) {
    final r = resumo;
    String n(int Function(ResumoPainel) f) => r == null ? '—' : '${f(r)}';

    final cartoes = [
      _CartaoNumero(
        valor: n((r) => r.estoquesTotal),
        rotulo: 'Estoques monitorados',
      ),
      _CartaoNumero(
        valor: r == null ? '—' : '${r.sensoresOnline} / ${r.sensoresAtivos}',
        rotulo: 'Sensores online',
      ),
      _CartaoNumero(
        valor: n((r) => r.alertasPendentes),
        rotulo: 'Alertas em aberto',
      ),
      _CartaoNumero(
        valor: n((r) => r.estoquesIrregulares),
        rotulo: 'Estoques em atenção/crítico',
      ),
      _CartaoNumero(
        valor: n((r) => r.estoquesComunicacao),
        rotulo: 'Estoques com falha de comunicação',
      ),
      _CartaoNumero(
        valor: r?.ultimaAtualizacao ?? '—',
        rotulo: 'Última atualização',
      ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        const espaco = 14.0;
        final colunas = restricoes.maxWidth > 820
            ? 3
            : (restricoes.maxWidth > 460 ? 2 : 1);
        final largura =
            (restricoes.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final cartao in cartoes) SizedBox(width: largura, child: cartao),
          ],
        );
      },
    );
  }
}

/// Valor mais recente de cada sensor (`resumo.atuais`), com a situação de
/// comunicação — um sensor sem comunicação NUNCA aparece como "normal".
class _ValoresAtuais extends StatelessWidget {
  const _ValoresAtuais({required this.atuais});

  final List<ValorAtual> atuais;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloCartao('Valores atuais dos sensores'),
          for (final a in atuais)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.texto,
                          ),
                        ),
                        Text(
                          '${a.estoqueNome} · ${a.tipo.label}',
                          style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        a.valor == null
                            ? '—'
                            : '${a.valor!.toStringAsFixed(1).replaceAll('.', ',')} ${a.tipo.unidade}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          color: c.texto,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _SeloSituacao(atual: a),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeloSituacao extends StatelessWidget {
  const _SeloSituacao({required this.atual});

  final ValorAtual atual;

  @override
  Widget build(BuildContext context) {
    if (atual.comunicacao == 'inativo') {
      return const StatusBadge(texto: 'Inativo', tom: TomBadge.neutro);
    }
    if (!atual.online) {
      return const StatusBadge(texto: 'Sem comunicação', tom: TomBadge.neutro);
    }
    return switch (atual.situacao) {
      'critico' => const StatusBadge(texto: 'Crítico', tom: TomBadge.erro),
      'atencao' => const StatusBadge(texto: 'Atenção', tom: TomBadge.alerta),
      _ => const StatusBadge(texto: 'Normal', tom: TomBadge.sucesso),
    };
  }
}

/// Alertas ainda não resolvidos (`resumo.alertas_recentes`, até 6).
class _AlertasRecentes extends StatelessWidget {
  const _AlertasRecentes({required this.alertas});

  final List<AlertaResumo> alertas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloCartao('Alertas recentes'),
          for (final a in alertas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge.severidade(Severidade.porChave(a.severidade)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.mensagem, style: TextStyle(color: c.texto)),
                        Text(
                          '${a.estoqueNome} · ${a.sensorNome} · '
                          '${StatusAlerta.porChave(a.status).label}',
                          style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/alertas'),
              child: const Text('Ver todos os alertas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoNumero extends StatelessWidget {
  const _CartaoNumero({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: c.fundoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.borda),
        boxShadow: c.sombra,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.link,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.5,
              color: c.textoSuave,
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalhos para as demais seções. Gestão de Sensores e de Cadastro são
/// exclusivas de administradores — usuário comum usa a Consulta de Sensores.
class _MenuAtalhos extends StatelessWidget {
  const _MenuAtalhos({required this.ehAdmin});

  final bool ehAdmin;

  @override
  Widget build(BuildContext context) {
    final itens = <_Atalho>[
      const _Atalho(Icons.warehouse_outlined, 'Estoques', '/estoques'),
      const _Atalho(Icons.show_chart, 'Gráficos de Sensores', '/graficos'),
      const _Atalho(Icons.warning_amber_rounded, 'Alertas', '/alertas'),
      const _Atalho(Icons.description_outlined, 'Relatórios', '/relatorios'),
      const _Atalho(
        Icons.list_alt_outlined,
        'Consulta de Sensores',
        '/sensores/listar',
      ),
      if (ehAdmin)
        const _Atalho(Icons.sensors, 'Gestão de Sensores', '/sensores/gestao'),
      if (ehAdmin)
        const _Atalho(
          Icons.groups_2_outlined,
          'Gestão de Cadastro',
          '/usuarios',
        ),
      const _Atalho(Icons.account_circle_outlined, 'Meu perfil', '/perfil'),
    ];

    // Colunas conforme a largura: celular 1, tablet 2, computador 3 (com 2
    // colunas num celular os nomes das seções quebrariam no meio da palavra).
    return LayoutBuilder(
      builder: (context, restricoes) {
        final largura = restricoes.maxWidth;
        final colunas = largura < 560 ? 1 : (largura < 820 ? 2 : 3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itens.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, i) => _CartaoAtalho(atalho: itens[i]),
        );
      },
    );
  }
}

class _Atalho {
  final IconData icone;
  final String titulo;
  final String rota;

  const _Atalho(this.icone, this.titulo, this.rota);
}

/// Cartão de atalho; a borda ganha a cor primária ao passar o mouse.
class _CartaoAtalho extends StatefulWidget {
  const _CartaoAtalho({required this.atalho});

  final _Atalho atalho;

  @override
  State<_CartaoAtalho> createState() => _CartaoAtalhoState();
}

class _CartaoAtalhoState extends State<_CartaoAtalho> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final atalho = widget.atalho;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(atalho.rota),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.fundoCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _sobre ? c.primaria : c.borda),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.infoFundo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(atalho.icone, size: 22, color: c.link),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    atalho.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                      color: c.texto,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textoFraco),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
