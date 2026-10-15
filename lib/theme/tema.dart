import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cores.dart';

/// Temas claro e escuro do ÁKRON (Material 3).
///
/// Toda a aparência vem de [AkronCores]: aqui só traduzimos esses tokens para
/// os componentes do Material (campos, botões, tabelas, diálogos...). Para
/// alterar uma cor da marca, edite `cores.dart` — os dois temas e todas as
/// telas acompanham.
///
/// Tipografia da marca: Montserrat nos títulos (o lettering da logo é uma
/// geométrica próxima dela) e Inter no restante do texto.
class AkronTema {
  AkronTema._();

  static const String fonteTexto = 'Inter';
  static const String fonteTitulo = 'Montserrat';

  static ThemeData get claro => _montar(Brightness.light, AkronCores.claro);
  static ThemeData get escuro => _montar(Brightness.dark, AkronCores.escuro);

  static ThemeData _montar(Brightness brilho, AkronCores c) {
    final escuro = brilho == Brightness.dark;
    final raio = BorderRadius.circular(8);

    // Esquema de cores do Material gerado a partir dos tokens da marca
    final esquema = ColorScheme(
      brightness: brilho,
      primary: c.primaria,
      onPrimary: c.textoSobrePrimaria,
      secondary: c.primaria,
      onSecondary: c.textoSobrePrimaria,
      error: c.erro,
      onError: c.textoSobreErro,
      surface: c.fundoCard,
      onSurface: c.texto,
      onSurfaceVariant: c.textoSuave,
      outline: c.bordaForte,
      outlineVariant: c.borda,
      surfaceContainerLowest: c.fundo,
      surfaceContainerLow: c.fundoCard,
      surfaceContainer: c.fundoCard,
      surfaceContainerHigh: c.fundoCardAlt,
      surfaceContainerHighest: c.fundoCardAlt,
      surfaceTint: Colors.transparent,
    );

    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: raio,
          borderSide: BorderSide(color: cor, width: largura),
        );

    // Botão sólido: escurece ao passar o mouse/pressionar, como na web
    final botaoSolido = ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: raio)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: fonteTexto,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((estados) {
        if (estados.contains(WidgetState.disabled)) {
          return c.primaria.withValues(alpha: 0.4);
        }
        if (estados.contains(WidgetState.hovered) ||
            estados.contains(WidgetState.pressed)) {
          return c.primariaHover;
        }
        return c.primaria;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((estados) {
        if (estados.contains(WidgetState.disabled)) {
          return c.textoSobrePrimaria.withValues(alpha: 0.7);
        }
        if (estados.contains(WidgetState.hovered) ||
            estados.contains(WidgetState.pressed)) {
          return Colors.white;
        }
        return c.textoSobrePrimaria;
      }),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      extensions: <ThemeExtension<dynamic>>[c],
      fontFamily: fonteTexto,
      textTheme: _textos(c),
      scaffoldBackgroundColor: c.fundo,
      canvasColor: c.fundoCard,
      dividerTheme: DividerThemeData(color: c.borda, space: 32, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.foco,
        selectionColor: c.primaria.withValues(alpha: 0.35),
        selectionHandleColor: c.foco,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.fundoCard,
        foregroundColor: c.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: escuro ? Brightness.light : Brightness.dark,
          statusBarBrightness: escuro ? Brightness.dark : Brightness.light,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.fundoEntrada,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        // Rótulo sempre sobre a borda: campos vazios e preenchidos ficam iguais
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(color: c.textoSuave, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: c.link,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: c.textoFraco),
        errorStyle: TextStyle(color: c.erro, fontSize: 12),
        border: borda(c.borda),
        enabledBorder: borda(c.borda),
        disabledBorder: borda(c.borda.withValues(alpha: 0.6)),
        focusedBorder: borda(c.foco, 1.6),
        errorBorder: borda(c.erro),
        focusedErrorBorder: borda(c.erro, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: botaoSolido),
      filledButtonTheme: FilledButtonThemeData(style: botaoSolido),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.texto,
          disabledForegroundColor: c.textoFraco,
          side: BorderSide(color: c.bordaForte),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: raio),
          textStyle: const TextStyle(
            fontFamily: fonteTexto,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.link,
          shape: RoundedRectangleBorder(borderRadius: raio),
          textStyle: const TextStyle(
            fontFamily: fonteTexto,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textoSuave),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(c.fundoCardAlt),
        dataRowColor: WidgetStateProperty.resolveWith((estados) {
          return estados.contains(WidgetState.hovered)
              ? c.infoFundo
              : Colors.transparent;
        }),
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          fontFamily: fonteTexto,
          color: c.textoSuave,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.5,
        ),
        dataTextStyle: TextStyle(
          fontFamily: fonteTexto,
          color: c.texto,
          fontSize: 13.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.fundoCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.borda),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fonteTitulo,
          color: c.texto,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fonteTexto,
          color: c.textoSuave,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.fundoCardAlt,
        contentTextStyle: TextStyle(
          fontFamily: fonteTexto,
          color: c.texto,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: raio,
          side: BorderSide(color: c.borda),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primaria,
        linearTrackColor: c.fundoCardAlt,
        circularTrackColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.fundoCardAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.borda),
        ),
        textStyle: TextStyle(
          fontFamily: fonteTexto,
          color: c.texto,
          fontSize: 12.5,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.fundoCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.borda),
        ),
      ),
    );
  }

  /// Escala tipográfica: títulos em Montserrat, texto em Inter.
  static TextTheme _textos(AkronCores c) {
    TextStyle inter(
      double tamanho,
      FontWeight peso, {
      Color? cor,
      double? altura,
    }) => TextStyle(
      fontFamily: fonteTexto,
      fontSize: tamanho,
      fontWeight: peso,
      color: cor ?? c.texto,
      height: altura,
    );
    TextStyle montserrat(double tamanho, FontWeight peso, {Color? cor}) =>
        TextStyle(
          fontFamily: fonteTitulo,
          fontSize: tamanho,
          fontWeight: peso,
          color: cor ?? c.texto,
        );

    return TextTheme(
      displaySmall: montserrat(32, FontWeight.w700),
      headlineMedium: montserrat(28, FontWeight.w700), // título do Painel
      headlineSmall: montserrat(24, FontWeight.w700), // título das telas
      titleLarge: montserrat(20, FontWeight.w600),
      titleMedium: montserrat(17, FontWeight.w600), // título de cartão/seção
      titleSmall: inter(14, FontWeight.w600),
      bodyLarge: inter(16, FontWeight.w400, altura: 1.5),
      bodyMedium: inter(14, FontWeight.w400, altura: 1.5),
      bodySmall: inter(12.5, FontWeight.w400, cor: c.textoSuave, altura: 1.4),
      labelLarge: inter(14, FontWeight.w600),
      labelMedium: inter(12, FontWeight.w600),
      labelSmall: inter(11, FontWeight.w600),
    );
  }
}
