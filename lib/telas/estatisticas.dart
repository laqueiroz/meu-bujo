import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/estatisticas.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'colecoes.dart';

/// UC20: números das tarefas na semana ou no mês.
class TelaEstatisticas extends StatefulWidget {
  final bool mes;
  final DateTime? dia;
  const TelaEstatisticas({super.key, this.mes = false, this.dia});

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  late bool _mes = widget.mes;
  late DateTime _ref = soDia(widget.dia ?? DateTime.now());

  void _mover(int n) => setState(() => _ref = _mes ? DateTime(_ref.year, _ref.month + n) : DateTime(_ref.year, _ref.month, _ref.day + 7 * n));

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final s = _mes ? Estatisticas.doMes(e.tarefas, _ref) : Estatisticas.daSemana(e.tarefas, _ref);
    final ini = inicioDaSemana(_ref);
    final fim = ini.add(const Duration(days: 6));
    final periodo = _mes
        ? DateFormat("MMMM 'de' y", 'pt_BR').format(_ref)
        : '${DateFormat('d MMM', 'pt_BR').format(ini)} – ${DateFormat('d MMM', 'pt_BR').format(fim)}'.replaceAll('.', '');
    final maisCheio = s.colunas.isEmpty ? null : s.colunas.reduce((a, b) => a.$2 + a.$3 >= b.$2 + b.$3 ? a : b);
    final fala = s.total == 0
        ? 'Nada anotado nesse período ainda.'
        : (_mes
            ? 'Você fez ${s.feitas} ${s.feitas == 1 ? 'tarefa' : 'tarefas'} nesse mês, ${s.taxa}% do que anotou.'
            : 'Você fez ${s.taxa}% do que anotou.${maisCheio != null && maisCheio.$2 + maisCheio.$3 > 0 ? ' ${toBeginningOfSentenceCase(DateFormat.EEEE('pt_BR').format(ini.add(Duration(days: s.colunas.indexOf(maisCheio)))))} foi o dia mais cheio.' : ''}');
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo('Seus números', acao: Row(mainAxisSize: MainAxisSize.min, children: [
              BotaoIcone(Icons.chevron_left_rounded, rotulo: _mes ? 'Mês anterior' : 'Semana anterior', onTap: () => _mover(-1)),
              const SizedBox(width: 6),
              BotaoIcone(Icons.chevron_right_rounded, rotulo: _mes ? 'Próximo mês' : 'Próxima semana', onTap: () => _mover(1)),
            ])),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(children: [
                Expanded(child: Text(periodo, style: corpo(context, cor: c.textoSuave))),
                EscolhaUnica<bool>(opcoes: const [false, true], valor: _mes, rotulo: (m) => m ? 'Mês' : 'Semana', onChanged: (m) => setState(() => _mes = m)),
              ]),
            ),
            GatinhaFalando(
              humor: e.humorDoMomento ?? (s.taxa >= 70 ? Humor.apaixonada : Humor.feliz),
              fala: e.falaDoMomento ?? fala,
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                Row(children: [
                  for (final (v, r) in [('${s.feitas}', 'feitas'), ('${s.taxa}%', 'do total'), ('${s.migradas}', 'migradas'), ('${s.canceladas}', 'canceladas')]) ...[
                    Expanded(
                      child: Cartao(
                        sombra: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        child: Column(children: [
                          Text(v, style: titulo(context, 22).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                          Text(r, textAlign: TextAlign.center, style: corpo(context, tamanho: 11, cor: c.textoSuave)),
                        ]),
                      ),
                    ),
                    if (r != 'canceladas') const SizedBox(width: 6),
                  ],
                ]),
                const SizedBox(height: 14),
                TituloSecao(_mes ? 'tarefas por semana' : 'tarefas por dia'),
                Cartao(child: _grafico(context, s)),
                if (s.porColecao.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const TituloSecao('por coleção'),
                  Cartao(
                    child: Column(children: [
                      for (final (nome, f, t) in s.porColecao)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Row(children: [
                              Expanded(child: Text(nome, style: corpo(context))),
                              Text('$f de $t', style: corpo(context, tamanho: 13, cor: c.textoSuave)),
                              SizedBox(width: 46, child: Text('${(f * 100 / t).round()}%', textAlign: TextAlign.right, style: corpo(context, tamanho: 13))),
                            ]),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(color: c.destaqueSuave, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.linha, width: 2)),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: f / t,
                                child: Container(color: e.colecoes.contains(nome) ? corDeHex(e.corDaColecao(nome)) : c.destaque),
                              ),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                ],
                if (s.alertas.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const TituloSecao('pra ficar de olho'),
                  Cartao(
                    cor: c.segundaSuave,
                    sombra: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final a in s.alertas)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(width: 22, child: Text('>', style: titulo(context, 18))),
                            Expanded(child: Text(a, style: corpo(context))),
                          ]),
                        ),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Colunas empilhadas: feitas (cheias) embaixo e as que ficaram abertas (tracejadas) em cima.
  Widget _grafico(BuildContext context, Estatisticas s) {
    final c = context.cores;
    final maior = s.colunas.fold(1, (m, x) => x.$2 + x.$3 > m ? x.$2 + x.$3 : m);
    const alturaMax = 110.0;
    return Column(children: [
      Semantics(
        label: s.colunas.map((x) => '${x.$1}: ${x.$2} feitas, ${x.$3} abertas').join('; '),
        child: ExcludeSemantics(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final (nome, feitas, abertas) in s.colunas)
              Expanded(
                child: Column(children: [
                  Text(feitas + abertas == 0 ? '–' : '$feitas/${feitas + abertas}', style: corpo(context, tamanho: 11, cor: c.textoSuave)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: alturaMax,
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (abertas > 0)
                        Container(
                          width: 24,
                          height: alturaMax * abertas / maior,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(color: c.cartao, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.linha.withValues(alpha: 0.6), width: 2)),
                        ),
                      if (feitas > 0)
                        Container(
                          width: 24,
                          height: alturaMax * feitas / maior,
                          decoration: BoxDecoration(color: c.destaque, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.linha, width: 2)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(nome, style: corpo(context, tamanho: 11, cor: c.textoSuave)),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legenda(context, c.destaque, c.linha, 'feitas'),
        const SizedBox(width: 14),
        _legenda(context, c.cartao, c.linha.withValues(alpha: 0.6), 'abertas'),
      ]),
    ]);
  }

  Widget _legenda(BuildContext context, Color fundo, Color borda, String texto) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(4), border: Border.all(color: borda, width: 2))),
        const SizedBox(width: 5),
        Text(texto, style: corpo(context, tamanho: 12, cor: context.cores.textoSuave)),
      ]);
}
