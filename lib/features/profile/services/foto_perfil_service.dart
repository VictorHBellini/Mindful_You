import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cuida de copiar a foto de perfil escolhida pelo usuário para um
/// diretório permanente do app, e de apagar a foto antiga quando ela é
/// trocada ou removida.
///
/// MELHORIA: antes, o caminho devolvido pelo `image_picker` era salvo
/// direto no banco (`perfil_tela.dart`). Esse caminho aponta pra uma
/// pasta temporária/cache do sistema — no iOS principalmente, o
/// próprio sistema pode apagar esses arquivos a qualquer momento
/// (inclusive entre uma abertura e outra do app), fazendo a foto
/// "sumir" silenciosamente (o app cai pro avatar padrão sem avisar por
/// quê). Agora copiamos o arquivo pra um diretório que só o app
/// controla, e ele só some se o próprio usuário removê-lo pelo app.
class FotoPerfilService {
  FotoPerfilService._();

  static const String _pasta = 'fotos_perfil';

  /// Copia o arquivo em [caminhoOrigem] (geralmente vindo do
  /// `image_picker`, de uma pasta temporária) para um diretório
  /// permanente do app, com um nome único, e devolve o novo caminho.
  static Future<String> salvarFotoPermanente(String caminhoOrigem) async {
    final dir = await getApplicationDocumentsDirectory();
    final pastaFotos = Directory(p.join(dir.path, _pasta));
    if (!await pastaFotos.exists()) {
      await pastaFotos.create(recursive: true);
    }

    final extensao = p.extension(caminhoOrigem);
    final nomeArquivo =
        'foto_${DateTime.now().millisecondsSinceEpoch}$extensao';
    final destino = File(p.join(pastaFotos.path, nomeArquivo));

    await File(caminhoOrigem).copy(destino.path);

    return destino.path;
  }

  /// Remove do disco a foto salva em [caminho], se ela existir e tiver
  /// sido criada por [salvarFotoPermanente] (evita tentar apagar
  /// arquivos que não foram criados por este serviço — por exemplo,
  /// caminhos temporários antigos salvos antes desta correção, que
  /// simplesmente deixam de ser referenciados).
  static Future<void> removerFotoAntiga(String? caminho) async {
    if (caminho == null || caminho.isEmpty) return;
    if (!caminho.contains(_pasta)) return;

    final arquivo = File(caminho);
    try {
      if (await arquivo.exists()) {
        await arquivo.delete();
      }
    } catch (_) {
      // Falha ao remover o arquivo antigo não deve impedir o fluxo
      // principal (trocar ou remover a foto atual).
    }
  }
}
