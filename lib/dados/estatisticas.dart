import 'modelos.dart';

/// UC20: números das tarefas num período (semana ou mês). Funções puras, testadas em test/estatisticas_test.dart.
/// O dia que conta é a data da tarefa: concluir mais tarde não muda o dia em que ela foi planejada.
class Estatisticas {
  final int feitas;
  final int abertas;
  final int canceladas;
  final int migradas;

  /// Uma coluna do gráfico: rótulo, feitas e as que ficaram abertas.
  final List<(String, int, int)> colunas;

  /// Por coleção: nome, feitas e total (sem as canceladas).
  final List<(String, int, int)> porColecao;

  /// Coisas pra ficar de olho (tarefa migrada demais, coleção acumulando).
  final List<String> alertas;

  Estatisticas({
    required this.feitas,
    required this.abertas,
    required this.canceladas,
    required this.migradas,
    required this.colunas,
    required this.porColecao,
    required this.alertas,
  });

  int get total => feitas + abertas;

  /// Quanto do que foi anotado virou feito (0 a 100).
  int get taxa => total == 0 ? 0 : (feitas * 100 / total).round();

  /// Semana de segunda a domingo (RN27): uma coluna por dia.
  static Estatisticas daSemana(List<Tarefa> tarefas, DateTime qualquerDia) {
    final ini = inicioDaSemana(qualquerDia);
    const nomes = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    final dias = [for (var i = 0; i < 7; i++) DateTime(ini.year, ini.month, ini.day + i)];
    return _calcular(tarefas, dias.first, dias.last, [
      for (var i = 0; i < 7; i++) (nomes[i], dataTexto(dias[i]), dataTexto(dias[i])),
    ]);
  }

  /// Mês inteiro: uma coluna por semana (cortada no começo e no fim do mês).
  static Estatisticas doMes(List<Tarefa> tarefas, DateTime mes) {
    final primeiro = DateTime(mes.year, mes.month);
    final ultimo = DateTime(mes.year, mes.month + 1, 0);
    final colunas = <(String, String, String)>[];
    var ini = primeiro;
    while (!ini.isAfter(ultimo)) {
      var fim = DateTime(ini.year, ini.month, ini.day + (7 - ini.weekday));
      if (fim.isAfter(ultimo)) fim = ultimo;
      colunas.add((ini.day == fim.day ? '${ini.day}' : '${ini.day}–${fim.day}', dataTexto(ini), dataTexto(fim)));
      ini = DateTime(fim.year, fim.month, fim.day + 1);
    }
    return _calcular(tarefas, primeiro, ultimo, colunas);
  }

  static Estatisticas _calcular(List<Tarefa> tarefas, DateTime de, DateTime ate, List<(String, String, String)> faixas) {
    final a = dataTexto(de);
    final b = dataTexto(ate);
    bool dentro(String d) => d.compareTo(a) >= 0 && d.compareTo(b) <= 0;
    final doPeriodo = tarefas.where((t) => dentro(t.data)).toList();
    final validas = doPeriodo.where((t) => t.status != StatusTarefa.cancelada).toList();

    final colunas = [
      for (final (nome, ini, fim) in faixas)
        (
          nome,
          validas.where((t) => !t.aberta && t.data.compareTo(ini) >= 0 && t.data.compareTo(fim) <= 0).length,
          validas.where((t) => t.aberta && t.data.compareTo(ini) >= 0 && t.data.compareTo(fim) <= 0).length,
        ),
    ];

    final grupos = <String, (int, int)>{};
    for (final t in validas) {
      final nome = t.colecao ?? 'Sem coleção';
      final (f, n) = grupos[nome] ?? (0, 0);
      grupos[nome] = (f + (t.aberta ? 0 : 1), n + 1);
    }
    final porColecao = [for (final e in grupos.entries) (e.key, e.value.$1, e.value.$2)]
      ..sort((x, y) => y.$3.compareTo(x.$3));

    final alertas = <String>[];
    for (final t in tarefas.where((t) => t.aberta && t.migracoes >= 3)) {
      alertas.add('“${t.texto}” já foi migrada ${t.migracoes} vezes. Ainda vale a pena?');
    }
    final acumulada = porColecao.where((c) => c.$1 != 'Sem coleção' && c.$3 - c.$2 >= 5).firstOrNull;
    if (acumulada != null) alertas.add('${acumulada.$1} ficou com ${acumulada.$3 - acumulada.$2} tarefas abertas no período.');

    return Estatisticas(
      feitas: validas.where((t) => !t.aberta).length,
      abertas: validas.where((t) => t.aberta).length,
      canceladas: doPeriodo.length - validas.length,
      migradas: tarefas.fold(0, (n, t) => n + t.migradaDe.where(dentro).length),
      colunas: colunas,
      porColecao: porColecao,
      alertas: alertas,
    );
  }
}
