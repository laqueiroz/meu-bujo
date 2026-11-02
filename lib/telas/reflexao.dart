import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/estatisticas.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'estatisticas.dart';

/// UC21: reflexão do mês (inclui UC20 e UC17 no resumo).
class TelaReflexao extends StatefulWidget {
  final DateTime mes;
  const TelaReflexao({super.key, required this.mes});

  @override
  State<TelaReflexao> createState() => _TelaReflexaoState();
}

class _TelaReflexaoState extends State<TelaReflexao> {
  static const _humores = [
    (Humor.comemorando, 'ótimo'),
    (Humor.feliz, 'bem'),
    (Humor.curiosa, 'ok'),
    (Humor.sonolenta, 'cansada'),
    (Humor.preocupada, 'difícil'),
  ];

  late final List<TextEditingController> _textos;
  late Humor _humor;
  final Set<Meta> _levar = {};

  @override
  void initState() {
    super.initState();
    final r = context.read<EstadoApp>().reflexoes[mesTexto(widget.mes)];
    _textos = [for (var i = 0; i < 3; i++) TextEditingController(text: r?.textos[i] ?? '')];
    _humor = Humor.values.where((h) => h.name == r?.humor).firstOrNull ?? Humor.feliz;
  }

  @override
  void dispose() {
    for (final t in _textos) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final nomeMes = toBeginningOfSentenceCase(DateFormat.MMMM('pt_BR').format(widget.mes));
    final proximo = DateFormat.MMMM('pt_BR').format(DateTime(widget.mes.year, widget.mes.month + 1));
    final s = Estatisticas.doMes(e.tarefas, widget.mes);
    final seq = e.melhorSequenciaDoMes(widget.mes);
    final metas = e.metasDoMes(widget.mes);
    final pendentes = metas.where((m) => !m.feita).toList();
    final salva = e.reflexoes.containsKey(mesTexto(widget.mes));
    final perguntas = [
      ('O que deu certo?', 'Uma conquista, mesmo pequena…'),
      ('O que ficou difícil?', 'Sem julgamento, só pra lembrar…'),
      ('Pra $proximo, eu quero…', 'Cada linha vira uma meta de $proximo'),
    ];
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo('$nomeMes, como foi?'),
            GatinhaFalando(
              humor: e.humorDoMomento ?? (salva ? Humor.apaixonada : Humor.curiosa),
              fala: e.falaDoMomento ?? (salva ? 'Essa é a sua reflexão de ${nomeMes.toLowerCase()} ♡' : '$nomeMes acabou! Bora olhar pra ele com carinho?'),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                const TituloSecao('o mês em números'),
                Cartao(
                  child: Column(children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _numero(context, '${s.feitas}', 'tarefas feitas'),
                      _numero(context, seq == null ? '–' : '${seq.$2} ${seq.$2 == 1 ? 'dia' : 'dias'}', seq == null ? 'sequência de hábito' : 'melhor sequência (${seq.$1})'),
                      _numero(context, metas.isEmpty ? '–' : '${metas.where((m) => m.feita).length} de ${metas.length}', 'metas do mês'),
                    ]),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaEstatisticas(mes: true, dia: widget.mes))),
                      child: Text('ver todos os números', style: corpo(context, tamanho: 13).copyWith(decoration: TextDecoration.underline)),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                const TituloSecao('como você se sentiu no mês?'),
                Cartao(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Row(children: [
                    for (final (h, nome) in _humores)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: h == _humor,
                          label: 'Mês $nome',
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _humor = h);
                              e.reagir(h, 'Mês $nome, anotado.');
                            },
                            child: Container(
                              padding: const EdgeInsets.only(top: 4, bottom: 6),
                              decoration: BoxDecoration(
                                color: h == _humor ? c.destaqueSuave : null,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: h == _humor ? c.linha : Colors.transparent, width: 2),
                              ),
                              child: Column(children: [
                                ExcludeSemantics(child: Gatinha(humor: h, tamanho: 44)),
                                Text(nome, style: corpo(context, tamanho: 11)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
                for (var i = 0; i < 3; i++) ...[
                  const SizedBox(height: 14),
                  Cartao(
                    sombra: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(perguntas[i].$1, style: titulo(context, 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textos[i],
                        minLines: 2,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(hintText: perguntas[i].$2),
                      ),
                    ]),
                  ),
                ],
                if (pendentes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Cartao(
                    cor: c.segundaSuave,
                    sombra: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('metas que ficaram pra trás', style: titulo(context, 16)),
                      const SizedBox(height: 6),
                      for (final m in pendentes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text(m.texto, style: corpo(context))),
                            ChipFofo(_levar.contains(m) ? '✓ vai pra $proximo' : 'levar pra $proximo',
                                selecionado: _levar.contains(m),
                                onTap: () => setState(() => _levar.contains(m) ? _levar.remove(m) : _levar.add(m))),
                          ]),
                        ),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                BotaoFofo(salva ? 'Atualizar reflexão' : 'Salvar reflexão', largo: true, onPressed: () {
                  e.salvarReflexao(widget.mes, humor: _humor.name, textos: [for (final t in _textos) t.text.trim()], levar: _levar.toList());
                  setState(_levar.clear);
                }),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _numero(BuildContext context, String valor, String rotulo) => Expanded(
        child: Column(children: [
          Text(valor, textAlign: TextAlign.center, style: titulo(context, 20)),
          const SizedBox(height: 2),
          Text(rotulo, textAlign: TextAlign.center, style: corpo(context, tamanho: 12, cor: context.cores.textoSuave)),
        ]),
      );
}
