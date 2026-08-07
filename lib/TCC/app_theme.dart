import 'package:flutter/material.dart';

/// Paleta baseada em public/assets/css/style.css (:root do IndustrialOS).
class AppColors {
  static const fundo = Color(0xFF0F1620);
  static const fundoCard = Color(0xFF16202C);
  static const fundoCardAlt = Color(0xFF1C2836);
  static const borda = Color(0xFF26343F);
  static const texto = Color(0xFFE6EDF3);
  static const textoSuave = Color(0xFF9FB1C1);
  static const primaria = Color(0xFF2EA8FF);
  static const primariaEscura = Color(0xFF1C7FD1);
  static const sucesso = Color(0xFF2FD48B);
  static const sucessoFundo = Color(0x1F2FD48B);
  static const erro = Color(0xFFFF5D6C);
  static const erroFundo = Color(0x1FFF5D6C);
  static const alerta = Color(0xFFFFB020);
  static const alertaFundo = Color(0x1FFFB020);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fundo,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaria,
        secondary: AppColors.primaria,
        surface: AppColors.fundoCard,
        error: AppColors.erro,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.texto,
        displayColor: AppColors.texto,
        fontFamily: 'Segoe UI',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fundoCard,
        foregroundColor: AppColors.texto,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fundo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.textoSuave),
        hintStyle: const TextStyle(color: AppColors.textoSuave),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaria, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaria,
          foregroundColor: const Color(0xFF06111C),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.texto,
          side: const BorderSide(color: AppColors.borda),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borda, space: 32),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.fundoCardAlt),
        dataRowColor: WidgetStateProperty.all(AppColors.fundoCard),
        headingTextStyle: const TextStyle(
          color: AppColors.textoSuave,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
        dataTextStyle: const TextStyle(color: AppColors.texto, fontSize: 13),
      ),
    );
  }
}
