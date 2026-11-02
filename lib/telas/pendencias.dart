import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

/// UC08 (revisar pendências) + UC09 (migrar tarefa).
class TelaPendencias extends StatelessWidget {
  const TelaPendencias({super.key});

  /// Pergunta da 3ª migração (RN28). Devolve true se pode seguir com a migração.
  static Future<bool> _confirmarMigracao(BuildContext context, EstadoApp e, Tarefa t) async {
    if (!e.deveAvisarMigracao(t)) return true;
    final resposta = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = ctx.cores;
        return AlertDialog(
          backgroundColor: c.cartao,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: c.linha, width: 2.5)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Gatinha(humor: Humor.curiosa, tamanho: 90),
            const SizedBox(height: 10),
            Text(
              'Hmm… “${t.texto}” já pulou de dia ${t.migracoes} vezes. Ainda vale a pena?',
              textAlign: TextAlign.center,
              style: titulo(ctx, 17),
            ),
            const SizedBox(height: 16),
            BotaoFofo('Migrar mesmo assim', largo: true, onPressed: () => Navigator.pop(ctx, 'migrar')),
            const SizedBox(height: 10),
            BotaoFofo('Cancelar a tarefa', largo: true, estilo: EstiloBotao.fantasma, onPressed: () => Navigator.pop(ctx, 'cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Voltar', style: corpo(ctx))),
          ]),
        );
      },
    );
    if (resposta == 'cancelar') e.cancelarTarefa(t);
    return resposta == 'migrar';
  }

  static Future<void> _migrar(BuildContext context, EstadoApp e, Tarefa t, {DateTime? destino}) async {
    if (!await _confirmarMigracao(context, e, t)) return;
    if (!context.mounted) return;
    destino ??= await showDatePicker(
      context: context,
      initialDate: e.hoje.add(const Duration(days: 1)),
      firstDate: e.hoje, // RN12
      lastDate: e.hoje.add(const Duration(days: 365)),
      helpText: 'Pra quando?',
    );
    if (destino == null) return;
    e.migrar(t, destino);
    e.reagir(Humor.comemorando, destino == e.hoje ? 'Foi pra hoje! >' : 'Agendada pra ${DateFormat('d/M').format(destino)}! >');
  }

  static Future<void> _todasPraHoje(BuildContext context, EstadoApp e) async {
    final lista = List<Tarefa>.from(e.pendencias);
    for (final t in lista.where((t) => !e.deveAvisarMigracao(t))) {
      e.migrar(t, e.hoje);
    }
    for (final t in lista.where(e.deveAvisarMigracao)) {
      if (!context.mounted) return;
      await _migrar(context, e, t, destino: e.hoje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final pend = e.pendencias;
    final dias = <String>[];
    for (final t in pend) {
      if (!dias.contains(t.data)) dias.add(t.data);
    }

    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            const Topo('Pendências'),
            if (pend.isEmpty)
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    GestureDetector(onTap: e.fazerCarinho, child: const Gatinha(humor: Humor.comemorando, tamanho: 160)),
                    const SizedBox(height: 14),
                    Text('Tudo em dia!', style: titulo(context, 28)),
                    const SizedBox(height: 6),
                    Text('Nenhuma pendência por aqui. Pode relaxar ♡', style: corpo(context, cor: c.textoSuave)),
                    const SizedBox(height: 18),
                    BotaoFofo('Voltar para hoje', onPressed: () => Navigator.pop(context)),
                  ]),
                ),
              )
            else ...[
              GatinhaFalando(
                humor: e.humorDoMomento ?? Humor.preocupada,
                fala: e.falaDoMomento ??
                    (pend.length == 1 ? 'Só falta 1! Bora resolver?' : '${pend.length} coisinhas ficaram pra trás… bora resolver?'),
                tamanho: 76,
                onTap: e.fazerCarinho,
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
                  BotaoFofo('Mover todas para hoje', estilo: EstiloBotao.fantasma, onPressed: () => _todasPraHoje(context, e)),
                  const SizedBox(height: 16),
                  for (final d in dias) ...[
                    TituloSecao(DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(dataDe(d))),
                    for (final t in pend.where((t) => t.data == d)) ...[
                      _cartaoPendencia(context, e, t),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ],
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _cartaoPendencia(BuildContext context, EstadoApp e, Tarefa t) {
    final c = context.cores;
    return Cartao(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('• ${t.texto}', style: corpo(context)),
        if (t.migracoes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: c.segundaSuave, borderRadius: BorderRadius.circular(999)),
              child: Text('> migrada ${t.migracoes}×', style: corpo(context, tamanho: 12)),
            ),
          ),
        const SizedBox(height: 10),
        Row(children: [
          ChipFofo('Pra hoje', selecionado: true, onTap: () => _migrar(context, e, t, destino: e.hoje)),
          const SizedBox(width: 8),
          ChipFofo('Outro dia', onTap: () => _migrar(context, e, t)),
          const Spacer(),
          BotaoIcone(Icons.check_rounded, rotulo: 'Concluir ${t.texto}', onTap: () => e.concluir(t)),
          const SizedBox(width: 8),
          BotaoIcone(Icons.close_rounded, rotulo: 'Cancelar ${t.texto}', onTap: () => e.cancelarTarefa(t)),
        ]),
      ]),
    );
  }
}
