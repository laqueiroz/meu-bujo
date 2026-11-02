import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema.dart';

enum Humor { feliz, comemorando, preocupada, sonolenta, curiosa, apaixonada }

const _olho = Color(0xFF4B3F5C);
const _rosa = Color(0xFFF6A8B3);
const _coracao = Color(0xFFF27C93);

/// A gatinha mascote. Quando o humor vira "comemorando", ela dá um pulinho.
class Gatinha extends StatefulWidget {
  final Humor humor;
  final double tamanho;

  const Gatinha({super.key, this.humor = Humor.feliz, this.tamanho = 76});

  @override
  State<Gatinha> createState() => _GatinhaState();
}

class _GatinhaState extends State<Gatinha> with SingleTickerProviderStateMixin {
  late final AnimationController _pulo = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(covariant Gatinha antigo) {
    super.didUpdateWidget(antigo);
    if (widget.humor == Humor.comemorando && antigo.humor != Humor.comemorando) {
      _pulo.forward(from: 0).then((_) => _pulo.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final largura = widget.tamanho;
    final altura = largura * 127 / 140;
    return Semantics(
      label: 'Gatinha ${widget.humor.name}',
      child: AnimatedBuilder(
        animation: _pulo,
        builder: (context, child) {
          final y = -10 * math.sin(_pulo.value * math.pi);
          return Transform.translate(offset: Offset(0, y), child: child);
        },
        child: CustomPaint(
          size: Size(largura, altura),
          painter: _GatinhaPainter(humor: widget.humor, linha: c.linha, mancha: c.destaque),
        ),
      ),
    );
  }
}

/// Desenho da gatinha, no mesmo sistema de coordenadas do protótipo (viewBox -10 -12 140 127).
class _GatinhaPainter extends CustomPainter {
  final Humor humor;
  final Color linha;
  final Color mancha;

  _GatinhaPainter({required this.humor, required this.linha, required this.mancha});

  Paint _preenche(Color cor) => Paint()..color = cor..style = PaintingStyle.fill;
  Paint _traco(Color cor, double largura) => Paint()
    ..color = cor
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path _tri(double x1, double y1, double x2, double y2, double x3, double y3) =>
      Path()..moveTo(x1, y1)..lineTo(x2, y2)..lineTo(x3, y3)..close();

  /// Coração com a ponta em (cx, ponta), laterais em y = meio e o "vale" de cima em y = topo.
  Path _coracaoPath(double cx, double ponta, double meio, double topo, double lado, double r) {
    return Path()
      ..moveTo(cx, ponta)
      ..lineTo(cx - lado, meio)
      ..arcToPoint(Offset(cx, topo), radius: Radius.circular(r))
      ..arcToPoint(Offset(cx + lado, meio), radius: Radius.circular(r))
      ..close();
  }

  void _texto(Canvas canvas, String s, double x, double yBase, double tamanho, Color cor) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: tamanho, fontWeight: FontWeight.w700, color: cor)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, yBase - tamanho * 0.85));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140, size.height / 127);
    canvas.translate(10, 12);

    // rosto (inclina quando está curiosa)
    canvas.save();
    if (humor == Humor.curiosa) {
      canvas.translate(60, 64);
      canvas.rotate(-8 * math.pi / 180);
      canvas.translate(-60, -64);
    }

    final orelhaE = _tri(20, 46, 26, 10, 54, 30);
    final orelhaD = _tri(100, 46, 94, 10, 66, 30);
    for (final o in [orelhaE, orelhaD]) {
      canvas.drawPath(o, _preenche(Colors.white));
      canvas.drawPath(o, _traco(linha, 4));
    }
    canvas.drawPath(_tri(29, 22, 32, 38, 45, 31), _preenche(_rosa));
    canvas.drawPath(_tri(91, 22, 88, 38, 75, 31), _preenche(_rosa));

    final cabeca = Rect.fromCenter(center: const Offset(60, 64), width: 100, height: 80);
    canvas.drawOval(cabeca, _preenche(Colors.white));
    final manchinha = Path()
      ..moveTo(70, 27)
      ..quadraticBezierTo(92, 30, 103, 50)
      ..quadraticBezierTo(90, 52, 82, 44)
      ..quadraticBezierTo(74, 37, 70, 27)
      ..close();
    canvas.drawPath(manchinha, _preenche(mancha));
    canvas.drawOval(cabeca, _traco(linha, 4));

    canvas.drawOval(Rect.fromCenter(center: const Offset(29, 77), width: 14, height: 9), _preenche(_rosa));
    canvas.drawOval(Rect.fromCenter(center: const Offset(91, 77), width: 14, height: 9), _preenche(_rosa));

    // olhos
    switch (humor) {
      case Humor.comemorando:
        for (final x in [35.0, 71.0]) {
          canvas.drawPath(Path()..moveTo(x, 66)..quadraticBezierTo(x + 7, 57, x + 14, 66), _traco(_olho, 4.5));
        }
      case Humor.sonolenta:
        for (final x in [35.0, 71.0]) {
          canvas.drawPath(Path()..moveTo(x, 64)..quadraticBezierTo(x + 7, 69, x + 14, 64), _traco(_olho, 4));
        }
      case Humor.apaixonada:
        for (final x in [42.0, 78.0]) {
          final p = _coracaoPath(x, 71, 64, 58, 7, 4);
          canvas.drawPath(p, _preenche(_coracao));
          canvas.drawPath(p, _traco(_olho, 1.5));
        }
      case Humor.feliz:
      case Humor.preocupada:
      case Humor.curiosa:
        for (final x in [42.0, 78.0]) {
          canvas.drawCircle(Offset(x, 64), 6.5, _preenche(_olho));
          canvas.drawCircle(Offset(x + 2, 61.5), 2, _preenche(Colors.white));
        }
    }
    if (humor == Humor.preocupada) {
      canvas.drawLine(const Offset(34, 52), const Offset(47, 56), _traco(_olho, 3.5));
      canvas.drawLine(const Offset(86, 52), const Offset(73, 56), _traco(_olho, 3.5));
    }

    // boca
    switch (humor) {
      case Humor.feliz:
      case Humor.apaixonada:
        canvas.drawPath(
          Path()
            ..moveTo(53, 72)
            ..quadraticBezierTo(56.5, 76.5, 60, 72)
            ..quadraticBezierTo(63.5, 76.5, 67, 72),
          _traco(_olho, 3),
        );
      case Humor.comemorando:
        final boca = Path()..moveTo(53, 71)..quadraticBezierTo(60, 82, 67, 71)..close();
        canvas.drawPath(boca, _preenche(_rosa));
        canvas.drawPath(boca, _traco(_olho, 3));
      case Humor.preocupada:
        canvas.drawPath(
          Path()
            ..moveTo(51, 76)
            ..quadraticBezierTo(54, 73, 57, 76)
            ..quadraticBezierTo(60, 79, 63, 76)
            ..quadraticBezierTo(66, 73, 69, 76),
          _traco(_olho, 3),
        );
      case Humor.sonolenta:
      case Humor.curiosa:
        canvas.drawCircle(const Offset(60, 75), 3.5, _traco(_olho, 3));
    }

    // bigodes
    final bigode = _traco(linha, 3);
    canvas.drawLine(const Offset(-4, 64), const Offset(14, 67), bigode);
    canvas.drawLine(const Offset(-4, 76), const Offset(14, 74), bigode);
    canvas.drawLine(const Offset(124, 64), const Offset(106, 67), bigode);
    canvas.drawLine(const Offset(124, 76), const Offset(106, 74), bigode);
    canvas.restore();

    // enfeites em volta
    switch (humor) {
      case Humor.comemorando:
        for (final pts in const [
          [2.0, 2.0, 4.5, 8.0, 10.5, 10.5, 4.5, 13.0, 2.0, 19.0, -0.5, 13.0, -6.5, 10.5, -0.5, 8.0],
          [116.0, -4.0, 118.0, 1.0, 123.0, 3.0, 118.0, 5.0, 116.0, 10.0, 114.0, 5.0, 109.0, 3.0, 114.0, 1.0],
        ]) {
          final p = Path()..moveTo(pts[0], pts[1]);
          for (var i = 2; i < pts.length; i += 2) {
            p.lineTo(pts[i], pts[i + 1]);
          }
          p.close();
          canvas.drawPath(p, _preenche(const Color(0xFFFFD66B)));
          canvas.drawPath(p, _traco(linha, 1.5));
        }
      case Humor.apaixonada:
        for (final p in [_coracaoPath(114, 12, 6, 1, 6, 3.4), _coracaoPath(4, 10, 5, 1, 5, 2.8)]) {
          canvas.drawPath(p, _preenche(_coracao));
          canvas.drawPath(p, _traco(linha, 1.5));
        }
      case Humor.sonolenta:
        _texto(canvas, 'z', 102, 10, 14, const Color(0xFF8E7CC3));
        _texto(canvas, 'z', 112, 0, 18, const Color(0xFF8E7CC3));
      case Humor.curiosa:
        _texto(canvas, '?', 106, 12, 22, const Color(0xFFF28C6B));
      case Humor.preocupada:
        final gota = Path()
          ..moveTo(108, 36)
          ..quadraticBezierTo(114, 44, 108, 48)
          ..quadraticBezierTo(102, 44, 108, 36)
          ..close();
        canvas.drawPath(gota, _preenche(corAgua));
        canvas.drawPath(gota, _traco(linha, 1.5));
      case Humor.feliz:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GatinhaPainter antigo) =>
      antigo.humor != humor || antigo.linha != linha || antigo.mancha != mancha;
}
