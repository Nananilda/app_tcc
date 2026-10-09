import 'package:app_tcc/models/sensor.dart';
import 'package:app_tcc/models/usuario.dart';
import 'package:app_tcc/services/api_service.dart';
import 'package:app_tcc/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio/servidor_falso.dart';

/// Testa o AppState + ApiService contra o ServidorFalso (que imita o PHP).
void main() {
  late ServidorFalso servidor;
  late AppState app;

  setUp(() {
    servidor = ServidorFalso();
    app = AppState(api: ApiService(client: servidor.cliente));
  });

  Future<void> entrarComo(String login) async {
    final r = await app.login(login, ServidorFalso.senhaDeTeste);
    expect(r.temErro, isFalse, reason: r.erros.join(', '));
  }

  group('login', () {
    test(
      'administrador entra e passa a enviar o token nas chamadas seguintes',
      () async {
        await entrarComo('admin');

        expect(app.estaLogado, isTrue);
        expect(app.ehAdmin, isTrue);
        expect(app.usuarioLogado!.nome, 'Admin de Testes');

        await app.carregarResumo();
        final chamada = servidor.chamadasA('dashboard.php').single;
        expect(
          chamada.cabecalhos['Authorization'],
          'Bearer ${ServidorFalso.token}',
        );
      },
    );

    test('o corpo do login leva só login e senha', () async {
      await app.login('  admin  ', ServidorFalso.senhaDeTeste);
      final corpo = servidor.chamadasA('login.php').single.corpo;
      expect(corpo, {'login': 'admin', 'senha': ServidorFalso.senhaDeTeste});
    });

    test('funcionário entra, mas não é administrador', () async {
      await entrarComo('maria.souza');
      expect(app.estaLogado, isTrue);
      expect(app.ehAdmin, isFalse);
    });

    test(
      'senha errada mostra a mensagem do servidor e não cria sessão',
      () async {
        final r = await app.login('admin', 'errada');
        expect(r.erros, ['Login ou senha inválidos.']);
        expect(app.estaLogado, isFalse);
      },
    );

    test('conta inativa é recusada com explicação', () async {
      final r = await app.login('joao.silva', ServidorFalso.senhaDeTeste);
      expect(r.erros.single, contains('inativa'));
      expect(app.estaLogado, isFalse);
    });

    test('campos vazios nem chegam ao servidor', () async {
      final r = await app.login('   ', '');
      expect(r.erros, ['Credenciais inválidas.']);
      expect(servidor.requisicoes, isEmpty);
    });

    test('servidor fora do ar vira mensagem amigável', () async {
      servidor.semConexao = true;
      final r = await app.login('admin', ServidorFalso.senhaDeTeste);
      expect(r.erros.single, contains('Não foi possível conectar ao servidor'));
      expect(app.estaLogado, isFalse);
    });

    test('logout encerra a sessão e esquece o token', () async {
      await entrarComo('admin');
      await app.logout();

      expect(app.estaLogado, isFalse);
      expect(servidor.chamadasA('logout.php'), hasLength(1));

      // Sem token, a próxima chamada é recusada pelo servidor
      final resposta = await app.carregarResumo();
      expect(resposta.ok, isFalse);
    });
  });

  group('sessão expirada', () {
    test(
      'quando o servidor responde 401 o app volta ao login com um aviso',
      () async {
        await entrarComo('admin');
        servidor.sessaoExpirada = true;

        final resposta = await app.carregarResumo();

        expect(resposta.ok, isFalse);
        expect(app.estaLogado, isFalse);
        expect(app.avisoLogin, 'Sessão expirada. Faça login novamente.');
      },
    );

    test('ações também derrubam a sessão', () async {
      await entrarComo('admin');
      servidor.sessaoExpirada = true;

      final r = await app.cadastrarUsuario(
        nome: 'Fulano',
        login: 'fulano',
        senha: 'x',
        confirmar: 'x',
        tipo: TipoUsuario.usuario,
        status: StatusConta.ativo,
      );

      expect(r.temErro, isTrue);
      expect(app.estaLogado, isFalse);
    });
  });

  group('gestão de usuários', () {
    test(
      'funcionário não consegue cadastrar, editar nem excluir (nem chega ao servidor)',
      () async {
        await entrarComo('maria.souza');
        servidor.requisicoes.clear();

        final cadastro = await app.cadastrarUsuario(
          nome: 'Fulano',
          login: 'fulano',
          senha: 'Abc@1234',
          confirmar: 'Abc@1234',
          tipo: TipoUsuario.admin,
          status: StatusConta.ativo,
        );
        final edicao = await app.atualizarUsuario(
          id: 3,
          nome: 'X',
          login: 'x',
          tipo: TipoUsuario.admin,
          status: StatusConta.ativo,
        );
        final exclusao = await app.excluirUsuario(3);

        for (final r in [cadastro, edicao, exclusao]) {
          expect(r.erros, ['Acesso negado.']);
        }
        expect(servidor.chamadasA('usuarios.php'), isEmpty);
      },
    );

    test('cadastro envia os campos e devolve a mensagem do servidor', () async {
      await entrarComo('admin');

      final r = await app.cadastrarUsuario(
        nome: '  Ana Lima ',
        login: ' ana.lima ',
        senha: 'Abc@1234',
        confirmar: 'Abc@1234',
        tipo: TipoUsuario.usuario,
        status: StatusConta.ativo,
      );

      expect(r.mensagem, 'Usuário cadastrado com sucesso!');
      final corpo = servidor.chamadasA('usuarios.php').last.corpo;
      expect(corpo['acao'], 'cadastrar');
      expect(corpo['nome'], 'Ana Lima'); // sem espaços nas pontas
      expect(corpo['login'], 'ana.lima');
      expect(corpo['tipo'], 'usuario');
      expect(servidor.usuarios.containsKey('ana.lima'), isTrue);
    });

    test('erros de validação do servidor chegam como lista', () async {
      await entrarComo('admin');

      final r = await app.cadastrarUsuario(
        nome: 'Maria',
        login: 'maria.souza', // já existe
        senha: 'Abc@1234',
        confirmar: 'outra',
        tipo: TipoUsuario.usuario,
        status: StatusConta.ativo,
      );

      expect(r.temSucesso, isFalse);
      expect(r.erros, [
        'Este login já está em uso.',
        'A confirmação da senha não confere.',
      ]);
    });

    test(
      'buscar por login: encontrado, inexistente e falha de rede são casos distintos',
      () async {
        await entrarComo('admin');

        final achou = await app.buscarUsuarioPorLogin('maria.souza');
        expect(achou.ok, isTrue);
        expect(achou.dados!.nome, 'Maria Souza');

        final naoAchou = await app.buscarUsuarioPorLogin('ninguem');
        expect(naoAchou.ok, isTrue);
        expect(naoAchou.dados, isNull);

        servidor.semConexao = true;
        final semRede = await app.buscarUsuarioPorLogin('maria.souza');
        expect(semRede.ok, isFalse);
        expect(semRede.erro, contains('Não foi possível conectar'));
      },
    );

    test('o administrador não exclui a própria conta', () async {
      await entrarComo('admin');
      servidor.requisicoes.clear();

      final r = await app.excluirUsuario(app.usuarioLogado!.id);

      expect(r.erros, ['Você não pode excluir seu próprio usuário.']);
      expect(servidor.chamadasA('usuarios.php'), isEmpty);
    });

    test('exclusão de outro usuário funciona', () async {
      await entrarComo('admin');
      final r = await app.excluirUsuario(2);
      expect(r.mensagem, 'Usuário excluído com sucesso!');
      expect(servidor.usuarios.containsKey('maria.souza'), isFalse);
    });

    test(
      'editar a própria conta atualiza o nome mostrado na barra superior',
      () async {
        await entrarComo('admin');

        final r = await app.atualizarUsuario(
          id: app.usuarioLogado!.id,
          nome: 'Administrador Geral',
          login: 'admin',
          tipo: TipoUsuario.admin,
          status: StatusConta.ativo,
        );

        expect(r.temSucesso, isTrue);
        expect(app.usuarioLogado!.nome, 'Administrador Geral');
      },
    );
  });

  group('sensores', () {
    test('cadastro valida nome e tipo antes de chamar o servidor', () async {
      await entrarComo('admin');
      servidor.requisicoes.clear();

      final r = await app.cadastrarSensor(
        nome: 'ab',
        tipo: null,
        localizacao: '',
        status: StatusSensor.ativo,
      );

      expect(r.erros, [
        'Nome do sensor deve ter ao menos 3 caracteres.',
        'Tipo de sensor inválido.',
      ]);
      expect(servidor.chamadasA('sensores.php'), isEmpty);
    });

    test('funcionário não gerencia sensores', () async {
      await entrarComo('maria.souza');
      final r = await app.cadastrarSensor(
        nome: 'Sensor novo',
        tipo: TipoSensor.uv,
        localizacao: '',
        status: StatusSensor.ativo,
      );
      expect(r.erros, ['Acesso negado.']);
    });
  });

  group('servidor', () {
    test(
      'testarEndereco informa a versão quando o servidor responde',
      () async {
        final status = await app.testarEndereco('192.168.0.10/tcc/api');
        expect(status.conectado, isTrue);
        expect(status.mensagem, contains('ÁKRON v2.0'));
        expect(servidor.requisicoes.single.arquivo, 'status.php');
      },
    );

    test('testarEndereco informa o problema quando não conecta', () async {
      servidor.semConexao = true;
      final status = await app.testarEndereco('192.168.0.10/tcc/api');
      expect(status.conectado, isFalse);
      expect(status.mensagem, contains('http://192.168.0.10/tcc/api'));
    });
  });
}
