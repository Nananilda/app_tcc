import 'package:app_tcc/state/tema_controller.dart';
import 'package:app_tcc/theme/cores.dart';
import 'package:app_tcc/widgets/akron_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio/app_de_teste.dart';

/// Testes de tela: o app inteiro roda dentro do teste, conversando com o
/// ServidorFalso no lugar da API PHP.
void main() {
  setUpAll(carregarFontesDoApp);

  /// Cor de fundo atual das telas (muda com o tema).
  Color fundoDaTela(WidgetTester tester) => Theme.of(
    tester.element(find.byType(Scaffold).first),
  ).scaffoldBackgroundColor;

  group('Login e identidade visual', () {
    testWidgets('mostra a logo ÁKRON, o formulário e o botão de tema', (
      tester,
    ) async {
      await abrirApp(tester);

      expect(find.byType(AkronLogo), findsOneWidget);
      expect(find.bySemanticsLabel('ÁKRON'), findsWidgets);
      expect(find.text('AUTENTICAÇÃO'), findsOneWidget);
      expect(find.text('AUTENTICAR ACESSO'), findsOneWidget);
      expect(find.byTooltip('Mudar para o tema escuro'), findsOneWidget);
    });

    testWidgets('campos vazios mostram os avisos de preenchimento', (
      tester,
    ) async {
      final app = await abrirApp(tester);

      await tester.tap(find.text('AUTENTICAR ACESSO'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o login.'), findsOneWidget);
      expect(find.text('Informe a senha.'), findsOneWidget);
      expect(
        app.servidor.chamadasA('login.php'),
        isEmpty,
        reason: 'nada é enviado com campos vazios',
      );
    });

    testWidgets(
      'senha errada exibe a mensagem do servidor e continua no login',
      (tester) async {
        await abrirApp(tester);

        await entrar(tester, 'admin', senha: 'errada');

        expect(find.text('Login ou senha inválidos.'), findsOneWidget);
        expect(find.text('AUTENTICAÇÃO'), findsOneWidget);
      },
    );

    testWidgets('servidor fora do ar explica o que fazer', (tester) async {
      final app = await abrirApp(tester);
      app.servidor.semConexao = true;

      await entrar(tester, 'admin');

      expect(
        find.textContaining('Não foi possível conectar ao servidor'),
        findsOneWidget,
      );
    });
  });

  group('Tema claro e escuro', () {
    testWidgets('segue o modo do aparelho quando a pessoa ainda não escolheu', (
      tester,
    ) async {
      await abrirApp(tester, sistema: Brightness.dark);
      expect(fundoDaTela(tester), AkronCores.escuro.fundo);
    });

    testWidgets(
      'o botão alterna o tema na hora e grava a escolha no aparelho',
      (tester) async {
        final app = await abrirApp(tester); // aparelho no modo claro
        expect(fundoDaTela(tester), AkronCores.claro.fundo);

        await tester.tap(find.byTooltip('Mudar para o tema escuro'));
        await tester.pumpAndSettle();

        expect(fundoDaTela(tester), AkronCores.escuro.fundo);
        expect(find.byTooltip('Mudar para o tema claro'), findsOneWidget);
        expect(app.tema.modo, ThemeMode.dark);
        expect(
          (await SharedPreferences.getInstance()).getString('akron_tema'),
          'escuro',
        );

        await tester.tap(find.byTooltip('Mudar para o tema claro'));
        await tester.pumpAndSettle();
        expect(fundoDaTela(tester), AkronCores.claro.fundo);
      },
    );

    testWidgets(
      'a escolha gravada no aparelho vale na próxima abertura do app',
      (tester) async {
        await abrirApp(tester);
        await tester.tap(find.byTooltip('Mudar para o tema escuro'));
        await tester.pumpAndSettle();

        // "Reabrir o app": um controller novo lê o que ficou gravado
        final reaberto = await TemaController.carregar();
        expect(reaberto.modo, ThemeMode.dark);
      },
    );
  });

  group('Painel', () {
    testWidgets('administrador vê os números e todos os atalhos', (
      tester,
    ) async {
      await abrirApp(tester);
      await entrar(tester, 'admin');

      expect(find.text('Painel'), findsOneWidget);
      expect(find.text('6 / 7'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('09/10/2026 14:30'), findsOneWidget);
      expect(find.textContaining('Admin de Testes'), findsOneWidget);

      for (final atalho in [
        'Gráficos de Sensores',
        'Alertas',
        'Relatórios',
        'Consulta de Sensores',
        'Gestão de Sensores',
        'Gestão de Cadastro',
      ]) {
        expect(find.text(atalho), findsOneWidget, reason: atalho);
      }
    });

    testWidgets('funcionário não vê as áreas de administração', (tester) async {
      await abrirApp(tester);
      await entrar(tester, 'maria.souza');

      expect(find.text('Painel'), findsOneWidget);
      expect(find.text('Consulta de Sensores'), findsOneWidget);
      expect(find.text('Gestão de Sensores'), findsNothing);
      expect(find.text('Gestão de Cadastro'), findsNothing);
    });

    testWidgets(
      'funcionário que digita o endereço de /usuarios volta ao painel',
      (tester) async {
        await abrirApp(tester);
        await entrar(tester, 'maria.souza');

        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).go('/usuarios');
        await tester.pumpAndSettle();

        expect(find.text('Gestão de Usuários'), findsNothing);
        expect(find.text('Painel'), findsOneWidget);
      },
    );

    testWidgets('cabe numa tela de celular sem estourar o layout', (
      tester,
    ) async {
      await abrirApp(tester, tamanho: const Size(360, 780));
      await entrar(tester, 'admin');

      expect(find.text('Painel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sair volta ao login', (tester) async {
      await abrirApp(tester);
      await entrar(tester, 'admin');

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(find.text('AUTENTICAR ACESSO'), findsOneWidget);
    });

    testWidgets('sessão que caiu no servidor leva ao login com aviso', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      await entrar(tester, 'admin');

      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).go('/usuarios/editar');
      await tester.pumpAndSettle();
      app.servidor.sessaoExpirada = true;

      await tester.enterText(find.byType(TextField).first, 'maria.souza');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('AUTENTICAR ACESSO'), findsOneWidget);
      expect(
        find.text('Sessão expirada. Faça login novamente.'),
        findsOneWidget,
      );
    });
  });

  group('Gestão de usuários', () {
    Future<AppDeTeste> comoAdmin(WidgetTester tester, {Size? tamanho}) async {
      final app = await abrirApp(
        tester,
        tamanho: tamanho ?? const Size(1280, 1000),
      );
      await entrar(tester, 'admin');
      await tocar(tester, find.text('Gestão de Cadastro'));
      return app;
    }

    testWidgets('o menu leva às três ações', (tester) async {
      await comoAdmin(tester);

      expect(find.text('Gestão de Usuários'), findsOneWidget);
      for (final item in [
        'Realizar Cadastro',
        'Editar Usuário',
        'Excluir Cadastro',
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }

      await tester.tap(find.text('Editar Usuário'));
      await tester.pumpAndSettle();
      expect(
        find.text('Busque um usuário pelo login e edite suas informações.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'cadastro: campos obrigatórios, erro do servidor e sucesso limpam/mantêm o formulário',
      (tester) async {
        final app = await comoAdmin(tester);
        await tester.tap(find.text('Realizar Cadastro'));
        await tester.pumpAndSettle();

        // 1) tudo vazio → avisos nos 4 campos, nada enviado
        await tocar(tester, find.text('Cadastrar Usuário'));
        expect(find.text('Campo obrigatório.'), findsNWidgets(4));
        expect(app.servidor.chamadasA('usuarios.php'), isEmpty);

        // 2) senhas diferentes → o servidor recusa e o formulário continua preenchido
        await digitar(tester, 'Nome Completo *', 'Ana Lima');
        await digitar(tester, 'Login *', 'ana.lima');
        await digitar(tester, 'Senha *', 'Abc@1234');
        await digitar(tester, 'Confirmar Senha *', 'diferente');
        await tocar(tester, find.text('Cadastrar Usuário'));

        expect(
          find.text('A confirmação da senha não confere.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextFormField, 'Ana Lima'), findsOneWidget);

        // 3) corrige e escolhe o perfil Administrador
        await digitar(tester, 'Confirmar Senha *', 'Abc@1234');
        await tocar(tester, find.text('Funcionário').first);
        await tocar(tester, find.text('Administrador').last);
        expect(find.textContaining('Acesso: Total'), findsOneWidget);
        await tocar(tester, find.text('Cadastrar Usuário'));

        expect(find.text('Usuário cadastrado com sucesso!'), findsOneWidget);
        final corpo = app.servidor.chamadasA('usuarios.php').last.corpo;
        expect(corpo['tipo'], 'admin');
        expect(corpo['status'], 'ativo');
        expect(app.servidor.usuarios['ana.lima']!['tipo'], 'admin');

        // formulário limpo e perfil de volta ao padrão para o próximo cadastro
        expect(find.widgetWithText(TextFormField, 'Ana Lima'), findsNothing);
        expect(find.textContaining('Acesso: Visualização'), findsOneWidget);
      },
    );

    testWidgets('editar: busca, altera e confirma o que foi salvo', (
      tester,
    ) async {
      final app = await comoAdmin(tester);
      await tester.tap(find.text('Editar Usuário'));
      await tester.pumpAndSettle();

      // login inexistente
      await tester.enterText(find.byType(TextField).first, 'ninguem');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Usuário não encontrado com este login.'),
        findsOneWidget,
      );
      expect(find.text('Editar dados'), findsNothing);

      // login existente → formulário preenchido
      await tester.enterText(find.byType(TextField).first, 'maria.souza');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar dados'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Maria Souza'), findsOneWidget);
      expect(find.text('Usuário não encontrado com este login.'), findsNothing);

      await digitar(tester, 'Nome Completo *', 'Maria Souza Lima');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('Usuário atualizado com sucesso!'), findsOneWidget);
      final corpo = app.servidor
          .chamadasA('usuarios.php')
          .lastWhere((r) => r.metodo == 'POST')
          .corpo;
      expect(corpo['acao'], 'atualizar');
      expect(corpo['id'], 2);
      expect(corpo['nome'], 'Maria Souza Lima');
      expect(corpo['senha'], ''); // senha em branco = manter a atual
      expect(app.servidor.usuarios['maria.souza']!['nome'], 'Maria Souza Lima');
    });

    testWidgets(
      'excluir: exige buscar, continuar e confirmar; não deixa excluir a si mesmo',
      (tester) async {
        final app = await comoAdmin(tester);
        await tester.tap(find.text('Excluir Cadastro'));
        await tester.pumpAndSettle();

        // a própria conta é recusada logo na busca
        await tester.enterText(find.byType(TextField).first, 'admin');
        await tester.tap(find.text('Buscar'));
        await tester.pumpAndSettle();
        expect(
          find.text('Você não pode excluir seu próprio usuário.'),
          findsOneWidget,
        );
        expect(find.text('Usuário encontrado'), findsNothing);

        // outra conta: 1) encontrada
        await tester.enterText(find.byType(TextField).first, 'maria.souza');
        await tester.tap(find.text('Buscar'));
        await tester.pumpAndSettle();
        expect(find.text('Usuário encontrado'), findsOneWidget);
        expect(find.text('Maria Souza'), findsOneWidget);
        expect(find.text('Funcionário'), findsOneWidget);

        // 2) pede para continuar
        await tocar(tester, find.text('Continuar para exclusão'));
        expect(find.text('Confirmar exclusão'), findsOneWidget);
        expect(find.text('Esta ação é irreversível!'), findsOneWidget);
        expect(
          app.servidor.usuarios.containsKey('maria.souza'),
          isTrue,
          reason: 'ainda não excluiu',
        );

        // desistir volta ao início sem excluir
        await tocar(tester, find.text('Não, cancelar'));
        expect(find.text('Confirmar exclusão'), findsNothing);
        expect(app.servidor.usuarios.containsKey('maria.souza'), isTrue);

        // 3) confirma de verdade
        await tester.enterText(find.byType(TextField).first, 'maria.souza');
        await tester.tap(find.text('Buscar'));
        await tester.pumpAndSettle();
        await tocar(tester, find.text('Continuar para exclusão'));
        await tocar(tester, find.text('Sim, excluir usuário'));

        expect(find.text('Usuário excluído com sucesso!'), findsOneWidget);
        expect(app.servidor.usuarios.containsKey('maria.souza'), isFalse);
        expect(find.text('Confirmar exclusão'), findsNothing);
      },
    );

    testWidgets(
      'formulários cabem em tela de celular, tema escuro, sem estourar',
      (tester) async {
        await comoAdmin(tester, tamanho: const Size(360, 780));
        await tester.tap(find.byTooltip('Mudar para o tema escuro'));
        await tester.pumpAndSettle();

        for (final destino in [
          'Realizar Cadastro',
          'Editar Usuário',
          'Excluir Cadastro',
        ]) {
          await tester.tap(find.text(destino));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: destino);

          GoRouter.of(
            tester.element(find.byType(Scaffold).first),
          ).go('/usuarios');
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
