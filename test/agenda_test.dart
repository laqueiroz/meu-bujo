import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:meu_bujo/dados/agenda.dart';
import 'package:meu_bujo/dados/modelos.dart';

void main() {
  test('RN24: marca de concluída/cancelada vai e volta pelo título', () {
    expect(tituloComMarca('Ler artigo', StatusTarefa.feita), '✓ Ler artigo');
    expect(tituloComMarca('Ler artigo', StatusTarefa.cancelada), '✕ Ler artigo');
    expect(tituloComMarca('Ler artigo', StatusTarefa.aberta), 'Ler artigo');
    expect(lerMarca('✓ Ler artigo'), ('Ler artigo', StatusTarefa.feita));
    expect(lerMarca('✕ Ler artigo'), ('Ler artigo', StatusTarefa.cancelada));
    expect(lerMarca('Ler artigo'), ('Ler artigo', StatusTarefa.aberta));
  });

  test('RN21: tarefa sem hora vai como dia inteiro', () {
    final ev = eventoDoItem(ItemParaGoogle.daTarefa(Tarefa(texto: 'Pagar conta', data: '2026-11-03')));
    expect(ev.start!.dateTime, isNull);
    expect(dataTexto(ev.start!.date!), '2026-11-03');
    expect(dataTexto(ev.end!.date!), '2026-11-04');
  });

  test('RN23: o aviso do Google fica desligado e o tipo do app vai junto', () {
    final ev = eventoDoItem(ItemParaGoogle.doEvento(Evento(titulo: 'Aula', data: '2026-11-03', hora: '19:00')));
    expect(ev.reminders!.useDefault, isFalse);
    expect(ev.reminders!.overrides, isEmpty);
    expect(ev.extendedProperties!.private!['meuBujo'], 'evento');
  });

  test('evento com hora vai e volta igual, com a duração', () {
    final t = Tarefa(texto: 'Reunião', data: '2026-11-03', hora: '09:30', status: StatusTarefa.feita);
    final ev = eventoDoItem(ItemParaGoogle.daTarefa(t))
      ..id = 'abc'
      ..updated = DateTime.utc(2026, 10, 29);
    final r = lerEvento(ev, 'agenda1')!;
    expect(r.data, '2026-11-03');
    expect(r.hora, '09:30');
    expect(r.duracaoMin, 30);
    expect(r.tipoBujo, 'tarefa');
    expect(lerMarca(r.titulo), ('Reunião', StatusTarefa.feita));
  });

  test('evento apagado no Google chega marcado como apagado', () {
    final r = lerEvento(cal.Event(id: 'x', status: 'cancelled'), 'agenda1')!;
    expect(r.apagado, isTrue);
  });

  test('a ligação com o Google sobrevive ao salvar no celular', () {
    final t = Tarefa(texto: 'A', data: '2026-11-03')
      ..google = LigacaoGoogle('ag', 'id1', duracaoMin: 45)
      ..sujo = true;
    final volta = Tarefa.fromJson(t.toJson());
    expect(volta.google!.id, 'id1');
    expect(volta.google!.duracaoMin, 45);
    expect(volta.sujo, isTrue);
  });
}
