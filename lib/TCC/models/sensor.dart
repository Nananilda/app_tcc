/// Tipos de sensor suportados pelo sistema, com rótulo de exibição e unidade.
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

  static TipoSensor porChave(String chave) {
    return TipoSensor.values.firstWhere(
      (t) => t.chave == chave,
      orElse: () => TipoSensor.temperatura,
    );
  }
}

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

class Sensor {
  final int id;
  String nome;
  TipoSensor tipo;
  String? localizacao;
  StatusSensor status;
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
      criadoEm: DateTime.tryParse(json['criado_em']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
