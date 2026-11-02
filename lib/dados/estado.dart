import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tema.dart';
import '../widgets/gatinha.dart';
import 'agenda.dart';
import 'widget_casa.dart';
import 'modelos.dart';
import 'notificacoes.dart';
import 'nuvem.dart';
import 'segundo_plano.dart';

/// Estado do app inteiro. Fica salvo no celular; com a conta Google, vai pro Drive e pra agenda.
class EstadoApp extends ChangeNotifier with WidgetsBindingObserver {
  static const _chave = 'meu_bujo_v1';

  List<Tarefa> tarefas = [];
  List<Evento> eventos = [];
  List<Habito> habitos = [];
  List<String> colecoes = ['Mestrado', 'Fatec', 'Casa'];

  // planejamento (UC13, UC14)
  List<ItemFuturo> futuro = [];

  /// Foco de cada semana (data da segunda-feira -> texto).
  Map<String, String> focos = {};

  /// Metas de cada mês ('aaaa-mm' -> lista).
  Map<String, List<Meta>> metas = {};

  /// Cor da etiqueta de cada coleção (nome -> '#RRGGBB'), UC19.
  Map<String, String> coresColecoes = {};

  /// Reflexão de cada mês ('aaaa-mm'), UC21.
  Map<String, Reflexao> reflexoes = {};

  String paletaId = 'pessego';
  ThemeMode tema = ThemeMode.light;
  int resumoHora = 7;
  bool comecou = false;

  // conta Google e backup (UC11, UC12)
  String? contaEmail;
  String? contaNome;
  DateTime? ultimoBackup;
  bool backupPendente = false;
  bool sincronizando = false;
  DateTime salvoEm = DateTime.fromMillisecondsSinceEpoch(0);
  final _nuvem = Nuvem.instancia;
  Timer? _timerBackup;

  bool get logada => contaEmail != null;

  // Google Calendar (UC22, UC23)
  List<AgendaGoogle> agendas = [];
  String? agendaDestino;
  bool agendaConectada = false;
  bool agendaPrecisaAutorizar = false;
  bool sincronizandoAgenda = false;
  DateTime? ultimaSincAgenda;

  /// Até quando cada agenda já foi lida (id da agenda -> momento).
  Map<String, DateTime> _lidaAte = {};

  /// Apagados no app que ainda precisam sair do Google (E1: esperam a internet).
  List<ExclusaoPendente> _apagarNoGoogle = [];

  /// Apagados no Google: a usuária decide se apaga aqui também (RN20).
  List<ExclusaoPendente> perguntasExclusao = [];

  final _agenda = Agenda.instancia;
  Timer? _timerAgenda;
  Timer? _timerPeriodico;

  List<AgendaGoogle> get agendasMarcadas => agendas.where((a) => a.marcada).toList();

  SharedPreferences? _prefs;
  final _avisos = Notificacoes.instancia;

  Paleta get paleta => paletaPorId(paletaId);
  DateTime get hoje => soDia(DateTime.now());
  String get hojeTexto => dataTexto(hoje);

  // ---------------------------------------------------------------- salvar / carregar

  Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
    final bruto = _prefs!.getString(_chave);
    if (bruto == null) {
      habitos = [
        Habito(nome: 'Beber água', tipo: TipoHabito.meta, meta: 2, unidade: 'L'),
        Habito(nome: 'Ler 20 min'),
      ];
      return;
    }
    final j = jsonDecode(bruto) as Map<String, dynamic>;
    _aplicar(j);
    comecou = j['comecou'] as bool? ?? false;
    contaEmail = j['contaEmail'] as String?;
    contaNome = j['contaNome'] as String?;
    ultimoBackup = DateTime.tryParse(j['ultimoBackup'] as String? ?? '');
    backupPendente = j['backupPendente'] as bool? ?? false;
    agendaConectada = j['agendaConectada'] as bool? ?? false;
    ultimaSincAgenda = DateTime.tryParse(j['ultimaSincAgenda'] as String? ?? '');
  }

  /// Os dados que vão pro backup na nuvem.
  Map<String, dynamic> _dados() => {
        'tarefas': tarefas.map((t) => t.toJson()).toList(),
        'eventos': eventos.map((e) => e.toJson()).toList(),
        'habitos': habitos.map((h) => h.toJson()).toList(),
        'colecoes': colecoes,
        'futuro': futuro.map((f) => f.toJson()).toList(),
        'focos': focos,
        'metas': metas.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
        'coresColecoes': coresColecoes,
        'reflexoes': reflexoes.map((k, v) => MapEntry(k, v.toJson())),
        'paleta': paletaId,
        'tema': tema.name,
        'resumoHora': resumoHora,
        'salvoEm': salvoEm.toIso8601String(),
        'agendas': agendas.map((a) => a.toJson()).toList(),
        'agendaDestino': agendaDestino,
        'lidaAte': _lidaAte.map((k, v) => MapEntry(k, v.toIso8601String())),
        'apagarNoGoogle': _apagarNoGoogle.map((x) => x.toJson()).toList(),
        'perguntasExclusao': perguntasExclusao.map((x) => x.toJson()).toList(),
      };

  void _aplicar(Map<String, dynamic> j) {
    List<Map<String, dynamic>> lista(String k) =>
        ((j[k] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    tarefas = lista('tarefas').map(Tarefa.fromJson).toList();
    eventos = lista('eventos').map(Evento.fromJson).toList();
    habitos = lista('habitos').map(Habito.fromJson).toList();
    colecoes = ((j['colecoes'] as List?) ?? colecoes).cast<String>();
    futuro = lista('futuro').map(ItemFuturo.fromJson).toList();
    focos = ((j['focos'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as String));
    metas = ((j['metas'] as Map?) ?? {}).map((k, v) => MapEntry(
          k as String,
          (v as List).map((m) => Meta.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
        ));
    coresColecoes = ((j['coresColecoes'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as String));
    reflexoes = ((j['reflexoes'] as Map?) ?? {})
        .map((k, v) => MapEntry(k as String, Reflexao.fromJson(Map<String, dynamic>.from(v as Map))));
    paletaId = j['paleta'] as String? ?? 'pessego';
    tema = ThemeMode.values.byName(j['tema'] as String? ?? 'light');
    resumoHora = j['resumoHora'] as int? ?? 7;
    salvoEm = DateTime.tryParse(j['salvoEm'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    agendas = lista('agendas').map(AgendaGoogle.fromJson).toList();
    agendaDestino = j['agendaDestino'] as String?;
    _lidaAte = ((j['lidaAte'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, DateTime.parse(v as String)));
    _apagarNoGoogle = lista('apagarNoGoogle').map(ExclusaoPendente.fromJson).toList();
    perguntasExclusao = lista('perguntasExclusao').map(ExclusaoPendente.fromJson).toList();
  }

  Future<void> _salvar() async {
    await _prefs?.setString(
      _chave,
      jsonEncode({
        ..._dados(),
        'comecou': comecou,
        'contaEmail': contaEmail,
        'contaNome': contaNome,
        'ultimoBackup': ultimoBackup?.toIso8601String(),
        'backupPendente': backupPendente,
        'agendaConectada': agendaConectada,
        'ultimaSincAgenda': ultimaSincAgenda?.toIso8601String(),
      }),
    );
  }

  void _mudou({bool agenda = false}) {
    salvoEm = DateTime.now();
    notifyListeners();
    _salvar();
    _agendarBackup();
    _agendarDiarios();
    if (agenda) _agendarSincAgenda();
  }

  // ---------------------------------------------------------------- resumo do dia (UC15) e lembrete de hábito (UC16)

  Timer? _timerDiarios;
  static const _diasAgendados = 7;

  void _agendarDiarios() {
    _timerDiarios?.cancel();
    _timerDiarios = Timer(const Duration(seconds: 2), () {
      reagendarDiarios();
      WidgetCasa.atualizar(this); // RN33
    });
  }

  /// RN32: no widget só dá pra somar água sem abrir o app. Tarefa se marca dentro do app.
  Future<void> toqueDoWidget(Uri? uri) async {
    if (uri?.host != 'agua') return;
    final d = hojeTexto;
    final h = WidgetCasa.habitoAgua(this);
    if (h == null) return;
    h.marcas[d] = (h.valorEm(d) + h.passo).clamp(0, h.meta * 2).toDouble();
    salvoEm = DateTime.now();
    if (logada) backupPendente = true;
    await _salvar();
  }

  /// O widget ou a sincronização em segundo plano podem ter mudado os dados: lê de novo do celular.
  Future<void> _lerDeNovoSeMudou({bool sincronizarDepois = true}) async {
    final p = _prefs;
    if (p == null) return;
    await p.reload();
    final bruto = p.getString(_chave);
    if (bruto == null) return;
    final j = jsonDecode(bruto) as Map<String, dynamic>;
    final em = DateTime.tryParse(j['salvoEm'] as String? ?? '');
    if (em == null || !em.isAfter(salvoEm)) return;
    _aplicar(j);
    backupPendente = j['backupPendente'] as bool? ?? backupPendente;
    for (final t in tarefas) {
      _avisos.agendarTarefa(t);
    }
    notifyListeners();
    if (backupPendente) _agendarBackup();
    if (agendaConectada && sincronizarDepois) _agendarSincAgenda();
  }

  /// Agenda os próximos 7 dias com o que se sabe agora. Roda de novo a cada mudança e ao abrir o app,
  /// então o texto do resumo fica sempre atualizado.
  Future<void> reagendarDiarios() async {
    for (var i = 0; i < _diasAgendados; i++) {
      final dia = hoje.add(Duration(days: i));
      final d = dataTexto(dia);
      await _avisos.agendarEm(
        id: 'resumo-$d',
        titulo: 'Bom dia! Seu dia no Meu Bujo ☀',
        texto: textoResumo(dia),
        quando: DateTime(dia.year, dia.month, dia.day, resumoHora),
      );
      for (final h in habitos) {
        final id = 'habito-${h.id}-$d';
        if (h.lembrete && !h.arquivado && h.agendadoEm(dia) && !h.feitoEm(d)) {
          final hm = h.lembreteHora.split(':');
          await _avisos.agendarEm(
            id: id,
            titulo: '${h.nome} ♡',
            texto: h.tipo == TipoHabito.meta
                ? 'Faltam ${formatarNumero((h.meta - h.valorEm(d)).clamp(0, h.meta).toDouble())} ${h.unidade} hoje. Bora?'
                : 'Ainda não marcado hoje. Bora?',
            quando: DateTime(dia.year, dia.month, dia.day, int.parse(hm[0]), int.parse(hm[1])),
          );
        } else {
          await _avisos.cancelar(id);
        }
      }
    }
  }

  /// RN26: o resumo diz o que tem no dia, o que ficou pendente e o que o future log guardou pro mês.
  String textoResumo(DateTime dia) {
    final d = dataTexto(dia);
    final abertas = tarefas.where((t) => t.data == d && t.aberta).length;
    final evs = eventos.where((e) => e.data == d).length;
    final pend = tarefas.where((t) => t.aberta && t.data.compareTo(d) < 0).length;
    final partes = <String>[
      if (evs > 0) '$evs ${evs == 1 ? 'evento' : 'eventos'}',
      if (abertas > 0) '$abertas ${abertas == 1 ? 'tarefa' : 'tarefas'}',
    ];
    var texto = partes.isEmpty ? 'Dia livre por enquanto ♡' : 'Hoje tem ${partes.join(' e ')}.';
    if (pend > 0) texto += ' $pend ${pend == 1 ? 'pendência' : 'pendências'} pra revisar.';
    if (dia.day == 1) {
      final fut = futuro.where((f) => f.mes == mesTexto(dia)).length;
      if (fut > 0) texto += ' O future log guardou $fut ${fut == 1 ? 'item' : 'itens'} pra este mês.';
    }
    return texto;
  }

  // ---------------------------------------------------------------- conta Google e backup (UC11, UC12)

  /// Ao abrir o app: volta pra conta sem perguntar e manda o backup que ficou pendente (RN15).
  Future<void> reconectar() async {
    if (!logada) return;
    final c = await _nuvem.entrarSemPerguntar();
    if (c != null && backupPendente) _agendarBackup(imediato: true);
    if (c != null && agendaConectada) {
      sincronizarAgenda();
      // UC23 passo 2: enquanto o app está aberto, olha a agenda de tempos em tempos
      _timerPeriodico ??= Timer.periodic(const Duration(minutes: 10), (_) => sincronizarAgenda());
    }
  }

  /// Ao voltar pro app, busca o que mudou no Google.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) return;
    _lerDeNovoSeMudou().whenComplete(() {
      _agendarDiarios(); // virou o dia? reagenda a semana seguinte
      if (agendaConectada) sincronizarAgenda();
    });
  }

  /// Devolve null se deu certo, ou a mensagem de erro pra mostrar.
  Future<String?> entrarComGoogle() async {
    try {
      final c = await _nuvem.entrar();
      contaEmail = c.email;
      contaNome = c.displayName;
      sincronizando = true;
      notifyListeners();

      // UC11 A1: se já existe backup (celular novo), recupera. Se os dois lados têm dados, vale o mais recente (RN19).
      final remoto = await _nuvem.baixar();
      if (remoto != null) {
        final j = jsonDecode(remoto) as Map<String, dynamic>;
        final remotoEm = DateTime.tryParse(j['salvoEm'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final celularVazio = tarefas.isEmpty && eventos.isEmpty;
        if (celularVazio || remotoEm.isAfter(salvoEm)) {
          _aplicar(j);
          for (final t in tarefas) {
            _avisos.agendarTarefa(t);
          }
          for (final e in eventos) {
            _avisos.agendarEvento(e);
          }
        }
      }
      comecou = true;
      sincronizando = false;
      await _salvar();
      notifyListeners();
      await fazerBackup();
      final nome = (contaNome ?? '').split(' ').first;
      reagir(Humor.comemorando, nome.isEmpty ? 'Tudo salvo na nuvem ♡' : 'Oi, $nome! Tudo salvo na nuvem ♡');
      return null;
    } on NuvemErro catch (e) {
      sincronizando = false;
      notifyListeners();
      return e.mensagem;
    }
  }

  /// UC11 A2: sai da conta; os dados continuam no celular.
  Future<void> sairDaConta() async {
    _timerBackup?.cancel();
    _timerAgenda?.cancel();
    _timerPeriodico?.cancel();
    _timerPeriodico = null;
    await _nuvem.sair();
    contaEmail = null;
    contaNome = null;
    ultimoBackup = null;
    backupPendente = false;
    agendaConectada = false;
    SegundoPlano.ajustar(ligado: false);
    agendaPrecisaAutorizar = false;
    await _salvar();
    notifyListeners();
    reagir(Humor.feliz, 'Saiu da conta. Os dados continuam aqui no celular.');
  }

  /// RN15: o backup sai sozinho alguns segundos depois de cada mudança.
  void _agendarBackup({bool imediato = false}) {
    if (!logada) return;
    backupPendente = true;
    _timerBackup?.cancel();
    _timerBackup = Timer(imediato ? Duration.zero : const Duration(seconds: 4), fazerBackup);
  }

  Future<bool> fazerBackup() async {
    if (!logada) return false;
    if (_nuvem.conta == null) await _nuvem.entrarSemPerguntar();
    // sem conta carregada (app fechado, RN25) o Drive ainda aceita a autorização já dada
    final ok = await _nuvem.enviar(jsonEncode(_dados()));
    if (ok) ultimoBackup = DateTime.now();
    backupPendente = !ok;
    await _salvar();
    notifyListeners();
    return ok;
  }

  // ---------------------------------------------------------------- Google Calendar (UC22, UC23)

  /// Pede acesso à agenda e traz a lista de agendas. Devolve null se deu certo, ou a mensagem de erro.
  Future<String?> conectarAgenda() async {
    if (!logada) return 'Entre com o Google primeiro.';
    if (_nuvem.conta == null) await _nuvem.entrarSemPerguntar();
    if (_nuvem.conta == null) return 'Não deu pra falar com o Google agora.';
    if (!await _agenda.autorizar()) return 'Sem acesso à agenda, a sincronização fica desligada.';
    agendaConectada = true;
    SegundoPlano.ajustar(ligado: true); // RN25
    agendaPrecisaAutorizar = false;
    return atualizarListaAgendas();
  }

  /// UC22 passo 1. Mantém o que a usuária já tinha escolhido em cada agenda.
  Future<String?> atualizarListaAgendas() async {
    try {
      final novas = await _agenda.listarAgendas(podePerguntar: true);
      for (final n in novas) {
        final antiga = agendas.where((a) => a.id == n.id).firstOrNull;
        if (antiga != null) {
          n.marcada = antiga.marcada;
          n.viraTarefa = antiga.viraTarefa;
        }
      }
      agendas = novas;
      if (!agendas.any((a) => a.id == agendaDestino)) agendaDestino = null;
      await _salvar();
      notifyListeners();
      return null;
    } on AgendaSemPermissao {
      agendaPrecisaAutorizar = true;
      notifyListeners();
      return 'O Google não deixou ler as agendas. Autorize de novo.';
    } catch (_) {
      return 'Não deu pra buscar as agendas. Confere a internet?';
    }
  }

  /// UC22 passos 2 a 5.
  void salvarAgendas(List<AgendaGoogle> escolhas, String? destino) {
    final antes = {for (final a in agendasMarcadas) a.id};
    final primeiraVez = agendaDestino == null && antes.isEmpty;
    agendas = escolhas;
    final agora = {for (final a in agendasMarcadas) a.id};
    agendaDestino = agora.contains(destino) ? destino : null;

    // A1: desmarcar tira os itens daquela agenda do app, sem apagar nada no Google
    for (final id in antes.difference(agora)) {
      _tirarItensDaAgenda(id);
      _lidaAte.remove(id);
    }
    // agenda nova: lê tudo da janela
    for (final id in agora.difference(antes)) {
      _lidaAte.remove(id);
    }
    // na primeira vez, o que já existe no app (de uma semana atrás pra frente) também vai pro Google (RN16)
    if (primeiraVez && agendaDestino != null) {
      final desde = dataTexto(hoje.subtract(const Duration(days: 7)));
      for (final s in <Sincronizavel>[...tarefas.where((t) => t.data.compareTo(desde) >= 0), ...eventos.where((e) => e.data.compareTo(desde) >= 0)]) {
        if (s.google == null && !s.soNoApp) s.sujo = true;
      }
    }
    _mudou();
    if (agora.isEmpty) {
      reagir(Humor.preocupada, 'Nenhuma agenda marcada: nada vai sincronizar.'); // E1
    } else {
      reagir(Humor.comemorando, 'Agendas salvas! Sincronizando…');
      sincronizarAgenda();
    }
  }

  void _tirarItensDaAgenda(String agendaId) {
    for (final t in tarefas.where((t) => t.google?.agenda == agendaId)) {
      _avisos.cancelar(t.id);
    }
    for (final e in eventos.where((e) => e.google?.agenda == agendaId)) {
      _avisos.cancelar(e.id);
    }
    tarefas.removeWhere((t) => t.google?.agenda == agendaId);
    eventos.removeWhere((e) => e.google?.agenda == agendaId);
    perguntasExclusao.removeWhere((p) => p.agenda == agendaId);
  }

  void _agendarSincAgenda() {
    if (!agendaConectada) return;
    _timerAgenda?.cancel();
    _timerAgenda = Timer(const Duration(seconds: 3), sincronizarAgenda);
  }

  /// UC23: apaga o que saiu do app, traz o que mudou no Google e manda o que mudou no app.
  /// Devolve false se não conseguiu (sem internet, sem permissão): fica na fila (E1).
  /// [semTela]: rodando com o app fechado (RN25); aí não dá pra pedir permissão, então falta de acesso não vira aviso.
  Future<bool> sincronizarAgenda({bool semTela = false}) async {
    if (!agendaConectada || sincronizandoAgenda) return false;
    // RN25: o app aberto e a sincronização em segundo plano têm cópias separadas dos dados.
    // Uma trava no celular garante que só uma sincroniza por vez, e cada uma lê antes o que a outra salvou;
    // sem isso, as duas criavam a mesma tarefa no Google.
    if (!await _pegarTrava()) {
      motivoSinc = 'outra sincronização em andamento';
      return false;
    }
    await _lerDeNovoSeMudou(sincronizarDepois: false);
    sincronizandoAgenda = true;
    notifyListeners();
    var ok = true;
    var mexeu = false;
    try {
      if (_nuvem.conta == null && !semTela) await _nuvem.entrarSemPerguntar();
      if (_nuvem.conta == null && !semTela) {
        motivoSinc = 'sem conta Google';
        return ok = false;
      }

      // 1. o que foi apagado no app sai do Google antes de ler (senão voltaria como item novo)
      for (final x in [..._apagarNoGoogle]) {
        await _agenda.apagar(x.agenda, x.googleId);
        _apagarNoGoogle.remove(x);
      }

      // 2. o que mudou no Google
      for (final a in agendasMarcadas) {
        final inicio = DateTime.now();
        try {
          final remotos = await _agenda.mudancas(a.id, desde: _lidaAte[a.id]);
          for (final r in remotos) {
            mexeu = _aplicarRemoto(r, a) || mexeu;
          }
          _lidaAte[a.id] = inicio;
        } on AgendaNaoEncontrada {
          // E3: a agenda foi apagada no Google
          agendas.removeWhere((x) => x.id == a.id);
          if (agendaDestino == a.id) agendaDestino = null;
          _tirarItensDaAgenda(a.id);
          _lidaAte.remove(a.id);
          mexeu = true;
          reagir(Humor.preocupada, 'A agenda "${a.nome}" sumiu do Google. Tirei ela da lista.');
        }
      }

      // 3. o que mudou no app
      for (final s in <Sincronizavel>[...tarefas, ...eventos]) {
        if (!s.sujo || s.soNoApp) continue;
        final item = s is Tarefa ? ItemParaGoogle.daTarefa(s) : ItemParaGoogle.doEvento(s as Evento);
        final l = s.google;
        if (l == null) {
          if (agendaDestino == null) continue; // sem destino, fica esperando (RN18)
          s.google = await _agenda.criar(agendaDestino!, item);
        } else if (agendas.any((a) => a.id == l.agenda && a.marcada)) {
          try {
            await _agenda.atualizar(l, item);
          } on AgendaNaoEncontrada {
            _perguntar(l, s, item.titulo); // apagado no Google enquanto mudava aqui
          }
        }
        s.sujo = false;
        mexeu = true;
      }
      ultimaSincAgenda = DateTime.now();
    } on AgendaSemPermissao {
      // E2: acesso revogado no Google
      if (!semTela) agendaPrecisaAutorizar = true;
      motivoSinc = 'sem permissão da agenda';
      ok = false;
    } catch (erro) {
      motivoSinc = '$erro';
      ok = false; // E1: tenta de novo depois
    } finally {
      sincronizandoAgenda = false;
      if (mexeu) salvoEm = DateTime.now(); // avisa a outra cópia que tem coisa nova pra ler
      await _salvar();
      await _soltarTrava();
      notifyListeners();
      if (mexeu) _agendarBackup();
    }
    return ok;
  }

  /// Por que a última sincronização falhou (pra diagnóstico).
  String? motivoSinc;

  static const _chaveTrava = 'meu_bujo_sinc_agenda_ate';

  Future<bool> _pegarTrava() async {
    final p = _prefs;
    if (p == null) return true;
    await p.reload();
    final ate = DateTime.tryParse(p.getString(_chaveTrava) ?? '');
    if (ate != null && ate.isAfter(DateTime.now())) return false; // a outra cópia está sincronizando
    await p.setString(_chaveTrava, DateTime.now().add(const Duration(minutes: 2)).toIso8601String());
    return true;
  }

  Future<void> _soltarTrava() async {
    await _prefs?.remove(_chaveTrava);
  }

  /// Aplica um evento que veio do Google. Devolve true se mudou algo no app.
  bool _aplicarRemoto(EventoRemoto r, AgendaGoogle agenda) {
    // apagado no app e ainda na fila pra sair do Google: não volta pro app
    if (_apagarNoGoogle.any((x) => x.googleId == r.id)) return false;
    bool ligado(Sincronizavel s) => s.google?.id == r.id && s.google?.agenda == r.agenda;
    final tarefa = tarefas.where(ligado).firstOrNull;
    final evento = tarefa == null ? eventos.where(ligado).firstOrNull : null;
    final Sincronizavel? local = tarefa ?? evento;

    if (r.apagado) {
      if (local == null || local.soNoApp) return false;
      _perguntar(local.google!, local, tarefa?.texto ?? evento!.titulo); // A2
      return true;
    }

    if (local != null) {
      // RN19: se o app mudou depois do Google, a versão do app vence (e vai pro Google em seguida)
      if (local.sujo && local.editadoEm.isAfter(r.atualizadoEm)) return false;
      local.google!.duracaoMin = r.duracaoMin;
      if (tarefa != null) {
        final (texto, status) = lerMarca(r.titulo);
        tarefa
          ..texto = texto
          ..status = status
          ..hora = r.hora;
        if (tarefa.data != r.data) tarefa.data = r.data; // A4 do outro lado
        tarefa.aberta ? _avisos.agendarTarefa(tarefa) : _avisos.cancelar(tarefa.id);
      } else {
        evento!
          ..titulo = r.titulo
          ..data = r.data
          ..hora = r.hora;
        _avisos.agendarEvento(evento);
      }
      local
        ..sujo = false
        ..editadoEm = r.atualizadoEm;
      return true;
    }

    // item novo no Google: vira tarefa ou evento conforme a agenda (RN17), ou o tipo que tinha no app
    final ligacao = LigacaoGoogle(r.agenda, r.id, duracaoMin: r.duracaoMin);
    final viraTarefa = r.tipoBujo == null ? agenda.viraTarefa : r.tipoBujo == 'tarefa';
    if (viraTarefa) {
      final (texto, status) = lerMarca(r.titulo);
      final t = Tarefa(texto: texto, data: r.data, hora: r.hora, status: status)
        ..google = ligacao
        ..editadoEm = r.atualizadoEm;
      tarefas.add(t);
      if (t.aberta) _avisos.agendarTarefa(t);
    } else {
      final e = Evento(titulo: r.titulo, data: r.data, hora: r.hora)
        ..google = ligacao
        ..editadoEm = r.atualizadoEm;
      eventos.add(e);
      _avisos.agendarEvento(e);
    }
    return true;
  }

  void _perguntar(LigacaoGoogle l, Sincronizavel s, String titulo) {
    if (perguntasExclusao.any((p) => p.googleId == l.id)) return;
    final id = s is Tarefa ? s.id : (s as Evento).id;
    perguntasExclusao.add(ExclusaoPendente(agenda: l.agenda, googleId: l.id, itemId: id, titulo: titulo));
  }

  /// RN20: item apagado no Google. Apagar aqui também, ou deixar só no app.
  void responderExclusao(ExclusaoPendente p, {required bool apagarAqui}) {
    perguntasExclusao.remove(p);
    final t = tarefas.where((x) => x.id == p.itemId).firstOrNull;
    final e = eventos.where((x) => x.id == p.itemId).firstOrNull;
    if (apagarAqui) {
      tarefas.removeWhere((x) => x.id == p.itemId);
      eventos.removeWhere((x) => x.id == p.itemId);
      if (p.itemId != null) _avisos.cancelar(p.itemId!);
    } else {
      for (final s in <Sincronizavel?>[t, e].nonNulls) {
        s
          ..google = null
          ..soNoApp = true
          ..sujo = false;
      }
    }
    _mudou();
    reagir(Humor.feliz, apagarAqui ? 'Apagado aqui também.' : 'Ficou só aqui no app ♡');
  }

  /// O item está ligado a uma agenda do Google? (pra perguntar antes de excluir, RN20)
  bool estaNoGoogle(Sincronizavel s) => agendaConectada && s.google != null && !s.soNoApp;

  void _apagouNoApp(Sincronizavel s, String titulo, bool tambemNoGoogle) {
    final l = s.google;
    if (l == null || !tambemNoGoogle) return;
    _apagarNoGoogle.add(ExclusaoPendente(agenda: l.agenda, googleId: l.id, titulo: titulo));
  }

  // ---------------------------------------------------------------- gatinha

  Humor? _humor;
  String? _fala;
  Timer? _timer;
  int _carinhos = 0;

  Humor? get humorDoMomento => _humor;
  String? get falaDoMomento => _fala;

  /// A gatinha reage por ~3 s e depois volta ao humor normal da tela.
  void reagir(Humor humor, String fala) {
    _timer?.cancel();
    _humor = humor;
    _fala = fala;
    notifyListeners();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      _humor = null;
      _fala = null;
      notifyListeners();
    });
  }

  void fazerCarinho() {
    const frases = [
      (Humor.curiosa, 'Já bebeu água hoje?'),
      (Humor.apaixonada, 'Miau! Você consegue ♡'),
      (Humor.sonolenta, 'Só um cochilinho… zzz'),
      (Humor.comemorando, 'Prrr… gostei do carinho!'),
    ];
    final f = frases[_carinhos++ % frases.length];
    reagir(f.$1, f.$2);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerBackup?.cancel();
    _timerAgenda?.cancel();
    _timerPeriodico?.cancel();
    _timerDiarios?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- consultas

  int _ordem(Tarefa a, Tarefa b) {
    if (a.aberta != b.aberta) return a.aberta ? -1 : 1;
    if (a.prioridade != b.prioridade) return a.prioridade ? -1 : 1; // RN03
    return (a.hora ?? '99').compareTo(b.hora ?? '99');
  }

  List<Tarefa> tarefasDoDia(String data) => tarefas.where((t) => t.data == data).toList()..sort(_ordem);

  /// Tarefas que saíram deste dia (aparecem como ">", RN04).
  List<Tarefa> migradasDoDia(String data) => tarefas.where((t) => t.migradaDe.contains(data)).toList();

  List<Evento> eventosDoDia(String data) =>
      eventos.where((e) => e.data == data).toList()..sort((a, b) => (a.hora ?? '').compareTo(b.hora ?? ''));

  List<Habito> habitosDoDia(DateTime dia) => habitos.where((h) => !h.arquivado && h.agendadoEm(dia)).toList();

  /// RN10: pendência é tarefa aberta com data antes de hoje.
  List<Tarefa> get pendencias =>
      tarefas.where((t) => t.aberta && dataDe(t.data).isBefore(hoje)).toList()..sort((a, b) => a.data.compareTo(b.data));

  // ---------------------------------------------------------------- tarefas (UC01, UC02, UC03)

  void salvarTarefa(Tarefa t) {
    final i = tarefas.indexWhere((x) => x.id == t.id);
    if (i >= 0) t.herdarLigacao(tarefas[i]);
    t.tocar();
    if (i >= 0) {
      tarefas[i] = t;
    } else {
      tarefas.add(t);
    }
    _avisos.agendarTarefa(t);
    _mudou(agenda: true);
  }

  void concluir(Tarefa t) {
    t.status = StatusTarefa.feita;
    for (final s in t.subtarefas) {
      s.feita = true; // UC02 A1
    }
    _avisos.cancelar(t.id);
    t.tocar(); // RN24: ganha ✓ no Google
    _mudou(agenda: true);
    reagir(Humor.comemorando, 'Boa! Menos uma ✓');
  }

  void reabrir(Tarefa t) {
    t.status = StatusTarefa.aberta;
    _avisos.agendarTarefa(t);
    t.tocar();
    _mudou(agenda: true);
    reagir(Humor.curiosa, 'Opa, voltou pra lista.');
  }

  void cancelarTarefa(Tarefa t) {
    t.status = StatusTarefa.cancelada;
    _avisos.cancelar(t.id);
    t.tocar();
    _mudou(agenda: true);
    reagir(Humor.feliz, 'Riscada. Menos peso ♡');
  }

  /// [tambemNoGoogle]: resposta da pergunta da RN20 (só vale pra tarefa sincronizada).
  void excluirTarefa(Tarefa t, {bool tambemNoGoogle = false}) {
    tarefas.removeWhere((x) => x.id == t.id);
    _avisos.cancelar(t.id);
    _apagouNoApp(t, t.texto, tambemNoGoogle);
    _mudou(agenda: true);
  }

  void alternarSubtarefa(Tarefa t, int i) {
    t.subtarefas[i].feita = !t.subtarefas[i].feita;
    _mudou();
  }

  /// RN28: a partir da 3ª migração, perguntar antes.
  bool deveAvisarMigracao(Tarefa t) => t.migracoes >= 2;

  /// UC09. RN11: só migra quando a usuária pede. RN12: nunca pro passado.
  void migrar(Tarefa t, DateTime destino) {
    final d = soDia(destino);
    if (d.isBefore(hoje)) {
      throw ArgumentError('Não dá pra migrar pro passado (RN12).');
    }
    t.migradaDe.add(t.data);
    t.data = dataTexto(d);
    _avisos.agendarTarefa(t);
    t.tocar(); // A4: a data muda no Google também
    _mudou(agenda: true);
  }

  // ---------------------------------------------------------------- eventos (UC04)

  void salvarEvento(Evento e) {
    final i = eventos.indexWhere((x) => x.id == e.id);
    if (i >= 0) e.herdarLigacao(eventos[i]);
    e.tocar();
    if (i >= 0) {
      eventos[i] = e;
    } else {
      eventos.add(e);
    }
    _avisos.agendarEvento(e);
    _mudou(agenda: true);
  }

  void excluirEvento(Evento e, {bool tambemNoGoogle = false}) {
    eventos.removeWhere((x) => x.id == e.id);
    _avisos.cancelar(e.id);
    _apagouNoApp(e, e.titulo, tambemNoGoogle);
    _mudou(agenda: true);
  }

  // ---------------------------------------------------------------- hábitos (UC05, UC06)

  void salvarHabito(Habito h) {
    final i = habitos.indexWhere((x) => x.id == h.id);
    if (i >= 0) {
      habitos[i] = h;
    } else {
      habitos.add(h);
    }
    _mudou();
  }

  void arquivarHabito(Habito h) {
    h.arquivado = true;
    _mudou();
  }

  /// RN09: dá pra marcar hoje e até 7 dias atrás; dia futuro não, e dia mais antigo fica travado.
  static const diasParaCorrigir = 7;

  bool podeMarcar(DateTime dia) => _travado(dia) == null;

  /// Por que o dia não pode ser marcado (ou null se pode).
  String? _travado(DateTime dia) {
    final d = soDia(dia);
    if (d.isAfter(hoje)) return 'Esse dia ainda não chegou!';
    if (d.isBefore(DateTime(hoje.year, hoje.month, hoje.day - diasParaCorrigir))) return 'Esse dia já fechou. Dá pra corrigir só até 7 dias atrás.';
    return null;
  }

  void alternarHabito(Habito h, DateTime dia) {
    if (!podeMarcar(dia)) {
      reagir(Humor.curiosa, _travado(dia)!);
      return;
    }
    final k = dataTexto(dia);
    if (h.feitoEm(k)) {
      h.marcas.remove(k);
      _mudou();
      reagir(Humor.curiosa, 'Desmarcado. Sem problema!');
    } else {
      h.marcas[k] = 1;
      _mudou();
      reagir(Humor.comemorando, 'Isso aí! ${h.nome} ✓');
    }
  }

  void somarHabito(Habito h, DateTime dia, double delta) {
    if (!podeMarcar(dia)) {
      reagir(Humor.curiosa, _travado(dia)!);
      return;
    }
    final k = dataTexto(dia);
    if (delta < 0 && h.valorEm(k) <= 0) {
      reagir(Humor.curiosa, 'O copo já tá vazio!');
      return;
    }
    final novo = (h.valorEm(k) + delta).clamp(0, h.meta * 2).toDouble();
    if (novo <= 0) {
      h.marcas.remove(k);
    } else {
      h.marcas[k] = novo;
    }
    _mudou();
    if (delta < 0) {
      reagir(Humor.curiosa, 'Corrigido! ${formatarNumero(novo)} ${h.unidade}');
    } else if (novo >= h.meta) {
      reagir(Humor.apaixonada, 'Meta batida! ${h.nome} ♡');
    } else {
      reagir(Humor.comemorando, 'Glub glub! Faltam ${formatarNumero(h.meta - novo)} ${h.unidade}');
    }
  }

  // ---------------------------------------------------------------- ajustes

  void comecar() {
    comecou = true;
    _mudou();
  }

  void escolherPaleta(String id) {
    paletaId = id;
    _mudou();
    reagir(Humor.apaixonada, 'Que cor linda! ${paleta.nome} ♡');
  }

  void escolherTema(ThemeMode m) {
    tema = m;
    _mudou();
    if (m == ThemeMode.dark) {
      reagir(Humor.sonolenta, 'Apagando as luzes… zzz');
    } else {
      reagir(Humor.comemorando, 'Prontinho!');
    }
  }

  void escolherResumoHora(int h) {
    resumoHora = h;
    _mudou();
    reagir(Humor.feliz, 'Te mando o resumo às ${h}h!');
  }

  // ---------------------------------------------------------------- semana e mês (UC13, UC18)

  String focoDaSemana(DateTime dia) => focos[dataTexto(inicioDaSemana(dia))] ?? '';

  void definirFoco(DateTime dia, String texto) {
    final k = dataTexto(inicioDaSemana(dia));
    if (texto.trim().isEmpty) {
      focos.remove(k);
    } else {
      focos[k] = texto.trim();
    }
    _mudou();
  }

  List<Meta> metasDoMes(DateTime mes) => metas[mesTexto(mes)] ?? [];

  void adicionarMeta(DateTime mes, String texto) {
    if (texto.trim().isEmpty) return;
    metas.putIfAbsent(mesTexto(mes), () => []).add(Meta(texto.trim()));
    _mudou();
    reagir(Humor.comemorando, 'Meta anotada! Bora ♡');
  }

  void alternarMeta(Meta m) {
    m.feita = !m.feita;
    _mudou();
    if (m.feita) {
      reagir(Humor.apaixonada, 'Meta batida! Orgulho ♡');
    } else {
      reagir(Humor.curiosa, 'Ainda não deu? Tudo bem!');
    }
  }

  void excluirMeta(DateTime mes, Meta m) {
    metas[mesTexto(mes)]?.remove(m);
    _mudou();
  }

  /// Tarefa rápida, só com texto, pra um dia (da semana).
  void adicionarTarefaRapida(String texto, DateTime dia) {
    if (texto.trim().isEmpty) return;
    salvarTarefa(Tarefa(texto: texto.trim(), data: dataTexto(dia)));
    reagir(Humor.comemorando, 'Anotado pra ${DateFormat.EEEE('pt_BR').format(dia)}!');
  }

  // ---------------------------------------------------------------- future log (UC14)

  List<ItemFuturo> futuroDoMes(String mes) => futuro.where((f) => f.mes == mes).toList();

  void adicionarFuturo(String texto, DateTime mes, {bool evento = false}) {
    if (texto.trim().isEmpty) return;
    futuro.add(ItemFuturo(texto: texto.trim(), mes: mesTexto(mes), evento: evento));
    _mudou();
    reagir(Humor.comemorando, 'Guardado em ${DateFormat.MMMM('pt_BR').format(mes)}!');
  }

  void excluirFuturo(ItemFuturo f) {
    futuro.remove(f);
    _mudou();
  }

  /// Passa o item do future log pro dia escolhido: vira tarefa ou evento de verdade.
  void agendarFuturo(ItemFuturo f, DateTime dia) {
    futuro.remove(f);
    if (f.evento) {
      salvarEvento(Evento(titulo: f.texto, data: dataTexto(dia), avisoMin: 0));
    } else {
      salvarTarefa(Tarefa(texto: f.texto, data: dataTexto(dia)));
    }
    reagir(Humor.comemorando, 'Foi pro dia ${DateFormat('d/M').format(dia)}! >');
  }

  // ---------------------------------------------------------------- progresso e lembrete de hábito (UC16, UC17)

  void definirLembrete(Habito h, {bool? ligado, String? hora}) {
    if (ligado != null) h.lembrete = ligado;
    if (hora != null) h.lembreteHora = hora;
    _mudou();
    reagir(Humor.feliz, h.lembrete ? 'Te lembro às ${h.lembreteHora}, se ainda não tiver marcado!' : 'Sem lembrete pra ${h.nome}.');
  }

  /// No calendário de progresso: feito <-> não feito; com meta, vazio -> metade -> cheio -> vazio.
  void corrigirHabito(Habito h, DateTime dia) {
    if (!podeMarcar(dia)) {
      reagir(Humor.curiosa, _travado(dia)!);
      return;
    }
    if (h.tipo == TipoHabito.feito) return alternarHabito(h, dia);
    final k = dataTexto(dia);
    final v = h.valorEm(k);
    final novo = v >= h.meta ? 0.0 : (v >= h.meta / 2 ? h.meta : h.meta / 2);
    if (novo <= 0) {
      h.marcas.remove(k);
    } else {
      h.marcas[k] = novo;
    }
    _mudou();
    reagir(novo >= h.meta ? Humor.comemorando : Humor.curiosa,
        novo >= h.meta ? 'Dia ${dia.day}: meta batida ✓' : (novo > 0 ? 'Dia ${dia.day}: meio caminho!' : 'Desmarquei o dia ${dia.day}.'));
  }

  // ---------------------------------------------------------------- coleções (UC19)

  /// Devolve null se deu certo, ou o motivo de não dar.
  String? adicionarColecao(String nome) {
    final n = nome.trim();
    if (n.isEmpty) return 'Dá um nome pra coleção!';
    if (colecoes.any((c) => c.toLowerCase() == n.toLowerCase())) return 'Já existe uma coleção com esse nome!';
    colecoes.add(n);
    coresColecoes[n] = coresColecao.values.elementAt((colecoes.length - 1) % coresColecao.length);
    _mudou();
    return null;
  }

  /// Cor da etiqueta; coleções antigas sem cor escolhida ganham uma pela posição.
  String corDaColecao(String nome) {
    final i = colecoes.indexOf(nome);
    return coresColecoes[nome] ?? coresColecao.values.elementAt((i < 0 ? 0 : i) % coresColecao.length);
  }

  void definirCorColecao(String nome, String cor) {
    coresColecoes[nome] = cor;
    _mudou();
    reagir(Humor.apaixonada, 'Que cor linda ♡');
  }

  List<Tarefa> tarefasDaColecao(String nome) => tarefas.where((t) => t.colecao == nome).toList()..sort((a, b) => b.data.compareTo(a.data));

  /// Renomeia e leva as tarefas junto. Devolve null se deu certo.
  String? renomearColecao(String antigo, String novo) {
    final n = novo.trim();
    if (n.isEmpty || n == antigo) return null;
    if (colecoes.any((c) => c != antigo && c.toLowerCase() == n.toLowerCase())) return 'Já existe uma coleção com esse nome!';
    final i = colecoes.indexOf(antigo);
    if (i < 0) return null;
    colecoes[i] = n;
    final cor = coresColecoes.remove(antigo);
    if (cor != null) coresColecoes[n] = cor;
    for (final t in tarefas.where((t) => t.colecao == antigo)) {
      t.colecao = n;
    }
    _mudou();
    reagir(Humor.feliz, 'Agora se chama $n. As tarefas foram junto!');
    return null;
  }

  /// Apaga a coleção; as tarefas continuam, só ficam sem coleção.
  void apagarColecao(String nome) {
    colecoes.remove(nome);
    coresColecoes.remove(nome);
    for (final t in tarefas.where((t) => t.colecao == nome)) {
      t.colecao = null;
    }
    _mudou();
    reagir(Humor.feliz, 'Coleção apagada. As tarefas continuam no dia delas.');
  }

  // ---------------------------------------------------------------- reflexão mensal (UC21)

  /// Mês que está pedindo reflexão: o atual no último dia, ou o anterior nos 5 primeiros dias se ficou sem.
  DateTime? mesPedindoReflexao() {
    final h = hoje;
    final ultimoDia = DateTime(h.year, h.month + 1, 0).day;
    if (h.day == ultimoDia && !reflexoes.containsKey(mesTexto(h))) return DateTime(h.year, h.month);
    final anterior = DateTime(h.year, h.month - 1);
    if (h.day <= 5 && !reflexoes.containsKey(mesTexto(anterior))) return anterior;
    return null;
  }

  /// Melhor sequência de algum hábito dentro do mês (pro resumo da reflexão).
  (String, int)? melhorSequenciaDoMes(DateTime mes) {
    (String, int)? melhor;
    final fim = DateTime(mes.year, mes.month + 1, 0);
    final ate = fim.isAfter(hoje) ? hoje : fim;
    for (final h in habitos.where((h) => !h.arquivado)) {
      var corrida = 0;
      var maior = 0;
      for (var d = DateTime(mes.year, mes.month); !d.isAfter(ate); d = DateTime(d.year, d.month, d.day + 1)) {
        if (!h.agendadoEm(d)) continue;
        corrida = h.feitoEm(dataTexto(d)) ? corrida + 1 : 0;
        if (corrida > maior) maior = corrida;
      }
      if (maior > 0 && (melhor == null || maior > melhor.$2)) melhor = (h.nome, maior);
    }
    return melhor;
  }

  /// Salva a reflexão. O que ela quer pro mês seguinte vira meta de lá (uma por linha),
  /// e as metas marcadas em [levar] são copiadas pro mês seguinte.
  void salvarReflexao(DateTime mes, {required String humor, required List<String> textos, List<Meta> levar = const []}) {
    final k = mesTexto(mes);
    final novaAntes = reflexoes[k]?.textos[2] ?? '';
    reflexoes[k] = Reflexao(mes: k, humor: humor, textos: textos);
    final proximo = DateTime(mes.year, mes.month + 1);
    final lista = metas.putIfAbsent(mesTexto(proximo), () => []);
    bool tem(String t) => lista.any((m) => m.texto.toLowerCase() == t.toLowerCase());
    final linhasAntes = novaAntes.split('\n').map((l) => l.trim()).toSet();
    for (final linha in textos[2].split('\n').map((l) => l.trim())) {
      if (linha.isNotEmpty && !linhasAntes.contains(linha) && !tem(linha)) lista.add(Meta(linha));
    }
    for (final m in levar) {
      if (!tem(m.texto)) lista.add(Meta(m.texto));
    }
    _mudou();
    reagir(Humor.comemorando, 'Reflexão guardada! ${DateFormat.MMMM('pt_BR').format(proximo)} começa leve ♡');
  }
}
