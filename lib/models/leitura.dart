import 'sensor.dart';

/// Uma leitura pontual de um sensor, usada nos gráficos e relatórios.
/// Equivale às linhas da tabela `leitura_sensor` (o tipo vem do JOIN com `sensores`).
class Leitura {
  final TipoSensor sensorTipo;
  final String? sensorNome;
  final double valor;
  final DateTime lidoEm;

  /// Sensor e estoque de origem. Um tipo de medição pode ter VÁRIOS sensores:
  /// o gráfico precisa desenhar uma linha por [sensorId], nunca uma só.
  final int sensorId;
  final int estoqueId;
  final String? estoqueNome;

  /// `normal`, `atencao` ou `critico` (só no relatório).
  final String? situacao;

  /// Origem do dado: `sensor`, `manual`, `demonstracao` ou `nao_informada`.
  final String? origem;

  /// Passou mais de 2x o prazo de comunicação do sensor desde o ponto
  /// anterior: NÃO ligar este ponto ao anterior no gráfico.
  final bool lacunaAntes;

  const Leitura({
    required this.sensorTipo,
    this.sensorNome,
    required this.valor,
    required this.lidoEm,
    this.sensorId = 0,
    this.estoqueId = 0,
    this.estoqueNome,
    this.situacao,
    this.origem,
    this.lacunaAntes = false,
  });

  factory Leitura.fromJson(Map<String, dynamic> json) {
    return Leitura(
      sensorTipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      sensorNome: json['sensor_nome'] as String?,
      valor: double.parse(json['valor'].toString()),
      lidoEm: DateTime.parse(json['lido_em'] as String),
      sensorId: int.tryParse('${json['sensor_id'] ?? 0}') ?? 0,
      estoqueId: int.tryParse('${json['estoque_id'] ?? 0}') ?? 0,
      estoqueNome: json['estoque_nome'] as String?,
      situacao: json['situacao'] as String?,
      origem: json['origem'] as String?,
      lacunaAntes:
          json['lacuna_antes'] == true ||
          json['lacuna_antes'] == 1 ||
          json['lacuna_antes'] == '1',
    );
  }
}

/// Período sem leituras de um sensor (`lacunas` em api/leituras.php).
class LacunaLeitura {
  final int sensorId;
  final DateTime de;
  final DateTime? ate;
  final int segundos;

  /// A lacuna continua aberta: o sensor segue sem enviar leituras.
  final bool aberta;

  const LacunaLeitura({
    required this.sensorId,
    required this.de,
    this.ate,
    required this.segundos,
    required this.aberta,
  });

  factory LacunaLeitura.fromJson(Map<String, dynamic> json) => LacunaLeitura(
    sensorId: int.tryParse('${json['sensor_id'] ?? 0}') ?? 0,
    de: DateTime.tryParse('${json['de']}') ?? DateTime.now(),
    ate: DateTime.tryParse('${json['ate'] ?? ''}'),
    segundos: int.tryParse('${json['segundos'] ?? 0}') ?? 0,
    aberta: json['aberta'] == true || json['aberta'] == 1,
  );
}

/// Série de um tipo de sensor para o gráfico de linha.
/// [total] é a quantidade de leituras brutas que formam os [pontos]
/// (a API agrupa leituras muito frequentes em médias por intervalo).
class SerieLeituras {
  final List<Leitura> pontos;
  final int total;
  final List<LacunaLeitura> lacunas;

  /// IDs dos sensores cujo último dado está vencido (fora do prazo).
  final List<int> sensoresDesatualizados;

  /// Janela de tempo consultada (início e fim), quando informada.
  final DateTime? janelaInicio;
  final DateTime? janelaFim;

  const SerieLeituras({
    required this.pontos,
    required this.total,
    this.lacunas = const [],
    this.sensoresDesatualizados = const [],
    this.janelaInicio,
    this.janelaFim,
  });

  /// Pontos agrupados por sensor, em ordem cronológica — uma linha por sensor.
  Map<int, List<Leitura>> get porSensor {
    final mapa = <int, List<Leitura>>{};
    for (final p in pontos) {
      mapa.putIfAbsent(p.sensorId, () => []).add(p);
    }
    for (final lista in mapa.values) {
      lista.sort((a, b) => a.lidoEm.compareTo(b.lidoEm));
    }
    return mapa;
  }

  static const vazia = SerieLeituras(pontos: [], total: 0);
}

/// Linha do resumo estatístico do relatório (por tipo de sensor), calculada
/// pelo banco sobre TODAS as leituras do filtro.
class ResumoSensor {
  final TipoSensor tipo;
  final int total;
  final double media;
  final double minimo;
  final double maximo;

  /// Leituras fora dos limites (atenção ou crítico).
  final int foraLimites;

  const ResumoSensor({
    required this.tipo,
    required this.total,
    required this.media,
    required this.minimo,
    required this.maximo,
    this.foraLimites = 0,
  });

  factory ResumoSensor.fromJson(Map<String, dynamic> json) {
    return ResumoSensor(
      tipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      total: int.parse(json['total'].toString()),
      media: double.parse(json['media'].toString()),
      minimo: double.parse(json['minimo'].toString()),
      maximo: double.parse(json['maximo'].toString()),
      foraLimites: int.tryParse('${json['fora_limites'] ?? 0}') ?? 0,
    );
  }
}

/// Resultado de uma consulta do relatório de qualidade ambiental.
class RelatorioResultado {
  final List<Leitura> leituras;
  final List<ResumoSensor> resumo;

  /// Total de leituras da consulta INTEIRA (a lista traz só a página atual).
  final int total;
  final int totalAlertas;
  final int pagina;
  final int porPagina;

  /// Estimativa do tempo fora dos limites (só entre amostras consecutivas e
  /// sem lacuna de comunicação; zero se houver filtro por valor).
  final int segundosForaLimites;

  const RelatorioResultado({
    required this.leituras,
    required this.resumo,
    this.total = 0,
    this.totalAlertas = 0,
    this.pagina = 1,
    this.porPagina = 200,
    this.segundosForaLimites = 0,
  });

  bool get temMaisPaginas => pagina * porPagina < total;

  static const vazio = RelatorioResultado(leituras: [], resumo: []);
}
