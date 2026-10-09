import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Erro de comunicação com a API (rede fora do ar, timeout, JSON inválido,
/// resposta HTTP de erro sem corpo legível etc.). [mensagem] já é amigável
/// para ser mostrada ao usuário.
class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// O servidor recusou o token (expirou, foi encerrado ou a conta foi
/// desativada). O app deve voltar para a tela de login.
class SessaoExpiradaException extends ApiException {
  const SessaoExpiradaException(super.mensagem);
}

/// Cliente HTTP dos endpoints `api/*.php` do backend ÁKRON.
///
/// Autenticação: o login devolve um `token`, que este serviço guarda e envia em
/// todas as chamadas seguintes no cabeçalho `Authorization: Bearer <token>`.
/// (Cookies não são usados: o navegador não os repassa entre endereços
/// diferentes, o que quebraria o app rodando como Flutter Web.)
///
/// O [http.Client] pode ser injetado — nos testes usamos o `MockClient`.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  /// Há um token de sessão guardado?
  bool get autenticado => _token != null;

  /// Descarta o token (logout local).
  void esquecerSessao() => _token = null;

  // ── Infraestrutura ──────────────────────────────────────────────────────

  Map<String, String> get _cabecalhos => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String caminho, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$caminho');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  /// Executa a requisição tratando timeout e falhas de rede de forma uniforme.
  /// [endereco] é o servidor citado na mensagem de erro (padrão: o configurado).
  Future<Map<String, dynamic>> _enviar(
    Future<http.Response> Function() requisicao, {
    String? endereco,
  }) async {
    try {
      final resposta = await requisicao().timeout(ApiConfig.timeout);
      return _decodificar(resposta);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou demais para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar ao servidor (${endereco ?? ApiConfig.baseUrl}). '
        'Confira o endereço em "Servidor" na tela de login e sua conexão de rede.',
      );
    }
  }

  Future<Map<String, dynamic>> _get(
    String caminho, [
    Map<String, String>? query,
  ]) {
    return _enviar(
      () => _client.get(_uri(caminho, query), headers: _cabecalhos),
    );
  }

  Future<Map<String, dynamic>> _post(
    String caminho,
    Map<String, dynamic> corpo,
  ) {
    return _enviar(
      () => _client.post(
        _uri(caminho),
        headers: _cabecalhos,
        body: jsonEncode(corpo),
      ),
    );
  }

  /// Converte a resposta em mapa e traduz os códigos HTTP em exceções.
  Map<String, dynamic> _decodificar(http.Response resposta) {
    Map<String, dynamic> corpo;
    try {
      corpo =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'Resposta inesperada do servidor (HTTP ${resposta.statusCode}). '
        'Verifique se o endereço aponta para a pasta "api" do sistema.',
      );
    }

    final mensagem = corpo['mensagem'] as String?;

    // 401 com token guardado = sessão encerrada. (Sem token, é só o login errado.)
    if (resposta.statusCode == 401 && _token != null) {
      _token = null;
      throw SessaoExpiradaException(
        mensagem ?? 'Sessão expirada. Faça login novamente.',
      );
    }
    if (resposta.statusCode >= 500) {
      throw ApiException(mensagem ?? 'Erro interno do servidor.');
    }
    return corpo;
  }

  // ── Servidor e sessão ───────────────────────────────────────────────────

  /// Testa o endereço da API configurado (não exige login).
  Future<Map<String, dynamic>> status() => _get('status.php');

  /// Testa um endereço QUALQUER de API (usado pelo diálogo "Servidor" antes de salvar).
  Future<Map<String, dynamic>> statusEm(String baseUrl) {
    final endereco = ApiConfig.normalizar(baseUrl);
    return _enviar(
      () => _client.get(
        Uri.parse('$endereco/status.php'),
        headers: const {'Accept': 'application/json'},
      ),
      endereco: endereco,
    );
  }

  /// Faz login e, se der certo, guarda o token devolvido pelo servidor.
  Future<Map<String, dynamic>> login(String login, String senha) async {
    final resposta = await _post('login.php', {'login': login, 'senha': senha});
    final token = resposta['token'];
    if (resposta['sucesso'] == true && token is String && token.isNotEmpty) {
      _token = token;
    }
    return resposta;
  }

  /// Encerra a sessão no servidor e descarta o token local.
  Future<void> logout() async {
    try {
      await _post('logout.php', {});
    } finally {
      _token = null;
    }
  }

  // ── Painel ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> dashboard() => _get('dashboard.php');

  // ── Sensores ────────────────────────────────────────────────────────────

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

  // ── Alertas ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listarAlertas() => _get('alertas.php');

  Future<Map<String, dynamic>> resolverAlerta(int alertaId) {
    return _post('alertas.php', {'acao': 'resolver', 'alerta_id': alertaId});
  }

  // ── Usuários (somente administrador) ────────────────────────────────────

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

  // ── Leituras e relatórios ───────────────────────────────────────────────

  Future<Map<String, dynamic>> leituras({
    required String sensor,
    required int horas,
  }) {
    return _get('leituras.php', {'sensor': sensor, 'horas': '$horas'});
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
