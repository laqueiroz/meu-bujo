import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'ajustes.dart';
import 'colecoes.dart';
import 'reflexao.dart';
import 'evento_form.dart';
import 'habito_form.dart';
import 'pendencias.dart';
import 'tarefa_form.dart';

/// UC07 (daily log), com UC02 (concluir) e UC06 (marcar hábito).
class TelaHoje extends StatefulWidget {
  const TelaHoje({super.key});

  @override
  State<TelaHoje> createState() => _TelaHojeState();
}

class _TelaHojeState extends State<TelaHoje> {
  DateTime dia = soDia(DateTime.now());

  void _abrir(Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  void _mudarDia(int delta) =>
      setState(() => dia = dia.add(Duration(days: delta)));

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final d = dataTexto(dia);
    final ehHoje = dia == e.hoje;
    final tarefas = e.tarefasDoDia(d);
    final migradas = e.migradasDoDia(d);
    final eventos = e.eventosDoDia(d);
    final habitos = e.habitosDoDia(dia);
    final pend = e.pendencias;
    final abertas = tarefas.where((t) => t.aberta).length;

    final (Humor humorBase, String falaBase) = !ehHoje
        ? (
            Humor.curiosa,
            dia.isAfter(e.hoje)
                ? 'Espiando o futuro…'
                : 'Olhando um dia que passou.'
          )
        : tarefas.isNotEmpty && abertas == 0
            ? (Humor.apaixonada, 'Tudo feito hoje! Que orgulho ♡')
            : (tarefas.isEmpty && eventos.isEmpty)
                ? (
                    Humor.feliz,
                    'Dia livre por enquanto! Toque no + pra anotar.'
                  )
                : (
                    Humor.feliz,
                    'Hoje tem ${eventos.length} ${eventos.length == 1 ? 'evento' : 'eventos'} e $abertas ${abertas == 1 ? 'tarefa' : 'tarefas'}.'
                  );

    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            _cabecalho(context, e, ehHoje),
            GatinhaFalando(
              humor: e.humorDoMomento ?? humorBase,
              fala: e.falaDoMomento ?? falaBase,
              tamanho: 76,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.linha,
                backgroundColor: c.cartao,
                onRefresh: e.atualizarAgora, // puxar pra atualizar
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    children: [
                      // RN20: apagado no Google, a usuária decide o que acontece aqui
                      for (final p in e.perguntasExclusao) ...[
                        Cartao(
                          cor: c.segundaSuave,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                    '"${p.titulo}" foi apagado no Google Agenda. Apagar aqui também?',
                                    style: corpo(context)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                      child: BotaoFofo('Apagar',
                                          estilo: EstiloBotao.rosa,
                                          onPressed: () => e.responderExclusao(
                                              p,
                                              apagarAqui: true))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: BotaoFofo('Manter aqui',
                                          estilo: EstiloBotao.fantasma,
                                          onPressed: () => e.responderExclusao(
                                              p,
                                              apagarAqui: false))),
                                ]),
                              ]),
                        ),
                        const SizedBox(height: 18),
                      ],
                      // UC21: no último dia do mês (ou nos primeiros dias do seguinte, se ficou sem), convida pra reflexão
                      if (ehHoje && e.mesPedindoReflexao() != null) ...[
                        Cartao(
                          cor: c.destaqueSuave,
                          onTap: () => _abrir(
                              TelaReflexao(mes: e.mesPedindoReflexao()!)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            const Gatinha(humor: Humor.apaixonada, tamanho: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  'Bora fazer a reflexão de ${DateFormat.MMMM('pt_BR').format(e.mesPedindoReflexao()!)}?',
                                  style: corpo(context)),
                            ),
                            Icon(Icons.chevron_right_rounded, color: c.texto),
                          ]),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (ehHoje && pend.isNotEmpty) ...[
                        Cartao(
                          cor: c.segundaSuave,
                          onTap: () => _abrir(const TelaPendencias()),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: c.segunda,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.linha, width: 2)),
                              child: Text('${pend.length}',
                                  style: titulo(context, 17,
                                      cor: corTextoSobreDestaque)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('pendências pra revisar',
                                    style: corpo(context))),
                            Icon(Icons.chevron_right_rounded, color: c.texto),
                          ]),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (eventos.isNotEmpty) ...[
                        const TituloSecao('eventos'),
                        Cartao(
                          padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                          child: Column(children: [
                            for (final ev in eventos) _linhaEvento(context, ev)
                          ]),
                        ),
                        const SizedBox(height: 18),
                      ],
                      const TituloSecao('tarefas'),
                      Cartao(
                        padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                        child: tarefas.isEmpty && migradas.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                    'Nenhuma tarefa. Toque no + pra anotar ♡',
                                    style: corpo(context, cor: c.textoSuave)),
                              )
                            : Column(children: [
                                for (final t in tarefas)
                                  _linhaTarefa(context, e, t),
                                for (final t in migradas)
                                  _linhaMigrada(context, t),
                              ]),
                      ),
                      const SizedBox(height: 18),
                      if (habitos.isNotEmpty) ...[
                        const TituloSecao('hábitos'),
                        Cartao(child: _habitos(context, e, habitos)),
                      ],
                    ]),
              ),
            ),
          ]),
        ),
      ),
      floatingActionButton: _botaoMais(context),
    );
  }

  Widget _cabecalho(BuildContext context, EstadoApp e, bool ehHoje) {
    final c = context.cores;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        BotaoIcone(Icons.chevron_left_rounded,
            rotulo: 'Dia anterior', onTap: () => _mudarDia(-1)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat.EEEE('pt_BR').format(dia),
                style: corpo(context, cor: c.textoSuave)),
            Text(DateFormat("d 'de' MMMM", 'pt_BR').format(dia),
                style: titulo(context, 26)),
          ]),
        ),
        if (!ehHoje) ...[
          ChipFofo('Hoje', onTap: () => setState(() => dia = e.hoje)),
          const SizedBox(width: 6)
        ],
        BotaoIcone(Icons.chevron_right_rounded,
            rotulo: 'Próximo dia', onTap: () => _mudarDia(1)),
        const SizedBox(width: 6),
        BotaoIcone(Icons.tune_rounded,
            rotulo: 'Ajustes', onTap: () => _abrir(const TelaAjustes())),
      ]),
    );
  }

  Widget _linhaEvento(BuildContext context, Evento ev) {
    final c = context.cores;
    return InkWell(
      onTap: () => _abrir(TelaEvento(evento: ev)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(children: [
          SizedBox(
              width: 44,
              child: Center(child: Text('○', style: titulo(context, 20)))),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ev.titulo, style: corpo(context)),
                  if (ev.hora != null)
                    Text(ev.hora!,
                        style: corpo(context, tamanho: 13, cor: c.textoSuave)),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _linhaTarefa(BuildContext context, EstadoApp e, Tarefa t) {
    final c = context.cores;
    final marca = switch (t.status) {
      StatusTarefa.aberta => '•',
      StatusTarefa.feita => '×',
      StatusTarefa.cancelada => '✕',
    };
    final riscada = !t.aberta;
    final feitasSub = t.subtarefas.where((s) => s.feita).length;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(children: [
        Semantics(
          button: true,
          label: t.aberta ? 'Concluir ${t.texto}' : 'Reabrir ${t.texto}',
          child: GestureDetector(
            onTap: () => t.aberta ? e.concluir(t) : e.reabrir(t),
            child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: Text(marca, style: titulo(context, 22)))),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _abrir(TelaTarefa(tarefa: t)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.texto,
                      style:
                          corpo(context, cor: riscada ? c.textoSuave : c.texto)
                              .copyWith(
                                  decoration: riscada
                                      ? TextDecoration.lineThrough
                                      : null),
                    ),
                    if (t.hora != null ||
                        t.colecao != null ||
                        t.subtarefas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (t.hora != null)
                                Text(t.hora!,
                                    style: corpo(context,
                                        tamanho: 13, cor: c.textoSuave)),
                              if (t.colecao != null)
                                Semantics(
                                  button: true,
                                  label: 'Abrir coleção ${t.colecao}',
                                  child: GestureDetector(
                                    onTap: () =>
                                        _abrir(TelaColecao(nome: t.colecao!)),
                                    child: _etiqueta(context, t.colecao!,
                                        cor: corDeHex(
                                            e.corDaColecao(t.colecao!))),
                                  ),
                                ),
                              if (t.subtarefas.isNotEmpty)
                                _etiqueta(context,
                                    '$feitasSub/${t.subtarefas.length}'),
                            ]),
                      ),
                  ]),
            ),
          ),
        ),
        if (t.prioridade)
          Semantics(
              label: 'prioridade',
              child: Icon(Icons.star_rounded, color: c.linha)),
        if (t.status != StatusTarefa.cancelada)
          CaixaCheck(
              feita: !t.aberta,
              rotulo: t.texto,
              onTap: () => t.aberta ? e.concluir(t) : e.reabrir(t)),
      ]),
    );
  }

  Widget _linhaMigrada(BuildContext context, Tarefa t) {
    final c = context.cores;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(children: [
        SizedBox(
            width: 44,
            child: Center(
                child:
                    Text('>', style: titulo(context, 20, cor: c.textoSuave)))),
        Expanded(
          child: Text(
            '${t.texto} · foi pra ${DateFormat('d/M').format(dataDe(t.data))}',
            style: corpo(context, peso: FontWeight.w600, cor: c.textoSuave),
          ),
        ),
      ]),
    );
  }

  Widget _etiqueta(BuildContext context, String texto, {Color? cor}) {
    final c = context.cores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: cor ?? c.destaqueSuave,
          borderRadius: BorderRadius.circular(999)),
      child: Text(texto,
          style: corpo(context,
              tamanho: 12, cor: cor == null ? null : corTextoSobreDestaque)),
    );
  }

  Widget _habitos(BuildContext context, EstadoApp e, List<Habito> habitos) {
    final c = context.cores;
    final d = dataTexto(dia);
    final comMeta = habitos.where((h) => h.tipo == TipoHabito.meta).toList();
    final simples = habitos.where((h) => h.tipo == TipoHabito.feito).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final h in comMeta)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onLongPress: () => _abrir(TelaHabito(habito: h)),
            child: Row(children: [
              Semantics(
                button: true,
                label:
                    'Somar ${formatarNumero(h.passo)} ${h.unidade} em ${h.nome}',
                child: GestureDetector(
                  onTap: () => e.somarHabito(h, dia, h.passo),
                  child:
                      Copo(progresso: h.meta == 0 ? 0 : h.valorEm(d) / h.meta),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.nome, style: titulo(context, 17)),
                      Text(
                          '${formatarNumero(h.valorEm(d))} de ${formatarNumero(h.meta)} ${h.unidade}',
                          style: corpo(context, cor: c.textoSuave)),
                      const SizedBox(height: 6),
                      Row(children: [
                        ChipFofo('+ ${formatarNumero(h.passo)} ${h.unidade}',
                            selecionado: true,
                            onTap: () => e.somarHabito(h, dia, h.passo)),
                        const SizedBox(width: 8),
                        BotaoIcone(Icons.remove_rounded,
                            rotulo:
                                'Tirar ${formatarNumero(h.passo)} ${h.unidade}',
                            onTap: () => e.somarHabito(h, dia, -h.passo)),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final h in simples)
          GestureDetector(
            onLongPress: () => _abrir(TelaHabito(habito: h)),
            child: ChipFofo('${h.feitoEm(d) ? '✓' : '○'} ${h.nome}',
                selecionado: h.feitoEm(d),
                onTap: () => e.alternarHabito(h, dia)),
          ),
        ChipFofo('+ hábito', onTap: () => _abrir(const TelaHabito())),
      ]),
      const SizedBox(height: 8),
      Text('Segure um hábito pra editar.',
          style: corpo(context,
              tamanho: 12, peso: FontWeight.w600, cor: c.textoSuave)),
    ]);
  }

  Widget _botaoMais(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      label: 'Adicionar',
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: c.cartao,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: c.linha, width: 2.5),
          ),
          builder: (sheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('O que vamos anotar?', style: titulo(context, 22)),
                    const SizedBox(height: 14),
                    BotaoFofo('•  Tarefa', onPressed: () {
                      Navigator.pop(sheet);
                      _abrir(TelaTarefa(dia: dia));
                    }),
                    const SizedBox(height: 10),
                    BotaoFofo('○  Evento', estilo: EstiloBotao.fantasma,
                        onPressed: () {
                      Navigator.pop(sheet);
                      _abrir(TelaEvento(dia: dia));
                    }),
                    const SizedBox(height: 10),
                    BotaoFofo('♡  Hábito', estilo: EstiloBotao.rosa,
                        onPressed: () {
                      Navigator.pop(sheet);
                      _abrir(const TelaHabito());
                    }),
                  ]),
            ),
          ),
        ),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: c.segunda,
            shape: BoxShape.circle,
            border: Border.all(color: c.linha, width: 2.5),
            boxShadow: [BoxShadow(color: c.linha, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add_rounded,
              size: 32, color: corTextoSobreDestaque),
        ),
      ),
    );
  }
}
