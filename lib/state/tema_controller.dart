import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escolha do tema (claro/escuro) feita pelo usuário.
///
/// Enquanto o usuário não escolher, vale [ThemeMode.system] — o app acompanha o
/// modo do aparelho. Ao tocar no botão de tema, a escolha vira explícita e é
/// gravada no aparelho (SharedPreferences) para a próxima abertura do app.
class TemaController extends ChangeNotifier {
  /// [prefs] (opcional) é onde a escolha é gravada; sem ele o tema vale só
  /// nesta sessão (usado nos testes).
  TemaController({ThemeMode modoInicial = ThemeMode.system, this._prefs})
    : _modo = modoInicial;

  static const String _chavePrefs = 'akron_tema'; // 'claro' | 'escuro'

  final SharedPreferences? _prefs;
  ThemeMode _modo;

  /// Modo atual (system, light ou dark), consumido pelo MaterialApp.
  ThemeMode get modo => _modo;

  /// Lê a escolha salva. Chamado em `main()` antes de `runApp`.
  static Future<TemaController> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_chavePrefs);
      final modo = switch (salvo) {
        'claro' => ThemeMode.light,
        'escuro' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      return TemaController(modoInicial: modo, prefs: prefs);
    } catch (_) {
      return TemaController(); // sem armazenamento: acompanha o sistema
    }
  }

  /// Alterna entre claro e escuro a partir do brilho que está sendo exibido
  /// agora ([brilhoAtual]) — assim, quem estava no "automático" troca para o
  /// oposto do que está vendo.
  Future<void> alternar(Brightness brilhoAtual) async {
    _modo = brilhoAtual == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await _prefs?.setString(
        _chavePrefs,
        _modo == ThemeMode.dark ? 'escuro' : 'claro',
      );
    } catch (_) {
      // A troca vale nesta sessão mesmo que não consiga gravar.
    }
  }
}
