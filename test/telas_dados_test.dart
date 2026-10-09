import 'package:app_tcc/models/sensor.dart';
import 'package:app_tcc/widgets/campo_selecao.dart';
import 'package:app_tcc/widgets/tabela_dados.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'apoio/app_de_teste.dart';

/// Telas de dados (alertas, sensores, gráficos e relatório) funcionando contra
/// o servidor simulado, em janela de computador e de celular.
void main() {
  setUpAll(carregarFontesDoApp);

  /// Entra com [login] e abre [destino] (rota do app).
  Future<AppDeTeste> abrir(
    WidgetTester tester,
    String login,
    String destino, {
    Size? tamanho,
  }) async {
    final app = await abrirApp(
      tester,
      tamanho: tamanho ?? const Size(1280, 1000),
    );
    await entrar(tester, login);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(destino);
    await tester.pumpAndSettle();
    return app;
  }

  group('Alertas', () {
    testWidgets('mostra a contagem de pendentes por severidade e o histórico', (
      tester,
    ) async {
      await abrir(tester, 'admin', '/alertas');

      expect(find.text('Alertas dos Sensores'), findsOneWidget);
      expect(find.text('Críticos'), findsOneWidget);
      expect(find.text('Informativos'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      expect(find.text('— Temperatura acima do limite'), findsOneWidget);
      expect(
        find.textContaining('41,50'),
        findsOneWidget,
      ); // número no formato brasileiro
      expect(
        find.textContaining('Resolvido'),
        findsOneWidget,
      ); // o informativo já resolvido
      expect(tester.takeException(), isNull);
    });

    testWidgets('administrador resolve um alerta pendente', (tester) async {
      final app = await abrir(tester, 'admin', '/alertas');
      expect(find.text('Marcar resolvido'), findsNWidgets(2));

      await tocar(tester, find.text('Marcar resolvido').first);

      expect(find.text('Alerta marcado como resolvido.'), findsOneWidget);
      expect(find.text('Marcar resolvido'), findsOneWidget);
      expect(
        app.servidor
            .chamadasA('alertas.php')
            .where((r) => r.metodo == 'POST')
            .single
            .corpo,
        {'acao': 'resolver', 'alerta_id': 1},
      );
    });

    testWidgets('funcionário só consulta: sem botão de resolver', (
      tester,
    ) async {
      await abrir(tester, 'maria.souza', '/alertas');

      expect(find.text('— Temperatura acima do limite'), findsOneWidget);
      expect(find.text('Marcar resolvido'), findsNothing);
    });

    testWidgets('cabe em celular nos dois temas', (tester) async {
      await abrir(tester, 'admin', '/alertas', tamanho: const Size(360, 780));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Mudar para o tema escuro'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Sensores', () {
    testWidgets(
      'a consulta lista os sensores e só o administrador vê o link da gestão',
      (tester) async {
        await abrir(tester, 'admin', '/sensores/listar');

        expect(find.text('Consulta de Sensores'), findsOneWidget);
        expect(find.byType(TabelaDados), findsOneWidget);
        expect(find.text('Sensor Estufa'), findsOneWidget);
        expect(find.text('Estufa 1'), findsOneWidget);
        expect(find.text('Ruído'), findsOneWidget);
        expect(find.text('—'), findsOneWidget); // sensor sem localização
        expect(
          find.textContaining(
            'acesse a Gestão de Sensores',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('funcionário vê a lista, sem link para a gestão', (
      tester,
    ) async {
      await abrir(tester, 'maria.souza', '/sensores/listar');

      expect(find.text('Sensor Estufa'), findsOneWidget);
      expect(
        find.textContaining('Gestão de Sensores', findRichText: true),
        findsNothing,
      );
      expect(
        find.text('Lista somente leitura dos sensores cadastrados.'),
        findsOneWidget,
      );
    });

    testWidgets('funcionário que abre a gestão é levado à consulta', (
      tester,
    ) async {
      await abrir(tester, 'maria.souza', '/sensores/gestao');

      expect(find.text('Consulta de Sensores'), findsOneWidget);
      expect(find.text('Adicionar Novo Sensor'), findsNothing);
    });

    testWidgets('gestão: valida o formulário, cadastra e alterna o status', (
      tester,
    ) async {
      final app = await abrir(tester, 'admin', '/sensores/gestao');
      expect(find.text('Adicionar Novo Sensor'), findsOneWidget);

      // formulário vazio
      await tocar(tester, find.text('Cadastrar Sensor'));
      expect(find.text('Mínimo 3 caracteres.'), findsOneWidget);
      expect(find.text('Selecione um tipo.'), findsOneWidget);
      expect(app.servidor.sensores, hasLength(2));

      // preenchido
      await digitar(tester, 'Nome do sensor', 'Sensor Pátio');
      await digitar(tester, 'Localização', 'Pátio externo');
      await tocar(tester, find.byType(CampoSelecao<TipoSensor>));
      await tocar(tester, find.text('Umidade').last);
      await tocar(tester, find.text('Cadastrar Sensor'));

      expect(find.text('Sensor cadastrado com sucesso!'), findsOneWidget);
      expect(app.servidor.sensores.last['nome'], 'Sensor Pátio');
      expect(app.servidor.sensores.last['tipo'], 'umidade');
      expect(find.text('Sensor Pátio'), findsOneWidget); // já aparece na tabela

      // alterna: o "Sensor Ruído Galpão" estava inativo
      await tocar(tester, find.widgetWithText(OutlinedButton, 'Ativar'));
      expect(app.servidor.sensores[1]['status'], 'ativo');
      expect(find.text('Status do sensor atualizado.'), findsOneWidget);
    });
  });

  group('Gráficos', () {
    testWidgets(
      'desenha a série de leituras e troca de sensor consultando de novo',
      (tester) async {
        final app = await abrir(tester, 'admin', '/graficos');

        expect(find.text('Gráficos de Sensores'), findsOneWidget);
        expect(find.text('Temperatura — últimas 24 h'), findsOneWidget);
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.text('Total de leituras: 144'), findsOneWidget);
        expect(app.servidor.chamadasA('leituras.php').last.query, {
          'sensor': 'temperatura',
          'horas': '24',
        });

        // troca o sensor
        await tocar(tester, find.text('Temperatura (°C)'));
        await tocar(tester, find.text('Ruído (dB)').last);
        expect(find.text('Ruído — últimas 24 h'), findsOneWidget);
        expect(
          app.servidor.chamadasA('leituras.php').last.query['sensor'],
          'ruido',
        );

        // troca o período
        await tocar(tester, find.text('24 h').first);
        await tocar(tester, find.text('7 dias').last);
        expect(find.text('Ruído — últimos 7 dias'), findsOneWidget);
        expect(
          app.servidor.chamadasA('leituras.php').last.query['horas'],
          '168',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cabe em celular, tema escuro', (tester) async {
      await abrir(
        tester,
        'maria.souza',
        '/graficos',
        tamanho: const Size(360, 780),
      );
      await tester.tap(find.byTooltip('Mudar para o tema escuro'));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Relatório', () {
    testWidgets('carrega ao abrir, mostra resumo e leituras e aplica filtros', (
      tester,
    ) async {
      final app = await abrir(tester, 'admin', '/relatorios');

      expect(find.text('Relatório de Qualidade Ambiental'), findsOneWidget);
      expect(find.text('Resumo do período'), findsOneWidget);
      expect(find.text('24,75'), findsOneWidget); // média com vírgula decimal
      expect(find.text('(2 registros)'), findsOneWidget);
      expect(
        find.text('25,50'),
        findsNWidgets(2),
      ); // máximo do resumo + a leitura da tabela

      // filtro por valor mínimo
      await tester.enterText(find.widgetWithText(TextField, '').first, '20');
      await tocar(tester, find.text('Filtrar'));
      final consulta = app.servidor.chamadasA('relatorio.php').last.query;
      expect(consulta['sensor'], '');
      expect(consulta['data_ini'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(consulta['data_fim'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('cabe em celular', (tester) async {
      await abrir(
        tester,
        'admin',
        '/relatorios',
        tamanho: const Size(360, 780),
      );
      expect(find.text('Resumo do período'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
