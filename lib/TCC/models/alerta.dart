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
}
