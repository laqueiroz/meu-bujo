import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uma das 5 paletas pastel (RN30). Os contornos seguem a paleta.
class Paleta {
  final String id;
  final String nome;
  final Color fundo;
  final Color destaque;
  final Color destaqueSuave;
  final Color segunda;
  final Color segundaSuave;
  final Color ponto;
  final Color linha;

  const Paleta({
    required this.id,
    required this.nome,
    required this.fundo,
    required this.destaque,
    required this.destaqueSuave,
    required this.segunda,
    required this.segundaSuave,
    required this.ponto,
    required this.linha,
  });
}

const paletas = <Paleta>[
  Paleta(id: 'pessego', nome: 'Pêssego', fundo: Color(0xFFFFF6EC), destaque: Color(0xFFF4B27F), destaqueSuave: Color(0xFFFDE3CC), segunda: Color(0xFFF6A8B3), segundaSuave: Color(0xFFFCE4E8), ponto: Color(0xFFEBD3BE), linha: Color(0xFFC9753F)),
  Paleta(id: 'rosa', nome: 'Rosa', fundo: Color(0xFFFFF4F6), destaque: Color(0xFFF6A8B3), destaqueSuave: Color(0xFFFCE1E6), segunda: Color(0xFFF4C58F), segundaSuave: Color(0xFFFDEBD6), ponto: Color(0xFFF0D0D6), linha: Color(0xFFC9566E)),
  Paleta(id: 'lilas', nome: 'Lilás', fundo: Color(0xFFF9F5FF), destaque: Color(0xFFC9B3EC), destaqueSuave: Color(0xFFEEE5FB), segunda: Color(0xFFF6B8CC), segundaSuave: Color(0xFFFCE6EE), ponto: Color(0xFFDDD0F0), linha: Color(0xFF8A6BC4)),
  Paleta(id: 'menta', nome: 'Menta', fundo: Color(0xFFF3FBF6), destaque: Color(0xFFA8DCC4), destaqueSuave: Color(0xFFE1F5EC), segunda: Color(0xFFF6C1A8), segundaSuave: Color(0xFFFDE9DF), ponto: Color(0xFFCFE7DA), linha: Color(0xFF3F9A78)),
  Paleta(id: 'ceu', nome: 'Céu', fundo: Color(0xFFF4F9FE), destaque: Color(0xFFA9CDEE), destaqueSuave: Color(0xFFE2F0FB), segunda: Color(0xFFF7C6D3), segundaSuave: Color(0xFFFCE8EE), ponto: Color(0xFFD2E2F0), linha: Color(0xFF4A86C0)),
];

Paleta paletaPorId(String id) => paletas.firstWhere((p) => p.id == id, orElse: () => paletas.first);

/// Texto sobre as cores de destaque: sempre o cinza-ameixa escuro.
const corTextoSobreDestaque = Color(0xFF4B3F5C);
const corAgua = Color(0xFFA9D8F5);

/// Cores do app, lidas com `context.cores`.
class BujoCores extends ThemeExtension<BujoCores> {
  final Color fundo;
  final Color cartao;
  final Color texto;
  final Color textoSuave;
  final Color destaque;
  final Color destaqueSuave;
  final Color segunda;
  final Color segundaSuave;
  final Color linha;
  final Color ponto;

  const BujoCores({
    required this.fundo,
    required this.cartao,
    required this.texto,
    required this.textoSuave,
    required this.destaque,
    required this.destaqueSuave,
    required this.segunda,
    required this.segundaSuave,
    required this.linha,
    required this.ponto,
  });

  factory BujoCores.de(Paleta p, {required bool escuro}) {
    if (!escuro) {
      return BujoCores(
        fundo: p.fundo,
        cartao: Colors.white,
        texto: const Color(0xFF4B3F5C),
        textoSuave: const Color(0xFF54486A),
        destaque: p.destaque,
        destaqueSuave: p.destaqueSuave,
        segunda: p.segunda,
        segundaSuave: p.segundaSuave,
        linha: p.linha,
        ponto: p.ponto,
      );
    }
    return BujoCores(
      fundo: const Color(0xFF24202C),
      cartao: const Color(0xFF322C3D),
      texto: const Color(0xFFF4EFF8),
      textoSuave: const Color(0xFFCFC4DC),
      destaque: p.destaque,
      destaqueSuave: const Color(0xFF4A3F52),
      segunda: p.segunda,
      segundaSuave: const Color(0xFF4D3A4A),
      linha: p.destaque,
      ponto: const Color(0xFF3E3749),
    );
  }

  @override
  BujoCores copyWith() => this;

  @override
  BujoCores lerp(ThemeExtension<BujoCores>? other, double t) {
    if (other is! BujoCores) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BujoCores(
      fundo: l(fundo, other.fundo),
      cartao: l(cartao, other.cartao),
      texto: l(texto, other.texto),
      textoSuave: l(textoSuave, other.textoSuave),
      destaque: l(destaque, other.destaque),
      destaqueSuave: l(destaqueSuave, other.destaqueSuave),
      segunda: l(segunda, other.segunda),
      segundaSuave: l(segundaSuave, other.segundaSuave),
      linha: l(linha, other.linha),
      ponto: l(ponto, other.ponto),
    );
  }
}

extension CoresDoContexto on BuildContext {
  BujoCores get cores => Theme.of(this).extension<BujoCores>()!;
}

/// Títulos e botões com letra de mão (Mali); texto corrido em Nunito.
TextStyle titulo(BuildContext context, double tamanho, {Color? cor}) =>
    GoogleFonts.mali(fontSize: tamanho, fontWeight: FontWeight.w700, color: cor ?? context.cores.texto, height: 1.15);

TextStyle corpo(BuildContext context, {double tamanho = 15, FontWeight peso = FontWeight.w700, Color? cor}) =>
    GoogleFonts.nunito(fontSize: tamanho, fontWeight: peso, color: cor ?? context.cores.texto);

ThemeData temaBujo(Paleta paleta, {required bool escuro}) {
  final cores = BujoCores.de(paleta, escuro: escuro);
  final base = ThemeData(
    useMaterial3: true,
    brightness: escuro ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: paleta.destaque,
      brightness: escuro ? Brightness.dark : Brightness.light,
      primary: cores.linha,
      surface: cores.cartao,
    ),
    scaffoldBackgroundColor: cores.fundo,
  );
  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(bodyColor: cores.texto, displayColor: cores.texto),
    extensions: [cores],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cores.cartao,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: cores.textoSuave),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cores.linha, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cores.linha, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cores.linha, width: 3)),
    ),
  );
}
