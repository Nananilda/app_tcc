/// Tipos de sensor suportados pelo sistema, com rótulo de exibição e unidade.
///
/// As chaves (`temperatura`, `qualidade_ar`...) são as mesmas gravadas no
/// ENUM `sensores.tipo` do banco e devolvidas pela API.
enum TipoSensor {
  temperatura('temperatura', 'Temperatura', '°C'),
  ruido('ruido', 'Ruído', 'dB'),
  qualidadeAr('qualidade_ar', 'Qualidade do Ar', 'AQI'),
  umidade('umidade', 'Umidade', '%'),
  pressao('pressao', 'Pressão', 'hPa'),
  uv('uv', 'UV', 'índice');

  final String chave;
  final String label;
  final String unidade;

  const TipoSensor(this.chave, this.label, this.unidade);

  /// Ex.: "Temperatura (°C)" — usado em seletores e relatórios.
  String get rotuloComUnidade => '$label ($unidade)';

  /// Converte a chave vinda da API; chaves desconhecidas viram temperatura.
  static TipoSensor porChave(String chave) {
    return TipoSensor.values.firstWhere(
      (t) => t.chave == chave,
      orElse: () => TipoSensor.temperatura,
    );
  }
}

/// Situação de um sensor (ENUM `sensores.status`).
enum StatusSensor {
  ativo('ativo', 'Ativo'),
  inativo('inativo', 'Inativo');

  final String chave;
  final String label;

  const StatusSensor(this.chave, this.label);

  static StatusSensor porChave(String chave) {
    return StatusSensor.values.firstWhere(
      (s) => s.chave == chave,
      orElse: () => StatusSensor.ativo,
    );
  }
}

double? _numero(Object? v) {
  if (v == null || '$v'.isEmpty) return null;
  return double.tryParse('$v'.replaceAll(',', '.'));
}

/// Limites de um sensor: valores iguais ao limite NÃO o ultrapassam.
/// Ordem esperada: críticoMín ≤ atençãoMín ≤ atençãoMáx ≤ críticoMáx
/// (qualquer um pode ser nulo).
class LimitesDoSensor {
  final double? criticoMin;
  final double? atencaoMin;
  final double? atencaoMax;
  final double? criticoMax;

  const LimitesDoSensor({
    this.criticoMin,
    this.atencaoMin,
    this.atencaoMax,
    this.criticoMax,
  });

  bool get definidos =>
      criticoMin != null ||
      atencaoMin != null ||
      atencaoMax != null ||
      criticoMax != null;

  factory LimitesDoSensor.fromJson(Map<String, dynamic> json) =>
      LimitesDoSensor(
        criticoMin: _numero(json['limite_critico_min']),
        atencaoMin: _numero(json['limite_atencao_min']),
        atencaoMax: _numero(json['limite_atencao_max']),
        criticoMax: _numero(json['limite_critico_max']),
      );

  /// Os preenchidos precisam seguir a ordem crescente. Devolve a mensagem de
  /// erro ou nulo se estiver tudo certo (a API valida de novo no servidor).
  String? validar() {
    final ordem = <MapEntry<String, double?>>[
      MapEntry('crítico mínimo', criticoMin),
      MapEntry('atenção mínimo', atencaoMin),
      MapEntry('atenção máximo', atencaoMax),
      MapEntry('crítico máximo', criticoMax),
    ].where((e) => e.value != null).toList();
    for (var i = 1; i < ordem.length; i++) {
      if (ordem[i].value! < ordem[i - 1].value!) {
        return 'Os limites devem seguir a ordem crescente: '
            '${ordem[i].key} não pode ser menor que ${ordem[i - 1].key}.';
      }
    }
    return null;
  }

  /// Corpo da requisição: chaves sempre presentes (nulo limpa o limite).
  Map<String, dynamic> paraApi() => {
    'limite_critico_min': criticoMin,
    'limite_atencao_min': atencaoMin,
    'limite_atencao_max': atencaoMax,
    'limite_critico_max': criticoMax,
  };
}

/// Sensor cadastrado (linha da tabela `sensores`, com o estoque a que pertence).
class Sensor {
  final int id;
  final String nome;
  final TipoSensor tipo;
  final String? localizacao;
  final StatusSensor status;
  final DateTime criadoEm;

  /// Estoque do sensor (obrigatório no cadastro desde o ÁKRON 2).
  final int estoqueId;
  final String? estoqueNome;

  /// Prazo (em segundos, 1 a 86400) para considerar o sensor sem comunicação.
  final int intervaloComunicacao;
  final LimitesDoSensor limites;

  /// `online`, `sem_comunicacao` ou `inativo`.
  final String comunicacao;
  final double? ultimoValor;
  final DateTime? ultimaLeitura;

  Sensor({
    required this.id,
    required this.nome,
    required this.tipo,
    this.localizacao,
    this.status = StatusSensor.ativo,
    DateTime? criadoEm,
    this.estoqueId = 0,
    this.estoqueNome,
    this.intervaloComunicacao = 300,
    this.limites = const LimitesDoSensor(),
    this.comunicacao = 'sem_comunicacao',
    this.ultimoValor,
    this.ultimaLeitura,
  }) : criadoEm = criadoEm ?? DateTime.now();

  bool get online => comunicacao == 'online';

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: int.parse(json['id'].toString()),
      nome: json['nome'] as String,
      tipo: TipoSensor.porChave(json['tipo'] as String),
      localizacao: json['localizacao'] as String?,
      status: StatusSensor.porChave(json['status'] as String),
      criadoEm:
          DateTime.tryParse(json['criado_em']?.toString() ?? '') ??
          DateTime.now(),
      estoqueId: int.tryParse('${json['estoque_id'] ?? 0}') ?? 0,
      estoqueNome: json['estoque_nome'] as String?,
      intervaloComunicacao:
          int.tryParse('${json['intervalo_comunicacao'] ?? 300}') ?? 300,
      limites: LimitesDoSensor.fromJson(json),
      comunicacao: '${json['comunicacao'] ?? 'sem_comunicacao'}',
      ultimoValor: _numero(json['ultimo_valor']),
      ultimaLeitura: DateTime.tryParse('${json['ultima_leitura'] ?? ''}'),
    );
  }
}
