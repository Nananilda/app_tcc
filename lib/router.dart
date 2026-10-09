import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/alertas/alertas_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/relatorios/relatorio_screen.dart';
import 'screens/sensores/gestao_sensores_screen.dart';
import 'screens/sensores/graficos_sensores_screen.dart';
import 'screens/sensores/listar_sensores_screen.dart';
import 'screens/usuarios/cadastro_usuario_screen.dart';
import 'screens/usuarios/editar_usuario_screen.dart';
import 'screens/usuarios/excluir_usuario_screen.dart';
import 'screens/usuarios/gestao_usuarios_screen.dart';
import 'state/app_state.dart';
import 'widgets/tela_padrao.dart';
import 'widgets/titulos.dart';

/// Rotas do app e regras de acesso (equivalem ao exigirLogin()/exigirAdmin()
/// do sistema web).
GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: appState,
    redirect: (context, state) {
      final logado = appState.estaLogado;
      final localAtual = state.uri.path;
      final indoParaLogin = localAtual == '/login';

      // exigirLogin(): sem sessão, força para a tela de autenticação.
      if (!logado && !indoParaLogin) return '/login';

      // Já logado tentando acessar /login → manda para o painel.
      if (logado && indoParaLogin) return '/painel';

      // exigirAdmin(): a área de usuários é restrita a administradores.
      if (logado && localAtual.startsWith('/usuarios') && !appState.ehAdmin) {
        return '/painel';
      }

      // Gestão de Sensores (cadastro/alteração de status) também é exclusiva
      // de administradores. Usuário comum vai para a Consulta de Sensores,
      // que é somente leitura.
      if (logado &&
          localAtual.startsWith('/sensores/gestao') &&
          !appState.ehAdmin) {
        return '/sensores/listar';
      }

      return null;
    },
    errorBuilder: (context, state) => const _PaginaNaoEncontrada(),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/painel',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/graficos',
        builder: (context, state) => const GraficosSensoresScreen(),
      ),
      GoRoute(
        path: '/alertas',
        builder: (context, state) => const AlertasScreen(),
      ),
      GoRoute(
        path: '/relatorios',
        builder: (context, state) => const RelatorioScreen(),
      ),

      // Sensores
      GoRoute(
        path: '/sensores/gestao',
        builder: (context, state) => const GestaoSensoresScreen(),
      ),
      GoRoute(
        path: '/sensores/listar',
        builder: (context, state) => const ListarSensoresScreen(),
      ),

      // Usuários (rota-mãe + sub-rotas; todas só para administrador via redirect)
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const GestaoUsuariosScreen(),
        routes: [
          GoRoute(
            path: 'cadastro',
            builder: (context, state) => const CadastroUsuarioScreen(),
          ),
          GoRoute(
            path: 'editar',
            builder: (context, state) => const EditarUsuarioScreen(),
          ),
          GoRoute(
            path: 'excluir',
            builder: (context, state) => const ExcluirUsuarioScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Exibida quando o endereço não corresponde a nenhuma tela.
class _PaginaNaoEncontrada extends StatelessWidget {
  const _PaginaNaoEncontrada();

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      larguraMaxima: 700,
      children: [
        const TituloPagina('Página não encontrada'),
        const Text('O endereço acessado não existe neste aplicativo.'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.go('/painel'),
          child: const Text('← Voltar ao painel'),
        ),
      ],
    );
  }
}
