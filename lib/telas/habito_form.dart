import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

const _nomesDias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

/// UC05: cadastrar (e editar/arquivar) hábito. RN27: semana começa na segunda.
class TelaHabito extends StatefulWidget {
  final Habito? habito;
  const TelaHabito({super.key, this.habito});

  @override
  State<TelaHabito> createState() => _TelaHabitoState();
}

class _TelaHabitoState extends State<TelaHabito> {
  late final TextEditingController _nome;
  late final TextEditingController _unidade;
  late Frequencia _freq;
  late List<int> _dias;
  late int _vezes;
  late TipoHabito _tipo;
  late double _meta;

  bool get _editando => widget.habito != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habito;
    _nome = TextEditingController(text: h?.nome ?? '');
    _unidade = TextEditingController(text: h?.unidade ?? 'L');
    _freq = h?.frequencia ?? Frequencia.todoDia;
    _dias = List.of(h?.dias ?? [1, 3, 5]);
    _vezes = h?.vezesPorSemana ?? 3;
    _tipo = h?.tipo ?? TipoHabito.feito;
    _meta = h?.meta ?? 2;
  }

  @override
  void dispose() {
    _nome.dispose();
    _unidade.dispose();
    super.dispose();
  }

  String _resumo() {
    final freq = switch (_freq) {
      Frequencia.todoDia => 'todo dia',
      Frequencia.diasSemana => _dias.isEmpty ? 'nenhum dia' : ([..._dias]..sort()).map((d) => _nomesDias[d - 1]).join(', '),
      Frequencia.vezesPorSemana => '$_vezes× por semana',
    };
    final meta = _tipo == TipoHabito.meta ? 'meta ${formatarNumero(_meta)} ${_unidade.text}, ' : '';
    return meta + freq;
  }

  void _salvar(EstadoApp e) {
    final nome = _nome.text.trim();
    // UC05 E1: nome vazio, nenhum dia escolhido ou meta <= 0
    if (nome.isEmpty) return e.reagir(Humor.preocupada, 'Dá um nome pro hábito!');
    if (_freq == Frequencia.diasSemana && _dias.isEmpty) return e.reagir(Humor.preocupada, 'Escolhe pelo menos um dia!');
    if (_tipo == TipoHabito.meta && _meta <= 0) return e.reagir(Humor.preocupada, 'A meta precisa ser maior que zero.');
    final antigo = widget.habito;
    e.salvarHabito(Habito(
      id: antigo?.id,
      nome: nome,
      frequencia: _freq,
      dias: _dias,
      vezesPorSemana: _vezes,
      tipo: _tipo,
      meta: _tipo == TipoHabito.meta ? _meta : 1,
      unidade: _tipo == TipoHabito.meta ? _unidade.text.trim() : '',
      marcas: antigo?.marcas, // RN08: o histórico fica como está
    ));
    e.reagir(Humor.comemorando, 'Combinado: ${_resumo()}!');
    Navigator.pop(context);
  }

  Widget _contador(String texto, VoidCallback menos, VoidCallback mais, String rotulo) {
    return Row(children: [
      BotaoIcone(Icons.remove_rounded, rotulo: 'Diminuir $rotulo', onTap: menos),
      SizedBox(width: 72, child: Center(child: Text(texto, style: titulo(context, 24)))),
      BotaoIcone(Icons.add_rounded, rotulo: 'Aumentar $rotulo', onTap: mais),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo(_editando ? '♡ Editar hábito' : '♡ Hábito'),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.curiosa,
              fala: e.falaDoMomento ?? 'Que hábito vamos cultivar?',
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                const Rotulo('Nome do hábito'),
                TextField(controller: _nome, textCapitalization: TextCapitalization.sentences, onChanged: (_) => setState(() {}), style: corpo(context, peso: FontWeight.w600)),
                const SizedBox(height: 18),
                const Rotulo('Com que frequência?'),
                EscolhaUnica<Frequencia>(
                  opcoes: Frequencia.values,
                  valor: _freq,
                  rotulo: (f) => switch (f) {
                    Frequencia.todoDia => 'Todo dia',
                    Frequencia.diasSemana => 'Dias da semana',
                    Frequencia.vezesPorSemana => 'X vezes por semana',
                  },
                  onChanged: (f) => setState(() => _freq = f),
                ),
                if (_freq == Frequencia.diasSemana) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (var d = 1; d <= 7; d++)
                      ChipFofo(
                        _nomesDias[d - 1],
                        selecionado: _dias.contains(d),
                        onTap: () => setState(() {
                          if (!_dias.remove(d)) _dias.add(d);
                        }),
                      ),
                  ]),
                ],
                if (_freq == Frequencia.vezesPorSemana) ...[
                  const SizedBox(height: 12),
                  _contador('$_vezes×', () => setState(() => _vezes = (_vezes - 1).clamp(1, 7)), () => setState(() => _vezes = (_vezes + 1).clamp(1, 7)), 'vezes por semana'),
                ],
                const SizedBox(height: 18),
                const Rotulo('Como marcar?'),
                EscolhaUnica<TipoHabito>(
                  opcoes: TipoHabito.values,
                  valor: _tipo,
                  rotulo: (t) => t == TipoHabito.feito ? 'Feito / não feito' : 'Meta com quantidade',
                  onChanged: (t) => setState(() => _tipo = t),
                ),
                if (_tipo == TipoHabito.meta) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    _contador(formatarNumero(_meta), () => setState(() => _meta = (_meta - 0.5).clamp(0.5, 999.0)), () => setState(() => _meta += 0.5), 'meta'),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _unidade,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: 'unidade'),
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 18),
                Cartao(
                  cor: c.segundaSuave,
                  sombra: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Vai aparecer assim no seu dia', style: corpo(context, tamanho: 13)),
                    const SizedBox(height: 6),
                    Text('○ ${_nome.text.isEmpty ? '…' : _nome.text} · ${_resumo()}', style: corpo(context)),
                  ]),
                ),
                if (_editando) ...[
                  const SizedBox(height: 24),
                  BotaoFofo('Arquivar hábito', estilo: EstiloBotao.fantasma, onPressed: () {
                    e.arquivarHabito(widget.habito!); // UC05 A2: some do dia a dia, histórico fica
                    Navigator.pop(context);
                  }),
                ],
              ]),
            ),
            RodapeBotao('Salvar hábito', onPressed: () => _salvar(e)),
          ]),
        ),
      ),
    );
  }
}
