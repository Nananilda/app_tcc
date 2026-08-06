# Sistema de monitoramento de ambiente industrial
Recriação em Flutter (Dart) do sistema PHP tcc-main-atualizado — um painel de monitoramento industrial (sensores, alertas, gráficos, relatórios e gestão de usuários), usando go_router para navegação e provider para estado.

# Como rodar
- flutter pub get
- flutter run
Requer Flutter 3.33+ (usa DropdownButtonFormField.initialValue, Color.withValues, CardThemeData — APIs atuais do Flutter). Se seu SDK for mais antigo, rode flutter upgrade primeiro.

# Login de teste
Igual ao sistema original (includes/auth.php, que era um mock):

# login admin (qualquer senha não vazia) → entra como Administrador
qualquer outro login → entra como Funcionário (usuário comum)
Usuários já cadastrados na base em memória: 
    | login   | senha       | tipo          | 
    | admin   | Admin@123   | Administrador | 
    | usuario | Usuario@123 | Funcionário   |

# O que foi preservado do sistema original
- Todas as telas, o fluxo de navegação e os textos/rótulos em português.
- A lógica de autenticação mockada (login admin vs. usuário comum).
- As regras de validação de cadastro de usuário (nome, login, senha forte).
- A área de "Gestão de Cadastro" restrita a administradores (equivalente a exigirAdmin()), com redirecionamento automático caso um usuário comum tente acessar /usuarios/*.
- A estética escura industrial (cores, cards, badges) inspirada em public/assets/css/style.css.
Gráficos de sensores com atualização periódica (equivalente ao polling de chart.js do sistema original).

# O que foi modernizado / diferente
No projeto PHP original, o banco de dados (SQLite) nunca chegava a ser inicializado com as tabelas, então, na prática, cadastrar sensores e usuários, ou consultar relatórios, sempre resultava em erro ("tabela não encontrada"). Só o login e os dados de exemplo de alertas/gráficos eram mockados e funcionavam de fato.

Nesta versão Flutter, foi mantido as mesmas telas e textos, mas fiz o CRUD de sensores e usuários funcionar de verdade (em memória, reiniciando ao recarregar o app), e o relatório passa a exibir dados simulados filtráveis. Ou seja: a mesma "casca" da aplicação, porém com o comportamento que ela claramente pretendia ter.
