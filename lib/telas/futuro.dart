import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

/// UC14: future log, coisas pros próximos meses ainda sem dia certo.
class TelaFuturo extends StatefulWidget {
  const TelaFuturo({super.key});

  @override
  State<TelaFuturo> createState() => _TelaFuturoState();
}

class _TelaFuturoState extends State<TelaFuturo> {
  final _texto = TextEditingController();
  int _mesEscolhido = 0;
  bool _evento = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  /// O mês atual e os próximos 5.
  List<DateTime> _meses() {
    final h = DateTime.now();
    return [for (var i = 0; i < 6; i++) DateTime(h.year, h.month + i)];
  }

  void _guardar(EstadoApp e) {
    e.adicionarFuturo(_texto.text, _meses()[_mesEscolhido], evento: _evento);
    _texto.clear();
  }

  Future<void> _agendar(EstadoApp e, ItemFuturo f) async {
    final mes = mesDe(f.mes);
    final hoje = e.hoje;
    final inicio = mes.isBefore(hoje) ? hoje : mes;
    final dia = await showDatePicker(
      context: context,
      helpText: 'Pra qual dia vai "${f.texto}"?',
      initialDate: inicio,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 3),
      locale: const Locale('pt', 'BR'),
    );
    if (dia != null) e.agendarFuturo(f, dia);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final meses = _meses();
    // meses com itens que não estão na janela (ex.: mais longe) também aparecem
    final extras = e.futuro.map((f) => f.mes).toSet().difference(meses.map(mesTexto).toSet()).map(mesDe).toList()..sort();
    final todos = [...meses, ...extras];
    final total = e.futuro.length;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Future log', style: titulo(context, 28)),
                Text('o que vem por aí nos próximos meses', style: corpo(context, cor: c.textoSuave)),
              ]),
            ),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.curiosa,
              fala: e.falaDoMomento ??
                  (total == 0 ? 'Guarda aqui o que ainda não tem dia certo ♡' : 'Guardei $total ${total == 1 ? 'coisinha' : 'coisinhas'} pro futuro. No resumo do dia 1º eu te lembro!'),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                Cartao(
                  cor: c.segundaSuave,
                  sombra: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _texto,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(hintText: 'Algo pra daqui a uns meses…'),
                          onSubmitted: (_) => _guardar(e),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BotaoIcone(Icons.add_rounded, rotulo: 'Guardar no future log', fundo: c.destaque, onTap: () => _guardar(e)),
                    ]),
                    const SizedBox(height: 10),
                    EscolhaUnica<int>(
                      opcoes: [for (var i = 0; i < meses.length; i++) i],
                      valor: _mesEscolhido,
                      rotulo: (i) => DateFormat("MMM yy", 'pt_BR').format(meses[i]),
                      onChanged: (i) => setState(() => _mesEscolhido = i),
                    ),
                    const SizedBox(height: 8),
                    EscolhaUnica<bool>(
                      opcoes: const [false, true],
                      valor: _evento,
                      rotulo: (ev) => ev ? '○ evento' : '• tarefa',
                      onChanged: (ev) => setState(() => _evento = ev),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                for (final m in todos) ...[_mes(context, e, m), const SizedBox(height: 14)],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mes(BuildContext context, EstadoApp e, DateTime mes) {
    final c = context.cores;
    final itens = e.futuroDoMes(mesTexto(mes));
    return Cartao(
      padding: const EdgeInsets.fromLTRB(6, 12, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 6, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(toBeginningOfSentenceCase(DateFormat.MMMM('pt_BR').format(mes)), style: titulo(context, 18)),
            const SizedBox(width: 8),
            Text('${mes.year}', style: corpo(context, tamanho: 13, cor: c.textoSuave)),
          ]),
        ),
        Divider(color: c.ponto, thickness: 2, height: 2),
        if (itens.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: Text('Nada ainda. Mês em branco ♡', style: corpo(context, cor: c.textoSuave))),
        for (final f in itens)
          GestureDetector(
            onLongPress: () async {
              final r = await confirmarExclusao(context, oQue: '"${f.texto}"', noGoogle: false);
              if (r != Exclusao.cancelar) e.excluirFuturo(f);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Row(children: [
                SizedBox(width: 36, child: Center(child: Text(f.evento ? '○' : '•', style: titulo(context, 20)))),
                Expanded(child: Text(f.texto, style: corpo(context))),
                BotaoIcone(Icons.arrow_forward_rounded, rotulo: 'Passar ${f.texto} pra um dia', onTap: () => _agendar(e, f)),
              ]),
            ),
          ),
        if (itens.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text('→ passa pro dia · segure pra apagar', style: corpo(context, tamanho: 12, peso: FontWeight.w600, cor: c.textoSuave)),
          ),
      ]),
    );
  }
}
