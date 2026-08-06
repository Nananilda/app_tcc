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

GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: appState,
    redirect: (context, state) {
      final logado = appState.estaLogado;
      // Usar state.uri.path é o padrão recomendado nas versões estáveis atuais
      final localAtual = state.uri.path; 
      final indoParaLogin = localAtual == '/login';

      // exigirLogin(): sem sessão, força para a tela de autenticação.
      if (!logado && !indoParaLogin) {
        return '/login';
      }

      // Já logado tentando acessar /login -> manda para o painel
      if (logado && indoParaLogin) {
        return '/painel';
      }

      // exigirAdmin(): área de usuários é restrita a administradores.
      // O startsWith('/usuarios') agora funciona perfeitamente com a árvore corrigida abaixo
      if (logado && localAtual.startsWith('/usuarios') && !appState.ehAdmin) {
        return '/painel';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login', 
        builder: (context, state) => const LoginScreen()
      ),
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
      
      // ROTAS DE SENSORES (Agrupadas)
      // Como não há uma tela "/sensores" pura, usamos um redirecionamento ou rota vazia se necessário.
      // Aqui tratamos como caminhos absolutos limpos, mas colocados explicitamente de forma correta.
      GoRoute(
        path: '/sensores/gestao',
        builder: (context, state) => const GestaoSensoresScreen(),
      ),
      GoRoute(
        path: '/sensores/listar',
        builder: (context, state) => const ListarSensoresScreen(),
      ),

      // ROTAS DE USUÁRIOS (Estrutura Pai e Filho / Sub-rotas)
      // Nota: Em rotas filhas, o 'path' NÃO leva a barra inicial "/". Ele herda do pai.
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const GestaoUsuariosScreen(),
        routes: [
          GoRoute(
            path: 'cadastro', // Caminho final: /usuarios/cadastro
            builder: (context, state) => const CadastroUsuarioScreen(),
          ),
          GoRoute(
            path: 'editar', // Caminho final: /usuarios/editar
            builder: (context, state) => const EditarUsuarioScreen(),
          ),
          GoRoute(
            path: 'excluir', // Caminho final: /usuarios/excluir
            builder: (context, state) => const ExcluirUsuarioScreen(),
          ),
        ],
      ),
    ],
  );
}
