import 'sensor.dart';

/// Uma leitura pontual de um sensor, usada nos gráficos e relatórios.
/// Equivalente às linhas da tabela `leitura_sensor` do backend PHP.
class Leitura {
  final TipoSensor sensorTipo;
  final double valor;
  final DateTime lidoEm;

  const Leitura({
    required this.sensorTipo,
    required this.valor,
    required this.lidoEm,
  });

  factory Leitura.fromJson(Map<String, dynamic> json) {
    return Leitura(
      sensorTipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      valor: double.parse(json['valor'].toString()),
      lidoEm: DateTime.parse(json['lido_em'] as String),
    );
  }
}
