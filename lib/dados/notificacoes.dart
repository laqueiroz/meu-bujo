import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'modelos.dart';

/// UC10: avisos no horário (com a antecedência escolhida, RN22).
/// RN23: só o app avisa. RN13: concluir/cancelar/excluir/mudar horário reagenda.
class Notificacoes {
  Notificacoes._();
  static final instancia = Notificacoes._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  Future<void> iniciar() async {
    try {
      // Avisos são de uma vez só, então basta o instante exato em UTC (não precisa do fuso do celular).
      tzdata.initializeTimeZones();
      await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _pronto = true;
    } catch (_) {
      // Sem permissão ou sem suporte: o app continua funcionando, só sem avisos (UC10 E2).
      _pronto = false;
    }
  }

  /// Pede a permissão de notificação (Android 13+). Chamado depois que o app já abriu,
  /// pra a tela não ficar parada esperando a resposta.
  Future<void> pedirPermissao() async {
    if (!_pronto) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Sem permissão: o app segue funcionando, só sem avisos (UC10 E2).
    }
  }

  /// Id numérico estável a partir do id de texto (o hashCode do Dart muda entre execuções).
  int _numero(String id) {
    var h = 0x811c9dc5;
    for (final c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes',
      'Lembretes',
      channelDescription: 'Avisos de tarefas e eventos com horário',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> agendar({
    required String id,
    required String titulo,
    required String texto,
    required String data,
    required String hora,
    required int avisoMin,
  }) async {
    if (!_pronto) return;
    await cancelar(id);
    final d = dataDe(data);
    final hm = hora.split(':');
    final local = DateTime(d.year, d.month, d.day, int.parse(hm[0]), int.parse(hm[1])).subtract(Duration(minutes: avisoMin));
    if (local.isBefore(DateTime.now())) return;
    final quando = tz.TZDateTime.from(local.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id: _numero(id),
      title: titulo,
      body: texto,
      scheduledDate: quando,
      notificationDetails: _detalhes,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static const _detalhesDiarios = NotificationDetails(
    android: AndroidNotificationDetails(
      'diarios',
      'Resumo e hábitos',
      channelDescription: 'Resumo do dia e lembretes de hábito',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  /// Resumo do dia (UC15) e lembrete de hábito (UC16), num horário exato. Horário que já passou é ignorado.
  Future<void> agendarEm({required String id, required String titulo, required String texto, required DateTime quando}) async {
    if (!_pronto) return;
    await cancelar(id);
    if (quando.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _numero(id),
      title: titulo,
      body: texto,
      scheduledDate: tz.TZDateTime.from(quando.toUtc(), tz.UTC),
      notificationDetails: _detalhesDiarios,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelar(String id) async {
    if (!_pronto) return;
    await _plugin.cancel(id: _numero(id));
  }

  Future<void> agendarTarefa(Tarefa t) async {
    if (!t.aberta || t.hora == null) return cancelar(t.id);
    await agendar(id: t.id, titulo: t.texto, texto: 'Tarefa ${t.hora} • Meu Bujo', data: t.data, hora: t.hora!, avisoMin: t.avisoMin);
  }

  Future<void> agendarEvento(Evento e) async {
    if (e.hora == null) return cancelar(e.id);
    await agendar(id: e.id, titulo: e.titulo, texto: 'Evento ${e.hora} • Meu Bujo', data: e.data, hora: e.hora!, avisoMin: e.avisoMin);
  }
}
