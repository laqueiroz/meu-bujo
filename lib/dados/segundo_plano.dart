import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

import 'estado.dart';
import 'notificacoes.dart';
import 'widget_casa.dart';

/// RN25: a agenda sincroniza também com o app fechado.
/// O Android roda isso no máximo a cada 15 min, só com internet, e pode atrasar pra economizar bateria.
class SegundoPlano {
  static const _tarefa = 'sincronizar-agenda';

  static Future<void> iniciar() async {
    try {
      await Workmanager().initialize(rodarEmSegundoPlano);
    } catch (_) {
      // sem suporte (ex.: testes): o app segue sincronizando quando está aberto
    }
  }

  /// Liga quando a agenda está conectada; desliga quando não está.
  static Future<void> ajustar({required bool ligado}) async {
    try {
      if (ligado) {
        await Workmanager().registerPeriodicTask(
          _tarefa,
          _tarefa,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } else {
        await Workmanager().cancelByUniqueName(_tarefa);
      }
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void rodarEmSegundoPlano() {
  Workmanager().executeTask((tarefa, dados) async {
    WidgetsFlutterBinding.ensureInitialized();
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
    await Notificacoes.instancia.iniciar();
    final e = EstadoApp();
    await e.carregar();
    if (!e.logada || !e.agendaConectada) return true;
    final ok = await e.sincronizarAgenda(semTela: true);
    await e.fazerBackup();
    await WidgetCasa.atualizar(e, comGata: false);
    // ignore: avoid_print
    print('MeuBujo RN25: agenda ${ok ? 'sincronizada' : 'não sincronizou (${e.motivoSinc})'} em segundo plano (${e.eventos.length} eventos)');
    return true; // se falhou, tenta de novo na próxima vez (E1)
  });
}
