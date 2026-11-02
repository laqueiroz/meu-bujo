import 'estado.dart';
import 'modelos.dart';

/// Modo demonstração, usado pros prints do README. Liga com --dart-define=DEMO=true.
/// Tudo aqui é inventado: nenhum dado de pessoa de verdade.
const modoDemonstracao = bool.fromEnvironment('DEMO');

void preencherExemplo(EstadoApp e) {
  final hoje = soDia(DateTime.now());
  String dia(int n) => dataTexto(DateTime(hoje.year, hoje.month, hoje.day + n));

  e.colecoes = ['Faculdade', 'Trabalho', 'Casa'];
  e.coresColecoes = {'Faculdade': '#C9B3EC', 'Trabalho': '#A9CDEE', 'Casa': '#A8DCC4'};

  Tarefa t(String texto, int d, {String? col, String? hora, bool feita = false, bool prio = false}) => Tarefa(
        texto: texto,
        data: dia(d),
        colecao: col,
        hora: hora,
        prioridade: prio,
        status: feita ? StatusTarefa.feita : StatusTarefa.aberta,
      );

  e.tarefas = [
    t('Entregar o relatório de estágio', 0, col: 'Faculdade', prio: true),
    t('Ler o capítulo 3 de Engenharia de Software', 0, col: 'Faculdade'),
    t('Comprar ração da gata', 0, col: 'Casa', hora: '18:00'),
    t('Responder os e-mails da equipe', 0, col: 'Trabalho', feita: true),
    t('Lavar roupa', -1, col: 'Casa', feita: true),
    t('Revisar slides da apresentação', -1, col: 'Trabalho', feita: true),
    t('Estudar para a prova de algoritmos', -2, col: 'Faculdade', feita: true),
    t('Pagar a conta de luz', -2, col: 'Casa', feita: true),
    t('Montar o cronograma do TCC', -3, col: 'Faculdade'),
    t('Organizar a mesa', 1, col: 'Casa'),
    t('Reunião de planejamento', 2, col: 'Trabalho', hora: '10:00'),
  ];
  e.eventos = [
    Evento(titulo: 'Aula de Banco de Dados', data: dia(0), hora: '19:00'),
    Evento(titulo: 'Dentista', data: dia(1), hora: '09:30'),
    Evento(titulo: 'Aniversário da Bia', data: dia(3), hora: '20:00'),
  ];

  final agua = Habito(nome: 'Beber água', tipo: TipoHabito.meta, meta: 2, unidade: 'L', lembrete: true);
  final leitura = Habito(nome: 'Ler 20 min');
  final treino = Habito(nome: 'Treino', frequencia: Frequencia.diasSemana, dias: [1, 3, 5]);
  for (var i = 1; i <= 20; i++) {
    final d = DateTime(hoje.year, hoje.month, hoje.day - i);
    if (i % 6 != 0) agua.marcas[dataTexto(d)] = 2;
    if (i <= 9 || i % 3 != 0) leitura.marcas[dataTexto(d)] = 1;
    if (treino.agendadoEm(d) && i % 5 != 0) treino.marcas[dataTexto(d)] = 1;
  }
  agua.marcas[dataTexto(hoje)] = 1.25;
  e.habitos = [agua, leitura, treino];

  e.focos = {dataTexto(inicioDaSemana(hoje)): 'Terminar o relatório de estágio ♡'};
  e.metas = {
    mesTexto(hoje): [Meta('Fechar o relatório de estágio'), Meta('Treinar 12 vezes', feita: true), Meta('Ler um livro')],
  };
  e.futuro = [
    ItemFuturo(texto: 'Renovar a CNH', mes: mesTexto(DateTime(hoje.year, hoje.month + 1))),
    ItemFuturo(texto: 'Viagem pra praia', mes: mesTexto(DateTime(hoje.year, hoje.month + 1)), evento: true),
    ItemFuturo(texto: 'Comprar presentes de Natal', mes: mesTexto(DateTime(hoje.year, hoje.month + 2))),
  ];
  e.comecou = true;
}
