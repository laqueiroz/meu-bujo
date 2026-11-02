import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_bujo/dados/estado.dart';
import 'package:meu_bujo/dados/modelos.dart';
import 'package:meu_bujo/dados/widget_casa.dart';

void main() {
  final hoje = DateTime(2026, 10, 29); // quinta-feira
  String dia(int n) => dataTexto(DateTime(2026, 10, n));

  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('UC17: sequência atual não quebra por hoje ainda não marcado', () {
    final h = Habito(nome: 'Ler')..marcas = {dia(26): 1, dia(27): 1, dia(28): 1};
    expect(h.sequenciaAtual(hoje), 3);
    h.marcas[dia(29)] = 1;
    expect(h.sequenciaAtual(hoje), 4);
  });

  test('UC17: dias de folga não quebram a sequência', () {
    // segunda, quarta e sexta
    final h = Habito(nome: 'Treino', frequencia: Frequencia.diasSemana, dias: [1, 3, 5])
      ..marcas = {dia(23): 1, dia(26): 1, dia(28): 1};
    expect(h.sequenciaAtual(hoje), 3);
    expect(h.melhorSequencia(hoje), 3);
  });

  test('UC17: porcentagem do mês conta só até hoje', () {
    final h = Habito(nome: 'Ler');
    for (var n = 1; n <= 29; n += 2) {
      h.marcas[dia(n)] = 1;
    }
    expect(h.taxaNoMes(DateTime(2026, 10), hoje), closeTo(15 / 29, 0.001));
  });

  test('RN27: a semana começa na segunda', () {
    expect(inicioDaSemana(hoje), DateTime(2026, 10, 26));
    expect(inicioDaSemana(DateTime(2026, 11, 1)), DateTime(2026, 10, 26)); // domingo
  });

  test('UC15: resumo conta eventos, tarefas abertas e pendências', () {
    final e = EstadoApp()
      ..tarefas = [
        Tarefa(texto: 'A', data: dia(29)),
        Tarefa(texto: 'B', data: dia(29), status: StatusTarefa.feita),
        Tarefa(texto: 'C', data: dia(27)),
      ]
      ..eventos = [Evento(titulo: 'Prova', data: dia(29))];
    expect(e.textoResumo(hoje), 'Hoje tem 1 evento e 1 tarefa. 1 pendência pra revisar.');
    expect(e.textoResumo(DateTime(2026, 10, 30)), 'Dia livre por enquanto ♡ 2 pendências pra revisar.');
  });

  test('UC15 + UC14: no dia 1º o resumo lembra do future log', () {
    final e = EstadoApp()..futuro = [ItemFuturo(texto: 'Renovar CNH', mes: '2026-11')];
    expect(e.textoResumo(DateTime(2026, 11, 1)), contains('future log guardou 1 item'));
  });

  test('UC25: no widget as abertas vêm antes das feitas, e as mais recentes primeiro', () {
    final hojeTexto = dataTexto(soDia(DateTime.now()));
    Tarefa t(String texto, int minutos, {bool feita = false, bool prio = false}) => Tarefa(
          texto: texto,
          data: hojeTexto,
          prioridade: prio,
          status: feita ? StatusTarefa.feita : StatusTarefa.aberta,
        )..editadoEm = DateTime(2026, 10, 29, 8, minutos);
    final e = EstadoApp()
      ..tarefas = [
        t('feita antiga', 1, feita: true),
        t('aberta antiga', 2),
        t('feita recente', 3, feita: true),
        t('aberta recente', 4),
        t('prioritária', 0, prio: true),
        Tarefa(texto: 'cancelada', data: hojeTexto, status: StatusTarefa.cancelada),
      ];
    expect(WidgetCasa.tarefasDoWidget(e).map((x) => x.texto), ['prioritária', 'aberta recente', 'aberta antiga', 'feita recente', 'feita antiga']);
  });

  test('UC14: passar do future log pro dia vira tarefa e sai do future log', () {
    final f = ItemFuturo(texto: 'Renovar CNH', mes: '2026-11');
    final e = EstadoApp()..futuro = [f];
    e.agendarFuturo(f, DateTime(2026, 11, 5));
    expect(e.futuro, isEmpty);
    expect(e.tarefas.single.texto, 'Renovar CNH');
    expect(e.tarefas.single.data, '2026-11-05');
  });
}
