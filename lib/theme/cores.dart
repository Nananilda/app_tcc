import 'package:flutter/material.dart';

/// Tokens de cor do ÁKRON para os temas claro e escuro.
///
/// Os nomes espelham as variáveis CSS do sistema web (public/assets/css/
/// style.css): `fundoCard` ↔ `--cor-fundo-card`, `textoSuave` ↔
/// `--cor-texto-suave` etc. Assim web e app compartilham uma única paleta, que
/// nasce do azul-ardósia da logo (#607487).
///
/// Como usar nas telas (nunca escreva cores fixas):
/// ```dart
/// final c = context.cores;
/// Container(color: c.fundoCard, ...);
/// ```
@immutable
class AkronCores extends ThemeExtension<AkronCores> {
  const AkronCores({
    required this.fundo,
    required this.fundoCard,
    required this.fundoCardAlt,
    required this.fundoEntrada,
    required this.borda,
    required this.bordaForte,
    required this.texto,
    required this.textoSuave,
    required this.textoFraco,
    required this.marca,
    required this.primaria,
    required this.primariaHover,
    required this.textoSobrePrimaria,
    required this.link,
    required this.foco,
    required this.sucesso,
    required this.sucessoFundo,
    required this.sucessoBorda,
    required this.erro,
    required this.erroFundo,
    required this.erroBorda,
    required this.erroHover,
    required this.textoSobreErro,
    required this.alerta,
    required this.alertaFundo,
    required this.alertaBorda,
    required this.infoFundo,
    required this.graficoLinha,
    required this.graficoArea,
    required this.graficoGrade,
    required this.graficoTexto,
    required this.graficoCritico,
    required this.graficoAtencao,
    required this.graficoInfo,
    required this.loginTopo,
    required this.loginBase,
    required this.sombra,
  });

  // ── Superfícies ──────────────────────────────────────────────────────────
  final Color fundo;
  final Color fundoCard;
  final Color fundoCardAlt;
  final Color fundoEntrada;
  final Color borda;
  final Color bordaForte;

  // ── Texto ────────────────────────────────────────────────────────────────
  final Color texto;
  final Color textoSuave;
  final Color textoFraco;

  // ── Marca (derivada da logo) ─────────────────────────────────────────────
  /// Cor aplicada à logo (símbolo e nome).
  final Color marca;

  /// Botões e destaques sólidos.
  final Color primaria;
  final Color primariaHover;
  final Color textoSobrePrimaria;

  /// Links e títulos de seção.
  final Color link;

  /// Anel de foco dos campos.
  final Color foco;

  // ── Semânticas ───────────────────────────────────────────────────────────
  final Color sucesso;
  final Color sucessoFundo;
  final Color sucessoBorda;
  final Color erro;
  final Color erroFundo;
  final Color erroBorda;

  /// Fundo do botão de perigo ao passar o mouse/pressionar.
  final Color erroHover;

  /// Texto sobre o botão de perigo (sólido).
  final Color textoSobreErro;
  final Color alerta;
  final Color alertaFundo;
  final Color alertaBorda;
  final Color infoFundo;

  // ── Gráficos ─────────────────────────────────────────────────────────────
  final Color graficoLinha;
  final Color graficoArea;
  final Color graficoGrade;
  final Color graficoTexto;
  final Color graficoCritico;
  final Color graficoAtencao;
  final Color graficoInfo;

  // ── Tela de login e profundidade ─────────────────────────────────────────
  final Color loginTopo;
  final Color loginBase;
  final List<BoxShadow> sombra;

  /// Tema claro (padrão quando o sistema operacional está no modo claro).
  static const claro = AkronCores(
    fundo: Color(0xFFF1F4F8),
    fundoCard: Color(0xFFFFFFFF),
    fundoCardAlt: Color(0xFFE9EEF4),
    fundoEntrada: Color(0xFFFFFFFF),
    borda: Color(0xFFD2DBE5),
    bordaForte: Color(0xFFAEBDCB),
    texto: Color(0xFF141F2B),
    textoSuave: Color(0xFF4A5B6C),
    textoFraco: Color(0xFF566A7F),
    marca: Color(0xFF607487),
    primaria: Color(0xFF4F6B85),
    primariaHover: Color(0xFF3E5973),
    textoSobrePrimaria: Color(0xFFFFFFFF),
    link: Color(0xFF3E5973),
    foco: Color(0xFF4F6B85),
    sucesso: Color(0xFF0C6B45),
    sucessoFundo: Color.fromRGBO(12, 107, 69, 0.10),
    sucessoBorda: Color.fromRGBO(12, 107, 69, 0.30),
    erro: Color(0xFFB32A38),
    erroFundo: Color.fromRGBO(179, 42, 56, 0.09),
    erroBorda: Color.fromRGBO(179, 42, 56, 0.30),
    erroHover: Color(0xFF8F2230),
    textoSobreErro: Color(0xFFFFFFFF),
    alerta: Color(0xFF7D5200),
    alertaFundo: Color.fromRGBO(224, 168, 63, 0.20),
    alertaBorda: Color.fromRGBO(125, 82, 0, 0.30),
    infoFundo: Color.fromRGBO(79, 107, 133, 0.12),
    graficoLinha: Color(0xFF4F6B85),
    graficoArea: Color.fromRGBO(79, 107, 133, 0.16),
    graficoGrade: Color(0xFFD9E1EA),
    graficoTexto: Color(0xFF4A5B6C),
    graficoCritico: Color.fromRGBO(194, 49, 63, 0.78),
    graficoAtencao: Color.fromRGBO(214, 154, 31, 0.85),
    graficoInfo: Color.fromRGBO(79, 107, 133, 0.78),
    loginTopo: Color(0xFFFFFFFF),
    loginBase: Color(0xFFE3E9F0),
    sombra: [
      BoxShadow(
        color: Color.fromRGBO(20, 31, 43, 0.06),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color.fromRGBO(20, 31, 43, 0.08),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  /// Tema escuro.
  static const escuro = AkronCores(
    fundo: Color(0xFF0D1218),
    fundoCard: Color(0xFF161F29),
    fundoCardAlt: Color(0xFF1D2733),
    fundoEntrada: Color(0xFF0D1218),
    borda: Color(0xFF2A3846),
    bordaForte: Color(0xFF3E5163),
    texto: Color(0xFFE9EEF3),
    textoSuave: Color(0xFF9FB0C0),
    textoFraco: Color(0xFF7B8EA2),
    marca: Color(0xFF9DB3C8),
    primaria: Color(0xFF6A89A7),
    primariaHover: Color(0xFF4F6B85),
    textoSobrePrimaria: Color(0xFF0A121A),
    link: Color(0xFF8CA6BE),
    foco: Color(0xFF8CA6BE),
    sucesso: Color(0xFF3FC98A),
    sucessoFundo: Color.fromRGBO(63, 201, 138, 0.12),
    sucessoBorda: Color.fromRGBO(63, 201, 138, 0.35),
    erro: Color(0xFFEF7480),
    erroFundo: Color.fromRGBO(239, 116, 128, 0.12),
    erroBorda: Color.fromRGBO(239, 116, 128, 0.35),
    erroHover: Color(0xFFF59AA3),
    textoSobreErro: Color(0xFF2B0709),
    alerta: Color(0xFFE0A83F),
    alertaFundo: Color.fromRGBO(224, 168, 63, 0.12),
    alertaBorda: Color.fromRGBO(224, 168, 63, 0.35),
    infoFundo: Color.fromRGBO(106, 137, 167, 0.16),
    graficoLinha: Color(0xFF8CA6BE),
    graficoArea: Color.fromRGBO(106, 137, 167, 0.18),
    graficoGrade: Color(0xFF2A3846),
    graficoTexto: Color(0xFF9FB0C0),
    graficoCritico: Color.fromRGBO(229, 99, 111, 0.75),
    graficoAtencao: Color.fromRGBO(224, 168, 63, 0.75),
    graficoInfo: Color.fromRGBO(106, 137, 167, 0.80),
    loginTopo: Color(0xFF182330),
    loginBase: Color(0xFF0D1218),
    sombra: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.35),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  @override
  AkronCores copyWith({Color? fundo, Color? marca}) {
    // Só os campos usados em personalizações pontuais; os demais vêm do tema.
    return AkronCores(
      fundo: fundo ?? this.fundo,
      fundoCard: fundoCard,
      fundoCardAlt: fundoCardAlt,
      fundoEntrada: fundoEntrada,
      borda: borda,
      bordaForte: bordaForte,
      texto: texto,
      textoSuave: textoSuave,
      textoFraco: textoFraco,
      marca: marca ?? this.marca,
      primaria: primaria,
      primariaHover: primariaHover,
      textoSobrePrimaria: textoSobrePrimaria,
      link: link,
      foco: foco,
      sucesso: sucesso,
      sucessoFundo: sucessoFundo,
      sucessoBorda: sucessoBorda,
      erro: erro,
      erroFundo: erroFundo,
      erroBorda: erroBorda,
      erroHover: erroHover,
      textoSobreErro: textoSobreErro,
      alerta: alerta,
      alertaFundo: alertaFundo,
      alertaBorda: alertaBorda,
      infoFundo: infoFundo,
      graficoLinha: graficoLinha,
      graficoArea: graficoArea,
      graficoGrade: graficoGrade,
      graficoTexto: graficoTexto,
      graficoCritico: graficoCritico,
      graficoAtencao: graficoAtencao,
      graficoInfo: graficoInfo,
      loginTopo: loginTopo,
      loginBase: loginBase,
      sombra: sombra,
    );
  }

  /// Interpola entre dois temas (usado na animação de troca claro ↔ escuro).
  @override
  AkronCores lerp(ThemeExtension<AkronCores>? other, double t) {
    if (other is! AkronCores) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AkronCores(
      fundo: c(fundo, other.fundo),
      fundoCard: c(fundoCard, other.fundoCard),
      fundoCardAlt: c(fundoCardAlt, other.fundoCardAlt),
      fundoEntrada: c(fundoEntrada, other.fundoEntrada),
      borda: c(borda, other.borda),
      bordaForte: c(bordaForte, other.bordaForte),
      texto: c(texto, other.texto),
      textoSuave: c(textoSuave, other.textoSuave),
      textoFraco: c(textoFraco, other.textoFraco),
      marca: c(marca, other.marca),
      primaria: c(primaria, other.primaria),
      primariaHover: c(primariaHover, other.primariaHover),
      textoSobrePrimaria: c(textoSobrePrimaria, other.textoSobrePrimaria),
      link: c(link, other.link),
      foco: c(foco, other.foco),
      sucesso: c(sucesso, other.sucesso),
      sucessoFundo: c(sucessoFundo, other.sucessoFundo),
      sucessoBorda: c(sucessoBorda, other.sucessoBorda),
      erro: c(erro, other.erro),
      erroFundo: c(erroFundo, other.erroFundo),
      erroBorda: c(erroBorda, other.erroBorda),
      erroHover: c(erroHover, other.erroHover),
      textoSobreErro: c(textoSobreErro, other.textoSobreErro),
      alerta: c(alerta, other.alerta),
      alertaFundo: c(alertaFundo, other.alertaFundo),
      alertaBorda: c(alertaBorda, other.alertaBorda),
      infoFundo: c(infoFundo, other.infoFundo),
      graficoLinha: c(graficoLinha, other.graficoLinha),
      graficoArea: c(graficoArea, other.graficoArea),
      graficoGrade: c(graficoGrade, other.graficoGrade),
      graficoTexto: c(graficoTexto, other.graficoTexto),
      graficoCritico: c(graficoCritico, other.graficoCritico),
      graficoAtencao: c(graficoAtencao, other.graficoAtencao),
      graficoInfo: c(graficoInfo, other.graficoInfo),
      loginTopo: c(loginTopo, other.loginTopo),
      loginBase: c(loginBase, other.loginBase),
      sombra: t < 0.5 ? sombra : other.sombra,
    );
  }
}

/// Atalho para as cores do tema atual: `context.cores.fundoCard`.
extension AkronCoresContexto on BuildContext {
  AkronCores get cores => Theme.of(this).extension<AkronCores>()!;
}
