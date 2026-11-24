import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../models/estoque.dart';
import '../models/leitura.dart';
import '../models/painel.dart';
import '../models/sensor.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Resultado padrão de operações que retornam mensagem de sucesso + erros,
/// no mesmo espírito dos controllers PHP (`['mensagem' => ..., 'erros' => ...]`).
class ResultadoOperacao {
  final String mensagem;
  final List<String> erros;

  const ResultadoOperacao({this.mensagem = '', this.erros = const []});

  bool get temErro => erros.isNotEmpty;
  bool get temSucesso => mensagem.isNotEmpty;
}

/// Resposta de uma consulta de dados: ou traz [dados], ou traz o [erro]
/// (já em texto amigável) para a tela exibir.
class Resposta<T> {
  final T? dados;
  final String? erro;

  const Resposta.sucesso(T this.dados) : erro = null;
  const Resposta.falha(String this.erro) : dados = null;

  bool get ok => erro == null;
}

/// Situação da conexão com o servidor (api/status.php).
class StatusServidor {
  final bool conectado;
  final String mensagem;

  const StatusServidor({required this.conectado, required this.mensagem});
}

/// Estado global do app: sessão do usuário logado e cache local dos dados
/// vindos da API (api/*.php), que por sua vez lê/escreve no MySQL (banco_tcc)
/// através do PHP — o app nunca acessa o banco diretamente.
class AppState extends ChangeNotifier {
  AppState({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  // ── Sessão ──────────────────────────────────────────────────────────────

  Usuario? _usuarioLogado;
  String? _avisoLogin;

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get ehAdmin => _usuarioLogado?.tipo == TipoUsuario.admin;

  /// Mensagem a mostrar na tela de login (ex.: "Sessão expirada").
  String? get avisoLogin => _avisoLogin;

  /// Marca o aviso como já exibido.
  void limparAvisoLogin() => _avisoLogin = null;

  /// Chamado com o tema salvo na conta (`claro`/`escuro`/`automatico`) depois
  /// do login. O `main.dart` liga isto ao [TemaController].
  void Function(String? tema)? aoCarregarTemaDaConta;

  Future<ResultadoOperacao> login(String login, String senha) async {
    final loginLimpo = login.trim();
    if (loginLimpo.isEmpty || senha.isEmpty) {
      return const ResultadoOperacao(erros: ['Credenciais inválidas.']);
    }

    try {
      final resposta = await _api.login(loginLimpo, senha);
      if (resposta['sucesso'] != true) {
        return ResultadoOperacao(
          erros: [
            resposta['mensagem'] as String? ?? 'Login ou senha inválidos.',
          ],
        );
      }
      _usuarioLogado = Usuario.fromJson(
        Map<String, dynamic>.from(resposta['usuario'] as Map),
      );
      _avisoLogin = null;
      notifyListeners();
      carregarConta(); // aplica o tema da conta; falha aqui não impede o login
      return const ResultadoOperacao(mensagem: 'Login realizado com sucesso.');
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    } on TypeError {
      return const ResultadoOperacao(
        erros: ['Resposta inesperada do servidor.'],
      );
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on ApiException {
      // Mesmo se a chamada falhar, encerramos a sessão localmente.
    }
    _encerrarSessaoLocal();
  }

  /// Limpa sessão e dados em memória e avisa o roteador (que volta ao login).
  void _encerrarSessaoLocal({String? aviso}) {
    _api.esquecerSessao();
    _usuarioLogado = null;
    _avisoLogin = aviso;
    _sensores = [];
    _alertas = [];
    _usuarios = [];
    _estoques = [];
    _fotoPerfil = null;
    _contagemAlertas = {};
    _totalAlertas = 0;
    notifyListeners();
  }

  // ── Servidor ────────────────────────────────────────────────────────────

  /// Testa o endereço configurado (api/status.php) e informa se o servidor e o
  /// banco de dados estão respondendo.
  Future<StatusServidor> verificarServidor() async {
    try {
      final r = await _api.status();
      if (r['sucesso'] == true) {
        return const StatusServidor(
          conectado: true,
          mensagem: 'Servidor conectado',
        );
      }
      return StatusServidor(
        conectado: false,
        mensagem: r['mensagem'] as String? ?? 'Servidor indisponível',
      );
    } on ApiException catch (e) {
      return StatusServidor(conectado: false, mensagem: e.mensagem);
    }
  }

  /// Testa um endereço de servidor informado pelo usuário, sem alterá-lo
  /// (usado pelo diálogo "Servidor" antes de salvar).
  Future<StatusServidor> testarEndereco(String url) async {
    try {
      final r = await _api.statusEm(url);
      if (r['sucesso'] == true) {
        final versao = r['versao'];
        return StatusServidor(
          conectado: true,
          mensagem:
              'Conectado${versao != null ? ' — ÁKRON v$versao' : ''} (banco de dados OK)',
        );
      }
      return StatusServidor(
        conectado: false,
        mensagem: r['mensagem'] as String? ?? 'Servidor indisponível',
      );
    } on ApiException catch (e) {
      return StatusServidor(conectado: false, mensagem: e.mensagem);
    }
  }

  // ── Utilitários internos ────────────────────────────────────────────────

  /// Extrai a lista de erros de uma resposta da API (ou usa [padrao]).
  List<String> _erros(Map<String, dynamic> resposta, String padrao) {
    final erros = resposta['erros'];
    if (erros is List && erros.isNotEmpty) {
      return erros.map((e) => '$e').toList();
    }
    final mensagem = resposta['mensagem'];
    if (mensagem is String && mensagem.isNotEmpty) return [mensagem];
    return [padrao];
  }

  /// Converte a resposta de uma ação (cadastrar, excluir...) em [ResultadoOperacao].
  ResultadoOperacao _resultado(
    Map<String, dynamic> resposta,
    String erroPadrao,
  ) {
    if (resposta['sucesso'] == true) {
      return ResultadoOperacao(
        mensagem: resposta['mensagem'] as String? ?? 'Operação concluída.',
      );
    }
    return ResultadoOperacao(erros: _erros(resposta, erroPadrao));
  }

  /// Executa uma ação traduzindo as exceções da API em [ResultadoOperacao].
  /// Se o servidor encerrou a sessão, volta ao login.
  Future<ResultadoOperacao> _executar(
    Future<ResultadoOperacao> Function() acao,
  ) async {
    try {
      return await acao();
    } on SessaoExpiradaException catch (e) {
      _encerrarSessaoLocal(aviso: e.mensagem);
      return ResultadoOperacao(erros: [e.mensagem]);
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    } on TypeError {
      return const ResultadoOperacao(
        erros: ['Resposta inesperada do servidor.'],
      );
    }
  }

  /// Executa uma consulta traduzindo as exceções da API em [Resposta].
  Future<Resposta<T>> _consultar<T>(Future<T> Function() consulta) async {
    try {
      return Resposta.sucesso(await consulta());
    } on SessaoExpiradaException catch (e) {
      _encerrarSessaoLocal(aviso: e.mensagem);
      return Resposta.falha(e.mensagem);
    } on ApiException catch (e) {
      return Resposta.falha(e.mensagem);
    } on TypeError {
      return const Resposta.falha('Resposta inesperada do servidor.');
    }
  }

  // ── Painel ──────────────────────────────────────────────────────────────

  Future<Resposta<ResumoPainel>> carregarResumo({int? estoqueId}) {
    return _consultar(() async {
      final r = await _api.dashboard(estoqueId: estoqueId);
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar o painel.').first);
      }
      return ResumoPainel.fromJson(
        Map<String, dynamic>.from(r['resumo'] as Map),
      );
    });
  }

  // ── Estoques ────────────────────────────────────────────────────────────

  List<Estoque> _estoques = [];
  List<Estoque> get estoques => List.unmodifiable(_estoques);

  /// Estoques ATIVOS (os únicos que aceitam novos sensores e leituras).
  List<Estoque> get estoquesAtivos =>
      _estoques.where((e) => e.ativo).toList(growable: false);

  Future<ResultadoOperacao> carregarEstoques() {
    return _executar(() async {
      final r = await _api.listarEstoques();
      if (r['sucesso'] != true) {
        return ResultadoOperacao(
          erros: _erros(r, 'Erro ao carregar estoques.'),
        );
      }
      _estoques = (r['estoques'] as List)
          .map((e) => Estoque.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    });
  }

  List<String> _validarEstoque(String nome) => [
    if (nome.trim().length < 3) 'Informe um nome com pelo menos 3 caracteres.',
  ];

  Future<ResultadoOperacao> cadastrarEstoque({
    required String nome,
    String descricao = '',
    String localizacao = '',
    bool ativo = true,
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    final erros = _validarEstoque(nome);
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.cadastrarEstoque(
        nome: nome.trim(),
        descricao: descricao.trim(),
        localizacao: localizacao.trim(),
        status: ativo ? 'ativo' : 'inativo',
      );
      final resultado = _resultado(r, 'Não foi possível salvar o estoque.');
      if (!resultado.temErro) await carregarEstoques();
      return resultado;
    });
  }

  Future<ResultadoOperacao> atualizarEstoque({
    required int id,
    required String nome,
    String descricao = '',
    String localizacao = '',
    bool ativo = true,
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    final erros = _validarEstoque(nome);
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.atualizarEstoque(
        id: id,
        nome: nome.trim(),
        descricao: descricao.trim(),
        localizacao: localizacao.trim(),
        status: ativo ? 'ativo' : 'inativo',
      );
      final resultado = _resultado(r, 'Não foi possível salvar o estoque.');
      if (!resultado.temErro) await carregarEstoques();
      return resultado;
    });
  }

  /// Desativa o estoque (o histórico de sensores, leituras e alertas é preservado).
  Future<ResultadoOperacao> desativarEstoque(int id) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    return _executar(() async {
      final r = await _api.desativarEstoque(id);
      final resultado = _resultado(r, 'Não foi possível desativar o estoque.');
      if (!resultado.temErro) await carregarEstoques();
      return resultado;
    });
  }

  // ── Sensores ────────────────────────────────────────────────────────────

  List<Sensor> _sensores = [];
  List<Sensor> get sensores => List.unmodifiable(_sensores);

  Future<ResultadoOperacao> carregarSensores({int? estoqueId}) {
    return _executar(() async {
      final r = await _api.listarSensores(estoqueId: estoqueId);
      if (r['sucesso'] != true) {
        return ResultadoOperacao(
          erros: _erros(r, 'Erro ao carregar sensores.'),
        );
      }
      _sensores = (r['sensores'] as List)
          .map((e) => Sensor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    });
  }

  /// Validações comuns ao cadastro e à edição de sensor (a API valida de novo).
  List<String> _validarSensor({
    required String nome,
    required TipoSensor? tipo,
    required Estoque? estoque,
    required int intervaloComunicacao,
    required LimitesDoSensor limites,
  }) {
    return [
      if (nome.trim().length < 3)
        'Nome do sensor deve ter ao menos 3 caracteres.',
      if (tipo == null) 'Tipo de sensor inválido.',
      if (estoque == null) 'Selecione o estoque do sensor.',
      if (intervaloComunicacao < 1 || intervaloComunicacao > 86400)
        'O prazo de comunicação deve ficar entre 1 e 86400 segundos.',
      if (limites.validar() case final erro?) erro,
    ];
  }

  /// Gestão de sensores (cadastro/alteração) é EXCLUSIVA de administradores —
  /// o backend (api/sensores.php) também bloqueia isso de forma independente;
  /// este `if` é só uma segunda camada para dar retorno imediato na tela.
  Future<ResultadoOperacao> cadastrarSensor({
    required String nome,
    required TipoSensor? tipo,
    required Estoque? estoque,
    required String localizacao,
    required StatusSensor status,
    int intervaloComunicacao = 300,
    LimitesDoSensor limites = const LimitesDoSensor(),
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    final erros = _validarSensor(
      nome: nome,
      tipo: tipo,
      estoque: estoque,
      intervaloComunicacao: intervaloComunicacao,
      limites: limites,
    );
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.cadastrarSensor(
        nome: nome.trim(),
        tipo: tipo!.chave,
        estoqueId: estoque!.id,
        localizacao: localizacao.trim(),
        status: status.chave,
        intervaloComunicacao: intervaloComunicacao,
        limites: limites.paraApi(),
      );
      final resultado = _resultado(r, 'Não foi possível cadastrar o sensor.');
      if (!resultado.temErro) await carregarSensores();
      return resultado;
    });
  }

  Future<ResultadoOperacao> atualizarSensor({
    required int sensorId,
    required String nome,
    required TipoSensor? tipo,
    required Estoque? estoque,
    required String localizacao,
    required StatusSensor status,
    int intervaloComunicacao = 300,
    LimitesDoSensor limites = const LimitesDoSensor(),
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    final erros = _validarSensor(
      nome: nome,
      tipo: tipo,
      estoque: estoque,
      intervaloComunicacao: intervaloComunicacao,
      limites: limites,
    );
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.atualizarSensor(
        sensorId: sensorId,
        nome: nome.trim(),
        tipo: tipo!.chave,
        estoqueId: estoque!.id,
        localizacao: localizacao.trim(),
        status: status.chave,
        intervaloComunicacao: intervaloComunicacao,
        limites: limites.paraApi(),
      );
      final resultado = _resultado(r, 'Não foi possível atualizar o sensor.');
      if (!resultado.temErro) await carregarSensores();
      return resultado;
    });
  }

  Future<ResultadoOperacao> alternarStatusSensor(int sensorId) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    final idx = _sensores.indexWhere((s) => s.id == sensorId);
    if (idx == -1) {
      return Future.value(
        const ResultadoOperacao(erros: ['Sensor não encontrado.']),
      );
    }
    final novo = _sensores[idx].status == StatusSensor.ativo
        ? StatusSensor.inativo
        : StatusSensor.ativo;

    return _executar(() async {
      final r = await _api.alternarStatusSensor(
        sensorId: sensorId,
        novoStatus: novo.chave,
      );
      final resultado = _resultado(r, 'Não foi possível alterar o status.');
      if (!resultado.temErro) await carregarSensores();
      return resultado;
    });
  }

  // ── Alertas ─────────────────────────────────────────────────────────────

  List<Alerta> _alertas = [];

  /// Limites dos alertas automáticos por tipo de sensor (vêm do servidor).
  Map<TipoSensor, LimitesSensor> _limitesAlerta = {};
  Map<TipoSensor, LimitesSensor> get limitesAlerta =>
      Map.unmodifiable(_limitesAlerta);

  /// Contagem de alertas EM ABERTO (pendentes + reconhecidos) por severidade,
  /// calculada pelo servidor sobre a consulta inteira — não só a página atual.
  Map<Severidade, int> _contagemAlertas = {};
  int _totalAlertas = 0;
  int _paginaAlertas = 1;

  /// Total de alertas da consulta (todas as páginas).
  int get totalAlertas => _totalAlertas;
  int get paginaAlertas => _paginaAlertas;

  /// Há mais alertas além dos carregados (a API entrega 50 por página)?
  bool get temMaisAlertas => _alertas.length < _totalAlertas;

  /// Em aberto primeiro; dentro de cada grupo, os mais recentes no topo.
  List<Alerta> get alertas {
    final lista = List<Alerta>.from(_alertas);
    lista.sort((a, b) {
      if (a.emAberto != b.emAberto) return a.emAberto ? -1 : 1;
      return b.criadoEm.compareTo(a.criadoEm);
    });
    return lista;
  }

  /// Carrega a primeira página (ou, com [acrescentar], a PRÓXIMA página,
  /// somando à lista). Os filtros valem para a consulta toda no servidor.
  Future<ResultadoOperacao> carregarAlertas({
    bool acrescentar = false,
    int? estoqueId,
    String severidade = '',
    String status = '',
  }) {
    final pagina = acrescentar ? _paginaAlertas + 1 : 1;
    return _executar(() async {
      final r = await _api.listarAlertas(
        pagina: pagina,
        estoqueId: estoqueId,
        severidade: severidade,
        status: status,
      );
      if (r['sucesso'] != true) {
        return ResultadoOperacao(erros: _erros(r, 'Erro ao carregar alertas.'));
      }
      final recebidos = (r['alertas'] as List)
          .map((e) => Alerta.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _alertas = acrescentar ? [..._alertas, ...recebidos] : recebidos;
      _paginaAlertas = pagina;
      _totalAlertas = (r['total'] as num?)?.toInt() ?? _alertas.length;
      final contagem = r['contagem'];
      if (contagem is Map) {
        _contagemAlertas = {
          for (final sev in Severidade.values)
            sev: int.tryParse('${contagem[sev.chave] ?? 0}') ?? 0,
        };
      }
      final limites = r['limites'];
      if (limites is Map) {
        _limitesAlerta = {
          for (final e in limites.entries)
            TipoSensor.porChave('${e.key}'): LimitesSensor.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            ),
        };
      }
      notifyListeners();
      return const ResultadoOperacao();
    });
  }

  /// Quantidade de alertas EM ABERTO (pendentes ou reconhecidos) por severidade.
  Map<Severidade, int> contarAlertasPorSeveridade() {
    if (_contagemAlertas.isNotEmpty) return Map.of(_contagemAlertas);
    final contagem = {for (final s in Severidade.values) s: 0};
    for (final a in _alertas) {
      if (a.emAberto) {
        contagem[a.severidade] = (contagem[a.severidade] ?? 0) + 1;
      }
    }
    return contagem;
  }

  /// Reconhece um alerta PENDENTE.
  Future<ResultadoOperacao> reconhecerAlerta(int alertaId) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    return _executar(() async {
      final r = await _api.reconhecerAlerta(alertaId);
      final resultado = _resultado(r, 'Não foi possível reconhecer o alerta.');
      if (!resultado.temErro) await carregarAlertas();
      return resultado;
    });
  }

  /// Conclui o atendimento. [observacoes] (até 5000 bytes) são opcionais.
  Future<ResultadoOperacao> resolverAlerta(
    int alertaId, {
    String observacoes = '',
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    return _executar(() async {
      final r = await _api.resolverAlerta(
        alertaId,
        observacoes: observacoes.trim(),
      );
      final resultado = _resultado(r, 'Não foi possível resolver o alerta.');
      if (!resultado.temErro) await carregarAlertas();
      return resultado;
    });
  }

  /// Cria um alerta manualmente (somente administrador): manutenção
  /// programada, aviso da equipe, ocorrência observada etc. [valor] é a
  /// medição, opcional (aceita vírgula decimal).
  Future<ResultadoOperacao> criarAlerta({
    required Sensor? sensor,
    required Severidade? severidade,
    required String mensagem,
    String valor = '',
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    final erros = <String>[];
    if (sensor == null) erros.add('Selecione o sensor do alerta.');
    if (severidade == null) erros.add('Severidade inválida.');
    if (mensagem.trim().length < 3) {
      erros.add('A mensagem do alerta deve ter ao menos 3 caracteres.');
    }
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.criarAlerta(
        sensorId: sensor!.id,
        severidade: severidade!.chave,
        mensagem: mensagem.trim(),
        valor: valor.trim().isEmpty ? null : valor.trim(),
      );
      final resultado = _resultado(r, 'Não foi possível criar o alerta.');
      if (!resultado.temErro) await carregarAlertas();
      return resultado;
    });
  }

  /// Registra uma leitura (somente administrador). Se o valor passar de um
  /// limite do tipo do sensor, o SERVIDOR cria o alerta automático — a
  /// mensagem devolvida já informa se isso aconteceu.
  Future<ResultadoOperacao> registrarLeitura({
    required Sensor? sensor,
    required String valor,
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    final erros = <String>[];
    if (sensor == null) erros.add('Selecione o sensor da leitura.');
    if (valor.trim().isEmpty) {
      erros.add('Informe o valor da leitura como um número (ex.: 36,5).');
    }
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.registrarLeitura(
        sensorId: sensor!.id,
        valor: valor.trim(),
      );
      final resultado = _resultado(r, 'Não foi possível registrar a leitura.');
      if (!resultado.temErro) await carregarAlertas();
      return resultado;
    });
  }

  // ── Usuários (gestão exclusiva de administradores) ──────────────────────

  List<Usuario> _usuarios = [];
  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  Future<ResultadoOperacao> carregarUsuarios() {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    return _executar(() async {
      final r = await _api.listarUsuarios();
      if (r['sucesso'] != true) {
        return ResultadoOperacao(
          erros: _erros(r, 'Erro ao carregar usuários.'),
        );
      }
      _usuarios = (r['usuarios'] as List)
          .map((e) => Usuario.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    });
  }

  /// Busca um usuário pelo login. `dados == null` significa "não encontrado"
  /// (diferente de [Resposta.falha], que indica problema de comunicação).
  Future<Resposta<Usuario?>> buscarUsuarioPorLogin(String login) {
    if (!ehAdmin || login.trim().isEmpty) {
      return Future.value(const Resposta.sucesso(null));
    }

    return _consultar<Usuario?>(() async {
      final r = await _api.buscarUsuarioPorLogin(login.trim());
      if (r['sucesso'] == true && r['usuario'] != null) {
        return Usuario.fromJson(Map<String, dynamic>.from(r['usuario'] as Map));
      }
      return null;
    });
  }

  Future<ResultadoOperacao> cadastrarUsuario({
    required String nome,
    required String login,
    required String senha,
    required String confirmar,
    required TipoUsuario tipo,
    required StatusConta status,
    List<int> estoqueIds = const [],
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    return _executar(() async {
      final r = await _api.cadastrarUsuario(
        nome: nome.trim(),
        login: login.trim(),
        senha: senha,
        confirmar: confirmar,
        tipo: tipo.chave,
        status: status.chave,
        estoqueIds: estoqueIds,
      );
      return _resultado(r, 'Não foi possível cadastrar o usuário.');
    });
  }

  Future<ResultadoOperacao> atualizarUsuario({
    required int id,
    required String nome,
    required String login,
    required TipoUsuario tipo,
    required StatusConta status,
    String senha = '',
    String confirmarSenha = '',
    // Nulo preserva os vínculos atuais; lista vazia revoga todos.
    List<int>? estoqueIds,
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    return _executar(() async {
      final r = await _api.atualizarUsuario(
        id: id,
        nome: nome.trim(),
        login: login.trim(),
        tipo: tipo.chave,
        status: status.chave,
        senha: senha,
        confirmarSenha: confirmarSenha,
        estoqueIds: estoqueIds,
      );
      final resultado = _resultado(r, 'Não foi possível atualizar o usuário.');

      // Se o administrador editou a PRÓPRIA conta, a topbar precisa refletir.
      if (!resultado.temErro && _usuarioLogado?.id == id) {
        _usuarioLogado = Usuario(
          id: id,
          nome: nome.trim(),
          login: login.trim(),
          tipo: tipo,
          status: status,
          criadoEm: _usuarioLogado!.criadoEm,
          estoqueIds: _usuarioLogado!.estoqueIds,
        );
        notifyListeners();
      }
      return resultado;
    });
  }

  Future<ResultadoOperacao> excluirUsuario(int id) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }
    if (_usuarioLogado?.id == id) {
      return Future.value(
        const ResultadoOperacao(
          erros: ['Você não pode desativar sua própria conta.'],
        ),
      );
    }

    return _executar(() async {
      final r = await _api.excluirUsuario(id);
      return _resultado(r, 'Não foi possível desativar o usuário.');
    });
  }

  // ── Gráficos e relatórios ───────────────────────────────────────────────

  /// Série de um tipo de medição. Usa `pontos` (um por sensor/intervalo) e NÃO
  /// `labels`/`valores`, que misturariam sensores e estoques diferentes numa
  /// linha só. `lacuna_antes` indica onde NÃO ligar um ponto ao anterior.
  Future<Resposta<SerieLeituras>> carregarLeituras(
    TipoSensor sensor,
    int horas, {
    int? estoqueId,
    int? sensorId,
  }) {
    return _consultar(() async {
      final r = await _api.leituras(
        sensor: sensor.chave,
        horas: horas,
        estoqueId: estoqueId,
        sensorId: sensorId,
      );
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar leituras.').first);
      }

      final bruto = r['pontos'];
      final pontos = <Leitura>[];
      if (bruto is List) {
        for (final p in bruto) {
          final mapa = Map<String, dynamic>.from(p as Map);
          pontos.add(Leitura.fromJson({'sensor_tipo': sensor.chave, ...mapa}));
        }
      } else {
        // Servidor sem `pontos`: cai no formato antigo (uma linha só).
        final labels = List<String>.from(r['labels'] as List);
        final valores = List<num>.from(r['valores'] as List);
        for (var i = 0; i < labels.length && i < valores.length; i++) {
          pontos.add(
            Leitura(
              sensorTipo: sensor,
              valor: valores[i].toDouble(),
              lidoEm: DateTime.tryParse(labels[i]) ?? DateTime.now(),
            ),
          );
        }
      }

      final janela = r['janela'];
      return SerieLeituras(
        pontos: pontos,
        total: (r['total'] as num?)?.toInt() ?? pontos.length,
        lacunas: [
          for (final l in (r['lacunas'] as List? ?? []))
            LacunaLeitura.fromJson(Map<String, dynamic>.from(l as Map)),
        ],
        sensoresDesatualizados: [
          for (final id in (r['sensores_desatualizados'] as List? ?? []))
            if (int.tryParse('$id') != null) int.parse('$id'),
        ],
        janelaInicio: janela is Map
            ? DateTime.tryParse('${janela['inicio']}')
            : null,
        janelaFim: janela is Map ? DateTime.tryParse('${janela['fim']}') : null,
      );
    });
  }

  Future<Resposta<RelatorioResultado>> carregarRelatorio(
    DateTime inicio,
    DateTime fim, {
    TipoSensor? sensor,
    double? valorMin,
    double? valorMax,
    int? estoqueId,
    int? sensorId,
    int pagina = 1,
    int porPagina = 50,
  }) {
    String data(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return _consultar(() async {
      final r = await _api.relatorio(
        dataIni: data(inicio),
        dataFim: data(fim),
        sensor: sensor?.chave ?? '',
        valMin: valorMin?.toString() ?? '',
        valMax: valorMax?.toString() ?? '',
        estoqueId: estoqueId,
        sensorId: sensorId,
        pagina: pagina,
        porPagina: porPagina,
      );
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar o relatório.').first);
      }

      final leituras = (r['leituras'] as List)
          .map((e) => Leitura.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return RelatorioResultado(
        leituras: leituras,
        resumo: (r['resumo'] as List)
            .map(
              (e) => ResumoSensor.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        total: (r['total'] as num?)?.toInt() ?? leituras.length,
        totalAlertas: (r['total_alertas'] as num?)?.toInt() ?? 0,
        pagina: pagina,
        porPagina: porPagina,
        segundosForaLimites: (r['segundos_fora_limites'] as num?)?.toInt() ?? 0,
      );
    });
  }

  // ── Conta (perfil e preferências do próprio usuário) ────────────────────

  Uint8List? _fotoPerfil;

  /// Foto do perfil (PNG), ou nulo se não houver.
  Uint8List? get fotoPerfil => _fotoPerfil;

  /// Converte a URL de dados (`data:image/png;base64,...`) devolvida pela API.
  static Uint8List? _fotoDeUrlDeDados(Object? bruto) {
    if (bruto is! String || !bruto.contains(',')) return null;
    try {
      return base64Decode(bruto.substring(bruto.indexOf(',') + 1));
    } on FormatException {
      return null;
    }
  }

  Future<ResultadoOperacao> enviarFotoDoPerfil({
    required List<int> bytes,
    required String nomeArquivo,
  }) {
    if (bytes.length > 2 * 1024 * 1024) {
      return Future.value(
        const ResultadoOperacao(erros: ['Envie uma imagem JPG ou PNG de até 2 MB.']),
      );
    }
    return _executar(() async {
      final r = await _api.enviarFoto(
        nome: _usuarioLogado?.nome ?? '',
        bytes: bytes,
        nomeArquivo: nomeArquivo,
      );
      final resultado = _resultado(r, 'Não foi possível enviar a foto.');
      if (!resultado.temErro) await carregarConta();
      return resultado;
    });
  }

  Future<ResultadoOperacao> removerFotoDoPerfil() {
    return _executar(() async {
      final r = await _api.removerFoto(nome: _usuarioLogado?.nome ?? '');
      final resultado = _resultado(r, 'Não foi possível remover a foto.');
      if (!resultado.temErro) {
        _fotoPerfil = null;
        notifyListeners();
      }
      return resultado;
    });
  }

  // ── Exportação do relatório ─────────────────────────────────────────────

  /// Gera o arquivo (`csv` ou `pdf`) com TODOS os registros do filtro.
  Future<Resposta<Uint8List>> exportarRelatorio(
    String formato,
    DateTime inicio,
    DateTime fim, {
    TipoSensor? sensor,
    double? valorMin,
    double? valorMax,
    int? estoqueId,
  }) {
    String data(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _consultar(() async {
      final bytes = await _api.baixarRelatorio(
        formato: formato,
        dataIni: data(inicio),
        dataFim: data(fim),
        sensor: sensor?.chave ?? '',
        valMin: valorMin?.toString() ?? '',
        valMax: valorMax?.toString() ?? '',
        estoqueId: estoqueId,
      );
      return Uint8List.fromList(bytes);
    });
  }

  /// Carrega a conta e aplica o tema salvo nela. Devolve o tema (ou nulo).
  Future<Resposta<String?>> carregarConta() {
    return _consultar<String?>(() async {
      final r = await _api.conta();
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar a conta.').first);
      }
      final conta = Map<String, dynamic>.from(r['usuario'] as Map);
      final tema = conta['tema'] as String?;
      _fotoPerfil = _fotoDeUrlDeDados(conta['foto']);
      notifyListeners();
      aoCarregarTemaDaConta?.call(tema);
      return tema;
    });
  }

  /// Salva o tema na conta (vale em qualquer aparelho em que o usuário entrar).
  Future<ResultadoOperacao> salvarTemaDaConta(String tema) {
    return _executar(() async {
      final r = await _api.salvarTema(tema);
      return _resultado(r, 'Não foi possível salvar o tema.');
    });
  }

  Future<ResultadoOperacao> salvarNomeDoPerfil(String nome) {
    if (nome.trim().length < 3) {
      return Future.value(
        const ResultadoOperacao(erros: ['Informe seu nome completo.']),
      );
    }
    return _executar(() async {
      final r = await _api.salvarConta(nome: nome.trim());
      final resultado = _resultado(r, 'Não foi possível salvar o perfil.');
      if (!resultado.temErro && _usuarioLogado != null) {
        final u = _usuarioLogado!;
        _usuarioLogado = Usuario(
          id: u.id,
          nome: nome.trim(),
          login: u.login,
          tipo: u.tipo,
          status: u.status,
          criadoEm: u.criadoEm,
          estoqueIds: u.estoqueIds,
        );
        notifyListeners();
      }
      return resultado;
    });
  }

  Future<ResultadoOperacao> trocarSenha({
    required String senhaAtual,
    required String senha,
    required String confirmarSenha,
  }) {
    final erros = <String>[
      if (senhaAtual.isEmpty) 'Informe a senha atual.',
      if (senha.isEmpty) 'Informe a nova senha.',
      if (senha != confirmarSenha) 'As senhas não coincidem.',
    ];
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));
    return _executar(() async {
      // A API exige o nome em toda gravação do perfil.
      final r = await _api.trocarSenhaComNome(
        nome: _usuarioLogado?.nome ?? '',
        senhaAtual: senhaAtual,
        senha: senha,
        confirmarSenha: confirmarSenha,
      );
      return _resultado(r, 'Não foi possível trocar a senha.');
    });
  }
}
