import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
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

  Future<Resposta<ResumoPainel>> carregarResumo() {
    return _consultar(() async {
      final r = await _api.dashboard();
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar o painel.').first);
      }
      return ResumoPainel.fromJson(
        Map<String, dynamic>.from(r['resumo'] as Map),
      );
    });
  }

  // ── Sensores ────────────────────────────────────────────────────────────

  List<Sensor> _sensores = [];
  List<Sensor> get sensores => List.unmodifiable(_sensores);

  Future<ResultadoOperacao> carregarSensores() {
    return _executar(() async {
      final r = await _api.listarSensores();
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

  /// Gestão de sensores (cadastro/alteração de status) é EXCLUSIVA de
  /// administradores — o backend (api/sensores.php) também bloqueia isso de
  /// forma independente; este `if` é só uma segunda camada para dar retorno
  /// imediato na tela.
  Future<ResultadoOperacao> cadastrarSensor({
    required String nome,
    required TipoSensor? tipo,
    required String localizacao,
    required StatusSensor status,
  }) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    final erros = <String>[];
    if (nome.trim().length < 3) {
      erros.add('Nome do sensor deve ter ao menos 3 caracteres.');
    }
    if (tipo == null) erros.add('Tipo de sensor inválido.');
    if (erros.isNotEmpty) return Future.value(ResultadoOperacao(erros: erros));

    return _executar(() async {
      final r = await _api.cadastrarSensor(
        nome: nome.trim(),
        tipo: tipo!.chave,
        localizacao: localizacao.trim(),
        status: status.chave,
      );
      final resultado = _resultado(r, 'Não foi possível cadastrar o sensor.');
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

  /// Pendentes primeiro; dentro de cada grupo, os mais recentes no topo.
  List<Alerta> get alertas {
    final lista = List<Alerta>.from(_alertas);
    lista.sort((a, b) {
      if (a.resolvido != b.resolvido) return a.resolvido ? 1 : -1;
      return b.criadoEm.compareTo(a.criadoEm);
    });
    return lista;
  }

  Future<ResultadoOperacao> carregarAlertas() {
    return _executar(() async {
      final r = await _api.listarAlertas();
      if (r['sucesso'] != true) {
        return ResultadoOperacao(erros: _erros(r, 'Erro ao carregar alertas.'));
      }
      _alertas = (r['alertas'] as List)
          .map((e) => Alerta.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
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

  /// Quantidade de alertas PENDENTES por severidade.
  Map<Severidade, int> contarAlertasPorSeveridade() {
    final contagem = {for (final s in Severidade.values) s: 0};
    for (final a in _alertas) {
      if (!a.resolvido) {
        contagem[a.severidade] = (contagem[a.severidade] ?? 0) + 1;
      }
    }
    return contagem;
  }

  Future<ResultadoOperacao> resolverAlerta(int alertaId) {
    if (!ehAdmin) {
      return Future.value(const ResultadoOperacao(erros: ['Acesso negado.']));
    }

    return _executar(() async {
      final r = await _api.resolverAlerta(alertaId);
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
          erros: ['Você não pode excluir seu próprio usuário.'],
        ),
      );
    }

    return _executar(() async {
      final r = await _api.excluirUsuario(id);
      return _resultado(r, 'Não foi possível excluir o usuário.');
    });
  }

  // ── Gráficos e relatórios ───────────────────────────────────────────────

  Future<Resposta<SerieLeituras>> carregarLeituras(
    TipoSensor sensor,
    int horas,
  ) {
    return _consultar(() async {
      final r = await _api.leituras(sensor: sensor.chave, horas: horas);
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar leituras.').first);
      }

      final labels = List<String>.from(r['labels'] as List);
      final valores = List<num>.from(r['valores'] as List);
      final pontos = <Leitura>[
        for (var i = 0; i < labels.length && i < valores.length; i++)
          Leitura(
            sensorTipo: sensor,
            valor: valores[i].toDouble(),
            lidoEm: DateTime.tryParse(labels[i]) ?? DateTime.now(),
          ),
      ];
      return SerieLeituras(
        pontos: pontos,
        total: (r['total'] as num?)?.toInt() ?? pontos.length,
      );
    });
  }

  Future<Resposta<RelatorioResultado>> carregarRelatorio(
    DateTime inicio,
    DateTime fim, {
    TipoSensor? sensor,
    double? valorMin,
    double? valorMax,
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
      );
      if (r['sucesso'] != true) {
        throw ApiException(_erros(r, 'Erro ao carregar o relatório.').first);
      }

      return RelatorioResultado(
        leituras: (r['leituras'] as List)
            .map((e) => Leitura.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        resumo: (r['resumo'] as List)
            .map(
              (e) => ResumoSensor.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    });
  }
}
