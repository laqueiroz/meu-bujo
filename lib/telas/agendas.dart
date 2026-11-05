import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../dados/tarefas_google.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

/// UC22: escolher quais agendas do Google entram no app, como cada uma vira item e para onde vão os novos.
class TelaAgendas extends StatefulWidget {
  const TelaAgendas({super.key});

  @override
  State<TelaAgendas> createState() => _TelaAgendasState();
}

class _TelaAgendasState extends State<TelaAgendas> {
  late List<AgendaGoogle> _agendas;
  String? _destino;

  @override
  void initState() {
    super.initState();
    final e = context.read<EstadoApp>();
    // cópia pra editar à vontade e só valer ao salvar
    _agendas = e.agendas.map((a) => AgendaGoogle.fromJson(a.toJson())).toList();
    _destino = e.agendaDestino;
  }

  Color? _cor(String? hex) {
    if (hex == null || hex.length != 7) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  void _salvar(EstadoApp e) {
    final marcadas = _agendas.where((a) => a.marcada && !e.ehAgendaDeTarefas(a.id)).toList();
    final destino = marcadas.any((a) => a.id == _destino) ? _destino : (marcadas.isEmpty ? null : marcadas.first.id);
    e.salvarAgendas(_agendas, destino);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    // a "Bujo – Tarefas" não é escolha da usuária: fica sempre ligada e aparece à parte
    final escolhiveis = _agendas.where((a) => !e.ehAgendaDeTarefas(a.id)).toList();
    final marcadas = escolhiveis.where((a) => a.marcada).toList();
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo('Agendas', acao: BotaoIcone(Icons.refresh_rounded, rotulo: 'Buscar agendas de novo', onTap: () async {
              final erro = await e.atualizarListaAgendas();
              if (erro != null) {
                e.reagir(Humor.preocupada, erro);
                return;
              }
              setState(() {
                final escolhas = {for (final a in _agendas) a.id: a};
                _agendas = e.agendas.map((a) {
                  final copia = AgendaGoogle.fromJson(a.toJson());
                  final antes = escolhas[a.id];
                  if (antes != null) {
                    copia.marcada = antes.marcada;
                    copia.viraTarefa = antes.viraTarefa;
                  }
                  return copia;
                }).toList();
              });
            })),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.curiosa,
              fala: e.falaDoMomento ?? 'Quais agendas eu trago pra cá?',
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                const TituloSecao('agendas da sua conta'),
                if (e.agendaTarefasId != null) ...[
                  Cartao(
                    cor: c.destaqueSuave,
                    sombra: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(TaskSyncService.nomeAgenda, style: corpo(context)),
                      const SizedBox(height: 4),
                      Text('Suas tarefas vão pra essa agenda, como eventos de dia inteiro. Tarefa feita ganha "✓ " no título.',
                          style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                if (escolhiveis.isEmpty)
                  Cartao(child: Text('Nenhuma agenda encontrada. Toque em ↻ pra buscar de novo.', style: corpo(context, cor: c.textoSuave))),
                for (final a in escolhiveis) ...[
                  Cartao(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(color: _cor(a.cor) ?? c.destaque, shape: BoxShape.circle, border: Border.all(color: c.linha, width: 2)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a.nome, style: corpo(context))),
                        Interruptor(rotulo: 'Trazer ${a.nome}', valor: a.marcada, onChanged: (v) => setState(() => a.marcada = v)),
                      ]),
                      if (a.marcada) ...[
                        const SizedBox(height: 10),
                        EscolhaUnica<bool>(
                          opcoes: const [false, true],
                          valor: a.viraTarefa,
                          rotulo: (t) => t ? '•  vira tarefa' : '○  vira evento',
                          onChanged: (t) => setState(() => a.viraTarefa = t),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                if (marcadas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const TituloSecao('eventos que eu anotar no app vão para'),
                  Cartao(
                    child: EscolhaUnica<String>(
                      opcoes: [for (final a in marcadas) a.id],
                      valor: marcadas.any((a) => a.id == _destino) ? _destino : marcadas.first.id,
                      rotulo: (id) => marcadas.firstWhere((a) => a.id == id).nome,
                      onChanged: (id) => setState(() => _destino = id),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Desmarcar uma agenda tira os itens dela do app, mas não apaga nada no Google. Hábitos não vão pro Google.',
                  style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave),
                ),
              ]),
            ),
            RodapeBotao('Salvar', onPressed: () => _salvar(e)),
          ]),
        ),
      ),
    );
  }
}
