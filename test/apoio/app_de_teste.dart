import 'package:app_tcc/main.dart';
import 'package:app_tcc/services/api_service.dart';
import 'package:app_tcc/state/app_state.dart';
import 'package:app_tcc/state/tema_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'servidor_falso.dart';

/// Carrega as fontes do app (Inter e Montserrat). Sem isso o Flutter usa, nos
/// testes, uma fonte de blocos largos e as telas "estouram" em larguras que
/// funcionam normalmente no aparelho.
Future<void> carregarFontesDoApp() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final carregador = FontLoader(familia);
    for (final arquivo in arquivos) {
      carregador.addFont(rootBundle.load('assets/fonts/$arquivo'));
    }
    await carregador.load();
  }

  await carregar('Inter', [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]);
  await carregar('Montserrat', [
    'Montserrat-SemiBold.ttf',
    'Montserrat-Bold.ttf',
  ]);
}

/// O app em execução dentro de um teste, com o servidor simulado por trás.
class AppDeTeste {
  AppDeTeste(this.servidor, this.estado, this.tema);

  final ServidorFalso servidor;
  final AppState estado;
  final TemaController tema;
}

/// Abre o ÁKRON (tela de login) numa janela de [tamanho] pixels lógicos.
Future<AppDeTeste> abrirApp(
  WidgetTester tester, {
  Size tamanho = const Size(1280, 1000),
  ServidorFalso? servidor,
  Brightness sistema = Brightness.light,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = sistema;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });

  SharedPreferences.setMockInitialValues({});
  final servidorUsado = servidor ?? ServidorFalso();
  final estado = AppState(api: ApiService(client: servidorUsado.cliente));
  final tema = await TemaController.carregar();

  await tester.pumpWidget(AkronApp(tema: tema, appState: estado));
  await tester.pumpAndSettle();
  return AppDeTeste(servidorUsado, estado, tema);
}

/// Preenche a tela de login e entra.
Future<void> entrar(
  WidgetTester tester,
  String login, {
  String senha = ServidorFalso.senhaDeTeste,
}) async {
  final campos = find.byType(TextFormField);
  await tester.enterText(campos.at(0), login);
  await tester.enterText(campos.at(1), senha);
  await tester.tap(find.text('AUTENTICAR ACESSO'));
  await tester.pumpAndSettle();
}

/// Rola até o elemento e toca nele (formulários longos passam da tela).
Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// Digita no campo de formulário que exibe o [rotulo].
Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  final campo = find.widgetWithText(TextFormField, rotulo);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}
