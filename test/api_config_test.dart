import 'package:app_tcc/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig.normalizar', () {
    test('acrescenta http:// e remove espaços e barras finais', () {
      expect(
        ApiConfig.normalizar('  192.168.0.10/tcc/api/ '),
        'http://192.168.0.10/tcc/api',
      );
      expect(
        ApiConfig.normalizar('localhost:8000/api'),
        'http://localhost:8000/api',
      );
    });

    test('preserva o esquema informado', () {
      expect(
        ApiConfig.normalizar('https://exemplo.com.br/api///'),
        'https://exemplo.com.br/api',
      );
    });

    test('texto vazio continua vazio', () {
      expect(ApiConfig.normalizar('   '), '');
    });
  });

  group('ApiConfig.urlValida', () {
    test('aceita endereços http e https com servidor', () {
      expect(ApiConfig.urlValida('http://10.0.2.2/tcc/api'), isTrue);
      expect(ApiConfig.urlValida('meuservidor.local/api'), isTrue);
      expect(ApiConfig.urlValida('https://exemplo.com/api'), isTrue);
    });

    test('recusa vazio, outros esquemas e endereços sem servidor', () {
      expect(ApiConfig.urlValida(''), isFalse);
      expect(ApiConfig.urlValida('ftp://servidor/api'), isFalse);
      expect(ApiConfig.urlValida('http://'), isFalse);
    });
  });

  test('o endereço padrão aponta para a pasta api do projeto web', () {
    expect(ApiConfig.padrao, endsWith('/tcc/api'));
  });
}
