import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../dados/modelos.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'estatisticas.dart';
import 'evento_form.dart';
import 'reflexao.dart';
import 'tarefa_form.dart';

/// UC13 (planejar semana/mês) e UC18 (calendário do mês). Semana começa na segunda (RN27).
class TelaSemana extends StatefulWidget {
  const TelaSemana({super.key});

  @override
  State<TelaSemana> createState() => _TelaSemanaState();
}

class _TelaSemanaState extends State<TelaSemana> {
  bool _mes = false;
  late DateTime _semana = inicioDaSemana(DateTime.now());
  late DateTime _mesAtual = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _diaSel = soDia(DateTime.now());
  int? _aberto = DateTime.now().weekday - 1;
  final _rascunhos = <int, TextEditingController>{};
  final _foco = TextEditingController();
  final _novaMeta = TextEditingController();
  String? _focoDe;

  @override
  void dispose() {
    for (final c in _rascunhos.values) {
      c.dispose();
    }
    _foco.dispose();
    _novaMeta.dispose();
    super.dispose();
  }

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  void _moverSemana(int n) => setState(() {
        _semana = DateTime(_semana.year, _semana.month, _semana.day + 7 * n);
        _aberto = null;
      });

  void _moverMes(int n) => setState(() => _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + n));

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final fim = _semana.add(const Duration(days: 6));
    final cabecalho = _mes ? toBeginningOfSentenceCase(DateFormat.MMMM('pt_BR').format(_mesAtual)) : 'Semana';
    final sub = _mes
        ? '${_mesAtual.year}'
        : '${DateFormat("d MMM", 'pt_BR').format(_semana)} – ${DateFormat("d MMM", 'pt_BR').format(fim)}';
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                BotaoIcone(Icons.chevron_left_rounded, rotulo: _mes ? 'Mês anterior' : 'Semana anterior', onTap: () => _mes ? _moverMes(-1) : _moverSemana(-1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cabecalho, style: titulo(context, 26)),
                    Text(sub, style: corpo(context, cor: context.cores.textoSuave)),
                  ]),
                ),
                BotaoIcone(Icons.chevron_right_rounded, rotulo: _mes ? 'Próximo mês' : 'Próxima semana', onTap: () => _mes ? _moverMes(1) : _moverSemana(1)),
                const SizedBox(width: 6),
                BotaoIcone(Icons.bar_chart_rounded, rotulo: 'Ver números', onTap: () => _abrir(TelaEstatisticas(mes: _mes, dia: _mes ? _mesAtual : _semana))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _Alternador(mes: _mes, onChanged: (m) => setState(() => _mes = m)),
            ),
            GatinhaFalando(
              humor: e.humorDoMomento ?? Humor.feliz,
              fala: e.falaDoMomento ?? (_mes ? _falaMes(e) : _falaSemana(e)),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(child: _mes ? _corpoMes(context, e) : _corpoSemana(context, e)),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- semana

  String _falaSemana(EstadoApp e) {
    var abertas = 0;
    for (var i = 0; i < 7; i++) {
      abertas += e.tarefasDoDia(dataTexto(_semana.add(Duration(days: i)))).where((t) => t.aberta).length;
    }
    return abertas == 0 ? 'Semana tranquila por enquanto ♡' : 'Essa semana tem $abertas ${abertas == 1 ? 'tarefinha' : 'tarefinhas'}. Bora?';
  }

  Widget _corpoSemana(BuildContext context, EstadoApp e) {
    final c = context.cores;
    final chave = dataTexto(_semana);
    if (_focoDe != chave) {
      _focoDe = chave;
      _foco.text = e.focoDaSemana(_semana);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
      Cartao(
        cor: c.segundaSuave,
        sombra: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('foco da semana ♡', style: titulo(context, 15)),
          const SizedBox(height: 6),
          TextField(
            controller: _foco,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'O que importa essa semana?'),
            onSubmitted: (t) => e.definirFoco(_semana, t),
            onTapOutside: (_) {
              if (_foco.text.trim() != e.focoDaSemana(_semana)) e.definirFoco(_semana, _foco.text);
              FocusScope.of(context).unfocus();
            },
          ),
        ]),
      ),
      const SizedBox(height: 14),
      for (var i = 0; i < 7; i++) ...[_dia(context, e, i), const SizedBox(height: 12)],
    ]);
  }

  Widget _dia(BuildContext context, EstadoApp e, int i) {
    final c = context.cores;
    final dia = _semana.add(Duration(days: i));
    final d = dataTexto(dia);
    final ehHoje = dia == e.hoje;
    final tarefas = e.tarefasDoDia(d);
    final eventos = e.eventosDoDia(d);
    final abertas = tarefas.where((t) => t.aberta).length;
    final partes = [
      if (eventos.isNotEmpty) '${eventos.length} ${eventos.length == 1 ? 'evento' : 'eventos'}',
      if (tarefas.isNotEmpty) '$abertas de ${tarefas.length} ${tarefas.length == 1 ? 'tarefa' : 'tarefas'}',
    ];
    final aberto = _aberto == i;
    final rascunho = _rascunhos.putIfAbsent(i, TextEditingController.new);
    return Container(
      decoration: BoxDecoration(
        color: ehHoje ? c.destaqueSuave : c.cartao,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.linha, width: 2.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: aberto,
          child: InkWell(
            onTap: () => setState(() => _aberto = aberto ? null : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.cartao, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.linha, width: 2)),
                  child: Text('${dia.day}', style: titulo(context, 17)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat.EEEE('pt_BR').format(dia), style: titulo(context, 16)),
                    Text(partes.isEmpty ? 'dia livre' : partes.join(' · '), style: corpo(context, tamanho: 13, cor: c.textoSuave)),
                  ]),
                ),
                if (ehHoje)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: c.segundaSuave, borderRadius: BorderRadius.circular(999)),
                    child: Text('hoje', style: corpo(context, tamanho: 12)),
                  ),
                AnimatedRotation(turns: aberto ? 0.5 : 0, duration: const Duration(milliseconds: 180), child: Icon(Icons.expand_more_rounded, color: c.texto)),
              ]),
            ),
          ),
        ),
        if (aberto)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (tarefas.isEmpty && eventos.isEmpty)
                Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: Text('Dia livre ♡', style: corpo(context, cor: c.textoSuave))),
              for (final ev in eventos)
                _LinhaItem(marca: '○', texto: ev.titulo, hora: ev.hora, onAbrir: () => _abrir(TelaEvento(evento: ev)), onMarca: () => e.reagir(Humor.curiosa, 'Evento é só pra lembrar, não precisa marcar!')),
              for (final t in tarefas)
                _LinhaItem(
                  marca: switch (t.status) { StatusTarefa.aberta => '•', StatusTarefa.feita => '×', StatusTarefa.cancelada => '✕' },
                  texto: t.texto,
                  hora: t.hora,
                  riscado: !t.aberta,
                  check: t.status != StatusTarefa.cancelada,
                  onAbrir: () => _abrir(TelaTarefa(tarefa: t)),
                  onMarca: () => t.aberta ? e.concluir(t) : e.reabrir(t),
                ),
              const SizedBox(height: 6),
              Row(children: [
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: rascunho,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: '+ tarefa pra ${DateFormat.E('pt_BR').format(dia).replaceAll('.', '')}'),
                    onSubmitted: (t) {
                      e.adicionarTarefaRapida(t, dia);
                      rascunho.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                BotaoIcone(Icons.add_rounded, rotulo: 'Adicionar tarefa', onTap: () {
                  e.adicionarTarefaRapida(rascunho.text, dia);
                  rascunho.clear();
                }),
              ]),
            ]),
          ),
      ]),
    );
  }

  // ---------------------------------------------------------------- mês

  String _falaMes(EstadoApp e) {
    final m = e.metasDoMes(_mesAtual);
    if (m.isEmpty) return 'Toca num dia pra ver o que tem ♡';
    return '${m.where((x) => x.feita).length} de ${m.length} metas do mês feitas.';
  }

  Widget _corpoMes(BuildContext context, EstadoApp e) {
    final c = context.cores;
    final primeiro = DateTime(_mesAtual.year, _mesAtual.month);
    final diasNoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final vazios = primeiro.weekday - 1;
    final d = dataTexto(_diaSel);
    final eventos = e.eventosDoDia(d);
    final tarefas = e.tarefasDoDia(d);
    final metas = e.metasDoMes(_mesAtual);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
      Cartao(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(children: [
          Row(children: [
            for (final n in const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'])
              Expanded(child: Text(n, textAlign: TextAlign.center, style: corpo(context, tamanho: 12, cor: c.textoSuave))),
          ]),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              for (var i = 0; i < vazios; i++) const SizedBox(),
              for (var n = 1; n <= diasNoMes; n++) _celula(context, e, DateTime(_mesAtual.year, _mesAtual.month, n)),
            ],
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Ponto(vazio: true, cor: c.linha),
            const SizedBox(width: 5),
            Text('evento', style: corpo(context, tamanho: 12, cor: c.textoSuave)),
            const SizedBox(width: 14),
            _Ponto(vazio: false, cor: c.linha),
            const SizedBox(width: 5),
            Text('tarefa', style: corpo(context, tamanho: 12, cor: c.textoSuave)),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      TituloSecao('${_diaSel == e.hoje ? 'hoje, ' : ''}${DateFormat("EEEE, d MMM", 'pt_BR').format(_diaSel)}'),
      Cartao(
        padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
        child: eventos.isEmpty && tarefas.isEmpty
            ? Padding(padding: const EdgeInsets.all(12), child: Text('Nada marcado. Dia tranquilo ♡', style: corpo(context, cor: c.textoSuave)))
            : Column(children: [
                for (final ev in eventos) _LinhaItem(marca: '○', texto: ev.titulo, hora: ev.hora, onAbrir: () => _abrir(TelaEvento(evento: ev))),
                for (final t in tarefas)
                  _LinhaItem(
                    marca: switch (t.status) { StatusTarefa.aberta => '•', StatusTarefa.feita => '×', StatusTarefa.cancelada => '✕' },
                    texto: t.texto,
                    hora: t.hora,
                    riscado: !t.aberta,
                    check: t.status != StatusTarefa.cancelada,
                    onAbrir: () => _abrir(TelaTarefa(tarefa: t)),
                    onMarca: () => t.aberta ? e.concluir(t) : e.reabrir(t),
                  ),
              ]),
      ),
      const SizedBox(height: 18),
      TituloSecao('metas de ${DateFormat.MMMM('pt_BR').format(_mesAtual)}'),
      Cartao(
        padding: const EdgeInsets.fromLTRB(4, 4, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final m in metas)
            Row(children: [
              CaixaCheck(feita: m.feita, rotulo: m.texto, onTap: () => e.alternarMeta(m)),
              Expanded(
                child: GestureDetector(
                  onLongPress: () => e.excluirMeta(_mesAtual, m),
                  child: Text(m.texto,
                      style: corpo(context, cor: m.feita ? c.textoSuave : c.texto).copyWith(decoration: m.feita ? TextDecoration.lineThrough : null)),
                ),
              ),
            ]),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _novaMeta,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Nova meta do mês'),
                  onSubmitted: (t) {
                    e.adicionarMeta(_mesAtual, t);
                    _novaMeta.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              BotaoIcone(Icons.add_rounded, rotulo: 'Adicionar meta', onTap: () {
                e.adicionarMeta(_mesAtual, _novaMeta.text);
                _novaMeta.clear();
              }),
            ]),
          ),
          if (metas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8),
              child: Text('Segure uma meta pra apagar.', style: corpo(context, tamanho: 12, peso: FontWeight.w600, cor: c.textoSuave)),
            ),
        ]),
      ),
      const SizedBox(height: 18),
      // UC21: a reflexão do mês fica guardada aqui
      Cartao(
        cor: c.segundaSuave,
        onTap: () => _abrir(TelaReflexao(mes: _mesAtual)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('reflexão de ${DateFormat.MMMM('pt_BR').format(_mesAtual)}', style: titulo(context, 16)),
              Text(
                e.reflexoes.containsKey(mesTexto(_mesAtual)) ? 'Guardada ♡ Toque pra reler ou mudar.' : 'Como foi o mês? O que fica pro próximo?',
                style: corpo(context, tamanho: 13, cor: c.textoSuave),
              ),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.texto),
        ]),
      ),
    ]);
  }

  Widget _celula(BuildContext context, EstadoApp e, DateTime dia) {
    final c = context.cores;
    final d = dataTexto(dia);
    final temEvento = e.eventosDoDia(d).isNotEmpty;
    final temTarefa = e.tarefasDoDia(d).isNotEmpty;
    final sel = dia == _diaSel;
    final ehHoje = dia == e.hoje;
    return Semantics(
      button: true,
      selected: sel,
      label: DateFormat("d 'de' MMMM", 'pt_BR').format(dia),
      child: GestureDetector(
        onTap: () => setState(() => _diaSel = dia),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: sel ? c.destaque : null,
            borderRadius: BorderRadius.circular(12),
            border: ehHoje ? Border.all(color: c.linha, width: 2) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${dia.day}', style: corpo(context, tamanho: 14, cor: sel ? corTextoSobreDestaque : c.texto)),
            const SizedBox(height: 2),
            SizedBox(
              height: 6,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (temEvento) _Ponto(vazio: true, cor: sel ? corTextoSobreDestaque : c.linha),
                if (temEvento && temTarefa) const SizedBox(width: 2),
                if (temTarefa) _Ponto(vazio: false, cor: sel ? corTextoSobreDestaque : c.linha),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Alternador extends StatelessWidget {
  final bool mes;
  final ValueChanged<bool> onChanged;
  const _Alternador({required this.mes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    Widget opcao(String texto, bool valor) => Expanded(
          child: Semantics(
            button: true,
            selected: mes == valor,
            child: GestureDetector(
              onTap: () => onChanged(valor),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                color: mes == valor ? c.destaque : c.cartao,
                child: Text(texto, style: titulo(context, 14, cor: mes == valor ? corTextoSobreDestaque : c.texto)),
              ),
            ),
          ),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: c.linha, width: 2.5)),
      child: Row(children: [opcao('Semana', false), opcao('Mês', true)]),
    );
  }
}

class _Ponto extends StatelessWidget {
  final bool vazio;
  final Color cor;
  const _Ponto({required this.vazio, required this.cor});

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vazio ? null : cor,
          border: vazio ? Border.all(color: cor, width: 1.5) : null,
        ),
      );
}

/// Uma linha de tarefa ou evento, com o marcador do bullet journal.
class _LinhaItem extends StatelessWidget {
  final String marca;
  final String texto;
  final String? hora;
  final bool riscado;
  final bool check;
  final VoidCallback? onMarca;
  final VoidCallback onAbrir;

  const _LinhaItem({required this.marca, required this.texto, this.hora, this.riscado = false, this.check = false, this.onMarca, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(children: [
        Semantics(
          button: onMarca != null,
          label: riscado ? 'Reabrir $texto' : 'Concluir $texto',
          child: GestureDetector(
            onTap: onMarca,
            child: SizedBox(width: 40, height: 44, child: Center(child: Text(marca, style: titulo(context, 20)))),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAbrir,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                texto,
                style: corpo(context, cor: riscado ? c.textoSuave : c.texto).copyWith(decoration: riscado ? TextDecoration.lineThrough : null),
              ),
            ),
          ),
        ),
        if (hora != null) Text(hora!, style: corpo(context, tamanho: 13, cor: c.textoSuave)),
        if (check && onMarca != null) CaixaCheck(feita: riscado, rotulo: texto, onTap: onMarca!),
      ]),
    );
  }
}
