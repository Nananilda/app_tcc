import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../models/leitura.dart';
import '../models/sensor.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Resultado padrão de operações que retornam mensagem de sucesso + erros,
/// no mesmo espírito dos controllers PHP (`compact('mensagem', 'erros')`).
class ResultadoOperacao {
  final String mensagem;
  final List<String> erros;

  const ResultadoOperacao({this.mensagem = '', this.erros = const []});

  bool get temErro => erros.isNotEmpty;
  bool get temSucesso => mensagem.isNotEmpty;
}

/// Estado global do app: sessão do usuário logado e cache local dos dados
/// vindos da API (api/*.php), que por sua vez lê/escreve no MySQL
/// (banco_tcc) através de app/config/conexao.php.
class AppState extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // ── Sessão ──────────────────────────────────────────────────────────────

  Usuario? _usuarioLogado;
  DateTime? _loginHora;

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get ehAdmin => _usuarioLogado?.tipo == TipoUsuario.admin;
  DateTime? get loginHora => _loginHora;

  Future<ResultadoOperacao> login(String login, String senha) async {
    final loginLimpo = login.trim();
    if (loginLimpo.isEmpty || senha.isEmpty) {
      return const ResultadoOperacao(erros: ['Credenciais inválidas.']);
    }

    try {
      final resposta = await _api.login(loginLimpo, senha);
      if (resposta['sucesso'] != true) {
        return ResultadoOperacao(
          erros: [resposta['mensagem'] as String? ?? 'Login ou senha inválidos.'],
        );
      }
      _usuarioLogado = Usuario.fromJson(
        Map<String, dynamic>.from(resposta['usuario'] as Map),
      );
      _loginHora = DateTime.now();
      notifyListeners();
      return const ResultadoOperacao(mensagem: 'Login realizado com sucesso.');
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on ApiException {
      // Mesmo se a chamada falhar, encerramos a sessão localmente.
    }
    _usuarioLogado = null;
    _loginHora = null;
    _sensores.clear();
    _alertas.clear();
    _usuarios.clear();
    notifyListeners();
  }

  // ── Sensores ────────────────────────────────────────────────────────────

  List<Sensor> _sensores = [];
  List<Sensor> get sensores => List.unmodifiable(_sensores);

  Future<ResultadoOperacao> carregarSensores() async {
    try {
      final resposta = await _api.listarSensores();
      if (resposta['sucesso'] != true) {
        return ResultadoOperacao(
          erros: List<String>.from(resposta['erros'] ?? const ['Erro ao carregar sensores.']),
        );
      }
      _sensores = (resposta['sensores'] as List)
          .map((e) => Sensor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  /// Gestão de sensores (cadastro/alteração de status) é EXCLUSIVA de
  /// administradores — o backend (api/sensores.php) também bloqueia isso
  /// de forma independente, então este `if` é apenas uma segunda camada
  /// de proteção para dar feedback imediato na UI.
  Future<ResultadoOperacao> cadastrarSensor({
    required String nome,
    required TipoSensor? tipo,
    required String localizacao,
    required StatusSensor status,
  }) async {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    if (nome.trim().length < 3 || tipo == null) {
      final erros = <String>[];
      if (nome.trim().length < 3) {
        erros.add('Nome do sensor deve ter ao menos 3 caracteres.');
      }
      if (tipo == null) erros.add('Tipo de sensor inválido.');
      return ResultadoOperacao(erros: erros);
    }

    try {
      final resposta = await _api.cadastrarSensor(
        nome: nome.trim(),
        tipo: tipo.chave,
        localizacao: localizacao.trim(),
        status: status.chave,
      );
      if (resposta['sucesso'] == true) {
        await carregarSensores();
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Future<ResultadoOperacao> alternarStatusSensor(int sensorId) async {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    final idx = _sensores.indexWhere((s) => s.id == sensorId);
    if (idx == -1) {
      return const ResultadoOperacao(erros: ['Sensor não encontrado.']);
    }
    final novo = _sensores[idx].status == StatusSensor.ativo
        ? StatusSensor.inativo
        : StatusSensor.ativo;

    try {
      final resposta = await _api.alternarStatusSensor(
        sensorId: sensorId,
        novoStatus: novo.chave,
      );
      if (resposta['sucesso'] == true) {
        await carregarSensores();
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  // ── Alertas ─────────────────────────────────────────────────────────────

  List<Alerta> _alertas = [];
  List<Alerta> get alertas {
    final lista = List<Alerta>.from(_alertas);
    lista.sort((a, b) {
      if (a.resolvido != b.resolvido) return a.resolvido ? 1 : -1;
      return b.criadoEm.compareTo(a.criadoEm);
    });
    return lista;
  }

  Future<ResultadoOperacao> carregarAlertas() async {
    try {
      final resposta = await _api.listarAlertas();
      if (resposta['sucesso'] != true) {
        return ResultadoOperacao(
          erros: List<String>.from(resposta['erros'] ?? const ['Erro ao carregar alertas.']),
        );
      }
      _alertas = (resposta['alertas'] as List)
          .map((e) => Alerta.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Map<Severidade, int> contarAlertasPorSeveridade() {
    final contagem = {for (final s in Severidade.values) s: 0};
    for (final a in _alertas) {
      if (!a.resolvido) {
        contagem[a.severidade] = (contagem[a.severidade] ?? 0) + 1;
      }
    }
    return contagem;
  }

  Future<ResultadoOperacao> resolverAlerta(int alertaId) async {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    try {
      final resposta = await _api.resolverAlerta(alertaId);
      if (resposta['sucesso'] == true) {
        await carregarAlertas();
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  // ── Usuários (gestão exclusiva de administradores) ────────────────────

  List<Usuario> _usuarios = [];
  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  Future<ResultadoOperacao> carregarUsuarios() async {
    if (!ehAdmin) return const ResultadoOperacao(erros: ['Acesso negado.']);
    try {
      final resposta = await _api.listarUsuarios();
      if (resposta['sucesso'] != true) {
        return ResultadoOperacao(
          erros: List<String>.from(resposta['erros'] ?? const ['Erro ao carregar usuários.']),
        );
      }
      _usuarios = (resposta['usuarios'] as List)
          .map((e) => Usuario.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
      return const ResultadoOperacao();
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Future<Usuario?> buscarUsuarioPorLogin(String login) async {
    if (!ehAdmin || login.trim().isEmpty) return null;
    try {
      final resposta = await _api.buscarUsuarioPorLogin(login.trim());
      if (resposta['sucesso'] == true && resposta['usuario'] != null) {
        return Usuario.fromJson(Map<String, dynamic>.from(resposta['usuario'] as Map));
      }
      return null;
    } on ApiException {
      return null;
    }
  }

  Future<ResultadoOperacao> cadastrarUsuario({
    required String nome,
    required String login,
    required String senha,
    required String confirmar,
    required TipoUsuario tipo,
    required StatusConta status,
  }) async {
    if (!ehAdmin) return const ResultadoOperacao(erros: ['Acesso negado.']);
    try {
      final resposta = await _api.cadastrarUsuario(
        nome: nome.trim(),
        login: login.trim(),
        senha: senha,
        confirmar: confirmar,
        tipo: tipo.chave,
        status: status.chave,
      );
      if (resposta['sucesso'] == true) {
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Future<ResultadoOperacao> atualizarUsuario({
    required int id,
    required String nome,
    required String login,
    required TipoUsuario tipo,
    required StatusConta status,
    String senha = '',
    String confirmarSenha = '',
  }) async {
    if (!ehAdmin) return const ResultadoOperacao(erros: ['Acesso negado.']);
    try {
      final resposta = await _api.atualizarUsuario(
        id: id,
        nome: nome.trim(),
        login: login.trim(),
        tipo: tipo.chave,
        status: status.chave,
        senha: senha,
        confirmarSenha: confirmarSenha,
      );
      if (resposta['sucesso'] == true) {
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  Future<ResultadoOperacao> excluirUsuario(int id) async {
    if (!ehAdmin) return const ResultadoOperacao(erros: ['Acesso negado.']);
    if (_usuarioLogado?.id == id) {
      return const ResultadoOperacao(
        erros: ['Você não pode excluir seu próprio usuário.'],
      );
    }
    try {
      final resposta = await _api.excluirUsuario(id);
      if (resposta['sucesso'] == true) {
        return ResultadoOperacao(mensagem: resposta['mensagem'] as String? ?? '');
      }
      return ResultadoOperacao(erros: List<String>.from(resposta['erros'] ?? const []));
    } on ApiException catch (e) {
      return ResultadoOperacao(erros: [e.mensagem]);
    }
  }

  // ── Dashboard ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> obterResumoDashboard() async {
    try {
      final resposta = await _api.dashboard();
      if (resposta['sucesso'] == true) {
        return Map<String, dynamic>.from(resposta['resumo'] as Map);
      }
      return null;
    } on ApiException {
      return null;
    }
  }

  // ── Leituras / gráficos e relatórios ───────────────────────────────────

  Future<List<Leitura>> carregarLeituras(TipoSensor sensor, int horas) async {
    try {
      final resposta = await _api.leituras(sensor: sensor.chave, horas: horas);
      if (resposta['sucesso'] != true) return [];
      final labels = List<String>.from(resposta['labels'] as List);
      final valores = List<num>.from(resposta['valores'] as List);
      return [
        for (var i = 0; i < labels.length && i < valores.length; i++)
          Leitura(
            sensorTipo: sensor,
            valor: valores[i].toDouble(),
            lidoEm: DateTime.tryParse(labels[i]) ?? DateTime.now(),
          ),
      ];
    } on ApiException {
      return [];
    }
  }

  Future<List<Leitura>> carregarRelatorio(
    DateTime inicio,
    DateTime fim, {
    TipoSensor? sensor,
    double? valorMin,
    double? valorMax,
  }) async {
    String data(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      final resposta = await _api.relatorio(
        dataIni: data(inicio),
        dataFim: data(fim),
        sensor: sensor?.chave ?? '',
        valMin: valorMin?.toString() ?? '',
        valMax: valorMax?.toString() ?? '',
      );
      if (resposta['sucesso'] != true) return [];
      return (resposta['leituras'] as List)
          .map((e) => Leitura.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on ApiException {
      return [];
    }
  }
}
