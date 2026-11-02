import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_bujo/dados/estado.dart';
import 'package:meu_bujo/dados/estatisticas.dart';
import 'package:meu_bujo/dados/modelos.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Tarefa t(String data, {StatusTarefa s = StatusTarefa.aberta, String? col, List<String>? migrada}) =>
      Tarefa(texto: 'x', data: data, status: s, colecao: col, migradaDe: migrada);

  test('UC20: semana conta feitas, abertas, canceladas e migradas', () {
    final ts = [
      t('2026-10-26', s: StatusTarefa.feita, col: 'Fatec'),
      t('2026-10-26', col: 'Fatec'),
      t('2026-10-28', s: StatusTarefa.feita, col: 'Casa'),
      t('2026-10-29', s: StatusTarefa.cancelada),
      t('2026-11-02', s: StatusTarefa.feita), // semana seguinte
      t('2026-10-30', migrada: ['2026-10-27', '2026-10-20']),
    ];
    final s = Estatisticas.daSemana(ts, DateTime(2026, 10, 30));
    expect(s.feitas, 2);
    expect(s.abertas, 2);
    expect(s.canceladas, 1);
    expect(s.migradas, 1); // só a migração de 27/10 cai nessa semana
    expect(s.taxa, 50);
    expect(s.colunas.first, ('seg', 1, 1));
    expect(s.porColecao.firstWhere((c) => c.$1 == 'Fatec'), ('Fatec', 1, 2));
  });

  test('UC20: o mês vira colunas por semana, cortadas no começo e no fim', () {
    final s = Estatisticas.doMes([], DateTime(2026, 10));
    expect(s.colunas.map((c) => c.$1), ['1–4', '5–11', '12–18', '19–25', '26–31']);
  });

  test('UC20: avisa tarefa migrada 3 vezes', () {
    final s = Estatisticas.daSemana([t('2026-10-30', migrada: ['2026-10-20', '2026-10-25', '2026-10-28'])], DateTime(2026, 10, 30));
    expect(s.alertas.single, contains('migrada 3 vezes'));
  });

  test('UC19: renomear leva as tarefas junto; apagar deixa as tarefas sem coleção', () {
    final a = t('2026-10-30', col: 'Fatec');
    final e = EstadoApp()
      ..colecoes = ['Fatec', 'Casa']
      ..tarefas = [a];
    expect(e.renomearColecao('Fatec', 'casa'), isNotNull); // nome repetido
    expect(e.renomearColecao('Fatec', 'Faculdade'), isNull);
    expect(e.colecoes, ['Faculdade', 'Casa']);
    expect(a.colecao, 'Faculdade');
    e.apagarColecao('Faculdade');
    expect(e.colecoes, ['Casa']);
    expect(a.colecao, isNull);
    expect(e.tarefas, [a]);
  });

  test('UC21: salvar reflexão vira metas do mês seguinte, sem repetir', () {
    final pendente = Meta('Ler 2 livros');
    final e = EstadoApp()..metas = {'2026-10': [pendente, Meta('Treinar', feita: true)]};
    e.salvarReflexao(DateTime(2026, 10), humor: 'feliz', textos: ['ok', '', 'Terminar o capítulo 2\nLer 2 livros'], levar: [pendente]);
    expect(e.reflexoes['2026-10']!.humor, 'feliz');
    expect(e.metas['2026-11']!.map((m) => m.texto), ['Terminar o capítulo 2', 'Ler 2 livros']);
    // salvar de novo não duplica
    e.salvarReflexao(DateTime(2026, 10), humor: 'bem', textos: ['ok', '', 'Terminar o capítulo 2\nLer 2 livros'], levar: [pendente]);
    expect(e.metas['2026-11']!.length, 2);
  });
}
