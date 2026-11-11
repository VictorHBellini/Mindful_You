import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gerencia as fotos de perfil armazenadas permanentemente pelo aplicativo.
class FotoPerfilService {
  FotoPerfilService._();

  static const String _pasta = 'fotos_perfil';

  /// Copia uma foto temporária para o diretório permanente do aplicativo.
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

  /// Exclui apenas arquivos regulares diretamente dentro da pasta de fotos
  /// do aplicativo. Caminhos externos, subpastas e links são ignorados.
  static Future<void> removerFotoAntiga(String? caminho) async {
    if (caminho == null || caminho.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final pastaFotos = p.normalize(p.absolute(p.join(dir.path, _pasta)));
      final caminhoNormalizado = p.normalize(p.absolute(caminho));

      // Exige que o arquivo esteja diretamente na pasta controlada pelo app.
      if (!p.isWithin(pastaFotos, caminhoNormalizado) ||
          !p.equals(p.dirname(caminhoNormalizado), pastaFotos)) {
        return;
      }

      // Não segue links simbólicos, inclusive quando apontam para fora.
      final tipo = await FileSystemEntity.type(
        caminhoNormalizado,
        followLinks: false,
      );
      if (tipo != FileSystemEntityType.file) return;

      await File(caminhoNormalizado).delete();
    } catch (_) {
      // A limpeza secundária não deve impedir a operação principal.
    }
  }
}
