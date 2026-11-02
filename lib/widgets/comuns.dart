import 'package:flutter/material.dart';

import '../tema.dart';
import 'gatinha.dart';

/// Fundo creme com pontinhos de caderno.
class FundoPontilhado extends StatelessWidget {
  final Widget child;
  const FundoPontilhado({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return CustomPaint(painter: _Pontos(c.ponto), child: Container(color: Colors.transparent, child: child));
  }
}

class _Pontos extends CustomPainter {
  final Color cor;
  _Pontos(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = cor;
    for (double y = 10; y < size.height; y += 20) {
      for (double x = 10; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1.3, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Pontos antigo) => antigo.cor != cor;
}

/// Cartão "adesivo": contorno grosso na cor da paleta e sombra dura.
class Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? cor;
  final bool sombra;
  final VoidCallback? onTap;

  const Cartao({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.cor, this.sombra = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final caixa = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cor ?? c.cartao,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.linha, width: 2.5),
        boxShadow: sombra ? [BoxShadow(color: c.linha, offset: const Offset(0, 4))] : null,
      ),
      child: child,
    );
    if (onTap == null) return caixa;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: caixa);
  }
}

enum EstiloBotao { principal, fantasma, rosa }

class BotaoFofo extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final EstiloBotao estilo;
  final bool largo;

  const BotaoFofo(this.texto, {super.key, this.onPressed, this.estilo = EstiloBotao.principal, this.largo = false});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final fundo = switch (estilo) {
      EstiloBotao.principal => c.destaque,
      EstiloBotao.rosa => c.segunda,
      EstiloBotao.fantasma => c.cartao,
    };
    final corTexto = estilo == EstiloBotao.fantasma ? c.texto : corTextoSobreDestaque;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: largo ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.linha, width: 2.5),
            boxShadow: [BoxShadow(color: c.linha, offset: const Offset(0, 3))],
          ),
          child: Text(texto, textAlign: TextAlign.center, style: titulo(context, 17, cor: corTexto)),
        ),
      ),
    );
  }
}

class ChipFofo extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback? onTap;

  const ChipFofo(this.texto, {super.key, this.selecionado = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      selected: selecionado,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selecionado ? c.destaque : c.cartao,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.linha, width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(texto, style: corpo(context, tamanho: 14, cor: selecionado ? corTextoSobreDestaque : c.texto)),
          ]),
        ),
      ),
    );
  }
}

/// Grupo de chips em que só um fica marcado.
class EscolhaUnica<T> extends StatelessWidget {
  final List<T> opcoes;
  final T? valor;
  final String Function(T) rotulo;
  final ValueChanged<T> onChanged;

  const EscolhaUnica({super.key, required this.opcoes, required this.valor, required this.rotulo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in opcoes) ChipFofo(rotulo(o), selecionado: o == valor, onTap: () => onChanged(o)),
    ]);
  }
}

class Interruptor extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;
  final String rotulo;

  const Interruptor({super.key, required this.valor, required this.onChanged, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      toggled: valor,
      label: rotulo,
      child: GestureDetector(
        onTap: () => onChanged(!valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 56,
          height: 34,
          padding: const EdgeInsets.all(3),
          alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: valor ? c.destaque : c.cartao,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.linha, width: 2),
          ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: c.linha, width: 2)),
          ),
        ),
      ),
    );
  }
}

/// Balão de fala da gatinha, com a "pontinha" virada pra ela.
class Balao extends StatelessWidget {
  final String texto;
  const Balao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: -7,
        top: 18,
        child: Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: c.cartao,
              border: Border(left: BorderSide(color: c.linha, width: 2.5), bottom: BorderSide(color: c.linha, width: 2.5)),
            ),
          ),
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: c.cartao, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.linha, width: 2.5)),
        child: Semantics(liveRegion: true, child: Text(texto, style: titulo(context, 15).copyWith(fontWeight: FontWeight.w600))),
      ),
    ]);
  }
}

/// Gatinha + balão, usado no topo de quase todas as telas.
class GatinhaFalando extends StatelessWidget {
  final Humor humor;
  final String fala;
  final double tamanho;
  final VoidCallback? onTap;

  const GatinhaFalando({super.key, required this.humor, required this.fala, this.tamanho = 70, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(children: [
        Semantics(
          button: true,
          label: 'Fazer carinho na gatinha',
          child: GestureDetector(onTap: onTap, child: Gatinha(humor: humor, tamanho: tamanho)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Balao(fala)),
      ]),
    );
  }
}

/// Copinho d'água com carinha, que enche conforme o progresso (0 a 1).
class Copo extends StatelessWidget {
  final double progresso;
  final double largura;

  const Copo({super.key, required this.progresso, this.largura = 64});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final altura = largura * 86 / 64;
    final p = progresso.clamp(0.0, 1.0);
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: c.cartao,
        border: Border.all(color: c.linha, width: 3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(largura * 0.12),
          topRight: Radius.circular(largura * 0.12),
          bottomLeft: Radius.circular(largura * 0.34),
          bottomRight: Radius.circular(largura * 0.34),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            height: (altura - 6) * p,
            width: double.infinity,
            color: corAgua,
          ),
        ),
        // carinha do copo
        Positioned(left: largura * 0.30, top: altura * 0.42, child: _ponto(6, corTextoSobreDestaque)),
        Positioned(left: largura * 0.53, top: altura * 0.42, child: _ponto(6, corTextoSobreDestaque)),
        Positioned(left: largura * 0.17, top: altura * 0.52, child: _bochecha()),
        Positioned(left: largura * 0.60, top: altura * 0.52, child: _bochecha()),
      ]),
    );
  }

  Widget _ponto(double t, Color cor) => Container(width: t, height: t, decoration: BoxDecoration(color: cor, shape: BoxShape.circle));
  Widget _bochecha() => Container(width: 9, height: 5, decoration: BoxDecoration(color: const Color(0xFFF6A8B3), borderRadius: BorderRadius.circular(5)));
}

/// Título de seção ("eventos", "tarefas"...).
class TituloSecao extends StatelessWidget {
  final String texto;
  const TituloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Semantics(header: true, child: Text(texto, style: titulo(context, 16, cor: context.cores.textoSuave))),
      );
}

/// Botão quadrado com ícone, sempre com rótulo de acessibilidade.
class BotaoIcone extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback? onTap;
  final Color? fundo;

  const BotaoIcone(this.icone, {super.key, required this.rotulo, this.onTap, this.fundo});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      label: rotulo,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: fundo ?? c.cartao, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.linha, width: 2)),
          child: Icon(icone, color: c.texto, size: 22),
        ),
      ),
    );
  }
}

/// Topo das telas internas: voltar + título + ação opcional.
class Topo extends StatelessWidget {
  final String texto;
  final Widget? acao;
  const Topo(this.texto, {super.key, this.acao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(children: [
        BotaoIcone(Icons.arrow_back_rounded, rotulo: 'Voltar', onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(child: Text(texto, style: titulo(context, 28))),
        if (acao != null) acao!,
      ]),
    );
  }
}

/// Rodapé fixo com o botão principal (Salvar).
class RodapeBotao extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  const RodapeBotao(this.texto, {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(color: c.cartao, border: Border(top: BorderSide(color: c.linha, width: 2.5))),
      child: BotaoFofo(texto, onPressed: onPressed, largo: true),
    );
  }
}

/// Caixinha de check (tarefa feita, meta do mês).
class CaixaCheck extends StatelessWidget {
  final bool feita;
  final String rotulo;
  final VoidCallback onTap;

  const CaixaCheck({super.key, required this.feita, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      checked: feita,
      label: feita ? 'Desmarcar $rotulo' : 'Marcar $rotulo como feita',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: feita ? c.destaque : c.cartao,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.linha, width: 2.5),
              ),
              child: feita ? const Icon(Icons.check_rounded, size: 18, color: corTextoSobreDestaque) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Resposta da confirmação de exclusão.
enum Exclusao { cancelar, soAqui, aquiEnoGoogle }

/// RN05: excluir pede confirmação. RN20: se o item está no Google, pergunta se apaga lá também.
Future<Exclusao> confirmarExclusao(BuildContext context, {required String oQue, required bool noGoogle}) async {
  final r = await showDialog<Exclusao>(
    context: context,
    builder: (ctx) {
      final c = ctx.cores;
      return AlertDialog(
        backgroundColor: c.cartao,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: c.linha, width: 2.5)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Gatinha(humor: Humor.preocupada, tamanho: 90),
          const SizedBox(height: 10),
          Text(
            noGoogle ? 'Excluir $oQue? Esse item também está no Google Agenda.' : 'Excluir $oQue? Não dá pra desfazer.',
            textAlign: TextAlign.center,
            style: titulo(ctx, 17),
          ),
          const SizedBox(height: 16),
          if (noGoogle) ...[
            BotaoFofo('Excluir daqui e do Google', largo: true, estilo: EstiloBotao.rosa, onPressed: () => Navigator.pop(ctx, Exclusao.aquiEnoGoogle)),
            const SizedBox(height: 10),
            BotaoFofo('Excluir só daqui', largo: true, estilo: EstiloBotao.fantasma, onPressed: () => Navigator.pop(ctx, Exclusao.soAqui)),
          ] else
            BotaoFofo('Excluir', largo: true, estilo: EstiloBotao.rosa, onPressed: () => Navigator.pop(ctx, Exclusao.soAqui)),
          TextButton(onPressed: () => Navigator.pop(ctx, Exclusao.cancelar), child: Text('Voltar', style: corpo(ctx))),
        ]),
      );
    },
  );
  return r ?? Exclusao.cancelar;
}

class Rotulo extends StatelessWidget {
  final String texto;
  const Rotulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto, style: corpo(context, tamanho: 13, cor: context.cores.textoSuave)),
      );
}
