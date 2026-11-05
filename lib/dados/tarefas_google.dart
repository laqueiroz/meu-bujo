import 'agenda.dart';
import 'modelos.dart';

/// Tarefas do app numa agenda própria do Google, "Bujo – Tarefas".
/// Essa agenda é o meio de troca com quem só enxerga o Google Agenda (como o Claude no celular).
///
/// Convenções (não mudar; o outro lado segue as mesmas):
///   - cada tarefa é um evento de DIA INTEIRO, que não ocupa horário;
///   - tarefa concluída tem o título começando com "✓ "; desmarcar tira o prefixo;
///   - tudo que vem dessa agenda é tarefa no app, nunca evento;
///   - tarefa cancelada no app sai da agenda (fica riscada só no app);
///   - o horário da tarefa, se tiver, fica só no app (é ele que avisa).
class TaskSyncService {
  static const nomeAgenda = 'Bujo – Tarefas';
  static const fuso = 'America/Sao_Paulo';

  final Agenda _agenda;
  TaskSyncService(this._agenda);

  /// Id da agenda de tarefas; cria na primeira vez.
  Future<String> garantirAgenda() => _agenda.acharOuCriarAgenda(nomeAgenda, fuso: fuso);

  /// Como a tarefa vai pra agenda: dia inteiro, sem hora, transparente, com "✓ " se feita.
  static ItemParaGoogle paraGoogle(Tarefa t) => ItemParaGoogle(
        bujoId: t.id,
        ehTarefa: true,
        titulo: tituloComMarca(t.texto, t.status == StatusTarefa.feita ? StatusTarefa.feita : StatusTarefa.aberta),
        data: t.data,
        transparente: true,
      );

  /// Tarefa cancelada não fica na agenda de tarefas.
  static bool ficaNaAgenda(Tarefa t) => t.status != StatusTarefa.cancelada;
}
