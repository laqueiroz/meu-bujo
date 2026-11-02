import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

String horaTexto(TimeOfDay h) => '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

TimeOfDay horaDe(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

/// Escolha de dia em chips: Hoje / Amanhã / outra data.
class EscolhaDia extends StatelessWidget {
  final DateTime valor;
  final DateTime primeiro;
  final ValueChanged<DateTime> onChanged;

  const EscolhaDia({super.key, required this.valor, required this.primeiro, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hoje = soDia(DateTime.now());
    final amanha = hoje.add(const Duration(days: 1));
    final outro = valor != hoje && valor != amanha;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      ChipFofo('Hoje', selecionado: valor == hoje, onTap: () => onChanged(hoje)),
      ChipFofo('Amanhã', selecionado: valor == amanha, onTap: () => onChanged(amanha)),
      ChipFofo(
        outro ? DateFormat("EEE, d 'de' MMM", 'pt_BR').format(valor) : 'Escolher data…',
        selecionado: outro,
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: valor.isBefore(primeiro) ? primeiro : valor,
            firstDate: primeiro,
            lastDate: hoje.add(const Duration(days: 730)),
          );
          if (d != null) onChanged(soDia(d));
        },
      ),
    ]);
  }
}

/// UC01 (registrar) e UC03 (editar, cancelar, excluir).
class TelaTarefa extends StatefulWidget {
  final Tarefa? tarefa;
  final DateTime? dia;

  const TelaTarefa({super.key, this.tarefa, this.dia});

  @override
  State<TelaTarefa> createState() => _TelaTarefaState();
}

class _TelaTarefaState extends State<TelaTarefa> {
  late final TextEditingController _texto;
  final _novaSub = TextEditingController();
  late DateTime _data;
  TimeOfDay? _hora;
  int _aviso = 0;
  bool _prio = false;
  String? _colecao;
  late List<Subtarefa> _subs;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    final hoje = soDia(DateTime.now());
    _texto = TextEditingController(text: t?.texto ?? '');
    _data = t != null ? dataDe(t.data) : (widget.dia != null && !widget.dia!.isBefore(hoje) ? widget.dia! : hoje);
    _hora = t?.hora != null ? horaDe(t!.hora!) : null;
    _aviso = t?.avisoMin ?? 0;
    _prio = t?.prioridade ?? false;
    _colecao = t?.colecao;
    _subs = [for (final s in t?.subtarefas ?? <Subtarefa>[]) Subtarefa(s.texto, feita: s.feita)];
  }

  @override
  void dispose() {
    _texto.dispose();
    _novaSub.dispose();
    super.dispose();
  }

  void _salvar(EstadoApp e) {
    final texto = _texto.text.trim();
    if (texto.isEmpty) {
      e.reagir(Humor.preocupada, 'Escreve o que é a tarefa primeiro!'); // UC01 E1
      return;
    }
    final antiga = widget.tarefa;
    e.salvarTarefa(Tarefa(
      id: antiga?.id,
      texto: texto,
      data: dataTexto(_data),
      hora: _hora == null ? null : horaTexto(_hora!),
      avisoMin: _aviso,
      prioridade: _prio,
      colecao: _colecao,
      subtarefas: _subs,
      status: antiga?.status ?? StatusTarefa.aberta,
      migradaDe: antiga?.migradaDe,
    ));
    e.reagir(Humor.comemorando, _editando ? 'Tarefa atualizada!' : 'Anotado! ✓');
    Navigator.pop(context);
  }

  Future<void> _excluir(EstadoApp e) async {
    final t = widget.tarefa!;
    final r = await confirmarExclusao(context, oQue: 'esta tarefa', noGoogle: e.estaNoGoogle(t)); // RN05, RN20
    if (r == Exclusao.cancelar || !mounted) return;
    e.excluirTarefa(t, tambemNoGoogle: r == Exclusao.aquiEnoGoogle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final hoje = e.hoje;
    final primeiroDia = _editando && _data.isBefore(hoje) ? _data : hoje;

    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo(
              _editando ? '• Editar' : '• Tarefa',
              acao: BotaoIcone(
                _prio ? Icons.star_rounded : Icons.star_outline_rounded,
                rotulo: _prio ? 'Tirar prioridade' : 'Marcar como prioridade',
                fundo: _prio ? c.destaqueSuave : null,
                onTap: () {
                  setState(() => _prio = !_prio);
                  e.reagir(_prio ? Humor.comemorando : Humor.feliz, _prio ? 'Importante! Vai pro topo ★' : 'Ok, sem estrela.');
                },
              ),
            ),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.curiosa,
              fala: e.falaDoMomento ?? (_editando ? 'Mudando alguma coisa?' : 'O que vamos anotar?'),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                const Rotulo('O que precisa fazer?'),
                TextField(controller: _texto, textCapitalization: TextCapitalization.sentences, style: corpo(context, peso: FontWeight.w600)),
                const SizedBox(height: 18),
                const Rotulo('Quando'),
                EscolhaDia(valor: _data, primeiro: primeiroDia, onChanged: (d) => setState(() => _data = d)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text('Tem horário?', style: corpo(context))),
                  Interruptor(
                    rotulo: 'Tem horário',
                    valor: _hora != null,
                    onChanged: (v) => setState(() => _hora = v ? const TimeOfDay(hour: 9, minute: 0) : null),
                  ),
                ]),
                if (_hora != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    ChipFofo('às ${horaTexto(_hora!)}', selecionado: true, onTap: () async {
                      final h = await showTimePicker(context: context, initialTime: _hora!);
                      if (h != null) setState(() => _hora = h);
                    }),
                  ]),
                  const SizedBox(height: 12),
                  const Rotulo('Me avisar'),
                  EscolhaUnica<int>(
                    opcoes: avisosMinutos,
                    valor: _aviso,
                    rotulo: nomeAviso,
                    onChanged: (v) {
                      setState(() => _aviso = v);
                      e.reagir(Humor.feliz, v == 0 ? 'Te aviso na hora certinha!' : 'Te aviso ${nomeAviso(v)}!');
                    },
                  ),
                ],
                const SizedBox(height: 18),
                const Rotulo('Coleção'),
                EscolhaUnica<String?>(
                  opcoes: [...e.colecoes, null],
                  valor: _colecao,
                  rotulo: (s) => s ?? 'Nenhuma',
                  onChanged: (v) => setState(() => _colecao = v),
                ),
                const SizedBox(height: 18),
                const Rotulo('Subtarefas'),
                for (var i = 0; i < _subs.length; i++)
                  InkWell(
                    onTap: () => setState(() => _subs[i].feita = !_subs[i].feita),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(children: [
                        Icon(_subs[i].feita ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: c.linha),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_subs[i].texto, style: corpo(context, peso: FontWeight.w600))),
                        BotaoIcone(Icons.close_rounded, rotulo: 'Tirar ${_subs[i].texto}', onTap: () => setState(() => _subs.removeAt(i))),
                      ]),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _novaSub,
                      decoration: const InputDecoration(hintText: 'Adicionar subtarefa'),
                      onSubmitted: (_) => _addSub(e),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BotaoIcone(Icons.add_rounded, rotulo: 'Adicionar subtarefa', onTap: () => _addSub(e)),
                ]),
                if (_editando) ...[
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: BotaoFofo('✕ Cancelar tarefa', estilo: EstiloBotao.fantasma, onPressed: () {
                        e.cancelarTarefa(widget.tarefa!);
                        Navigator.pop(context);
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: BotaoFofo('Excluir', estilo: EstiloBotao.fantasma, onPressed: () => _excluir(e))),
                  ]),
                ],
              ]),
            ),
            RodapeBotao('Salvar', onPressed: () => _salvar(e)),
          ]),
        ),
      ),
    );
  }

  void _addSub(EstadoApp e) {
    final t = _novaSub.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _subs.add(Subtarefa(t));
      _novaSub.clear();
    });
    e.reagir(Humor.comemorando, 'Mais uma subtarefa anotada!');
  }
}
