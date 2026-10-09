/// Números exibidos no painel principal (vêm de `api/dashboard.php`).
class ResumoPainel {
  final int sensoresAtivos;
  final int sensoresTotal;
  final int alertasPendentes;

  /// Texto pronto, no formato "dd/MM/aaaa HH:mm".
  final String ultimaAtualizacao;

  const ResumoPainel({
    required this.sensoresAtivos,
    required this.sensoresTotal,
    required this.alertasPendentes,
    required this.ultimaAtualizacao,
  });

  factory ResumoPainel.fromJson(Map<String, dynamic> json) {
    return ResumoPainel(
      sensoresAtivos: int.parse(json['sensores_ativos'].toString()),
      sensoresTotal: int.parse(json['sensores_total'].toString()),
      alertasPendentes: int.parse(json['alertas_pendentes'].toString()),
      ultimaAtualizacao: json['ultima_atualizacao'].toString(),
    );
  }
}
