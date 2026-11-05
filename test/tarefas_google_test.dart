import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:meu_bujo/dados/agenda.dart';
import 'package:meu_bujo/dados/modelos.dart';
import 'package:meu_bujo/dados/tarefas_google.dart';

void main() {
  test('Bujo – Tarefas: tarefa vira evento de dia inteiro, transparente, mesmo com hora', () {
    final t = Tarefa(texto: 'Comprar ração', data: '2026-11-05', hora: '18:00');
    final ev = eventoDoItem(TaskSyncService.paraGoogle(t));
    expect(ev.start!.dateTime, isNull);
    expect(dataTexto(ev.start!.date!), '2026-11-05');
    expect(dataTexto(ev.end!.date!), '2026-11-06');
    expect(ev.transparency, 'transparent');
    expect(ev.summary, 'Comprar ração');
  });

  test('Bujo – Tarefas: feita ganha "✓ "; aberta fica sem prefixo', () {
    final feita = Tarefa(texto: 'Ler', data: '2026-11-05', status: StatusTarefa.feita);
    expect(TaskSyncService.paraGoogle(feita).titulo, '✓ Ler');
    final aberta = Tarefa(texto: 'Ler', data: '2026-11-05');
    expect(TaskSyncService.paraGoogle(aberta).titulo, 'Ler');
  });

  test('Bujo – Tarefas: cancelada não fica na agenda', () {
    expect(TaskSyncService.ficaNaAgenda(Tarefa(texto: 'x', data: '2026-11-05', status: StatusTarefa.cancelada)), isFalse);
    expect(TaskSyncService.ficaNaAgenda(Tarefa(texto: 'x', data: '2026-11-05', status: StatusTarefa.feita)), isTrue);
  });

  test('evento criado pelo Claude (dia inteiro, "✓ ") é lido como tarefa feita, sem o prefixo', () {
    final ev = cal.Event(
      id: 'abc',
      summary: '✓ Pagar boleto',
      start: cal.EventDateTime(date: DateTime(2026, 11, 5)),
      end: cal.EventDateTime(date: DateTime(2026, 11, 6)),
      updated: DateTime.utc(2026, 11, 5),
    );
    final r = lerEvento(ev, 'bujo-tarefas')!;
    expect(r.hora, isNull);
    expect(r.data, '2026-11-05');
    expect(lerMarca(r.titulo), ('Pagar boleto', StatusTarefa.feita));
  });
}
