import 'sensor.dart';

int _int(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

/// Valor atual de um sensor, como o painel o recebe (`resumo.atuais`).
class ValorAtual {
  final int sensorId;
  final String nome;
  final TipoSensor tipo;
  final int estoqueId;
  final String estoqueNome;
  final double? valor;
  final DateTime? lidoEm;

  /// `online`, `sem_comunicacao` ou `inativo`.
  final String comunicacao;

  /// `normal`, `atencao`, `critico` ou nulo (nunca houve leitura).
  final String? situacao;

  /// `sensor`, `manual`, `demonstracao` ou `nao_informada`.
  final String origem;

  const ValorAtual({
    required this.sensorId,
    required this.nome,
    required this.tipo,
    required this.estoqueId,
    required this.estoqueNome,
    this.valor,
    this.lidoEm,
    this.comunicacao = 'sem_comunicacao',
    this.situacao,
    this.origem = 'nao_informada',
  });

  bool get online => comunicacao == 'online';

  factory ValorAtual.fromJson(Map<String, dynamic> json) => ValorAtual(
    sensorId: _int(json['id']),
    nome: '${json['nome'] ?? ''}',
    tipo: TipoSensor.porChave('${json['tipo']}'),
    estoqueId: _int(json['estoque_id']),
    estoqueNome: '${json['estoque_nome'] ?? ''}',
    valor: json['ultimo_valor'] == null
        ? null
        : double.tryParse('${json['ultimo_valor']}'),
    lidoEm: DateTime.tryParse('${json['lido_em'] ?? ''}'),
    comunicacao: '${json['comunicacao'] ?? 'sem_comunicacao'}',
    situacao: json['situacao_ambiental'] as String?,
    origem: '${json['ultima_origem'] ?? 'nao_informada'}',
  );
}

/// Alerta resumido exibido no painel (`resumo.alertas_recentes`).
class AlertaResumo {
  final int id;
  final String mensagem;
  final String severidade;
  final String status;
  final String sensorNome;
  final String estoqueNome;
  final DateTime? criadoEm;

  const AlertaResumo({
    required this.id,
    required this.mensagem,
    required this.severidade,
    required this.status,
    required this.sensorNome,
    required this.estoqueNome,
    this.criadoEm,
  });

  factory AlertaResumo.fromJson(Map<String, dynamic> json) => AlertaResumo(
    id: _int(json['id']),
    mensagem: '${json['mensagem'] ?? ''}',
    severidade: '${json['severidade'] ?? 'info'}',
    status: '${json['status'] ?? 'pendente'}',
    sensorNome: '${json['sensor_nome'] ?? ''}',
    estoqueNome: '${json['estoque_nome'] ?? ''}',
    criadoEm: DateTime.tryParse('${json['criado_em'] ?? ''}'),
  );
}

/// Números exibidos no painel principal (vêm de `api/dashboard.php`).
class ResumoPainel {
  final int estoquesTotal;
  final int sensoresOnline;
  final int sensoresAtivos;
  final int sensoresTotal;

  /// Alertas pendentes ou reconhecidos (ainda não normalizados/resolvidos).
  final int alertasPendentes;

  /// Estoques ativos em atenção/crítico (irregularidade ambiental).
  final int estoquesIrregulares;

  /// Estoques ativos com comunicação parcial ou ausente (falha de
  /// comunicação, contada à parte da irregularidade ambiental).
  final int estoquesComunicacao;

  /// Texto pronto, no formato "dd/MM/aaaa HH:mm", ou "—" se nunca houve leitura.
  final String ultimaAtualizacao;

  final List<ValorAtual> atuais;
  final List<AlertaResumo> alertasRecentes;

  const ResumoPainel({
    this.estoquesTotal = 0,
    this.sensoresOnline = 0,
    required this.sensoresAtivos,
    required this.sensoresTotal,
    required this.alertasPendentes,
    this.estoquesIrregulares = 0,
    this.estoquesComunicacao = 0,
    required this.ultimaAtualizacao,
    this.atuais = const [],
    this.alertasRecentes = const [],
  });

  factory ResumoPainel.fromJson(Map<String, dynamic> json) {
    final bruto = json['ultima_atualizacao'];
    final data = DateTime.tryParse('${bruto ?? ''}');
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final texto = data != null
        ? '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
              '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}'
        : (bruto is String && bruto.isNotEmpty ? bruto : '—');

    return ResumoPainel(
      estoquesTotal: _int(json['estoques_total']),
      sensoresOnline: _int(json['sensores_online']),
      sensoresAtivos: _int(json['sensores_ativos']),
      sensoresTotal: _int(json['sensores_total']),
      alertasPendentes: _int(json['alertas_pendentes']),
      estoquesIrregulares: _int(json['estoques_irregulares']),
      estoquesComunicacao: _int(json['estoques_comunicacao']),
      ultimaAtualizacao: texto,
      atuais: [
        for (final e in (json['atuais'] as List? ?? []))
          ValorAtual.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      alertasRecentes: [
        for (final e in (json['alertas_recentes'] as List? ?? []))
          AlertaResumo.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}
