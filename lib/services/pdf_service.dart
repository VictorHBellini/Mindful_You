import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  PdfService._();

  /// Título padrão usado no topo de todos os relatórios em PDF do app,
  /// para manter a identidade visual consistente entre as telas que
  /// geram PDF (Relatório e Resultado do check-in).
  static pw.Widget cabecalho(String titulo, {double fontSize = 24}) {
    return pw.Text(
      titulo,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  /// Nome de arquivo padronizado para os relatórios do app, com
  /// timestamp para nunca colidir entre gerações.
  static String gerarNomeArquivo() =>
      'relatorio_mindful_you_${DateTime.now().millisecondsSinceEpoch}.pdf';

  /// Salva/compartilha o PDF. Retorna `true` se o compartilhamento foi
  /// concluído e `false` se algo deu errado (ex.: usuário sem app de
  /// compartilhamento disponível, falha ao salvar). Antes, uma falha
  /// aqui não era percebida: a tela sempre mostrava "sucesso" mesmo
  /// quando o PDF não chegava a ser compartilhado.
  static Future<bool> share({
    required pw.Document document,
    required String filename,
  }) async {
    try {
      final bytes = await document.save();
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return true;
    } catch (_) {
      return false;
    }
  }
}
