import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../tema.dart';
import '../widgets/gatinha.dart';
import 'estado.dart';
import 'modelos.dart';

/// UC25: o widget da tela inicial do celular, em 3 tamanhos (RN31).
/// O app escreve aqui o que o widget mostra; o desenho fica em android/app/src/main/res/layout/widget_*.xml.
class WidgetCasa {
  static const _provedores = ['WidgetPequeno', 'WidgetMedio', 'WidgetGrande', 'WidgetFaixa'];
  static const maxTarefas = 6;
  static String? _gataDesenhada;

  /// O hábito do copo d'água: o primeiro com meta de hoje, de preferência um de "água".
  static Habito? habitoAgua(EstadoApp e) {
    final metas = e.habitosDoDia(e.hoje).where((h) => h.tipo == TipoHabito.meta).toList();
    return metas.where((h) => h.nome.toLowerCase().contains('gua')).firstOrNull ?? metas.firstOrNull;
  }

  /// Tarefas de hoje na ordem do widget: as abertas primeiro (prioritárias, depois as mais recentes),
  /// e as feitas no fim (as concluídas por último primeiro). Se não couber tudo, quem fica de fora são as feitas.
  static List<Tarefa> tarefasDoWidget(EstadoApp e) {
    final doDia = e.tarefasDoDia(e.hojeTexto).where((t) => t.status != StatusTarefa.cancelada).toList();
    final abertas = doDia.where((t) => t.aberta).toList()
      ..sort((a, b) => a.prioridade != b.prioridade ? (a.prioridade ? -1 : 1) : b.editadoEm.compareTo(a.editadoEm));
    final feitas = doDia.where((t) => !t.aberta).toList()..sort((a, b) => b.editadoEm.compareTo(a.editadoEm));
    return [...abertas, ...feitas];
  }

  /// RN33: chamado sempre que algo muda no app. Sem widget na tela, não faz nada.
  static Future<void> atualizar(EstadoApp e, {bool comGata = true}) async {
    try {
      final hoje = e.hojeTexto;
      final agua = habitoAgua(e);
      final todas = tarefasDoWidget(e);
      final tarefas = todas.take(maxTarefas).toList();
      final abertas = todas.where((t) => t.aberta).length;
      final dados = <String, Object?>{
        'data': DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(e.hoje),
        'fala': abertas == 0 ? (tarefas.isEmpty ? 'Dia livre ♡' : 'Tudo feito hoje ♡') : 'Faltam $abertas ${abertas == 1 ? 'tarefa' : 'tarefas'}!',
        'agua_ok': agua != null,
        'agua_nome': agua?.nome ?? '',
        'agua_texto': agua == null ? '' : '${formatarNumero(agua.valorEm(hoje))} de ${formatarNumero(agua.meta)} ${agua.unidade}',
        'agua_pct': agua == null || agua.meta == 0 ? 0 : (agua.valorEm(hoje) / agua.meta * 100).clamp(0, 100).round(),
        'agua_passo': agua == null ? '' : '+ ${formatarNumero(agua.passo)} ${agua.unidade}',
        'n_tarefas': tarefas.length,
        'n_total': todas.length,
        // faixa da tela de bloqueio: só a próxima que falta fazer
        'proxima': todas.where((t) => t.aberta).map((t) => '• ${t.texto}').firstOrNull ?? (todas.isEmpty ? 'Dia livre ♡' : 'Tudo feito hoje ♡'),
        'abertas': abertas,
        for (var i = 0; i < tarefas.length; i++) ...{
          't${i}_texto': tarefas[i].texto,
          't${i}_feita': !tarefas[i].aberta,
          't${i}_id': tarefas[i].id,
        },
      };
      for (final d in dados.entries) {
        await HomeWidget.saveWidgetData(d.key, d.value);
      }
      if (comGata && _gataDesenhada != e.paletaId) {
        await HomeWidget.renderFlutterWidget(
          Theme(
            data: temaBujo(e.paleta, escuro: false),
            child: const Material(color: Colors.transparent, child: Center(child: Gatinha(humor: Humor.feliz, tamanho: 110))),
          ),
          key: 'gata',
          logicalSize: const Size(120, 110),
        );
        _gataDesenhada = e.paletaId;
      }
      for (final p in _provedores) {
        await HomeWidget.updateWidget(qualifiedAndroidName: 'com.meubujo.meu_bujo.$p');
      }
    } catch (_) {
      // sem widget (ou em teste): tudo bem
    }
  }
}

/// RN32: toque no "+ água" do widget. Roda em segundo plano, com o app fechado.
@pragma('vm:entry-point')
Future<void> toqueNoWidget(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final e = EstadoApp();
  await e.carregar();
  await e.toqueDoWidget(uri);
  await WidgetCasa.atualizar(e, comGata: false);
}
