import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'habito_form.dart';
import 'tarefa_form.dart';

/// UC17 (ver progresso dos hábitos) e UC16 (lembrete de hábito).
class TelaProgresso extends StatefulWidget {
  const TelaProgresso({super.key});

  @override
  State<TelaProgresso> createState() => _TelaProgressoState();
}

class _TelaProgressoState extends State<TelaProgresso> {
  String? _habitoId;
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final habitos = e.habitos.where((h) => !h.arquivado).toList();
    final h = habitos.where((x) => x.id == _habitoId).firstOrNull ?? habitos.firstOrNull;

    final Widget conteudo;
    final Humor humorBase;
    final String falaBase;
    if (h == null) {
      humorBase = Humor.curiosa;
      falaBase = 'Nenhum hábito ainda. Bora criar um?';
      conteudo = ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        BotaoFofo('+ Novo hábito', onPressed: () => _abrir(const TelaHabito())),
      ]);
    } else {
      final atual = h.sequenciaAtual(e.hoje);
      humorBase = atual >= 7 ? Humor.apaixonada : (atual >= 3 ? Humor.feliz : Humor.curiosa);
      falaBase = atual >= 7
          ? '$atual dias seguidos de ${h.nome}! Que orgulho ♡'
          : (atual > 1 ? '$atual dias seguidos de ${h.nome}. Continua!' : (atual == 1 ? '${h.nome}: 1º dia da sequência. Continua!' : 'Bora começar a sequência de ${h.nome}?'));
      conteudo = _detalhe(context, e, habitos, h, atual);
    }

    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hábitos', style: titulo(context, 28)),
                    Text(DateFormat("MMMM 'de' y", 'pt_BR').format(_mes), style: corpo(context, cor: c.textoSuave)),
                  ]),
                ),
                ChipFofo('+ novo', onTap: () => _abrir(const TelaHabito())),
              ]),
            ),
            GatinhaFalando(humor: e.humorDoMomento ?? humorBase, fala: e.falaDoMomento ?? falaBase, tamanho: 62, onTap: e.fazerCarinho),
            Expanded(child: conteudo),
          ]),
        ),
      ),
    );
  }

  Widget _detalhe(BuildContext context, EstadoApp e, List<Habito> habitos, Habito h, int atual) {
    final c = context.cores;
    final taxa = h.taxaNoMes(_mes, e.hoje);
    final primeiro = DateTime(_mes.year, _mes.month);
    final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
      Semantics(
        button: true,
        label: 'Escolher hábito, agora ${h.nome}',
        child: Cartao(
          sombra: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          onTap: () => _escolherHabito(context, habitos, h),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('hábito', style: corpo(context, tamanho: 12, cor: c.textoSuave)),
                Text(h.nome, style: titulo(context, 18)),
              ]),
            ),
            Icon(Icons.expand_more_rounded, color: c.texto, size: 28),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _numero(context, '$atual', 'seguidos agora')),
        const SizedBox(width: 10),
        Expanded(child: _numero(context, '${h.melhorSequencia(e.hoje)}', 'melhor sequência')),
        const SizedBox(width: 10),
        Expanded(child: _numero(context, '${(taxa * 100).round()}%', 'dos dias do mês')),
      ]),
      const SizedBox(height: 14),
      Cartao(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: Column(children: [
          Row(children: [
            BotaoIcone(Icons.chevron_left_rounded, rotulo: 'Mês anterior', onTap: () => setState(() => _mes = DateTime(_mes.year, _mes.month - 1))),
            Expanded(child: Text(toBeginningOfSentenceCase(DateFormat.MMMM('pt_BR').format(_mes)), textAlign: TextAlign.center, style: titulo(context, 16))),
            BotaoIcone(Icons.chevron_right_rounded, rotulo: 'Próximo mês', onTap: () => setState(() => _mes = DateTime(_mes.year, _mes.month + 1))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'])
              Expanded(child: Text(n, textAlign: TextAlign.center, style: corpo(context, tamanho: 12, cor: c.textoSuave))),
          ]),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < primeiro.weekday - 1; i++) const SizedBox(),
              for (var n = 1; n <= diasNoMes; n++) _celula(context, e, h, DateTime(_mes.year, _mes.month, n)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
            _legenda(context, c.destaque, false, 'feito'),
            if (h.tipo == TipoHabito.meta) _legenda(context, c.destaqueSuave, false, 'parcial'),
            _legenda(context, null, true, 'não feito'),
            if (h.frequencia == Frequencia.diasSemana) Text('sem marca = folga', style: corpo(context, tamanho: 12, cor: c.textoSuave)),
          ]),
          const SizedBox(height: 8),
          Text('Dá pra corrigir até 7 dias atrás. Os mais antigos ficam travados.',
              textAlign: TextAlign.center, style: corpo(context, tamanho: 12, cor: c.textoSuave)),
        ]),
      ),
      const SizedBox(height: 14),
      Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Lembrete de ${h.nome}', style: corpo(context)),
                Text('às ${h.lembreteHora}, se ainda não tiver marcado', style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave)),
              ]),
            ),
            Interruptor(rotulo: 'Lembrete de ${h.nome}', valor: h.lembrete, onChanged: (v) => e.definirLembrete(h, ligado: v)),
          ]),
          if (h.lembrete) ...[
            const SizedBox(height: 10),
            Row(children: [
              ChipFofo('às ${h.lembreteHora}', selecionado: true, onTap: () async {
                final t = await showTimePicker(context: context, initialTime: horaDe(h.lembreteHora));
                if (t != null) e.definirLembrete(h, hora: horaTexto(t));
              }),
            ]),
          ],
        ]),
      ),
    ]);
  }

  /// Listinha pra trocar de hábito; o lápis abre a edição.
  Future<void> _escolherHabito(BuildContext context, List<Habito> habitos, Habito atual) async {
    final c = context.cores;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.cartao,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: c.linha, width: 2.5),
      ),
      builder: (folha) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(folha).size.height * 0.7),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), children: [
            Padding(padding: const EdgeInsets.only(left: 6, bottom: 10), child: Text('Qual hábito?', style: titulo(context, 22))),
            for (final x in habitos)
              Semantics(
                button: true,
                selected: x.id == atual.id,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(folha, x.id),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      color: x.id == atual.id ? c.destaqueSuave : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Icon(x.id == atual.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: c.linha),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(x.nome, style: corpo(context)),
                          Text('${x.sequenciaAtual(soDia(DateTime.now()))} seguidos agora', style: corpo(context, tamanho: 12, cor: c.textoSuave)),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Editar ${x.nome}',
                        icon: Icon(Icons.edit_rounded, color: c.textoSuave),
                        onPressed: () {
                          Navigator.pop(folha);
                          _abrir(TelaHabito(habito: x));
                        },
                      ),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            BotaoFofo('+ Novo hábito', estilo: EstiloBotao.fantasma, onPressed: () {
              Navigator.pop(folha);
              _abrir(const TelaHabito());
            }),
          ]),
        ),
      ),
    );
    if (id != null) setState(() => _habitoId = id);
  }

  Widget _numero(BuildContext context, String valor, String rotulo) => Cartao(
        sombra: false,
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: titulo(context, 24)),
          Text(rotulo, style: corpo(context, tamanho: 12, cor: context.cores.textoSuave)),
        ]),
      );

  Widget _legenda(BuildContext context, Color? cor, bool tracejado, String texto) {
    final c = context.cores;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.linha.withValues(alpha: tracejado ? 0.5 : 1), width: 2),
        ),
      ),
      const SizedBox(width: 5),
      Text(texto, style: corpo(context, tamanho: 12, cor: c.textoSuave)),
    ]);
  }

  Widget _celula(BuildContext context, EstadoApp e, Habito h, DateTime dia) {
    final c = context.cores;
    final d = dataTexto(dia);
    final futuro = dia.isAfter(e.hoje);
    final folga = !h.agendadoEm(dia);
    final v = h.valorEm(d);
    final feito = h.feitoEm(d);
    final parcial = !feito && v > 0;
    // RN09: mais de 7 dias atrás fica travado; mostra o que foi feito, mas não deixa mudar
    final travado = !futuro && !e.podeMarcar(dia);
    final estado = futuro ? 'ainda não chegou' : (folga ? 'folga' : (feito ? 'feito' : (parcial ? 'parcial' : 'não feito')));
    final ehHoje = dia == e.hoje;
    return Semantics(
      button: !travado && !futuro,
      label: '${dia.day}: $estado${travado ? ', travado' : ''}',
      child: GestureDetector(
        onTap: () {
          if (futuro) return e.reagir(Humor.curiosa, 'Dia ${dia.day} ainda não chegou!');
          if (folga) return e.reagir(Humor.sonolenta, 'Dia ${dia.day} é folga. zzz');
          if (travado) return e.reagir(Humor.sonolenta, 'Dia ${dia.day} já fechou. Só dá pra corrigir os últimos 7 dias.');
          e.corrigirHabito(h, dia);
        },
        child: Opacity(
          opacity: travado ? 0.45 : 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: futuro || folga ? null : (feito ? c.destaque : (parcial ? c.destaqueSuave : null)),
              borderRadius: BorderRadius.circular(10),
              // travado: sem moldura, só mostra se foi feito
              border: futuro || folga || (travado && !feito && !parcial)
                  ? null
                  : Border.all(color: ehHoje ? c.texto : c.linha.withValues(alpha: feito || parcial ? 1 : 0.5), width: ehHoje ? 2.5 : 2),
            ),
            child: Text('${dia.day}',
                style: corpo(context, tamanho: 13, cor: feito ? corTextoSobreDestaque : (futuro || folga ? c.textoSuave.withValues(alpha: 0.6) : c.texto))),
          ),
        ),
      ),
    );
  }
}
