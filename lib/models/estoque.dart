/// Condição ambiental de um estoque (só vem de leituras válidas e recentes).
enum CondicaoAmbiental {
  normal('normal', 'Normal'),
  atencao('atencao', 'Atenção'),
  critico('critico', 'Crítico'),
  indisponivel('indisponivel', 'Indisponível');

  final String chave;
  final String label;
  const CondicaoAmbiental(this.chave, this.label);

  static CondicaoAmbiental porChave(String? chave) => values.firstWhere(
    (c) => c.chave == chave,
    orElse: () => CondicaoAmbiental.indisponivel,
  );
}

/// Estado da comunicação dos sensores de um estoque.
enum EstadoComunicacao {
  todosOnline('todos_online', 'Todos online'),
  parcial('parcial', 'Comunicação parcial'),
  semComunicacao('sem_comunicacao', 'Sem comunicação'),
  semSensores('sem_sensores', 'Sem sensores');

  final String chave;
  final String label;
  const EstadoComunicacao(this.chave, this.label);

  static EstadoComunicacao porChave(String? chave) => values.firstWhere(
    (c) => c.chave == chave,
    orElse: () => EstadoComunicacao.semSensores,
  );
}

int _inteiro(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

/// Estoque monitorado (api/estoques.php). O estado é descrito por três
/// informações independentes: condição ambiental, comunicação e situação
/// cadastral — falha de comunicação nunca vira condição ambiental.
class Estoque {
  final int id;
  final String nome;
  final String descricao;
  final String localizacao;
  final bool ativo;
  final CondicaoAmbiental condicao;
  final EstadoComunicacao comunicacao;
  final String comunicacaoRotulo;
  final int sensoresTotal;
  final int sensoresAtivos;
  final int sensoresOnline;
  final int sensoresSemComunicacao;
  final List<String> sensoresSemComunicacaoNomes;
  final int sensoresCriticos;
  final int sensoresAtencao;
  final int alertasAtivos;
  final int alertasCriticosPendentes;
  final DateTime? ultimaLeitura;

  const Estoque({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.localizacao = '',
    this.ativo = true,
    this.condicao = CondicaoAmbiental.indisponivel,
    this.comunicacao = EstadoComunicacao.semSensores,
    this.comunicacaoRotulo = '',
    this.sensoresTotal = 0,
    this.sensoresAtivos = 0,
    this.sensoresOnline = 0,
    this.sensoresSemComunicacao = 0,
    this.sensoresSemComunicacaoNomes = const [],
    this.sensoresCriticos = 0,
    this.sensoresAtencao = 0,
    this.alertasAtivos = 0,
    this.alertasCriticosPendentes = 0,
    this.ultimaLeitura,
  });

  // Igualdade por id: os seletores (Dropdown) comparam o item escolhido com a
  // lista recarregada, que traz novas instâncias do mesmo estoque.
  @override
  bool operator ==(Object other) => other is Estoque && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Estoque.fromJson(Map<String, dynamic> json) {
    final comunicacao = EstadoComunicacao.porChave(
      json['comunicacao_estado'] as String?,
    );
    return Estoque(
      id: _inteiro(json['id']),
      nome: '${json['nome'] ?? ''}',
      descricao: '${json['descricao'] ?? ''}',
      localizacao: '${json['localizacao'] ?? ''}',
      ativo: json['status'] != 'inativo',
      // `condicao_ambiental` é o campo novo; `condicao` só existe por
      // compatibilidade e hoje traz o mesmo conteúdo (rótulo).
      condicao: CondicaoAmbiental.porChave(
        json['condicao_ambiental'] as String?,
      ),
      comunicacao: comunicacao,
      comunicacaoRotulo:
          (json['comunicacao_rotulo'] as String?) ?? comunicacao.label,
      sensoresTotal: _inteiro(json['sensores_total']),
      sensoresAtivos: _inteiro(json['sensores_ativos']),
      sensoresOnline: _inteiro(json['sensores_online']),
      sensoresSemComunicacao: _inteiro(json['sensores_sem_comunicacao']),
      sensoresSemComunicacaoNomes: [
        for (final n in (json['sensores_sem_comunicacao_nomes'] as List? ?? []))
          '$n',
      ],
      sensoresCriticos: _inteiro(json['sensores_criticos']),
      sensoresAtencao: _inteiro(json['sensores_atencao']),
      alertasAtivos: _inteiro(json['alertas_ativos']),
      alertasCriticosPendentes: _inteiro(json['alertas_criticos_pendentes']),
      ultimaLeitura: DateTime.tryParse('${json['ultima_leitura'] ?? ''}'),
    );
  }
}
