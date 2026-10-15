import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Endereço da API PHP do ÁKRON (pasta `api/` do projeto web `tcc`).
///
/// Atenção: este é o endereço do servidor web (Apache/PHP), NÃO do MySQL. O app
/// nunca fala direto com o banco — quem consulta o MySQL é o PHP, e o app usa
/// a API (por isso nenhuma senha de banco fica dentro do aplicativo).
///
/// Como o endereço é definido (do mais forte para o mais fraco):
///   1. o que o usuário salvou em "Servidor" na tela de login (fica gravado no
///      aparelho) — útil no laboratório, onde o IP do servidor muda a cada aula;
///   2. a opção de compilação `--dart-define=API_BASE_URL=http://IP/tcc/api`;
///   3. o padrão da plataforma abaixo.
///
/// Exemplos de endereço:
///   - emulador Android → PC:      http://10.0.2.2/tcc/api
///   - celular/desktop/web na rede: http://192.168.0.10/tcc/api
///   - `php -S` na porta 8000:      http://localhost:8000/api
class ApiConfig {
  ApiConfig._();

  static const String _chavePrefs = 'akron_api_base_url';

  /// Valor passado em `--dart-define=API_BASE_URL=...` (vazio se não houver).
  static const String _definidoNaCompilacao = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Tempo máximo de espera por uma resposta do servidor.
  static const Duration timeout = Duration(seconds: 12);

  static String _baseUrl = _padrao();

  /// Endereço atual da API, sem barra no final.
  static String get baseUrl => _baseUrl;

  /// Padrão quando nada foi configurado.
  static String _padrao() {
    if (_definidoNaCompilacao.isNotEmpty) {
      return normalizar(_definidoNaCompilacao);
    }
    // No emulador do Android, "localhost" é o próprio emulador; o PC é 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/tcc/api';
    }
    return 'http://localhost/tcc/api';
  }

  /// Endereço padrão (ignorando o que o usuário salvou).
  static String get padrao => _padrao();

  /// Lê do armazenamento do aparelho o endereço salvo pelo usuário (se houver).
  /// Deve ser chamado uma vez em `main()`, antes de `runApp`.
  static Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_chavePrefs);
      if (salvo != null && urlValida(salvo)) _baseUrl = normalizar(salvo);
    } catch (_) {
      // Sem armazenamento disponível: segue com o padrão.
    }
  }

  /// Define e grava um novo endereço. Lança [FormatException] se for inválido.
  static Future<void> salvar(String url) async {
    if (!urlValida(url)) throw const FormatException('Endereço inválido.');
    _baseUrl = normalizar(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chavePrefs, _baseUrl);
  }

  /// Volta ao padrão e apaga o endereço salvo.
  static Future<void> restaurarPadrao() async {
    _baseUrl = _padrao();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chavePrefs);
  }

  /// Usado só em testes: define o endereço em memória, sem gravar.
  @visibleForTesting
  static void definirParaTeste(String url) => _baseUrl = normalizar(url);

  /// Limpa espaços, acrescenta `http://` se faltar o esquema e remove a barra final.
  static String normalizar(String url) {
    var limpo = url.trim();
    if (limpo.isEmpty) return limpo;
    if (!limpo.contains('://')) limpo = 'http://$limpo';
    while (limpo.endsWith('/')) {
      limpo = limpo.substring(0, limpo.length - 1);
    }
    return limpo;
  }

  /// O texto é um endereço http(s) com servidor?
  static bool urlValida(String url) {
    final uri = Uri.tryParse(normalizar(url));
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
