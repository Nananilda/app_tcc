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

/// Sensor cadastrado (linha da tabela `sensores`).
class Sensor {
  final int id;
  final String nome;
  final TipoSensor tipo;
  final String? localizacao;
  final StatusSensor status;
  final DateTime criadoEm;

  Sensor({
    required this.id,
    required this.nome,
    required this.tipo,
    this.localizacao,
    this.status = StatusSensor.ativo,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

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
    );
  }
}
