import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bujo/dados/estado.dart';
import 'package:meu_bujo/dados/modelos.dart';

void main() {
  late EstadoApp e;
  final hoje = soDia(DateTime.now());
  final ontem = hoje.subtract(const Duration(days: 1));
  final amanha = hoje.add(const Duration(days: 1));

  setUp(() => e = EstadoApp());

  test('RN10: pendência é tarefa aberta de antes de hoje', () {
    final atrasada = Tarefa(texto: 'Lavar roupa', data: dataTexto(ontem));
    final feita = Tarefa(texto: 'Pagar luz', data: dataTexto(ontem), status: StatusTarefa.feita);
    final deHoje = Tarefa(texto: 'Ler artigo', data: dataTexto(hoje));
    e.tarefas = [atrasada, feita, deHoje];
    expect(e.pendencias, [atrasada]);
  });

  test('UC09 / RN04: migrar muda a data e lembra de onde saiu', () {
    final t = Tarefa(texto: 'Lavar roupa', data: dataTexto(ontem));
    e.tarefas = [t];
    e.migrar(t, hoje);
    expect(t.data, dataTexto(hoje));
    expect(t.migradaDe, [dataTexto(ontem)]);
    expect(e.migradasDoDia(dataTexto(ontem)), [t]);
    expect(e.pendencias, isEmpty);
  });

  test('RN12: não dá pra migrar pro passado', () {
    final t = Tarefa(texto: 'X', data: dataTexto(hoje));
    e.tarefas = [t];
    expect(() => e.migrar(t, ontem), throwsArgumentError);
  });

  test('RN28: avisa a partir da 3ª migração', () {
    final t = Tarefa(texto: 'E-mail', data: dataTexto(hoje), migradaDe: ['2026-10-20']);
    expect(e.deveAvisarMigracao(t), isFalse);
    t.migradaDe.add('2026-10-26');
    expect(e.deveAvisarMigracao(t), isTrue);
  });

  test('RN09: marca hábito até 7 dias atrás, mas não no futuro nem antes disso', () {
    final h = Habito(nome: 'Ler');
    e.habitos = [h];
    e.alternarHabito(h, ontem);
    expect(h.feitoEm(dataTexto(ontem)), isTrue);
    e.alternarHabito(h, amanha);
    expect(h.feitoEm(dataTexto(amanha)), isFalse);
    final seteAtras = DateTime(hoje.year, hoje.month, hoje.day - 7);
    final oitoAtras = DateTime(hoje.year, hoje.month, hoje.day - 8);
    e.alternarHabito(h, seteAtras);
    expect(h.feitoEm(dataTexto(seteAtras)), isTrue);
    e.alternarHabito(h, oitoAtras);
    expect(h.feitoEm(dataTexto(oitoAtras)), isFalse);
  });

  test('RN03: prioritárias primeiro; feitas por último', () {
    final a = Tarefa(texto: 'a', data: dataTexto(hoje));
    final b = Tarefa(texto: 'b', data: dataTexto(hoje), prioridade: true);
    final c = Tarefa(texto: 'c', data: dataTexto(hoje), status: StatusTarefa.feita, prioridade: true);
    e.tarefas = [a, c, b];
    expect(e.tarefasDoDia(dataTexto(hoje)), [b, a, c]);
  });

  test('hábito com meta: soma e conta como feito ao bater a meta', () {
    final agua = Habito(nome: 'Água', tipo: TipoHabito.meta, meta: 2, unidade: 'L');
    e.habitos = [agua];
    for (var i = 0; i < 8; i++) {
      e.somarHabito(agua, hoje, agua.passo);
    }
    expect(agua.valorEm(dataTexto(hoje)), 2);
    expect(agua.feitoEm(dataTexto(hoje)), isTrue);
  });
}
