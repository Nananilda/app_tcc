import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'router.dart';
import 'state/app_state.dart';
import 'state/tema_controller.dart';
import 'theme/tema.dart';

/// Ponto de entrada do app ÁKRON.
///
/// Antes de abrir a primeira tela carrega, do armazenamento do aparelho, o
/// endereço do servidor e o tema (claro/escuro) escolhidos na última vez.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.carregar();
  final tema = await TemaController.carregar();
  runApp(AkronApp(tema: tema));
}

/// Raiz do aplicativo: provê o estado (sessão/dados), o controle de tema, o
/// roteador e os dois temas (claro e escuro).
class AkronApp extends StatefulWidget {
  const AkronApp({super.key, required this.tema, this.appState});

  final TemaController tema;

  /// Estado da aplicação. Em produção fica nulo (cria um novo); os testes
  /// injetam um [AppState] com servidor simulado.
  final AppState? appState;

  @override
  State<AkronApp> createState() => _AkronAppState();
}

class _AkronAppState extends State<AkronApp> {
  late final AppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ?? AppState();
    // O tema salvo na conta (web e app compartilham) vale ao entrar.
    _appState.aoCarregarTemaDaConta = widget.tema.aplicarDaConta;
    // O roteador é criado uma única vez; refreshListenable cuida de
    // reavaliar os redirecionamentos (login/admin) quando o estado mudar.
    _router = buildRouter(_appState);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _appState),
        ChangeNotifierProvider<TemaController>.value(value: widget.tema),
      ],
      child: Consumer<TemaController>(
        builder: (context, tema, _) => MaterialApp.router(
          title: 'ÁKRON',
          debugShowCheckedModeBanner: false,
          theme: AkronTema.claro,
          darkTheme: AkronTema.escuro,
          themeMode: tema.modo, // sistema, claro ou escuro
          routerConfig: _router,
          // Calendários, botões e textos padrão do Flutter em português do Brasil
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
