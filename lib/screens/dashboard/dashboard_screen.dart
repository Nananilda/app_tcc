import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/painel.dart';
import '../../state/app_state.dart';
import '../../theme/cores.dart';
import '../../widgets/feedback_box.dart';
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
        _MenuAtalhos(ehAdmin: ehAdmin),
      ],
    );
  }
}

/// Os três números de resumo (equivalem aos `.stat-card` do web).
class _CartoesResumo extends StatelessWidget {
  const _CartoesResumo({required this.resumo});

  final ResumoPainel? resumo;

  @override
  Widget build(BuildContext context) {
    final cartoes = [
      _CartaoNumero(
        valor: resumo == null
            ? '—'
            : '${resumo!.sensoresAtivos} / ${resumo!.sensoresTotal}',
        rotulo: 'Sensores ativos',
      ),
      _CartaoNumero(
        valor: resumo == null ? '—' : '${resumo!.alertasPendentes}',
        rotulo: 'Alertas pendentes',
      ),
      _CartaoNumero(
        valor: resumo?.ultimaAtualizacao ?? '—',
        rotulo: 'Última atualização',
      ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth > 620) {
          return Row(
            children: [
              for (var i = 0; i < cartoes.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cartoes[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final cartao in cartoes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: cartao,
              ),
          ],
        );
      },
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
