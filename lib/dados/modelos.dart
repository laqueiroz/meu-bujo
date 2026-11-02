/// Modelos do Meu Bujo. Datas ficam guardadas como texto 'aaaa-mm-dd' e horas como 'hh:mm'.
library;

String dataTexto(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dataDe(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

String _novoId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

/// Antecedência do aviso, em minutos (RN22).
const avisosMinutos = <int>[0, 15, 60, 1440];

String nomeAviso(int minutos) => switch (minutos) {
      0 => 'Na hora',
      15 => '15 min antes',
      60 => '1 h antes',
      1440 => '1 dia antes',
      _ => '$minutos min antes',
    };

enum StatusTarefa { aberta, feita, cancelada }

/// Ligação de um item do app com um evento do Google Calendar (UC23).
class LigacaoGoogle {
  final String agenda;
  final String id;

  /// Duração no Google, pra não encurtar um evento de lá quando o app reenvia.
  int duracaoMin;

  LigacaoGoogle(this.agenda, this.id, {this.duracaoMin = 60});

  Map<String, dynamic> toJson() => {'agenda': agenda, 'id': id, 'duracaoMin': duracaoMin};

  static LigacaoGoogle? fromJson(Object? j) {
    if (j is! Map) return null;
    return LigacaoGoogle(j['agenda'] as String, j['id'] as String, duracaoMin: j['duracaoMin'] as int? ?? 60);
  }
}

/// O que tarefas e eventos têm em comum pra sincronizar (RN16 a RN21).
mixin Sincronizavel {
  LigacaoGoogle? google;

  /// RN20: a usuária disse "não apagar do outro lado"; o item fica só no app.
  bool soNoApp = false;

  /// Mudou no app e ainda não foi pro Google (E1: fica na fila sem internet).
  bool sujo = false;

  /// Última mudança feita no app (RN19: vale a mais recente).
  DateTime editadoEm = DateTime.now();

  /// Marca o item pra ir pro Google na próxima sincronização.
  void tocar() {
    editadoEm = DateTime.now();
    sujo = !soNoApp;
  }

  /// Copia a ligação de uma versão antiga do mesmo item (o formulário cria um objeto novo).
  void herdarLigacao(Sincronizavel antigo) {
    google = antigo.google;
    soNoApp = antigo.soNoApp;
  }

  Map<String, dynamic> sincJson() => {
        'google': google?.toJson(),
        'soNoApp': soNoApp,
        'sujo': sujo,
        'editadoEm': editadoEm.toIso8601String(),
      };

  void lerSinc(Map<String, dynamic> j) {
    google = LigacaoGoogle.fromJson(j['google']);
    soNoApp = j['soNoApp'] as bool? ?? false;
    sujo = j['sujo'] as bool? ?? false;
    editadoEm = DateTime.tryParse(j['editadoEm'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class Subtarefa {
  String texto;
  bool feita;

  Subtarefa(this.texto, {this.feita = false});

  Map<String, dynamic> toJson() => {'texto': texto, 'feita': feita};
  factory Subtarefa.fromJson(Map<String, dynamic> j) => Subtarefa(j['texto'] as String, feita: j['feita'] as bool? ?? false);
}

/// RN01: texto e data obrigatórios; o resto é opcional.
class Tarefa with Sincronizavel {
  final String id;
  String texto;
  String data;
  String? hora;
  int avisoMin;
  bool prioridade;
  String? colecao;
  List<Subtarefa> subtarefas;
  StatusTarefa status;

  /// Datas de onde a tarefa já foi migrada (RN04: lá ela aparece como ">").
  List<String> migradaDe;

  Tarefa({
    String? id,
    required this.texto,
    required this.data,
    this.hora,
    this.avisoMin = 0,
    this.prioridade = false,
    this.colecao,
    List<Subtarefa>? subtarefas,
    this.status = StatusTarefa.aberta,
    List<String>? migradaDe,
  })  : id = id ?? _novoId(),
        subtarefas = subtarefas ?? [],
        migradaDe = migradaDe ?? [];

  int get migracoes => migradaDe.length;
  bool get aberta => status == StatusTarefa.aberta;

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'data': data,
        'hora': hora,
        'avisoMin': avisoMin,
        'prioridade': prioridade,
        'colecao': colecao,
        'subtarefas': subtarefas.map((s) => s.toJson()).toList(),
        'status': status.name,
        'migradaDe': migradaDe,
        ...sincJson(),
      };

  factory Tarefa.fromJson(Map<String, dynamic> j) => Tarefa(
        id: j['id'] as String,
        texto: j['texto'] as String,
        data: j['data'] as String,
        hora: j['hora'] as String?,
        avisoMin: j['avisoMin'] as int? ?? 0,
        prioridade: j['prioridade'] as bool? ?? false,
        colecao: j['colecao'] as String?,
        subtarefas: ((j['subtarefas'] as List?) ?? []).map((e) => Subtarefa.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        status: StatusTarefa.values.byName(j['status'] as String? ?? 'aberta'),
        migradaDe: ((j['migradaDe'] as List?) ?? []).cast<String>(),
      )..lerSinc(j);
}

/// RN06: evento não tem status e não vira pendência.
class Evento with Sincronizavel {
  final String id;
  String titulo;
  String data;
  String? hora;
  int avisoMin;

  Evento({String? id, required this.titulo, required this.data, this.hora, this.avisoMin = 15}) : id = id ?? _novoId();

  Map<String, dynamic> toJson() => {'id': id, 'titulo': titulo, 'data': data, 'hora': hora, 'avisoMin': avisoMin, ...sincJson()};

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        data: j['data'] as String,
        hora: j['hora'] as String?,
        avisoMin: j['avisoMin'] as int? ?? 15,
      )..lerSinc(j);
}

/// Uma agenda da conta Google e como ela entra no app (UC22, RN17).
class AgendaGoogle {
  final String id;
  String nome;
  String? cor;
  bool marcada;
  bool viraTarefa;

  AgendaGoogle({required this.id, required this.nome, this.cor, this.marcada = false, this.viraTarefa = false});

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'cor': cor, 'marcada': marcada, 'viraTarefa': viraTarefa};

  factory AgendaGoogle.fromJson(Map<String, dynamic> j) => AgendaGoogle(
        id: j['id'] as String,
        nome: j['nome'] as String,
        cor: j['cor'] as String?,
        marcada: j['marcada'] as bool? ?? false,
        viraTarefa: j['viraTarefa'] as bool? ?? false,
      );
}

/// Item apagado de um lado, esperando a usuária decidir o outro (RN20).
class ExclusaoPendente {
  final String agenda;
  final String googleId;

  /// Preenchido quando o item foi apagado no Google e ainda existe no app.
  final String? itemId;
  final String titulo;

  ExclusaoPendente({required this.agenda, required this.googleId, this.itemId, required this.titulo});

  Map<String, dynamic> toJson() => {'agenda': agenda, 'googleId': googleId, 'itemId': itemId, 'titulo': titulo};

  factory ExclusaoPendente.fromJson(Map<String, dynamic> j) => ExclusaoPendente(
        agenda: j['agenda'] as String,
        googleId: j['googleId'] as String,
        itemId: j['itemId'] as String?,
        titulo: j['titulo'] as String? ?? '',
      );
}

enum Frequencia { todoDia, diasSemana, vezesPorSemana }

enum TipoHabito { feito, meta }

/// RN07: frequência e tipo. RN08: mudar o hábito não mexe nas marcas antigas.
class Habito {
  final String id;
  String nome;
  Frequencia frequencia;

  /// Dias da semana (1 = segunda ... 7 = domingo), usado em [Frequencia.diasSemana].
  List<int> dias;
  int vezesPorSemana;
  TipoHabito tipo;
  double meta;
  String unidade;
  bool arquivado;

  /// UC16: lembrete diário, só se ainda não estiver marcado.
  bool lembrete;
  String lembreteHora;

  /// Valor marcado em cada dia ('aaaa-mm-dd' -> valor). Para "feito", 1 = feito.
  Map<String, double> marcas;

  Habito({
    String? id,
    required this.nome,
    this.frequencia = Frequencia.todoDia,
    List<int>? dias,
    this.vezesPorSemana = 3,
    this.tipo = TipoHabito.feito,
    this.meta = 1,
    this.unidade = '',
    this.arquivado = false,
    this.lembrete = false,
    this.lembreteHora = '20:00',
    Map<String, double>? marcas,
  })  : id = id ?? _novoId(),
        dias = dias ?? [1, 3, 5],
        marcas = marcas ?? {};

  bool agendadoEm(DateTime dia) => frequencia != Frequencia.diasSemana || dias.contains(dia.weekday);

  double valorEm(String data) => marcas[data] ?? 0;

  bool feitoEm(String data) => tipo == TipoHabito.feito ? valorEm(data) >= 1 : valorEm(data) >= meta;

  // ---- progresso (UC17)

  /// Dias seguidos feitos até hoje. Hoje ainda sem marca não quebra a sequência.
  int sequenciaAtual(DateTime hoje) {
    var dia = soDia(hoje);
    if (!feitoEm(dataTexto(dia))) dia = dia.subtract(const Duration(days: 1));
    var n = 0;
    for (var i = 0; i < 400; i++, dia = dia.subtract(const Duration(days: 1))) {
      if (!agendadoEm(dia)) continue;
      if (!feitoEm(dataTexto(dia))) break;
      n++;
    }
    return n;
  }

  /// Maior sequência no último ano.
  int melhorSequencia(DateTime hoje) {
    var melhor = 0;
    var corrida = 0;
    var dia = soDia(hoje).subtract(const Duration(days: 365));
    for (var i = 0; i <= 365; i++, dia = dia.add(const Duration(days: 1))) {
      if (!agendadoEm(dia)) continue;
      corrida = feitoEm(dataTexto(dia)) ? corrida + 1 : 0;
      if (corrida > melhor) melhor = corrida;
    }
    return melhor;
  }

  /// Fração dos dias agendados do mês (até hoje) em que foi feito. Conta só a partir da primeira marca,
  /// pra um hábito novo não começar com porcentagem baixa.
  double taxaNoMes(DateTime mes, DateTime hoje) {
    if (marcas.isEmpty) return 0;
    final inicio = marcas.keys.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    var agendados = 0;
    var feitos = 0;
    for (var dia = DateTime(mes.year, mes.month); dia.month == mes.month && !dia.isAfter(hoje); dia = dia.add(const Duration(days: 1))) {
      if (!agendadoEm(dia) || dataTexto(dia).compareTo(inicio) < 0) continue;
      agendados++;
      if (feitoEm(dataTexto(dia))) feitos++;
    }
    return agendados == 0 ? 0 : feitos / agendados;
  }

  /// Quanto soma cada toque no botão "+" de um hábito com meta (ex.: 2 L -> 250 ml).
  double get passo => tipo == TipoHabito.meta ? (meta / 8).clamp(0.05, double.infinity) : 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'frequencia': frequencia.name,
        'dias': dias,
        'vezesPorSemana': vezesPorSemana,
        'tipo': tipo.name,
        'meta': meta,
        'unidade': unidade,
        'arquivado': arquivado,
        'lembrete': lembrete,
        'lembreteHora': lembreteHora,
        'marcas': marcas,
      };

  factory Habito.fromJson(Map<String, dynamic> j) => Habito(
        id: j['id'] as String,
        nome: j['nome'] as String,
        frequencia: Frequencia.values.byName(j['frequencia'] as String? ?? 'todoDia'),
        dias: ((j['dias'] as List?) ?? [1, 3, 5]).cast<int>(),
        vezesPorSemana: j['vezesPorSemana'] as int? ?? 3,
        tipo: TipoHabito.values.byName(j['tipo'] as String? ?? 'feito'),
        meta: (j['meta'] as num?)?.toDouble() ?? 1,
        unidade: j['unidade'] as String? ?? '',
        arquivado: j['arquivado'] as bool? ?? false,
        lembrete: j['lembrete'] as bool? ?? false,
        lembreteHora: j['lembreteHora'] as String? ?? '20:00',
        marcas: ((j['marcas'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      );
}

/// Mês como texto 'aaaa-mm'.
String mesTexto(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime mesDe(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]));
}

/// RN27: a semana começa na segunda.
DateTime inicioDaSemana(DateTime d) => soDia(d).subtract(Duration(days: d.weekday - 1));

/// UC14: algo pra um mês futuro, ainda sem dia.
class ItemFuturo {
  final String id;
  String texto;
  String mes;
  bool evento;

  ItemFuturo({String? id, required this.texto, required this.mes, this.evento = false}) : id = id ?? _novoId();

  Map<String, dynamic> toJson() => {'id': id, 'texto': texto, 'mes': mes, 'evento': evento};

  factory ItemFuturo.fromJson(Map<String, dynamic> j) =>
      ItemFuturo(id: j['id'] as String, texto: j['texto'] as String, mes: j['mes'] as String, evento: j['evento'] as bool? ?? false);
}

/// Meta do mês (UC13), um checklist simples.
class Meta {
  String texto;
  bool feita;

  Meta(this.texto, {this.feita = false});

  Map<String, dynamic> toJson() => {'texto': texto, 'feita': feita};
  factory Meta.fromJson(Map<String, dynamic> j) => Meta(j['texto'] as String, feita: j['feita'] as bool? ?? false);
}

/// UC21: reflexão do fim do mês. [humor] guarda o nome de um humor da gatinha.
class Reflexao {
  final String mes;
  String humor;
  List<String> textos;
  DateTime salvaEm;

  Reflexao({required this.mes, this.humor = 'feliz', List<String>? textos, DateTime? salvaEm})
      : textos = textos ?? ['', '', ''],
        salvaEm = salvaEm ?? DateTime.now();

  Map<String, dynamic> toJson() => {'mes': mes, 'humor': humor, 'textos': textos, 'salvaEm': salvaEm.toIso8601String()};

  factory Reflexao.fromJson(Map<String, dynamic> j) => Reflexao(
        mes: j['mes'] as String,
        humor: j['humor'] as String? ?? 'feliz',
        textos: ((j['textos'] as List?) ?? ['', '', '']).cast<String>(),
        salvaEm: DateTime.tryParse(j['salvaEm'] as String? ?? ''),
      );
}

/// Cores de etiqueta das coleções (as mesmas cinco do app).
const coresColecao = <String, String>{
  'pêssego': '#F4B27F',
  'rosa': '#F6A8B3',
  'lilás': '#C9B3EC',
  'menta': '#A8DCC4',
  'céu': '#A9CDEE',
};

String formatarNumero(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return s.replaceAll('.', ',');
}
