enum TipoUsuario {
  admin('admin', 'Administrador'),
  usuario('usuario', 'Funcionário');

  final String chave;
  final String label;

  const TipoUsuario(this.chave, this.label);

  static TipoUsuario porChave(String chave) {
    return TipoUsuario.values.firstWhere(
      (t) => t.chave == chave,
      orElse: () => TipoUsuario.usuario,
    );
  }
}

enum StatusConta {
  ativo('ativo', 'Ativo'),
  inativo('inativo', 'Inativo');

  final String chave;
  final String label;

  const StatusConta(this.chave, this.label);

  static StatusConta porChave(String chave) {
    return StatusConta.values.firstWhere(
      (s) => s.chave == chave,
      orElse: () => StatusConta.ativo,
    );
  }
}

/// Usuário do sistema. Não guarda senha/hash no cliente — a API nunca
/// devolve esse campo (só o próprio backend, via password_verify, lida
/// com credenciais).
class Usuario {
  final int id;
  String nome;
  String login;
  TipoUsuario tipo;
  StatusConta status;
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.login,
    required this.tipo,
    this.status = StatusConta.ativo,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: int.parse(json['id'].toString()),
      nome: json['nome'] as String,
      login: json['login'] as String,
      tipo: TipoUsuario.porChave(json['tipo'] as String),
      status: StatusConta.porChave(json['status'] as String),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
