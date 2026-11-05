import 'package:googleapis/calendar/v3.dart' as cal;

import 'modelos.dart';
import 'nuvem.dart';

/// UC22 e UC23: conversa com o Google Calendar da mesma conta do login (RN14).
class Agenda {
  Agenda._();
  static final instancia = Agenda._();

  static const escopos = [cal.CalendarApi.calendarScope];

  final _nuvem = Nuvem.instancia;

  /// Pede acesso à agenda (tela do próprio Google). False se a usuária negou (UC11 E1).
  Future<bool> autorizar() => _nuvem.autorizar(escopos);

  Future<cal.CalendarApi> _api({bool podePerguntar = false}) async {
    final cli = await _nuvem.cliente(escopos, podePerguntar: podePerguntar);
    if (cli == null) throw AgendaSemPermissao();
    return cal.CalendarApi(cli);
  }

  /// Acha a agenda com esse nome entre as da conta; se não existir, cria (é a usuária a dona).
  Future<String> acharOuCriarAgenda(String nome, {required String fuso}) async {
    final api = await _api();
    final r = await _chamar(() => api.calendarList.list(minAccessRole: 'owner'));
    for (final a in r.items ?? <cal.CalendarListEntry>[]) {
      if (a.summary == nome && a.id != null) return a.id!;
    }
    final nova = await _chamar(() => api.calendars.insert(cal.Calendar(summary: nome, timeZone: fuso)));
    return nova.id!;
  }

  /// Lista as agendas da conta (UC22 passo 1).
  Future<List<AgendaGoogle>> listarAgendas({bool podePerguntar = false}) async {
    final api = await _api(podePerguntar: podePerguntar);
    final r = await _chamar(() => api.calendarList.list(minAccessRole: 'writer'));
    return [
      for (final a in r.items ?? <cal.CalendarListEntry>[])
        if (a.id != null) AgendaGoogle(id: a.id!, nome: a.summaryOverride ?? a.summary ?? a.id!, cor: a.backgroundColor),
    ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  /// O que mudou na agenda desde [desde] (ou tudo da janela, na primeira vez). UC23 passo 2.
  Future<List<EventoRemoto>> mudancas(String agenda, {DateTime? desde}) async {
    final api = await _api();
    final hoje = DateTime.now();
    final saida = <EventoRemoto>[];
    String? pagina;
    do {
      final r = await _chamar(() => api.events.list(
            agenda,
            singleEvents: true,
            showDeleted: desde != null,
            timeMin: hoje.subtract(const Duration(days: 7)).toUtc(), // não traz coisa velha pras pendências
            timeMax: hoje.add(const Duration(days: 365)).toUtc(),
            updatedMin: desde?.subtract(const Duration(minutes: 1)).toUtc(),
            maxResults: 250,
            pageToken: pagina,
          ));
      for (final e in r.items ?? <cal.Event>[]) {
        final lido = lerEvento(e, agenda);
        if (lido != null) saida.add(lido);
      }
      pagina = r.nextPageToken;
    } while (pagina != null);
    return saida;
  }

  Future<LigacaoGoogle> criar(String agenda, ItemParaGoogle item) async {
    final api = await _api();
    final ev = await _chamar(() => api.events.insert(eventoDoItem(item), agenda));
    return LigacaoGoogle(agenda, ev.id!, duracaoMin: item.duracaoMin);
  }

  Future<void> atualizar(LigacaoGoogle l, ItemParaGoogle item) async {
    final api = await _api();
    await _chamar(() => api.events.patch(eventoDoItem(item), l.agenda, l.id));
  }

  Future<void> apagar(String agenda, String id) async {
    final api = await _api();
    try {
      await _chamar(() => api.events.delete(agenda, id));
    } on AgendaNaoEncontrada {
      // já não existia: tá ótimo
    }
  }

  /// Traduz os erros do Google pros casos do UC23 (E2 e E3).
  Future<T> _chamar<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on cal.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) throw AgendaSemPermissao();
      if (e.status == 404 || e.status == 410) throw AgendaNaoEncontrada();
      rethrow;
    }
  }
}

class AgendaSemPermissao implements Exception {}

class AgendaNaoEncontrada implements Exception {}

/// O que o app manda pro Google de uma tarefa ou evento.
class ItemParaGoogle {
  final String bujoId;
  final bool ehTarefa;
  final String titulo;
  final String data;
  final String? hora;
  final int duracaoMin;

  /// Não ocupa horário na agenda (tarefas da agenda "Bujo – Tarefas").
  final bool transparente;

  ItemParaGoogle({required this.bujoId, required this.ehTarefa, required this.titulo, required this.data, this.hora, this.duracaoMin = 60, this.transparente = false});

  factory ItemParaGoogle.daTarefa(Tarefa t) => ItemParaGoogle(
        bujoId: t.id,
        ehTarefa: true,
        titulo: tituloComMarca(t.texto, t.status),
        data: t.data,
        hora: t.hora,
        duracaoMin: t.google?.duracaoMin ?? 30,
      );

  factory ItemParaGoogle.doEvento(Evento e) => ItemParaGoogle(
        bujoId: e.id,
        ehTarefa: false,
        titulo: e.titulo,
        data: e.data,
        hora: e.hora,
        duracaoMin: e.google?.duracaoMin ?? 60,
      );
}

/// Um evento lido do Google, já no formato do app.
class EventoRemoto {
  final String id;
  final String agenda;
  final String titulo;
  final String data;
  final String? hora;
  final int duracaoMin;
  final DateTime atualizadoEm;
  final bool apagado;

  /// 'tarefa' ou 'evento' quando o item nasceu no app; null quando nasceu no Google.
  final String? tipoBujo;

  EventoRemoto({
    required this.id,
    required this.agenda,
    required this.titulo,
    required this.data,
    this.hora,
    this.duracaoMin = 60,
    required this.atualizadoEm,
    this.apagado = false,
    this.tipoBujo,
  });
}

// ---------------------------------------------------------------- conversões (testadas em test/agenda_test.dart)

const marcaFeita = '✓ ';
const marcaCancelada = '✕ ';

/// RN24: concluída ganha "✓ " e cancelada "✕ " no começo do título no Google.
String tituloComMarca(String texto, StatusTarefa s) => switch (s) {
      StatusTarefa.aberta => texto,
      StatusTarefa.feita => '$marcaFeita$texto',
      StatusTarefa.cancelada => '$marcaCancelada$texto',
    };

/// O caminho de volta: tira a marca do título e descobre o status.
(String, StatusTarefa) lerMarca(String titulo) {
  if (titulo.startsWith(marcaFeita)) return (titulo.substring(marcaFeita.length), StatusTarefa.feita);
  if (titulo.startsWith(marcaCancelada)) return (titulo.substring(marcaCancelada.length), StatusTarefa.cancelada);
  return (titulo, StatusTarefa.aberta);
}

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

cal.Event eventoDoItem(ItemParaGoogle item) {
  final dia = dataDe(item.data);
  final cal.EventDateTime inicio;
  final cal.EventDateTime fim;
  if (item.hora == null) {
    // RN21: sem hora vira item de dia inteiro
    inicio = cal.EventDateTime(date: dia);
    fim = cal.EventDateTime(date: dia.add(const Duration(days: 1)));
  } else {
    final p = item.hora!.split(':');
    final comeco = DateTime(dia.year, dia.month, dia.day, int.parse(p[0]), int.parse(p[1]));
    inicio = cal.EventDateTime(dateTime: comeco.toUtc());
    fim = cal.EventDateTime(dateTime: comeco.add(Duration(minutes: item.duracaoMin)).toUtc());
  }
  return cal.Event(
    summary: item.titulo,
    start: inicio,
    end: fim,
    // RN23: só o app avisa
    reminders: cal.EventReminders(useDefault: false, overrides: []),
    transparency: item.transparente ? 'transparent' : null,
    extendedProperties: cal.EventExtendedProperties(private: {'meuBujo': item.ehTarefa ? 'tarefa' : 'evento', 'bujoId': item.bujoId}),
  );
}

EventoRemoto? lerEvento(cal.Event e, String agenda) {
  final id = e.id;
  if (id == null) return null;
  final atualizado = e.updated?.toLocal() ?? DateTime.now();
  if (e.status == 'cancelled') {
    return EventoRemoto(id: id, agenda: agenda, titulo: e.summary ?? '', data: '', atualizadoEm: atualizado, apagado: true);
  }
  final ini = e.start;
  if (ini == null) return null;
  String data;
  String? hora;
  var duracao = 60;
  if (ini.dateTime != null) {
    final d = ini.dateTime!.toLocal();
    data = dataTexto(d);
    hora = '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';
    final f = e.end?.dateTime?.toLocal();
    if (f != null && f.isAfter(d)) duracao = f.difference(d).inMinutes;
  } else if (ini.date != null) {
    data = dataTexto(ini.date!);
  } else {
    return null;
  }
  return EventoRemoto(
    id: id,
    agenda: agenda,
    titulo: (e.summary ?? '').trim().isEmpty ? '(sem título)' : e.summary!.trim(),
    data: data,
    hora: hora,
    duracaoMin: duracao,
    atualizadoEm: atualizado,
    tipoBujo: e.extendedProperties?.private?['meuBujo'],
  );
}
