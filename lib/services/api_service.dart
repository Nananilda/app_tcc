import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  Future<Map<String, dynamic>> dashboard({int? estoqueId}) => _get(
    'dashboard.php',
    estoqueId == null ? null : {'estoque_id': '$estoqueId'},
  );

  // ── Estoques ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listarEstoques() => _get('estoques.php');

  Future<Map<String, dynamic>> buscarEstoque(int id) =>
      _get('estoques.php', {'id': '$id'});

  Future<Map<String, dynamic>> cadastrarEstoque({
    required String nome,
    required String descricao,
    required String localizacao,
    required String status,
  }) {
    return _post('estoques.php', {
      'acao': 'cadastrar',
      'nome': nome,
      'descricao': descricao,
      'localizacao': localizacao,
      'status': status,
    });
  }

  Future<Map<String, dynamic>> atualizarEstoque({
    required int id,
    required String nome,
    required String descricao,
    required String localizacao,
    required String status,
  }) {
    return _post('estoques.php', {
      'acao': 'atualizar',
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'localizacao': localizacao,
      'status': status,
    });
  }

  /// Desativa o estoque preservando o histórico (a API exige a confirmação).
  Future<Map<String, dynamic>> desativarEstoque(int id) {
    return _post('estoques.php', {
      'acao': 'desativar',
      'id': id,
      'confirmacao': 'desativar',
    });
  }

  // ── Sensores ────────────────────────────────────────────────────────────

  /// Sensores visíveis ao usuário; [estoqueId] filtra por estoque.
  Future<Map<String, dynamic>> listarSensores({int? estoqueId}) => _get(
    'sensores.php',
    estoqueId == null ? null : {'estoque_id': '$estoqueId'},
  );

  Future<Map<String, dynamic>> cadastrarSensor({
    required String nome,
    required String tipo,
    required int estoqueId,
    required String localizacao,
    required String status,
    int intervaloComunicacao = 300,
    Map<String, dynamic> limites = const {},
  }) {
    return _post('sensores.php', {
      'acao': 'cadastrar',
      'nome': nome,
      'tipo': tipo,
      'estoque_id': estoqueId,
      'localizacao': localizacao,
      'status': status,
      'intervalo_comunicacao': intervaloComunicacao,
      ...limites,
    });
  }

  Future<Map<String, dynamic>> atualizarSensor({
    required int sensorId,
    required String nome,
    required String tipo,
    required int estoqueId,
    required String localizacao,
    required String status,
    int intervaloComunicacao = 300,
    Map<String, dynamic> limites = const {},
  }) {
    return _post('sensores.php', {
      'acao': 'atualizar',
      'sensor_id': sensorId,
      'nome': nome,
      'tipo': tipo,
      'estoque_id': estoqueId,
      'localizacao': localizacao,
      'status': status,
      'intervalo_comunicacao': intervaloComunicacao,
      ...limites,
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

  /// Lista paginada (50 por página). Filtros opcionais: [estoqueId],
  /// [severidade] (info/atencao/critico) e [status]
  /// (pendente/reconhecido/normalizado/resolvido).
  Future<Map<String, dynamic>> listarAlertas({
    int pagina = 1,
    int? estoqueId,
    String severidade = '',
    String status = '',
  }) {
    return _get('alertas.php', {
      'pagina': '$pagina',
      if (estoqueId != null) 'estoque_id': '$estoqueId',
      if (severidade.isNotEmpty) 'severidade': severidade,
      if (status.isNotEmpty) 'status': status,
    });
  }

  /// Reconhece um alerta PENDENTE (a equipe viu e está cuidando).
  Future<Map<String, dynamic>> reconhecerAlerta(int alertaId) {
    return _post('alertas.php', {'acao': 'reconhecer', 'alerta_id': alertaId});
  }

  /// Conclui o atendimento; registra responsável, horário e [observacoes].
  Future<Map<String, dynamic>> resolverAlerta(
    int alertaId, {
    String observacoes = '',
  }) {
    return _post('alertas.php', {
      'acao': 'resolver',
      'alerta_id': alertaId,
      'observacoes': observacoes,
    });
  }

  /// Cria um alerta manualmente (administrador). [valor] é opcional e pode
  /// ter vírgula decimal ("36,5"): o servidor faz a conversão.
  Future<Map<String, dynamic>> criarAlerta({
    required int sensorId,
    required String severidade,
    required String mensagem,
    String? valor,
  }) {
    return _post('alertas.php', {
      'acao': 'criar',
      'sensor_id': sensorId,
      'severidade': severidade,
      'mensagem': mensagem,
      'valor': valor,
    });
  }

  /// Registra uma leitura de sensor (administrador); se passar de um limite,
  /// o servidor cria o alerta automaticamente (api/leituras.php, POST).
  Future<Map<String, dynamic>> registrarLeitura({
    required int sensorId,
    required String valor,
  }) {
    return _post('leituras.php', {'sensor_id': sensorId, 'valor': valor});
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
    List<int> estoqueIds = const [],
  }) {
    return _post('usuarios.php', {
      'acao': 'cadastrar',
      'nome': nome,
      'login': login,
      'senha': senha,
      'confirmar': confirmar,
      'tipo': tipo,
      'status': status,
      'estoque_ids': estoqueIds,
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
    // Nulo preserva os vínculos atuais; lista vazia revoga todos.
    List<int>? estoqueIds,
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
      if (estoqueIds != null) 'estoque_ids': estoqueIds,
    });
  }

  /// A API desativa a conta (preserva o histórico); `excluir` é alias.
  Future<Map<String, dynamic>> excluirUsuario(int id) {
    return _post('usuarios.php', {'acao': 'desativar', 'id': id});
  }

  // ── Leituras e relatórios ───────────────────────────────────────────────

  Future<Map<String, dynamic>> leituras({
    required String sensor,
    required int horas,
    int? estoqueId,
    int? sensorId,
  }) {
    return _get('leituras.php', {
      'sensor': sensor,
      'horas': '$horas',
      if (estoqueId != null) 'estoque_id': '$estoqueId',
      if (sensorId != null) 'sensor_id': '$sensorId',
    });
  }

  Future<Map<String, dynamic>> relatorio({
    required String dataIni,
    required String dataFim,
    String sensor = '',
    String valMin = '',
    String valMax = '',
    int? estoqueId,
    int? sensorId,
    int pagina = 1,
    int porPagina = 50,
  }) {
    return _get('relatorio.php', {
      'data_ini': dataIni,
      'data_fim': dataFim,
      'sensor': sensor,
      'val_min': valMin,
      'val_max': valMax,
      if (estoqueId != null) 'estoque_id': '$estoqueId',
      if (sensorId != null) 'sensor_id': '$sensorId',
      'pagina': '$pagina',
      'por_pagina': '$porPagina',
    });
  }

  // ── Conta (perfil e preferências do próprio usuário) ────────────────────

  Future<Map<String, dynamic>> conta() => _get('conta.php');

  /// Salva o nome do perfil (obrigatório na API). A identidade e as
  /// permissões vêm da sessão — a API recusa `id`, `tipo`, `status` etc.
  Future<Map<String, dynamic>> salvarConta({
    required String nome,
    String? tema,
  }) {
    return _post('conta.php', {'nome': nome, if (tema != null) 'tema': tema});
  }

  /// Salva SÓ a preferência visual (`claro`, `escuro` ou `automatico`).
  Future<Map<String, dynamic>> salvarTema(String tema) {
    return _post('conta.php', {'acao': 'tema', 'tema': tema});
  }

  /// Troca a senha da PRÓPRIA conta (a API exige reenviar o nome).
  Future<Map<String, dynamic>> trocarSenhaComNome({
    required String nome,
    required String senhaAtual,
    required String senha,
    required String confirmarSenha,
  }) {
    return _post('conta.php', {
      'nome': nome,
      'senha_atual': senhaAtual,
      'senha': senha,
      'confirmar_senha': confirmarSenha,
    });
  }

  /// Baixa o relatório COMPLETO (todos os registros, sem paginação) em
  /// [formato] `csv` ou `pdf`, com os mesmos filtros da consulta.
  Future<List<int>> baixarRelatorio({
    required String formato,
    required String dataIni,
    required String dataFim,
    String sensor = '',
    String valMin = '',
    String valMax = '',
    int? estoqueId,
    int? sensorId,
  }) async {
    try {
      final resposta = await _client
          .get(
            _uri('relatorio.php', {
              'formato': formato,
              'data_ini': dataIni,
              'data_fim': dataFim,
              'sensor': sensor,
              'val_min': valMin,
              'val_max': valMax,
              if (estoqueId != null) 'estoque_id': '$estoqueId',
              if (sensorId != null) 'sensor_id': '$sensorId',
            }),
            headers: {if (_token != null) 'Authorization': 'Bearer $_token'},
          )
          .timeout(ApiConfig.timeout);
      final tipo = resposta.headers['content-type'] ?? '';
      if (resposta.statusCode == 200 && !tipo.contains('json')) {
        return resposta.bodyBytes;
      }
      // Erro da API vem em JSON; reaproveita o tratamento de 401/422.
      _decodificar(resposta);
      throw const ApiException('Não foi possível gerar o arquivo.');
    } on TimeoutException {
      throw const ApiException('O servidor demorou demais para responder.');
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar ao servidor (${ApiConfig.baseUrl}).',
      );
    }
  }

  /// Envia a foto do perfil (JPEG/PNG até 2 MB; o servidor valida e
  /// redimensiona). A API exige reenviar o nome em toda gravação.
  Future<Map<String, dynamic>> enviarFoto({
    required String nome,
    required List<int> bytes,
    required String nomeArquivo,
  }) {
    final extensao = nomeArquivo.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    return _enviar(() async {
      final pedido = http.MultipartRequest('POST', _uri('conta.php'))
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $_token'
        ..fields['nome'] = nome
        ..files.add(
          http.MultipartFile.fromBytes(
            'foto',
            bytes,
            filename: nomeArquivo,
            contentType: MediaType('image', extensao),
          ),
        );
      return http.Response.fromStream(await _client.send(pedido));
    });
  }

  Future<Map<String, dynamic>> removerFoto({required String nome}) {
    return _post('conta.php', {'nome': nome, 'remover_foto': '1'});
  }
}
