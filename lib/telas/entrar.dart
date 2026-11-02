import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dados/estado.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/gatinha.dart';

/// Primeira tela: entrar com Google (UC11) ou continuar só no celular.
class TelaEntrar extends StatelessWidget {
  const TelaEntrar({super.key});

  Future<void> _entrar(BuildContext context, EstadoApp e) async {
    final erro = await e.entrarComGoogle();
    if (erro != null) e.reagir(Humor.preocupada, erro);
  }

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EstadoApp>();
    final c = context.cores;
    return Scaffold(
      body: FundoPontilhado(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(children: [
              const Spacer(),
              Balao(e.falaDoMomento ?? 'Oi! Vamos organizar seu dia?'),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'Fazer carinho na gatinha',
                child: GestureDetector(onTap: e.fazerCarinho, child: Gatinha(humor: e.humorDoMomento ?? Humor.feliz, tamanho: 170)),
              ),
              const SizedBox(height: 12),
              Text('Meu Bujo', style: titulo(context, 44)),
              const SizedBox(height: 8),
              Text(
                'tarefas, eventos e hábitos num lugar só, sem esquecer de nada',
                textAlign: TextAlign.center,
                style: corpo(context, tamanho: 17, peso: FontWeight.w600, cor: c.textoSuave),
              ),
              const SizedBox(height: 24),
              Cartao(
                child: Wrap(spacing: 24, runSpacing: 8, alignment: WrapAlignment.center, children: [
                  for (final par in const [('•', 'tarefa'), ('○', 'evento'), ('×', 'feita'), ('>', 'migrada')])
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(par.$1, style: titulo(context, 20)),
                      const SizedBox(width: 8),
                      Text(par.$2, style: corpo(context)),
                    ]),
                ]),
              ),
              const Spacer(),
              if (e.sincronizando)
                const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
              else ...[
                BotaoFofo('Entrar com Google', largo: true, onPressed: () => _entrar(context, e)),
                const SizedBox(height: 10),
                BotaoFofo('Continuar sem conta', largo: true, estilo: EstiloBotao.fantasma, onPressed: e.comecar),
              ],
              const SizedBox(height: 12),
              Text(
                'Com a conta Google, seus dados ficam guardados numa pasta escondida do seu Drive. Trocou de celular? É só entrar de novo.',
                textAlign: TextAlign.center,
                style: corpo(context, tamanho: 13, peso: FontWeight.w600, cor: c.textoSuave),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
