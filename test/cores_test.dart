import 'dart:math' as math;

import 'package:app_tcc/theme/cores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Razão de contraste WCAG 2.1 entre duas cores opacas (1 a 21).
double contraste(Color a, Color b) {
  double luminancia(Color cor) {
    double canal(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(cor.r) +
        0.7152 * canal(cor.g) +
        0.0722 * canal(cor.b);
  }

  final la = luminancia(a);
  final lb = luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const temas = {'claro': AkronCores.claro, 'escuro': AkronCores.escuro};

  for (final MapEntry(key: nome, value: c) in temas.entries) {
    group('Tema $nome — acessibilidade (WCAG AA)', () {
      test('texto legível sobre todas as superfícies (≥ 4,5:1)', () {
        for (final fundo in [c.fundo, c.fundoCard, c.fundoCardAlt]) {
          expect(
            contraste(c.texto, fundo),
            greaterThanOrEqualTo(4.5),
            reason: 'texto',
          );
          expect(
            contraste(c.textoSuave, fundo),
            greaterThanOrEqualTo(4.5),
            reason: 'textoSuave',
          );
          expect(
            contraste(c.link, fundo),
            greaterThanOrEqualTo(4.5),
            reason: 'link',
          );
        }
        expect(
          contraste(c.textoFraco, c.fundoCard),
          greaterThanOrEqualTo(4.5),
          reason: 'textoFraco',
        );
        expect(
          contraste(c.textoFraco, c.fundo),
          greaterThanOrEqualTo(4.5),
          reason: 'textoFraco/fundo',
        );
      });

      test('logo (cor da marca) visível sobre o fundo e o cartão (≥ 3:1)', () {
        expect(contraste(c.marca, c.fundo), greaterThanOrEqualTo(3));
        expect(contraste(c.marca, c.fundoCard), greaterThanOrEqualTo(3));
      });

      test(
        'botão principal e botão de perigo têm texto legível, também no hover',
        () {
          expect(
            contraste(c.textoSobrePrimaria, c.primaria),
            greaterThanOrEqualTo(4.5),
          );
          // No hover o texto do botão principal fica branco (ver AkronTema)
          expect(
            contraste(Colors.white, c.primariaHover),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contraste(c.textoSobreErro, c.erro),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contraste(c.textoSobreErro, c.erroHover),
            greaterThanOrEqualTo(4.5),
          );
        },
      );

      test(
        'mensagens e selos (sucesso, erro, alerta) legíveis sobre o próprio fundo',
        () {
          final pares = {
            'sucesso': (c.sucesso, c.sucessoFundo),
            'erro': (c.erro, c.erroFundo),
            'alerta': (c.alerta, c.alertaFundo),
          };
          for (final MapEntry(key: tipo, value: (cor, fundo))
              in pares.entries) {
            // Os fundos são translúcidos: compõe sobre o cartão, onde aparecem
            final composto = Color.alphaBlend(fundo, c.fundoCard);
            expect(
              contraste(cor, composto),
              greaterThanOrEqualTo(4.5),
              reason: tipo,
            );
          }
        },
      );

      test('campos de texto têm borda visível contra o cartão', () {
        expect(contraste(c.bordaForte, c.fundoCard), greaterThanOrEqualTo(1.7));
      });
    });
  }

  test('os dois temas têm exatamente os mesmos tokens (nada fica sem cor)', () {
    // Interpolar claro → escuro percorre todos os campos; se algum faltasse, quebraria.
    final meio = AkronCores.claro.lerp(AkronCores.escuro, 0.5);
    expect(
      meio.fundo,
      Color.lerp(AkronCores.claro.fundo, AkronCores.escuro.fundo, 0.5),
    );
    expect(
      AkronCores.claro.lerp(AkronCores.escuro, 0).texto,
      AkronCores.claro.texto,
    );
    expect(
      AkronCores.claro.lerp(AkronCores.escuro, 1).texto,
      AkronCores.escuro.texto,
    );
  });

  test('o tema escuro é de fato mais escuro que o claro', () {
    expect(
      AkronCores.escuro.fundo.computeLuminance(),
      lessThan(AkronCores.claro.fundo.computeLuminance()),
    );
    expect(
      AkronCores.escuro.texto.computeLuminance(),
      greaterThan(AkronCores.claro.texto.computeLuminance()),
    );
  });
}
