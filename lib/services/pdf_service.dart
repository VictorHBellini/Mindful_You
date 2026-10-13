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

  /// Monta o PDF de um check-in (resultado do questionário).
  ///
  /// AJUSTE: `grafico_tela.dart` (botão "Relatório", com o resultado
  /// atual) e `registros_tela.dart` (aberta a partir do Histórico, com
  /// um check-in salvo) cada uma montava seu próprio PDF, com layouts
  /// diferentes — uma mostrava usuário/ponto de atenção mas os
  /// indicadores em texto corrido, a outra mostrava os indicadores em
  /// caixas mas sem usuário, data ou ponto de atenção. Agora as duas
  /// chamam este único método, então o PDF gerado é sempre igual,
  /// venha ele do resultado recém-respondido ou de um item do
  /// histórico.
  ///
  /// [usuario], [data], [principalPonto] e [bemEstar] são opcionais —
  /// quando não informados (ou vazios), a seção correspondente
  /// simplesmente não aparece no PDF. [perguntas] e [respostas] devem
  /// ter o mesmo tamanho; qualquer pergunta sem resposta correspondente
  /// é ignorada.
  static pw.Document construirRelatorioCheckin({
    String? usuario,
    String? data,
    String? principalPonto,
    int? bemEstar,
    required List<String> perguntas,
    required List<String> respostas,
  }) {
    final pdf = pw.Document();

    final int totalItens = perguntas.length < respostas.length
        ? perguntas.length
        : respostas.length;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          cabecalho("Relatório Mindful You"),
          pw.SizedBox(height: 20),
          if (usuario != null && usuario.isNotEmpty)
            pw.Text(
              "Usuário: $usuario",
              style: const pw.TextStyle(fontSize: 16),
            ),
          if (data != null && data.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              "Data: $data",
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
          if (principalPonto != null && principalPonto.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              "Principal ponto de atenção: $principalPonto",
              style: const pw.TextStyle(fontSize: 15),
            ),
          ],
          if (bemEstar != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              "Bem-estar geral: $bemEstar%",
              style: const pw.TextStyle(fontSize: 15),
            ),
          ],
          pw.SizedBox(height: 20),
          ...List.generate(totalItens, (index) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    perguntas[index],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(respostas[index]),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          pw.Text(
            "Observação",
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            "Este resultado possui caráter informativo e "
            "não substitui uma avaliação realizada por "
            "um profissional especializado.",
            style: const pw.TextStyle(fontSize: 13),
          ),
        ],
      ),
    );

    return pdf;
  }

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
