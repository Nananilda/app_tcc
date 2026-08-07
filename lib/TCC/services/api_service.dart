import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Erro de comunicação com a API (rede fora do ar, timeout, JSON inválido,
/// resposta HTTP de erro sem corpo JSON legível etc).
class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Fala com os endpoints em `api/*.php` do backend tcc-main.
///
/// A autenticação do backend é baseada em sessão PHP (cookie PHPSESSID).
/// Como o pacote `http` não guarda cookies entre chamadas sozinho, este
/// serviço captura o `Set-Cookie` da resposta de login e o reenvia em
/// todas as chamadas seguintes — o mesmo papel que o navegador faria
/// automaticamente para as páginas HTML originais.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();
  String? _cookie;

  void _guardarCookie(http.Response resposta) {
    final setCookie = resposta.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      // Guarda só o par nome=valor (antes do primeiro ';'), como um
      // navegador faria ao montar o cabeçalho Cookie da próxima requisição.
      _cookie = setCookie.split(';').first;
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_cookie != null) 'Cookie': _cookie!,
      };

  Uri _uri(String caminho, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}/$caminho').replace(
      queryParameters: query,
    );
  }

  Future<Map<String, dynamic>> _get(
    String caminho, [
    Map<String, String>? query,
  ]) async {
    try {
      final resposta = await _client
          .get(_uri(caminho, query), headers: _headers)
          .timeout(ApiConfig.timeout);
      _guardarCookie(resposta);
      return _decodificar(resposta);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou demais para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique o endereço da API '
        'em api_config.dart e sua conexão de rede.',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String caminho,
    Map<String, dynamic> corpo,
  ) async {
    try {
      final resposta = await _client
          .post(_uri(caminho), headers: _headers, body: jsonEncode(corpo))
          .timeout(ApiConfig.timeout);
      _guardarCookie(resposta);
      return _decodificar(resposta);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou demais para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique o endereço da API '
        'em api_config.dart e sua conexão de rede.',
      );
    }
  }

  Map<String, dynamic> _decodificar(http.Response resposta) {
    Map<String, dynamic> corpo;
    try {
      corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'Resposta inesperada do servidor (HTTP ${resposta.statusCode}).',
      );
    }
    if (resposta.statusCode >= 500) {
      throw ApiException(
        corpo['mensagem'] as String? ?? 'Erro interno do servidor.',
      );
    }
    return corpo;
  }

  // ── Sessão ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String login, String senha) {
    return _post('login.php', {'login': login, 'senha': senha});
  }

  Future<void> logout() async {
    await _post('logout.php', {});
    _cookie = null;
  }

  // ── Dashboard ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> dashboard() => _get('dashboard.php');

  // ── Sensores ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listarSensores() => _get('sensores.php');

  Future<Map<String, dynamic>> cadastrarSensor({
    required String nome,
    required String tipo,
    required String localizacao,
    required String status,
  }) {
    return _post('sensores.php', {
      'acao': 'cadastrar',
      'nome': nome,
      'tipo': tipo,
      'localizacao': localizacao,
      'status': status,
    });
  }

  Future<Map<String, dynamic>> alternarStatusSensor({
    required int sensorId,
    required String novoStatus,
  }) {
    return _post('sensores.php', {
      'acao': 'toggle_status',
      'sensor_id': sensorId,
      'novo_status': novoStatus,
    });
  }

  // ── Alertas ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listarAlertas() => _get('alertas.php');

  Future<Map<String, dynamic>> resolverAlerta(int alertaId) {
    return _post('alertas.php', {'acao': 'resolver', 'alerta_id': alertaId});
  }

  // ── Usuários (somente admin) ─────────────────────────────────────────

  Future<Map<String, dynamic>> listarUsuarios() => _get('usuarios.php');

  Future<Map<String, dynamic>> buscarUsuarioPorLogin(String login) {
    return _get('usuarios.php', {'login': login});
  }

  Future<Map<String, dynamic>> cadastrarUsuario({
    required String nome,
    required String login,
    required String senha,
    required String confirmar,
    required String tipo,
    required String status,
  }) {
    return _post('usuarios.php', {
      'acao': 'cadastrar',
      'nome': nome,
      'login': login,
      'senha': senha,
      'confirmar': confirmar,
      'tipo': tipo,
      'status': status,
    });
  }

  Future<Map<String, dynamic>> atualizarUsuario({
    required int id,
    required String nome,
    required String login,
    required String tipo,
    required String status,
    String senha = '',
    String confirmarSenha = '',
  }) {
    return _post('usuarios.php', {
      'acao': 'atualizar',
      'id': id,
      'nome': nome,
      'login': login,
      'tipo': tipo,
      'status': status,
      'senha': senha,
      'confirmar_senha': confirmarSenha,
    });
  }

  Future<Map<String, dynamic>> excluirUsuario(int id) {
    return _post('usuarios.php', {'acao': 'excluir', 'id': id});
  }

  // ── Leituras / Relatórios ─────────────────────────────────────────────

  Future<Map<String, dynamic>> leituras({
    required String sensor,
    required int horas,
  }) {
    return _get('leituras.php', {
      'sensor': sensor,
      'horas': '$horas',
    });
  }

  Future<Map<String, dynamic>> relatorio({
    required String dataIni,
    required String dataFim,
    String sensor = '',
    String valMin = '',
    String valMax = '',
  }) {
    return _get('relatorio.php', {
      'data_ini': dataIni,
      'data_fim': dataFim,
      'sensor': sensor,
      'val_min': valMin,
      'val_max': valMax,
    });
  }
}
