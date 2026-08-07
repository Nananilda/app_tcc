import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'TCC/app_theme.dart';
import 'TCC/router.dart';
import 'TCC/state/app_state.dart';

void main() {
  runApp(const IndustrialOsApp());
}

class IndustrialOsApp extends StatefulWidget {
  const IndustrialOsApp({super.key});

  @override
  State<IndustrialOsApp> createState() => _IndustrialOsAppState();
}

class _IndustrialOsAppState extends State<IndustrialOsApp> {
  late final AppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    // O router é criado uma única vez; refreshListenable cuida de
    // reavaliar os redirects (login/admin) quando o estado mudar.
    _router = buildRouter(_appState);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: MaterialApp.router(
        title: 'IndustrialOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
