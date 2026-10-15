import 'sensor.dart';

/// Uma leitura pontual de um sensor, usada nos gráficos e relatórios.
/// Equivale às linhas da tabela `leitura_sensor` (o tipo vem do JOIN com `sensores`).
class Leitura {
  final TipoSensor sensorTipo;
  final String? sensorNome;
  final double valor;
  final DateTime lidoEm;

  const Leitura({
    required this.sensorTipo,
    this.sensorNome,
    required this.valor,
    required this.lidoEm,
  });

  factory Leitura.fromJson(Map<String, dynamic> json) {
    return Leitura(
      sensorTipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      sensorNome: json['sensor_nome'] as String?,
      valor: double.parse(json['valor'].toString()),
      lidoEm: DateTime.parse(json['lido_em'] as String),
    );
  }
}

/// Série de um tipo de sensor para o gráfico de linha.
/// [total] é a quantidade de leituras brutas que formam os [pontos]
/// (a API agrupa leituras muito frequentes em médias por intervalo).
class SerieLeituras {
  final List<Leitura> pontos;
  final int total;

  const SerieLeituras({required this.pontos, required this.total});

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

  const ResumoSensor({
    required this.tipo,
    required this.total,
    required this.media,
    required this.minimo,
    required this.maximo,
  });

  factory ResumoSensor.fromJson(Map<String, dynamic> json) {
    return ResumoSensor(
      tipo: TipoSensor.porChave(json['sensor_tipo'] as String),
      total: int.parse(json['total'].toString()),
      media: double.parse(json['media'].toString()),
      minimo: double.parse(json['minimo'].toString()),
      maximo: double.parse(json['maximo'].toString()),
    );
  }
}

/// Resultado de uma consulta do relatório de qualidade ambiental.
class RelatorioResultado {
  final List<Leitura> leituras;
  final List<ResumoSensor> resumo;

  const RelatorioResultado({required this.leituras, required this.resumo});

  static const vazio = RelatorioResultado(leituras: [], resumo: []);
}
