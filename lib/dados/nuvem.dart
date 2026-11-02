import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../config_google.dart';

/// UC11 (entrar com Google) e UC12 (backup na nuvem).
/// O backup é um arquivo JSON na pasta escondida do app no Google Drive (appDataFolder):
/// só o Meu Bujo enxerga, e não aparece no Drive da usuária.
class Nuvem {
  Nuvem._();
  static final instancia = Nuvem._();

  static const _escopos = [drive.DriveApi.driveAppdataScope];
  static const _arquivo = 'meu_bujo_backup.json';

  final _google = GoogleSignIn.instance;
  bool _iniciado = false;
  GoogleSignInAccount? conta;

  Future<void> iniciar() async {
    if (_iniciado || !googleConfigurado) return;
    await _google.initialize(serverClientId: googleWebClientId);
    _iniciado = true;
  }

  /// Ao abrir o app: volta pra conta de antes sem mostrar nada na tela.
  Future<GoogleSignInAccount?> entrarSemPerguntar() async {
    if (!googleConfigurado) return null;
    try {
      await iniciar();
      conta = await _google.attemptLightweightAuthentication();
    } catch (_) {
      conta = null;
    }
    return conta;
  }

  /// Botão "Entrar com Google". Lança [NuvemErro] com uma mensagem amigável.
  Future<GoogleSignInAccount> entrar() async {
    if (!googleConfigurado) {
      throw NuvemErro('O login com Google ainda não foi configurado (veja o README).');
    }
    try {
      await iniciar();
      final c = await _google.authenticate(scopeHint: _escopos);
      await c.authorizationClient.authorizeScopes(_escopos); // permissão pro Drive (UC11 passo 2)
      conta = c;
      return c;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw NuvemErro('Login cancelado.');
      throw NuvemErro('Não deu pra entrar com o Google (${e.code.name}).');
    }
  }

  Future<void> sair() async {
    conta = null;
    if (_iniciado) await _google.signOut();
  }

  /// Pede uma permissão a mais (ex.: a agenda, UC11 passo 2). Devolve false se a usuária negou.
  Future<bool> autorizar(List<String> escopos) async {
    final c = conta;
    if (c == null) return false;
    try {
      await c.authorizationClient.authorizeScopes(escopos);
      return true;
    } on GoogleSignInException {
      return false;
    }
  }

  /// Cliente HTTP já com o token pros [escopos], ou null se não há permissão.
  /// Sem conta carregada (ex.: app fechado, RN25), usa a autorização já dada antes, sem mostrar nada.
  Future<http.Client?> cliente(List<String> escopos, {bool podePerguntar = false}) async {
    final c = conta;
    if (c == null && podePerguntar) return null;
    try {
      await iniciar();
      final autorizacao = c?.authorizationClient ?? _google.authorizationClient;
      final cabecalhos = await autorizacao.authorizationHeaders(escopos, promptIfNecessary: podePerguntar);
      return cabecalhos == null ? null : _ClienteComToken(cabecalhos);
    } on GoogleSignInException {
      return null;
    }
  }

  Future<drive.DriveApi?> _api({bool podePerguntar = false}) async {
    final cli = await cliente(_escopos, podePerguntar: podePerguntar);
    return cli == null ? null : drive.DriveApi(cli);
  }

  Future<String?> _idDoArquivo(drive.DriveApi api) async {
    final lista = await api.files.list(spaces: 'appDataFolder', q: "name = '$_arquivo'", $fields: 'files(id)');
    final arquivos = lista.files ?? [];
    return arquivos.isEmpty ? null : arquivos.first.id;
  }

  /// Envia o backup. Devolve false se não conseguiu (sem internet, sem permissão...): RN15 tenta de novo depois.
  Future<bool> enviar(String json) async {
    try {
      final api = await _api();
      if (api == null) return false;
      final bytes = utf8.encode(json);
      final midia = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');
      final id = await _idDoArquivo(api);
      if (id == null) {
        await api.files.create(drive.File(name: _arquivo, parents: ['appDataFolder']), uploadMedia: midia);
      } else {
        await api.files.update(drive.File(), id, uploadMedia: midia);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Baixa o backup, se existir (UC11 A1: celular novo recupera os dados).
  Future<String?> baixar() async {
    try {
      final api = await _api(podePerguntar: true);
      if (api == null) return null;
      final id = await _idDoArquivo(api);
      if (id == null) return null;
      final midia = await api.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final partes = await midia.stream.toList();
      return utf8.decode(partes.expand((p) => p).toList());
    } catch (_) {
      return null;
    }
  }
}

class NuvemErro implements Exception {
  final String mensagem;
  NuvemErro(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Cliente HTTP que põe o token do Google em cada pedido pro Drive.
class _ClienteComToken extends http.BaseClient {
  final Map<String, String> cabecalhos;
  final _interno = http.Client();

  _ClienteComToken(this.cabecalhos);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(cabecalhos);
    return _interno.send(request);
  }
}
