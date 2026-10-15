import 'package:intl/intl.dart';

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

/// Limites dos alertas AUTOMÁTICOS de um tipo de sensor.
///
/// Os números vêm do servidor (`limites` em api/alertas.php, definidos em
/// AlertaModel::LIMITES), então o app nunca fica fora de sincronia com o
/// sistema web. Quando uma leitura passa de um limite, o servidor cria o alerta.
class LimitesSensor {
  /// O valor fica ABAIXO destes números → alerta da severidade correspondente.
  final Map<Severidade, double> minimos;

  /// O valor fica ACIMA destes números → alerta da severidade correspondente.
  final Map<Severidade, double> maximos;

  const LimitesSensor({this.minimos = const {}, this.maximos = const {}});

  factory LimitesSensor.fromJson(Map<String, dynamic> json) {
    Map<Severidade, double> faixa(Object? bruto) {
      if (bruto is! Map) return const {};
      return {
        for (final e in bruto.entries)
          if (double.tryParse('${e.value}') != null)
            Severidade.porChave('${e.key}'): double.parse('${e.value}'),
      };
    }

    return LimitesSensor(
      minimos: faixa(json['min']),
      maximos: faixa(json['max']),
    );
  }

  /// Texto do limite de uma severidade, ex.: "acima de 30 °C" ou
  /// "abaixo de 35% ou acima de 80%". Devolve "—" se não houver limite.
  String faixa(Severidade severidade, TipoSensor tipo) {
    final partes = <String>[
      if (minimos[severidade] != null)
        'abaixo de ${formatarLimite(minimos[severidade]!, tipo.unidade)}',
      if (maximos[severidade] != null)
        'acima de ${formatarLimite(maximos[severidade]!, tipo.unidade)}',
    ];
    return partes.isEmpty ? '—' : partes.join(' ou ');
  }

  /// Número + unidade, como nas mensagens do servidor: "35 °C", "35%", "índice 8".
  static String formatarLimite(double numero, String unidade) {
    final texto = NumberFormat('#,##0.##', 'pt_BR').format(numero);
    return switch (unidade) {
      '%' => '$texto%',
      'índice' => 'índice $texto',
      '' => texto,
      _ => '$texto $unidade',
    };
  }
}
