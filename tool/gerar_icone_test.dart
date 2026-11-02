// Gera o ícone do app a partir do desenho da gatinha (o mesmo do app).
// Rodar: flutter test tool/gerar_icone_test.dart
// Depois: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bujo/tema.dart';
import 'package:meu_bujo/widgets/gatinha.dart';

const _lado = 1024.0;
const _fundo = Color(0xFFFFF6EC);

Future<void> _salvar(WidgetTester tester, Widget desenho, String arquivo) async {
  final chave = GlobalKey();
  await tester.binding.setSurfaceSize(const Size(_lado, _lado));
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    Theme(
      data: ThemeData(extensions: [BujoCores.de(paletaPorId('pessego'), escuro: false)]),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: chave, child: SizedBox(width: _lado, height: _lado, child: desenho))),
      ),
    ),
  );
  await tester.runAsync(() async {
    final borda = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagem = await borda.toImage(pixelRatio: 1);
    final png = await imagem.toByteData(format: ui.ImageByteFormat.png);
    File(arquivo)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('gera os PNGs do ícone', (tester) async {
    // ícone completo (Android antigo): fundo creme com a gatinha grande
    await _salvar(
      tester,
      Container(
        color: _fundo,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 70),
        child: const Gatinha(humor: Humor.feliz, tamanho: 820),
      ),
      'assets/icone/icone.png',
    );
    // frente do ícone adaptativo: só a gatinha, dentro da área segura (66% do centro)
    await _salvar(
      tester,
      Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 60),
        child: const Gatinha(humor: Humor.feliz, tamanho: 700),
      ),
      'assets/icone/icone_frente.png',
    );
  });
}
