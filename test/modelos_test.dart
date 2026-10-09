import 'package:app_tcc/models/alerta.dart';
import 'package:app_tcc/models/leitura.dart';
import 'package:app_tcc/models/painel.dart';
import 'package:app_tcc/models/sensor.dart';
import 'package:app_tcc/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

// Os mapas abaixo reproduzem o JSON devolvido pelas APIs PHP (tcc/api/*.php),
// inclusive o detalhe de o MySQL entregar números como texto ("7", "21.50").
void main() {
  group('Sensor', () {
    test('lê o JSON da API', () {
      final sensor = Sensor.fromJson({
        'id': '7',
        'nome': 'Sensor Galpão A',
        'tipo': 'qualidade_ar',
        'localizacao': 'Galpão A',
        'status': 'inativo',
        'criado_em': '2026-10-01 08:30:00',
      });

      expect(sensor.id, 7);
      expect(sensor.nome, 'Sensor Galpão A');
      expect(sensor.tipo, TipoSensor.qualidadeAr);
      expect(sensor.tipo.unidade, 'AQI');
      expect(sensor.localizacao, 'Galpão A');
      expect(sensor.status, StatusSensor.inativo);
      expect(sensor.criadoEm, DateTime(2026, 10, 1, 8, 30));
    });

    test(
      'localização ausente continua nula e tipo desconhecido vira temperatura',
      () {
        final sensor = Sensor.fromJson({
          'id': 1,
          'nome': 'X',
          'tipo': 'radiacao',
          'localizacao': null,
          'status': 'ativo',
        });

        expect(sensor.localizacao, isNull);
        expect(sensor.tipo, TipoSensor.temperatura);
      },
    );

    test(
      'todo tipo tem rótulo com unidade e chave única (espelha o ENUM do banco)',
      () {
        final chaves = TipoSensor.values.map((t) => t.chave).toSet();
        expect(chaves.length, TipoSensor.values.length);
        expect(chaves, {
          'temperatura',
          'ruido',
          'qualidade_ar',
          'umidade',
          'pressao',
          'uv',
        });
        expect(TipoSensor.temperatura.rotuloComUnidade, 'Temperatura (°C)');
      },
    );
  });

  group('Alerta', () {
    test('lê o JSON da API', () {
      final alerta = Alerta.fromJson({
        'id': '12',
        'sensor_tipo': 'ruido',
        'sensor_nome': 'Sensor de Ruído',
        'severidade': 'critico',
        'mensagem': 'Ruído acima do limite',
        'valor': '96.50',
        'resolvido': '0',
        'criado_em': '2026-10-09 14:00:00',
      });

      expect(alerta.id, 12);
      expect(alerta.sensorTipo, TipoSensor.ruido);
      expect(alerta.severidade, Severidade.critico);
      expect(alerta.valor, 96.5);
      expect(alerta.resolvido, isFalse);
      expect(alerta.criadoEm, DateTime(2026, 10, 9, 14));
    });

    test(
      'aceita resolvido como 1, "1" ou true e severidade desconhecida vira informativo',
      () {
        Alerta com(Object? resolvido, String? severidade) => Alerta.fromJson({
          'id': 1,
          'sensor_tipo': 'uv',
          'severidade': severidade,
          'mensagem': 'm',
          'resolvido': resolvido,
          'criado_em': '2026-10-09 10:00:00',
        });

        expect(com(1, 'info').resolvido, isTrue);
        expect(com('1', 'info').resolvido, isTrue);
        expect(com(true, 'info').resolvido, isTrue);
        expect(com(0, 'info').resolvido, isFalse);
        expect(com(0, 'inexistente').severidade, Severidade.info);
        expect(com(0, null).severidade, Severidade.info);
      },
    );
  });

  group('Usuario', () {
    test('lê o JSON da API e nunca carrega senha', () {
      final usuario = Usuario.fromJson({
        'id': 3,
        'nome': 'Maria Souza',
        'login': 'maria.souza',
        'tipo': 'usuario',
        'status': 'ativo',
        'criado_em': '2026-10-01 09:00:00',
      });

      expect(usuario.id, 3);
      expect(usuario.tipo, TipoUsuario.usuario);
      expect(usuario.tipo.label, 'Funcionário');
      expect(usuario.status, StatusConta.ativo);
      expect(usuario.criadoEm, DateTime(2026, 10, 1, 9));
    });

    test('perfis e status têm rótulos em português', () {
      expect(TipoUsuario.porChave('admin').label, 'Administrador');
      expect(TipoUsuario.porChave('qualquer-coisa'), TipoUsuario.usuario);
      expect(StatusConta.porChave('inativo').label, 'Inativo');
    });
  });

  group('Leituras e relatório', () {
    test('Leitura.fromJson converte texto em número e data', () {
      final leitura = Leitura.fromJson({
        'sensor_tipo': 'temperatura',
        'sensor_nome': 'Sensor Estufa',
        'valor': '23.40',
        'lido_em': '2026-10-09 12:15:00',
      });

      expect(leitura.sensorTipo, TipoSensor.temperatura);
      expect(leitura.valor, 23.4);
      expect(leitura.lidoEm, DateTime(2026, 10, 9, 12, 15));
    });

    test('ResumoSensor.fromJson lê as estatísticas calculadas pelo banco', () {
      final resumo = ResumoSensor.fromJson({
        'sensor_tipo': 'umidade',
        'total': '200',
        'media': '55.1234',
        'minimo': '30.00',
        'maximo': '81.50',
      });

      expect(resumo.tipo, TipoSensor.umidade);
      expect(resumo.total, 200);
      expect(resumo.media, closeTo(55.1234, 1e-9));
      expect(resumo.minimo, 30);
      expect(resumo.maximo, 81.5);
    });

    test('ResumoPainel.fromJson lê os três números do painel', () {
      final painel = ResumoPainel.fromJson({
        'sensores_ativos': 6,
        'sensores_total': '7',
        'alertas_pendentes': 5,
        'ultima_atualizacao': '09/10/2026 14:30',
      });

      expect(painel.sensoresAtivos, 6);
      expect(painel.sensoresTotal, 7);
      expect(painel.alertasPendentes, 5);
      expect(painel.ultimaAtualizacao, '09/10/2026 14:30');
    });
  });
}
