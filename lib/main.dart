import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'dados/estado.dart';
import 'dados/notificacoes.dart';
import 'dados/segundo_plano.dart';
import 'dados/widget_casa.dart';
import 'tema.dart';
import 'telas/entrar.dart';
import 'telas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  final estado = EstadoApp();
  await estado.carregar();
  await Notificacoes.instancia.iniciar();
  await SegundoPlano.iniciar();
  SegundoPlano.ajustar(ligado: estado.agendaConectada); // RN25
  runApp(ChangeNotifierProvider.value(value: estado, child: const MeuBujoApp()));
  WidgetsBinding.instance.addObserver(estado); // sincroniza a agenda ao voltar pro app
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Notificacoes.instancia.pedirPermissao();
    estado.reagendarDiarios(); // resumo do dia e lembretes de hábito (UC15, UC16)
    WidgetCasa.atualizar(estado); // widget da tela inicial (UC25)
    HomeWidget.registerInteractivityCallback(toqueNoWidget);
    estado.reconectar(); // volta pra conta Google sem perguntar (UC11)
  });
}

class MeuBujoApp extends StatelessWidget {
  const MeuBujoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    return MaterialApp(
      title: 'Meu Bujo',
      debugShowCheckedModeBanner: false,
      theme: temaBujo(e.paleta, escuro: false),
      darkTheme: temaBujo(e.paleta, escuro: true),
      themeMode: e.tema,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: e.comecou ? const TelaInicio() : const TelaEntrar(),
    );
  }
}
