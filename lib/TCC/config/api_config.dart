/// Endereço base da API PHP (pasta `api/` do projeto tcc-main).
///
/// IMPORTANTE: este é o endereço do servidor Apache/PHP (não do MySQL).
/// No laboratório os dois costumam rodar na mesma máquina, então o IP
/// abaixo tende a coincidir com o $host de app/config/conexao.php — mas
/// ajuste [baseUrl] sempre que o Apache estiver publicado em outro
/// endereço.
///
/// A pasta `api/` precisa existir dentro do projeto PHP publicado no
/// servidor (junto de app/, includes/, sql/ etc.) — sem ela não há nada
/// para o app conversar e toda chamada aqui falha com erro de conexão.
///
/// - Emulador Android apontando para o PHP rodando no mesmo PC: use
///   "http://10.0.2.2/tcc-main/api".
/// - Dispositivo físico / desktop / web na mesma rede: use o IP da máquina
///   que roda o Apache/PHP, ex.: "http://192.168.0.10/tcc-main/api".
class ApiConfig {
  static const String baseUrl = 'http://10.140.169.12/tcc-main/api';

  static const Duration timeout = Duration(seconds: 12);
}
