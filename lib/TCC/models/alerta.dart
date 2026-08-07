import 'sensor.dart';

enum Severidade {
  critico('critico', 'Crítico'),
  atencao('atencao', 'Atenção'),
  info('info', 'Informativo');

  final String chave;
  final String label;

  const Severidade(this.chave, this.label);
}

class Alerta {
  final int id;
  final TipoSensor sensorTipo;
  final Severidade severidade;
  final String mensagem;
  final double valor;
  bool resolvido;
  final DateTime criadoEm;

  Alerta({
    required this.id,
    required this.sensorTipo,
    required this.severidade,
    required this.mensagem,
    required this.valor,
    this.resolvido = false,
    required this.criadoEm,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: int.parse(json['id'].toString()),
      sensorTipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      severidade: Severidade.values.firstWhere(
        (s) => s.chave == json['severidade'],
        orElse: () => Severidade.info,
      ),
      mensagem: json['mensagem'] as String,
      valor: double.tryParse(json['valor']?.toString() ?? '') ?? 0,
      resolvido: json['resolvido'] == true ||
          json['resolvido'] == 1 ||
          json['resolvido'] == '1',
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }
}
