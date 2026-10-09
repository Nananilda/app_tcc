import 'sensor.dart';

/// Gravidade de um alerta (ENUM `alertas.severidade`).
enum Severidade {
  critico('critico', 'Crítico'),
  atencao('atencao', 'Atenção'),
  info('info', 'Informativo');

  final String chave;
  final String label;

  const Severidade(this.chave, this.label);

  static Severidade porChave(String? chave) {
    return Severidade.values.firstWhere(
      (s) => s.chave == chave,
      orElse: () => Severidade.info,
    );
  }
}

/// Alerta gerado por um sensor (linha da tabela `alertas`).
/// O tipo e o nome do sensor vêm do JOIN feito pela API.
class Alerta {
  final int id;
  final TipoSensor sensorTipo;
  final String? sensorNome;
  final Severidade severidade;
  final String mensagem;
  final double? valor;
  final bool resolvido;
  final DateTime criadoEm;

  const Alerta({
    required this.id,
    required this.sensorTipo,
    this.sensorNome,
    required this.severidade,
    required this.mensagem,
    this.valor,
    this.resolvido = false,
    required this.criadoEm,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: int.parse(json['id'].toString()),
      sensorTipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      sensorNome: json['sensor_nome'] as String?,
      severidade: Severidade.porChave(json['severidade'] as String?),
      mensagem: json['mensagem'] as String,
      valor: double.tryParse(json['valor']?.toString() ?? ''),
      resolvido:
          json['resolvido'] == true ||
          json['resolvido'] == 1 ||
          json['resolvido'] == '1',
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }
}
