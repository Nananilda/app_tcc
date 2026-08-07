/// Endereço base da API PHP (pasta `api/` do projeto tcc-main).
///
/// IMPORTANTE: o host abaixo (10.140.170.170) é o endereço do MySQL
/// (definido em app/config/conexao.php), NÃO necessariamente o endereço
/// onde o Apache/PHP está publicado. Ajuste [baseUrl] para o endereço real
/// do seu servidor PHP (ex.: "http://10.140.170.170/tcc-main/api" ou
/// "http://SEU_SERVIDOR/tcc-main/api").
///
/// - Emulador Android apontando para o PHP rodando no mesmo PC: use
///   "http://10.0.2.2/tcc-main/api".
/// - Dispositivo físico / desktop / web na mesma rede: use o IP da máquina
///   que roda o Apache/PHP, ex.: "http://192.168.0.10/tcc-main/api".
class ApiConfig {
  static const String baseUrl = 'http://10.140.170.170/tcc-main/api';

  static const Duration timeout = Duration(seconds: 12);
}
