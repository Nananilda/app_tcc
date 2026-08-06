enum TipoUsuario {
  admin('admin', 'Administrador'),
  usuario('usuario', 'Funcionário');

  final String chave;
  final String label;

  const TipoUsuario(this.chave, this.label);
}

enum StatusConta {
  ativo('ativo', 'Ativo'),
  inativo('inativo', 'Inativo');

  final String chave;
  final String label;

  const StatusConta(this.chave, this.label);
}

class Usuario {
  final int id;
  String nome;
  String login;
  String senhaHash;
  TipoUsuario tipo;
  StatusConta status;
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.login,
    required this.senhaHash,
    required this.tipo,
    this.status = StatusConta.ativo,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();
}
