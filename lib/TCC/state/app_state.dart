import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../models/leitura.dart';
import '../models/sensor.dart';
import '../models/usuario.dart';

/// Resultado padrão de operações que retornam mensagem de sucesso + erros,
/// no mesmo espírito dos controllers PHP (`compact('mensagem', 'erros')`).
class ResultadoOperacao {
  final String mensagem;
  final List<String> erros;

  const ResultadoOperacao({this.mensagem = '', this.erros = const []});

  bool get temErro => erros.isNotEmpty;
  bool get temSucesso => mensagem.isNotEmpty;
}

/// Estado global do app: sessão do usuário logado e todos os dados
/// "persistidos" em memória (equivalente ao banco de dados do sistema
/// original, que no PHP nunca chegou a ser configurado de verdade).
class AppState extends ChangeNotifier {
  AppState() {
    _seedDados();
  }

  final _rand = Random();

  // ── Sessão ──────────────────────────────────────────────────────────────

  Usuario? _usuarioLogado;
  DateTime? _loginHora;

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get ehAdmin => _usuarioLogado?.tipo == TipoUsuario.admin;

  /// Réplica da autenticação mockada de includes/auth.php:
  /// login "admin" entra como administrador; qualquer outro login
  /// entra como usuário comum. A senha só precisa estar preenchida.
  ResultadoOperacao login(String login, String senha) {
    final loginLimpo = login.trim();
    if (loginLimpo.isEmpty || senha.isEmpty) {
      return const ResultadoOperacao(erros: ['Credenciais inválidas.']);
    }

    if (loginLimpo == 'admin') {
      _usuarioLogado = _usuarios.firstWhere(
        (u) => u.login == 'admin',
        orElse: () => _usuarios.first,
      );
    } else {
      final existente = _usuarios.where((u) => u.login == loginLimpo);
      _usuarioLogado = existente.isNotEmpty
          ? existente.first
          : Usuario(
              id: 2,
              nome: 'Usuário Comum',
              login: loginLimpo,
              senhaHash: '',
              tipo: TipoUsuario.usuario,
            );
    }

    _loginHora = DateTime.now();
    notifyListeners();
    return const ResultadoOperacao(mensagem: 'Login realizado com sucesso.');
  }

  void logout() {
    _usuarioLogado = null;
    _loginHora = null;
    notifyListeners();
  }

  DateTime? get loginHora => _loginHora;

  // ── Sensores ────────────────────────────────────────────────────────────

  final List<Sensor> _sensores = [];
  List<Sensor> get sensores => List.unmodifiable(_sensores);

  int _proximoIdSensor = 1;

  ResultadoOperacao cadastrarSensor({
    required String nome,
    required TipoSensor? tipo,
    required String localizacao,
    required StatusSensor status,
  }) {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    final erros = <String>[];
    if (nome.trim().length < 3) {
      erros.add('Nome do sensor deve ter ao menos 3 caracteres.');
    }
    if (tipo == null) {
      erros.add('Tipo de sensor inválido.');
    }
    if (erros.isNotEmpty) return ResultadoOperacao(erros: erros);

    final sensor = Sensor(
      id: _proximoIdSensor++,
      nome: nome.trim(),
      tipo: tipo!,
      localizacao: localizacao.trim().isEmpty ? null : localizacao.trim(),
      status: status,
    );
    _sensores.add(sensor);
    notifyListeners();
    return ResultadoOperacao(
      mensagem: 'Sensor "${sensor.nome}" cadastrado com sucesso.',
    );
  }

  ResultadoOperacao alternarStatusSensor(int sensorId) {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    final idx = _sensores.indexWhere((s) => s.id == sensorId);
    if (idx == -1) {
      return const ResultadoOperacao(erros: ['Sensor não encontrado.']);
    }
    final atual = _sensores[idx];
    final novo = atual.status == StatusSensor.ativo
        ? StatusSensor.inativo
        : StatusSensor.ativo;
    atual.status = novo;
    notifyListeners();
    return ResultadoOperacao(
      mensagem: 'Status do sensor atualizado para "${novo.label}".',
    );
  }

  // ── Alertas ─────────────────────────────────────────────────────────────

  final List<Alerta> _alertas = [];
  List<Alerta> get alertas {
    final lista = List<Alerta>.from(_alertas);
    lista.sort((a, b) {
      if (a.resolvido != b.resolvido) {
        return a.resolvido ? 1 : -1;
      }
      return b.criadoEm.compareTo(a.criadoEm);
    });
    return lista;
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

  ResultadoOperacao resolverAlerta(int alertaId) {
    if (!ehAdmin) {
      return const ResultadoOperacao(erros: ['Acesso negado.']);
    }
    final idx = _alertas.indexWhere((a) => a.id == alertaId);
    if (idx == -1) {
      return const ResultadoOperacao(erros: ['ID de alerta inválido.']);
    }
    _alertas[idx].resolvido = true;
    notifyListeners();
    return const ResultadoOperacao(mensagem: 'Alerta marcado como resolvido.');
  }

  // ── Usuários ────────────────────────────────────────────────────────────

  final List<Usuario> _usuarios = [];
  int _proximoIdUsuario = 3;

  bool _loginExiste(String login) => _usuarios.any((u) => u.login == login);

  ResultadoOperacao cadastrarUsuario({
    required String nome,
    required String login,
    required String senha,
    required String confirmar,
    required TipoUsuario tipo,
    required StatusConta status,
  }) {
    final erros = <String>[];

    if (nome.trim().isEmpty || nome.trim().length < 3) {
      erros.add('Nome deve ter no mínimo 3 caracteres.');
    }
    if (nome.trim().length > 100) {
      erros.add('Nome muito longo (máx 100 chars).');
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-.]+$').hasMatch(nome.trim()) &&
        nome.trim().isNotEmpty) {
      erros.add('Nome contém caracteres inválidos.');
    }

    if (!RegExp(r'^[a-zA-Z0-9._\-]{3,50}$').hasMatch(login.trim())) {
      erros.add(
        'Login inválido (3-50 chars, apenas letras, números, ponto, hífen, underscore).',
      );
    }

    erros.addAll(_validarSenha(senha));
    if (senha != confirmar) {
      erros.add('As senhas não coincidem.');
    }

    if (erros.isEmpty && _loginExiste(login.trim())) {
      erros.add('O login \'${login.trim()}\' já está em uso.');
    }

    if (erros.isNotEmpty) return ResultadoOperacao(erros: erros);

    final usuario = Usuario(
      id: _proximoIdUsuario++,
      nome: nome.trim(),
      login: login.trim(),
      senhaHash: senha, // simulação; nunca use texto puro em produção real
      tipo: tipo,
      status: status,
    );
    _usuarios.add(usuario);
    notifyListeners();
    return ResultadoOperacao(
      mensagem: 'Usuário "${usuario.login}" cadastrado com sucesso.',
    );
  }

  List<String> _validarSenha(String senha) {
    final erros = <String>[];
    if (senha.length < 8) erros.add('Mínimo 8 caracteres.');
    if (!RegExp(r'[A-Z]').hasMatch(senha)) {
      erros.add('Pelo menos uma letra maiúscula.');
    }
    if (!RegExp(r'[a-z]').hasMatch(senha)) {
      erros.add('Pelo menos uma letra minúscula.');
    }
    if (!RegExp(r'[0-9]').hasMatch(senha)) erros.add('Pelo menos um número.');
    if (!RegExp(r'[\W_]').hasMatch(senha)) {
      erros.add('Pelo menos um caractere especial.');
    }
    return erros;
  }

  Usuario? buscarUsuarioPorLogin(String login) {
    final resultado = _usuarios.where((u) => u.login == login.trim());
    return resultado.isNotEmpty ? resultado.first : null;
  }

  ResultadoOperacao atualizarUsuario({
    required int id,
    required String nome,
    required String login,
    required TipoUsuario tipo,
    required StatusConta status,
    String senha = '',
    String confirmarSenha = '',
  }) {
    final idx = _usuarios.indexWhere((u) => u.id == id);
    if (idx == -1) {
      return const ResultadoOperacao(erros: ['Usuário não encontrado.']);
    }
    final erros = <String>[];
    if (nome.trim().length < 3) {
      erros.add('Nome deve ter no mínimo 3 caracteres.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._\-]{3,50}$').hasMatch(login.trim())) {
      erros.add('Login inválido.');
    }
    final loginDuplicado = _usuarios.any(
      (u) => u.login == login.trim() && u.id != id,
    );
    if (loginDuplicado) {
      erros.add('O login \'${login.trim()}\' já está em uso.');
    }
    if (senha.isNotEmpty || confirmarSenha.isNotEmpty) {
      erros.addAll(_validarSenha(senha));
      if (senha != confirmarSenha) {
        erros.add('As senhas não coincidem.');
      }
    }
    if (erros.isNotEmpty) return ResultadoOperacao(erros: erros);

    final u = _usuarios[idx];
    u.nome = nome.trim();
    u.login = login.trim();
    u.tipo = tipo;
    u.status = status;
    if (senha.isNotEmpty) u.senhaHash = senha;
    notifyListeners();
    return const ResultadoOperacao(mensagem: 'Usuário atualizado com sucesso.');
  }

  ResultadoOperacao excluirUsuario(int id) {
    if (_usuarioLogado?.id == id) {
      return const ResultadoOperacao(
        erros: ['Você não pode excluir seu próprio usuário.'],
      );
    }
    final removido = _usuarios.any((u) => u.id == id);
    if (!removido) {
      return const ResultadoOperacao(erros: ['Usuário não encontrado.']);
    }
    _usuarios.removeWhere((u) => u.id == id);
    notifyListeners();
    return const ResultadoOperacao(mensagem: 'Usuário excluído com sucesso.');
  }

  // ── Dashboard ───────────────────────────────────────────────────────────

  Map<String, dynamic> obterResumoDashboard() {
    final ativos =
        _sensores.where((s) => s.status == StatusSensor.ativo).length;
    final pendentes = contarAlertasPorSeveridade().values.fold<int>(
          0,
          (acc, v) => acc + v,
        );
    return {
      'sensoresAtivos': ativos,
      'sensoresTotal': _sensores.length,
      'alertasPendentes': pendentes,
      'ultimaAtualizacao': DateTime.now(),
    };
  }

  // ── Leituras / gráficos (dados simulados em tempo real) ────────────────

  /// Gera uma série de leituras simuladas para um sensor em uma janela de
  /// horas, com um passeio aleatório suave dentro da faixa típica do
  /// sensor — mesma ideia de app/models/DadosExemplo.php.
  List<Leitura> gerarLeituras(TipoSensor sensor, int horas) {
    final faixas = <TipoSensor, List<double>>{
      TipoSensor.temperatura: [18, 32],
      TipoSensor.ruido: [40, 95],
      TipoSensor.qualidadeAr: [20, 180],
      TipoSensor.umidade: [30, 80],
      TipoSensor.pressao: [995, 1025],
      TipoSensor.uv: [0, 11],
    };
    final faixa = faixas[sensor] ?? [0, 100];
    final min = faixa[0];
    final max = faixa[1];

    final pontos = (horas / 2).round().clamp(6, 48);
    final intervaloSeg = (horas * 3600) ~/ pontos;

    final leituras = <Leitura>[];
    final agora = DateTime.now();
    double valorAtual = (min + max) / 2;

    for (int i = pontos; i >= 0; i--) {
      final variacao = (max - min) * 0.05;
      valorAtual += (_rand.nextDouble() * 2 - 1) * variacao;
      valorAtual = valorAtual.clamp(min, max);
      leituras.add(
        Leitura(
          sensorTipo: sensor,
          valor: double.parse(valorAtual.toStringAsFixed(2)),
          lidoEm: agora.subtract(Duration(seconds: i * intervaloSeg)),
        ),
      );
    }
    return leituras;
  }

  /// Gera leituras históricas de todos os sensores entre duas datas,
  /// usadas pela tela de Relatórios.
  List<Leitura> gerarLeiturasPeriodo(DateTime inicio, DateTime fim) {
    final leituras = <Leitura>[];
    for (final tipo in TipoSensor.values) {
      final horas = fim.difference(inicio).inHours.clamp(1, 24 * 30);
      final base = gerarLeituras(tipo, horas);
      for (final l in base) {
        if (!l.lidoEm.isBefore(inicio) && !l.lidoEm.isAfter(fim)) {
          leituras.add(l);
        }
      }
    }
    leituras.sort((a, b) => b.lidoEm.compareTo(a.lidoEm));
    return leituras;
  }

  // ── Dados iniciais (equivalente aos "dados de exemplo" do PHP) ─────────

  void _seedDados() {
    _usuarios.addAll([
      Usuario(
        id: 1,
        nome: 'Admin de Testes',
        login: 'admin',
        senhaHash: 'Admin@123',
        tipo: TipoUsuario.admin,
      ),
      Usuario(
        id: 2,
        nome: 'Usuário Comum',
        login: 'usuario',
        senhaHash: 'Usuario@123',
        tipo: TipoUsuario.usuario,
      ),
    ]);

    _sensores.addAll([
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor Temperatura — Galpão A',
        tipo: TipoSensor.temperatura,
        localizacao: 'Galpão A',
      ),
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor Ruído — Linha 2',
        tipo: TipoSensor.ruido,
        localizacao: 'Linha de produção 2',
      ),
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor Qualidade do Ar — Setor B',
        tipo: TipoSensor.qualidadeAr,
        localizacao: 'Setor B',
      ),
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor Umidade — Estoque',
        tipo: TipoSensor.umidade,
        localizacao: 'Estoque central',
      ),
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor Pressão — Caldeira',
        tipo: TipoSensor.pressao,
        localizacao: 'Casa de caldeiras',
      ),
      Sensor(
        id: _proximoIdSensor++,
        nome: 'Sensor UV — Área Externa',
        tipo: TipoSensor.uv,
        localizacao: 'Pátio externo',
        status: StatusSensor.inativo,
      ),
    ]);

    final agora = DateTime.now();
    _alertas.addAll([
      Alerta(
        id: 1,
        sensorTipo: TipoSensor.temperatura,
        severidade: Severidade.critico,
        mensagem: 'Temperatura acima do limite de segurança',
        valor: 78.4,
        criadoEm: agora.subtract(const Duration(minutes: 10)),
      ),
      Alerta(
        id: 2,
        sensorTipo: TipoSensor.qualidadeAr,
        severidade: Severidade.atencao,
        mensagem: 'Qualidade do ar em nível moderado',
        valor: 132,
        criadoEm: agora.subtract(const Duration(minutes: 30)),
      ),
      Alerta(
        id: 3,
        sensorTipo: TipoSensor.ruido,
        severidade: Severidade.atencao,
        mensagem: 'Ruído acima do recomendado para o turno',
        valor: 87.2,
        criadoEm: agora.subtract(const Duration(hours: 1)),
      ),
      Alerta(
        id: 4,
        sensorTipo: TipoSensor.umidade,
        severidade: Severidade.info,
        mensagem: 'Umidade retornou ao patamar normal',
        valor: 54.1,
        resolvido: true,
        criadoEm: agora.subtract(const Duration(hours: 2)),
      ),
      Alerta(
        id: 5,
        sensorTipo: TipoSensor.pressao,
        severidade: Severidade.info,
        mensagem: 'Leitura de pressão registrada normalmente',
        valor: 1013,
        resolvido: true,
        criadoEm: agora.subtract(const Duration(hours: 3)),
      ),
      Alerta(
        id: 6,
        sensorTipo: TipoSensor.uv,
        severidade: Severidade.critico,
        mensagem: 'Índice UV muito alto na área externa',
        valor: 11.3,
        criadoEm: agora.subtract(const Duration(hours: 4)),
      ),
    ]);
  }
}
