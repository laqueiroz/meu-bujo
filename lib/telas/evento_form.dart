import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'tarefa_form.dart';

/// UC04: registrar (e editar/excluir) evento.
class TelaEvento extends StatefulWidget {
  final Evento? evento;
  final DateTime? dia;

  const TelaEvento({super.key, this.evento, this.dia});

  @override
  State<TelaEvento> createState() => _TelaEventoState();
}

class _TelaEventoState extends State<TelaEvento> {
  late final TextEditingController _titulo;
  late DateTime _data;
  TimeOfDay? _hora;
  int _aviso = 15;

  bool get _editando => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final ev = widget.evento;
    final hoje = soDia(DateTime.now());
    _titulo = TextEditingController(text: ev?.titulo ?? '');
    _data = ev != null ? dataDe(ev.data) : (widget.dia != null && !widget.dia!.isBefore(hoje) ? widget.dia! : hoje);
    _hora = ev?.hora != null ? horaDe(ev!.hora!) : const TimeOfDay(hour: 12, minute: 0);
    _aviso = ev?.avisoMin ?? 15;
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  void _salvar(EstadoApp e) {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      e.reagir(Humor.preocupada, 'Dá um nome pro evento!'); // UC04 E1
      return;
    }
    e.salvarEvento(Evento(
      id: widget.evento?.id,
      titulo: titulo,
      data: dataTexto(_data),
      hora: _hora == null ? null : horaTexto(_hora!),
      avisoMin: _aviso,
    ));
    e.reagir(Humor.comemorando, 'Evento anotado! ○');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final hoje = e.hoje;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            Topo(_editando ? '○ Editar evento' : '○ Evento'),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.feliz,
              fala: e.falaDoMomento ?? 'Compromisso novo? Eu te lembro!',
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                const Rotulo('Nome do evento'),
                TextField(controller: _titulo, textCapitalization: TextCapitalization.sentences, style: corpo(context, peso: FontWeight.w600)),
                const SizedBox(height: 18),
                const Rotulo('Dia'),
                EscolhaDia(
                  valor: _data,
                  primeiro: _editando && _data.isBefore(hoje) ? _data : hoje,
                  onChanged: (d) => setState(() => _data = d),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text('Tem horário?', style: corpo(context))),
                  Interruptor(
                    rotulo: 'Tem horário',
                    valor: _hora != null,
                    onChanged: (v) => setState(() => _hora = v ? const TimeOfDay(hour: 12, minute: 0) : null),
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
                if (_editando) ...[
                  const SizedBox(height: 24),
                  BotaoFofo('Excluir evento', estilo: EstiloBotao.fantasma, onPressed: () async {
                    final ev = widget.evento!;
                    final r = await confirmarExclusao(context, oQue: 'este evento', noGoogle: e.estaNoGoogle(ev)); // RN20
                    if (r == Exclusao.cancelar || !context.mounted) return;
                    e.excluirEvento(ev, tambemNoGoogle: r == Exclusao.aquiEnoGoogle);
                    Navigator.pop(context);
                  }),
                ],
              ]),
            ),
            RodapeBotao('Salvar', onPressed: () => _salvar(e)),
          ]),
        ),
      ),
    );
  }
}
