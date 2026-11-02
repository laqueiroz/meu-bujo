import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';
import 'agendas.dart';
import 'colecoes.dart';

/// Ajustes: cores (UC24), tema, horário do resumo, coleções, conta/backup (UC11, UC12) e Google Agenda (UC22, UC23).
class TelaAjustes extends StatefulWidget {
  const TelaAjustes({super.key});

  @override
  State<TelaAjustes> createState() => _TelaAjustesState();
}

class _TelaAjustesState extends State<TelaAjustes> {
  final _novaColecao = TextEditingController();

  @override
  void dispose() {
    _novaColecao.dispose();
    super.dispose();
  }

  Widget _cartaoConta(BuildContext context, EstadoApp e) {
    final c = context.cores;
    if (!e.logada) {
      return Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Seus dados estão só neste celular. Entre com o Google pra ter backup no seu Drive.',
              style: corpo(context, peso: FontWeight.w600)),
          const SizedBox(height: 12),
          e.sincronizando
              ? const Center(child: CircularProgressIndicator())
              : BotaoFofo('Entrar com Google', onPressed: () async {
                  final erro = await e.entrarComGoogle();
                  if (erro != null) e.reagir(Humor.preocupada, erro);
                }),
        ]),
      );
    }
    final quando = e.ultimoBackup == null ? 'ainda não' : DateFormat("d/M 'às' HH:mm").format(e.ultimoBackup!);
    return Cartao(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.destaque, shape: BoxShape.circle, border: Border.all(color: c.linha, width: 2.5)),
            child: Text((e.contaNome ?? e.contaEmail ?? '?').substring(0, 1).toUpperCase(),
                style: titulo(context, 20, cor: corTextoSobreDestaque)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.contaNome ?? 'Conta Google', style: corpo(context)),
              Text(e.contaEmail ?? '', style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(e.backupPendente ? Icons.cloud_upload_outlined : Icons.cloud_done_rounded, color: c.linha),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.backupPendente ? 'Backup pendente: sai quando a internet voltar.' : 'Backup em dia · $quando',
              style: corpo(context, peso: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        BotaoFofo('Fazer backup agora', onPressed: () async {
          final ok = await e.fazerBackup();
          e.reagir(ok ? Humor.comemorando : Humor.preocupada, ok ? 'Backup feito! ☁' : 'Não deu agora. Tento de novo depois.');
        }),
        const SizedBox(height: 10),
        BotaoFofo('Sair da conta', estilo: EstiloBotao.fantasma, onPressed: e.sairDaConta),
      ]),
    );
  }

  /// UC22 e UC23: ligar o Google Agenda e ver como está a sincronização.
  Widget _cartaoAgenda(BuildContext context, EstadoApp e) {
    final c = context.cores;
    Future<void> conectar() async {
      final erro = await e.conectarAgenda();
      if (erro != null) {
        e.reagir(Humor.preocupada, erro);
      } else if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TelaAgendas()));
      }
    }

    if (!e.agendaConectada || e.agendaPrecisaAutorizar) {
      return Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            e.agendaPrecisaAutorizar
                ? 'O Google parou de deixar o app ver a agenda. Autorize de novo pra voltar a sincronizar.'
                : 'Traga suas agendas do Google pra cá. O que você anotar aqui também vai pra lá.',
            style: corpo(context, peso: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          BotaoFofo(e.agendaPrecisaAutorizar ? 'Autorizar de novo' : 'Conectar Google Agenda', onPressed: conectar),
        ]),
      );
    }
    final marcadas = e.agendasMarcadas;
    final destino = e.agendas.where((a) => a.id == e.agendaDestino).firstOrNull;
    final quando = e.ultimaSincAgenda == null ? 'ainda não' : DateFormat("d/M 'às' HH:mm").format(e.ultimaSincAgenda!);
    return Cartao(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          marcadas.isEmpty ? 'Nenhuma agenda marcada: nada sincroniza.' : marcadas.map((a) => a.nome).join(' · '),
          style: corpo(context),
        ),
        if (destino != null) Text('Novos itens vão para: ${destino.nome}', style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave)),
        const SizedBox(height: 10),
        Row(children: [
          e.sincronizandoAgenda
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.linha))
              : Icon(Icons.event_available_rounded, color: c.linha),
          const SizedBox(width: 8),
          Expanded(child: Text(e.sincronizandoAgenda ? 'Sincronizando…' : 'Última sincronização · $quando', style: corpo(context, peso: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        BotaoFofo('Escolher agendas', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TelaAgendas()))),
        const SizedBox(height: 10),
        BotaoFofo('Sincronizar agora', estilo: EstiloBotao.fantasma, onPressed: () async {
          final ok = await e.sincronizarAgenda();
          e.reagir(ok ? Humor.comemorando : Humor.preocupada, ok ? 'Agenda em dia! 📅' : 'Não deu agora. Tento de novo depois.');
        }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    final escuro = e.tema == ThemeMode.dark;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Column(children: [
            const Topo('Ajustes'),
            GatinhaFalando(
              humor: e.humorDoMomento ?? (escuro ? Humor.sonolenta : Humor.feliz),
              fala: e.falaDoMomento ?? (escuro ? 'Modo noturno… zzz' : 'Deixa tudo do seu jeitinho!'),
              tamanho: 62,
              onTap: e.fazerCarinho,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
                const TituloSecao('cores do app'),
                Cartao(
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final p in paletas)
                      Semantics(
                        button: true,
                        selected: p.id == e.paletaId,
                        label: 'Paleta ${p.nome}',
                        child: GestureDetector(
                          onTap: () => e.escolherPaleta(p.id),
                          child: Column(children: [
                            Container(
                              width: 46,
                              height: 46,
                              padding: EdgeInsets.all(p.id == e.paletaId ? 3 : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: p.id == e.paletaId ? Border.all(color: c.linha, width: 3) : null,
                              ),
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.linha, width: 2.5)),
                                child: Row(children: [
                                  Expanded(child: Container(color: p.destaque)),
                                  Expanded(child: Container(color: p.segunda)),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(p.nome, style: corpo(context, tamanho: 12)),
                          ]),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 18),
                const TituloSecao('aparência'),
                Cartao(
                  child: EscolhaUnica<ThemeMode>(
                    opcoes: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                    valor: e.tema,
                    rotulo: (m) => switch (m) {
                      ThemeMode.system => 'Seguir o celular',
                      ThemeMode.light => 'Claro',
                      ThemeMode.dark => 'Escuro',
                    },
                    onChanged: e.escolherTema,
                  ),
                ),
                const SizedBox(height: 18),
                const TituloSecao('resumo do dia'),
                Cartao(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Um aviso por dia com o que tem hoje e o que ficou pendente.', style: corpo(context, peso: FontWeight.w600)),
                    const SizedBox(height: 10),
                    EscolhaUnica<int>(opcoes: const [6, 7, 8, 9], valor: e.resumoHora, rotulo: (h) => '${h}h', onChanged: e.escolherResumoHora),
                  ]),
                ),
                const SizedBox(height: 18),
                const TituloSecao('coleções'),
                Cartao(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final col in e.colecoes)
                        ChipFofo(col, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaColecao(nome: col)))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: _novaColecao, decoration: const InputDecoration(hintText: 'Nova coleção'))),
                      const SizedBox(width: 8),
                      BotaoIcone(Icons.add_rounded, rotulo: 'Adicionar coleção', onTap: () {
                        final erro = e.adicionarColecao(_novaColecao.text);
                        if (erro != null) return e.reagir(Humor.curiosa, erro);
                        _novaColecao.clear();
                      }),
                    ]),
                    const SizedBox(height: 10),
                    BotaoFofo('Ver coleções', estilo: EstiloBotao.fantasma, largo: true,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TelaColecoes()))),
                  ]),
                ),
                const SizedBox(height: 18),
                const TituloSecao('conta e backup'),
                _cartaoConta(context, e),
                if (e.logada) ...[
                  const SizedBox(height: 18),
                  const TituloSecao('google agenda'),
                  _cartaoAgenda(context, e),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
