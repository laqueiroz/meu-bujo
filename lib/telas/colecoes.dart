import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'tarefa_form.dart';

Color corDeHex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// Quando a tarefa é: hoje, ontem, dia da semana próximo ou a data.
String quandoCurto(String data, DateTime hoje) {
  final d = dataDe(data);
  final dif = d.difference(hoje).inDays;
  if (dif == 0) return 'hoje';
  if (dif == -1) return 'ontem';
  if (dif == 1) return 'amanhã';
  if (dif > 1 && dif < 7) return DateFormat.E('pt_BR').format(d).replaceAll('.', '');
  return DateFormat('d MMM', 'pt_BR').format(d).replaceAll('.', '');
}

/// UC19: lista de coleções com quanto já foi feito em cada uma.
class TelaColecoes extends StatefulWidget {
  const TelaColecoes({super.key});

  @override
  State<TelaColecoes> createState() => _TelaColecoesState();
}

class _TelaColecoesState extends State<TelaColecoes> {
  final _nova = TextEditingController();

  @override
  void dispose() {
    _nova.dispose();
    super.dispose();
  }

  void _criar(EstadoApp e) {
    final erro = e.adicionarColecao(_nova.text);
    if (erro != null) return e.reagir(Humor.curiosa, erro);
    e.reagir(Humor.comemorando, 'Coleção ${_nova.text.trim()} criada!');
    _nova.clear();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final abertas = e.tarefas.where((t) => t.aberta && t.colecao != null).length;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            const Topo('Coleções'),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.feliz,
              fala: e.falaDoMomento ?? (abertas == 0 ? 'Cada coisa no seu cantinho ♡' : 'Tem $abertas ${abertas == 1 ? 'tarefinha aberta' : 'tarefinhas abertas'} espalhadas por aqui.'),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                for (final nome in e.colecoes) ...[
                  _cartao(context, e, nome),
                  const SizedBox(height: 12),
                ],
                Cartao(
                  cor: c.segundaSuave,
                  sombra: false,
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _nova,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Nova coleção…'),
                        onSubmitted: (_) => _criar(e),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotaoIcone(Icons.add_rounded, rotulo: 'Criar coleção', fundo: c.destaque, onTap: () => _criar(e)),
                  ]),
                ),
                const SizedBox(height: 10),
                Text('A barrinha mostra quanto já foi feito em cada coleção.',
                    style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cartao(BuildContext context, EstadoApp e, String nome) {
    final c = context.cores;
    final ts = e.tarefasDaColecao(nome).where((t) => t.status != StatusTarefa.cancelada).toList();
    final feitas = ts.where((t) => !t.aberta).length;
    final fracao = ts.isEmpty ? 0.0 : feitas / ts.length;
    return Semantics(
      button: true,
      label: '$nome: ${ts.length - feitas} abertas, $feitas feitas',
      child: Cartao(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaColecao(nome: nome))),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: corDeHex(e.corDaColecao(nome)), shape: BoxShape.circle, border: Border.all(color: c.linha, width: 2.5)),
            child: Text(nome.substring(0, 1).toUpperCase(), style: titulo(context, 15, cor: corTextoSobreDestaque)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(nome, style: titulo(context, 17))),
                Text('${ts.length - feitas} abertas · $feitas feitas', style: corpo(context, tamanho: 13, cor: c.textoSuave)),
              ]),
              const SizedBox(height: 6),
              Container(
                height: 12,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: c.destaqueSuave, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.linha, width: 2)),
                child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: fracao, child: Container(color: c.destaque)),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: c.texto),
        ]),
      ),
    );
  }
}

/// UC19: uma coleção: renomear, trocar a cor, apagar e ver as tarefas dela.
class TelaColecao extends StatefulWidget {
  final String nome;
  const TelaColecao({super.key, required this.nome});

  @override
  State<TelaColecao> createState() => _TelaColecaoState();
}

class _TelaColecaoState extends State<TelaColecao> {
  late String _nome = widget.nome;
  late final _campo = TextEditingController(text: widget.nome);
  bool _confirmar = false;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _renomear(EstadoApp e) {
    final erro = e.renomearColecao(_nome, _campo.text);
    if (erro != null) {
      e.reagir(Humor.curiosa, erro);
      _campo.text = _nome;
      return;
    }
    if (_campo.text.trim().isNotEmpty) setState(() => _nome = _campo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final todas = e.tarefasDaColecao(_nome).where((t) => t.status != StatusTarefa.cancelada).toList();
    final abertas = todas.where((t) => t.aberta).toList()..sort((a, b) => a.data.compareTo(b.data));
    final feitas = todas.where((t) => !t.aberta).toList();
    final cor = e.corDaColecao(_nome);
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo(_nome),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.curiosa,
              fala: e.falaDoMomento ?? 'Aqui ficam só as tarefas de $_nome.',
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                Cartao(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Rotulo('Nome'),
                    TextField(
                      controller: _campo,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _renomear(e),
                      onTapOutside: (_) {
                        if (_campo.text.trim() != _nome) _renomear(e);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    const SizedBox(height: 12),
                    const Rotulo('Cor da etiqueta'),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      for (final k in coresColecao.entries)
                        Semantics(
                          button: true,
                          selected: k.value == cor,
                          label: 'Cor ${k.key}',
                          child: GestureDetector(
                            onTap: () => e.definirCorColecao(_nome, k.value),
                            child: Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: k.value == cor ? Border.all(color: c.linha, width: 2.5) : null),
                              child: Container(decoration: BoxDecoration(color: corDeHex(k.value), shape: BoxShape.circle, border: Border.all(color: c.linha, width: 2))),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 18),
                TituloSecao('abertas · ${abertas.length}'),
                Cartao(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: abertas.isEmpty
                      ? Padding(padding: const EdgeInsets.all(12), child: Text('Nada aberto aqui ♡', style: corpo(context, cor: c.textoSuave)))
                      : Column(children: [for (final t in abertas) _linha(context, e, t)]),
                ),
                if (feitas.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  TituloSecao('feitas · ${feitas.length}'),
                  Cartao(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    child: Column(children: [for (final t in feitas) _linha(context, e, t)]),
                  ),
                ],
                const SizedBox(height: 22),
                if (_confirmar)
                  Cartao(
                    cor: c.segundaSuave,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Apagar a coleção “$_nome”? As ${todas.length} tarefas continuam no app, só ficam sem coleção.', style: corpo(context)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: BotaoFofo('Apagar', estilo: EstiloBotao.rosa, onPressed: () {
                            e.apagarColecao(_nome);
                            Navigator.pop(context);
                          }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: BotaoFofo('Voltar', estilo: EstiloBotao.fantasma, onPressed: () => setState(() => _confirmar = false))),
                      ]),
                    ]),
                  )
                else
                  Center(child: ChipFofo('Apagar coleção', onTap: () => setState(() => _confirmar = true))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, EstadoApp e, Tarefa t) {
    final c = context.cores;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(children: [
        SizedBox(width: 40, child: Center(child: Text(t.aberta ? '•' : '×', style: titulo(context, 20)))),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaTarefa(tarefa: t))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.texto,
                style: corpo(context, cor: t.aberta ? c.texto : c.textoSuave).copyWith(decoration: t.aberta ? null : TextDecoration.lineThrough),
              ),
            ),
          ),
        ),
        Text(quandoCurto(t.data, e.hoje), style: corpo(context, tamanho: 12, cor: c.textoSuave)),
        CaixaCheck(feita: !t.aberta, rotulo: t.texto, onTap: () => t.aberta ? e.concluir(t) : e.reabrir(t)),
      ]),
    );
  }
}
