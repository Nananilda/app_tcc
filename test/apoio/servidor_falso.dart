import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Uma chamada recebida pelo [ServidorFalso] (para os testes conferirem o que o
/// app enviou: caminho, cabeçalhos e corpo).
class Requisicao {
  Requisicao(
    this.metodo,
    this.arquivo,
    this.query,
    this.cabecalhos,
    this.corpo,
  );

  final String metodo;

  /// Ex.: `usuarios.php`.
  final String arquivo;
  final Map<String, String> query;
  final Map<String, String> cabecalhos;
  final Map<String, dynamic> corpo;
}

/// Imita a API PHP do ÁKRON (`tcc/api/*.php`) em memória, para testar o app
/// sem rede nem banco de dados. As respostas seguem o formato real do backend.
class ServidorFalso {
  ServidorFalso() {
    cliente = MockClient(_atender);
  }

  late final MockClient cliente;

  /// Todas as chamadas recebidas, em ordem.
  final List<Requisicao> requisicoes = [];

  /// Contas conhecidas: login → dados. A senha de teste é `Teste@123` para todos.
  final Map<String, Map<String, dynamic>> usuarios = {
    'admin': _usuario(1, 'Admin de Testes', 'admin', 'admin', 'ativo'),
    'maria.souza': _usuario(
      2,
      'Maria Souza',
      'maria.souza',
      'usuario',
      'ativo',
    ),
    'joao.silva': _usuario(3, 'João Silva', 'joao.silva', 'usuario', 'inativo'),
  };

  /// Sensores cadastrados (a ordem é a da lista).
  final List<Map<String, dynamic>> sensores = [
    {
      'id': 1,
      'nome': 'Sensor Estufa',
      'tipo': 'temperatura',
      'localizacao': 'Estufa 1',
      'status': 'ativo',
      'criado_em': '2026-10-01 08:00:00',
    },
    {
      'id': 2,
      'nome': 'Sensor Ruído Galpão',
      'tipo': 'ruido',
      'localizacao': null,
      'status': 'inativo',
      'criado_em': '2026-10-02 10:30:00',
    },
  ];

  /// Alertas (um crítico pendente, um de atenção pendente e um informativo já resolvido).
  final List<Map<String, dynamic>> alertas = [
    {
      'id': 1,
      'sensor_tipo': 'temperatura',
      'sensor_nome': 'Sensor Estufa',
      'severidade': 'critico',
      'mensagem': 'Temperatura acima do limite',
      'valor': '41.50',
      'resolvido': 0,
      'criado_em': '2026-10-09 13:00:00',
    },
    {
      'id': 2,
      'sensor_tipo': 'ruido',
      'sensor_nome': 'Sensor Ruído Galpão',
      'severidade': 'atencao',
      'mensagem': 'Ruído elevado no turno',
      'valor': '88.00',
      'resolvido': 0,
      'criado_em': '2026-10-09 09:15:00',
    },
    {
      'id': 3,
      'sensor_tipo': 'umidade',
      'sensor_nome': 'Sensor Umidade',
      'severidade': 'info',
      'mensagem': 'Umidade normalizada',
      'valor': '55.00',
      'resolvido': 1,
      'criado_em': '2026-10-08 18:00:00',
    },
  ];

  static const String senhaDeTeste = 'Teste@123';
  static const String token = 'tokendeteste0123456789abcdef';

  /// Quando verdadeiro, qualquer chamada autenticada responde 401 (sessão caiu).
  bool sessaoExpirada = false;

  /// Quando verdadeiro, simula servidor fora do ar (falha de conexão).
  bool semConexao = false;

  static Map<String, dynamic> _usuario(
    int id,
    String nome,
    String login,
    String tipo,
    String status,
  ) => {
    'id': id,
    'nome': nome,
    'login': login,
    'tipo': tipo,
    'status': status,
    'criado_em': '2026-10-01 09:00:00',
  };

  Iterable<Requisicao> chamadasA(String arquivo) =>
      requisicoes.where((r) => r.arquivo == arquivo);

  Future<http.Response> _atender(http.Request pedido) async {
    if (semConexao) throw http.ClientException('sem conexão', pedido.url);

    final arquivo = pedido.url.pathSegments.last;
    final corpo = pedido.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(pedido.body) as Map<String, dynamic>;
    requisicoes.add(
      Requisicao(
        pedido.method,
        arquivo,
        pedido.url.queryParameters,
        pedido.headers,
        corpo,
      ),
    );

    http.Response json(Map<String, dynamic> dados, [int status = 200]) =>
        http.Response.bytes(
          utf8.encode(jsonEncode(dados)),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );

    // status.php e login.php são públicos; o resto exige o token
    if (arquivo == 'status.php') {
      return json({
        'sucesso': true,
        'sistema': 'ÁKRON',
        'versao': '2.0',
        'banco': 'ok',
      });
    }
    if (arquivo == 'login.php') return _login(corpo, json);

    final autorizado = pedido.headers['Authorization'] == 'Bearer $token';
    if (!autorizado || sessaoExpirada) {
      return json({
        'sucesso': false,
        'mensagem': 'Sessão expirada. Faça login novamente.',
      }, 401);
    }

    switch (arquivo) {
      case 'logout.php':
        return json({'sucesso': true});
      case 'dashboard.php':
        return json({
          'sucesso': true,
          'resumo': {
            'sensores_ativos': 6,
            'sensores_total': 7,
            'alertas_pendentes': 5,
            'ultima_atualizacao': '09/10/2026 14:30',
          },
        });
      case 'sensores.php':
        return _sensores(pedido, corpo, json);
      case 'alertas.php':
        return _alertas(pedido, corpo, json);
      case 'leituras.php':
        if (pedido.method == 'POST') return _registrarLeitura(corpo, json);
        return json({
          'sucesso': true,
          'labels': [
            for (var h = 0; h < 12; h++)
              '2026-10-09 ${(h + 6).toString().padLeft(2, '0')}:00:00',
          ],
          'valores': [for (var h = 0; h < 12; h++) 22.0 + h * 0.5],
          'total': 144,
        });
      case 'relatorio.php':
        return json({
          'sucesso': true,
          'leituras': [
            {
              'sensor_tipo': 'temperatura',
              'sensor_nome': 'Sensor Estufa',
              'valor': '25.50',
              'lido_em': '2026-10-09 12:00:00',
            },
            {
              'sensor_tipo': 'temperatura',
              'sensor_nome': 'Sensor Estufa',
              'valor': '24.00',
              'lido_em': '2026-10-09 11:00:00',
            },
          ],
          'resumo': [
            {
              'sensor_tipo': 'temperatura',
              'total': 2,
              'media': '24.75',
              'minimo': '24.00',
              'maximo': '25.50',
            },
          ],
        });
      case 'usuarios.php':
        return _usuarios(pedido, corpo, json);
      default:
        return json({'sucesso': false, 'mensagem': 'Não encontrado.'}, 404);
    }
  }

  http.Response _sensores(
    http.Request pedido,
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    if (pedido.method == 'GET') {
      return json({'sucesso': true, 'sensores': sensores});
    }

    switch (corpo['acao']) {
      case 'cadastrar':
        sensores.add({
          'id': sensores.length + 1,
          'nome': corpo['nome'],
          'tipo': corpo['tipo'],
          'localizacao': (corpo['localizacao'] as String).isEmpty
              ? null
              : corpo['localizacao'],
          'status': corpo['status'],
          'criado_em': '2026-10-09 15:00:00',
        });
        return json({
          'sucesso': true,
          'mensagem': 'Sensor cadastrado com sucesso!',
          'erros': const [],
        });
      case 'toggle_status':
        final sensor = sensores.firstWhere(
          (s) => s['id'] == corpo['sensor_id'],
        );
        sensor['status'] = corpo['novo_status'];
        return json({
          'sucesso': true,
          'mensagem': 'Status do sensor atualizado.',
          'erros': const [],
        });
    }
    return json({
      'sucesso': false,
      'mensagem': 'Ação desconhecida.',
      'erros': const ['Ação desconhecida.'],
    }, 400);
  }

  /// Limites dos alertas automáticos (os mesmos de AlertaModel::LIMITES).
  static const Map<String, dynamic> limitesDeAlerta = {
    'temperatura': {
      'max': {'atencao': 30, 'critico': 35},
    },
    'ruido': {
      'max': {'atencao': 85, 'critico': 95},
    },
    'qualidade_ar': {
      'max': {'atencao': 100, 'critico': 150},
    },
    'umidade': {
      'min': {'atencao': 35, 'critico': 20},
      'max': {'atencao': 80, 'critico': 90},
    },
    'pressao': {
      'min': {'atencao': 1000, 'critico': 990},
      'max': {'atencao': 1030, 'critico': 1040},
    },
    'uv': {
      'max': {'atencao': 6, 'critico': 8},
    },
  };

  http.Response _recusa(
    List<String> erros,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) => json({'sucesso': false, 'mensagem': '', 'erros': erros}, 422);

  /// POST alertas.php acao=criar (mesmas validações do AlertaController).
  http.Response _criarAlerta(
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    final sensor = sensores.where((s) => s['id'] == corpo['sensor_id']);
    final mensagem = '${corpo['mensagem'] ?? ''}'.trim();
    final erros = <String>[
      if (sensor.isEmpty) 'Sensor não encontrado.',
      if (!['info', 'atencao', 'critico'].contains(corpo['severidade']))
        'Severidade inválida.',
      if (mensagem.length < 3)
        'A mensagem do alerta deve ter ao menos 3 caracteres.',
    ];
    if (erros.isNotEmpty) return _recusa(erros, json);

    final valor = corpo['valor'] == null
        ? null
        : double.tryParse('${corpo['valor']}'.replaceAll(',', '.'));
    final id =
        alertas.map((a) => a['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    alertas.add({
      'id': id,
      'sensor_tipo': sensor.first['tipo'],
      'sensor_nome': sensor.first['nome'],
      'severidade': corpo['severidade'],
      'mensagem': mensagem,
      'valor': valor?.toStringAsFixed(2),
      'resolvido': 0,
      'criado_em': '2026-10-09 16:00:00',
    });
    return json({
      'sucesso': true,
      'mensagem': 'Alerta criado com sucesso.',
      'erros': const [],
      'id': id,
    });
  }

  /// POST leituras.php: grava a leitura e, para temperatura acima de 35 °C,
  /// cria o alerta crítico (sem duplicar um igual ainda pendente).
  http.Response _registrarLeitura(
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    final sensor = sensores.where((s) => s['id'] == corpo['sensor_id']);
    if (sensor.isEmpty) return _recusa(['Sensor não encontrado.'], json);
    if (sensor.first['status'] != 'ativo') {
      return _recusa([
        'O sensor "${sensor.first['nome']}" está inativo e não pode enviar leituras.',
      ], json);
    }
    final valor = double.tryParse('${corpo['valor']}'.replaceAll(',', '.'));
    if (valor == null) {
      return _recusa([
        'Informe o valor da leitura como um número (ex.: 36,5).',
      ], json);
    }

    const texto = 'Temperatura acima do limite crítico de 35 °C';
    if (sensor.first['tipo'] != 'temperatura' || valor <= 35) {
      return json({
        'sucesso': true,
        'mensagem': 'Leitura registrada.',
        'erros': const [],
        'alerta': null,
      });
    }
    final existente = alertas.where(
      (a) => a['mensagem'] == texto && a['resolvido'] == 0,
    );
    if (existente.isNotEmpty) {
      return json({
        'sucesso': true,
        'mensagem':
            'Leitura registrada. Já existe um alerta crítico pendente para este limite: $texto.',
        'erros': const [],
      });
    }
    alertas.add({
      'id': alertas.length + 1,
      'sensor_tipo': 'temperatura',
      'sensor_nome': sensor.first['nome'],
      'severidade': 'critico',
      'mensagem': texto,
      'valor': valor.toStringAsFixed(2),
      'resolvido': 0,
      'criado_em': '2026-10-09 16:05:00',
    });
    return json({
      'sucesso': true,
      'mensagem':
          'Leitura registrada. Alerta crítico gerado automaticamente: $texto.',
      'erros': const [],
    });
  }

  http.Response _alertas(
    http.Request pedido,
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    if (pedido.method == 'GET') {
      return json({
        'sucesso': true,
        'alertas': alertas,
        'contagem': const {'critico': 1, 'atencao': 1, 'info': 0},
        'limites': limitesDeAlerta,
      });
    }

    if (corpo['acao'] == 'criar') return _criarAlerta(corpo, json);

    if (corpo['acao'] == 'resolver') {
      alertas.firstWhere((a) => a['id'] == corpo['alerta_id'])['resolvido'] = 1;
      return json({
        'sucesso': true,
        'mensagem': 'Alerta marcado como resolvido.',
        'erros': const [],
      });
    }
    return json({
      'sucesso': false,
      'mensagem': 'Ação desconhecida.',
      'erros': const ['Ação desconhecida.'],
    }, 400);
  }

  http.Response _login(
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    final conta = usuarios[corpo['login']];
    if (conta == null || corpo['senha'] != senhaDeTeste) {
      return json({
        'sucesso': false,
        'mensagem': 'Login ou senha inválidos.',
      }, 401);
    }
    if (conta['status'] != 'ativo') {
      return json({
        'sucesso': false,
        'mensagem': 'Conta inativa. Procure o administrador.',
      }, 401);
    }
    return json({
      'sucesso': true,
      'mensagem': 'Login realizado com sucesso.',
      'usuario': conta,
      'token': token,
    });
  }

  http.Response _usuarios(
    http.Request pedido,
    Map<String, dynamic> corpo,
    http.Response Function(Map<String, dynamic>, [int]) json,
  ) {
    if (pedido.method == 'GET') {
      final login = pedido.url.queryParameters['login'];
      if (login == null) {
        return json({'sucesso': true, 'usuarios': usuarios.values.toList()});
      }
      final achado = usuarios[login];
      return json({
        'sucesso': achado != null,
        'usuario': achado,
      }, achado != null ? 200 : 404);
    }

    switch (corpo['acao']) {
      case 'cadastrar':
        final erros = <String>[];
        if ((corpo['nome'] as String).trim().length < 3) {
          erros.add('Nome deve ter ao menos 3 caracteres.');
        }
        if (usuarios.containsKey(corpo['login'])) {
          erros.add('Este login já está em uso.');
        }
        if (corpo['senha'] != corpo['confirmar']) {
          erros.add('A confirmação da senha não confere.');
        }
        if (erros.isNotEmpty) {
          return json({'sucesso': false, 'mensagem': '', 'erros': erros}, 422);
        }

        usuarios[corpo['login']] = _usuario(
          usuarios.length + 1,
          corpo['nome'],
          corpo['login'],
          corpo['tipo'],
          corpo['status'],
        );
        return json({
          'sucesso': true,
          'mensagem': 'Usuário cadastrado com sucesso!',
          'erros': const [],
        });

      case 'atualizar':
        final conta = usuarios.values.firstWhere((u) => u['id'] == corpo['id']);
        usuarios.remove(conta['login']);
        conta
          ..['nome'] = corpo['nome']
          ..['login'] = corpo['login']
          ..['tipo'] = corpo['tipo']
          ..['status'] = corpo['status'];
        usuarios[conta['login']] = conta;
        return json({
          'sucesso': true,
          'mensagem': 'Usuário atualizado com sucesso!',
          'erros': const [],
        });

      case 'excluir':
        usuarios.removeWhere((_, u) => u['id'] == corpo['id']);
        return json({
          'sucesso': true,
          'mensagem': 'Usuário excluído com sucesso!',
          'erros': const [],
        });
    }
    return json({
      'sucesso': false,
      'mensagem': 'Ação desconhecida.',
      'erros': const ['Ação desconhecida.'],
    }, 400);
  }
}
