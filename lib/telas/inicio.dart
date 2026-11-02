import 'package:flutter/material.dart';

import '../tema.dart';
import 'futuro.dart';
import 'hoje.dart';
import 'progresso.dart';
import 'semana.dart';

/// Casca do app com as abas de baixo: Hoje, Semana (e mês), Futuro e Hábitos.
class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _aba = 0;

  static const _abas = [
    (Icons.calendar_today_rounded, 'Hoje'),
    (Icons.view_week_rounded, 'Semana'),
    (Icons.star_border_rounded, 'Futuro'),
    (Icons.favorite_border_rounded, 'Hábitos'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Scaffold(
      body: IndexedStack(index: _aba, children: const [TelaHoje(), TelaSemana(), TelaFuturo(), TelaProgresso()]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.cartao, border: Border(top: BorderSide(color: c.linha, width: 2.5))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              for (var i = 0; i < _abas.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == _aba,
                    child: InkWell(
                      onTap: () => setState(() => _aba = i),
                      child: SizedBox(
                        height: 60,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_abas[i].$1, color: i == _aba ? c.texto : c.textoSuave, size: 24),
                          const SizedBox(height: 2),
                          Text(_abas[i].$2,
                              style: corpo(context, tamanho: 12, peso: i == _aba ? FontWeight.w800 : FontWeight.w700, cor: i == _aba ? c.texto : c.textoSuave)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
