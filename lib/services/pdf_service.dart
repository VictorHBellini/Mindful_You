import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  PdfService._();

  static final PdfColor _marrom = PdfColor.fromHex('#40352F');
  static final PdfColor _cinza = PdfColor.fromHex('#80675C');
  static final PdfColor _fundo = PdfColor.fromHex('#F8F5F2');
  static final PdfColor _bege = PdfColor.fromHex('#F1E8E1');
  static final PdfColor _rosa = PdfColor.fromHex('#C89494');
  static final PdfColor _azul = PdfColor.fromHex('#8299E8');
  static final PdfColor _lilas = PdfColor.fromHex('#AE91DD');
  static final PdfColor _laranja = PdfColor.fromHex('#E6B26D');

  static pw.Widget cabecalho(String titulo, {double fontSize = 24}) =>
      pw.Text(titulo,
          style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: _marrom));

  static String gerarNomeArquivo() =>
      'relatorio_mindful_you_${DateTime.now().millisecondsSinceEpoch}.pdf';

  static double? _percentual(String resposta) {
    final match =
        RegExp(r'^\s*(\d{1,3})(?:[.,]\d+)?\s*%\s*$').firstMatch(resposta);
    if (match == null) return null;
    final valor = double.tryParse(match.group(1)!);
    if (valor == null || valor < 0 || valor > 100) return null;
    return valor;
  }

  static PdfColor _corIndicador(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('cansa')) return _azul;
    if (t.contains('sono')) return _lilas;
    if (t.contains('ansiedade')) return _laranja;
    return _rosa;
  }

  static pw.Widget _indicador(String titulo, String resposta) {
    final percentual = _percentual(resposta);
    final cor = _corIndicador(titulo);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 13),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _bege, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(titulo,
                    style: pw.TextStyle(
                        color: _marrom,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 12),
              pw.Text(resposta,
                  style: pw.TextStyle(
                      color: _marrom,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (percentual != null) ...[
            pw.SizedBox(height: 9),
            pw.LayoutBuilder(builder: (context, constraints) {
              final largura = constraints!.maxWidth;
              return pw.Container(
                width: largura,
                height: 7,
                decoration: pw.BoxDecoration(
                  color: _bege,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: largura * percentual / 100,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: cor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  static pw.Document construirRelatorioCheckin({
    String? usuario,
    String? data,
    String? principalPonto,
    int? bemEstar,
    required List<String> perguntas,
    required List<String> respostas,
  }) {
    final pdf = pw.Document();
    final total = perguntas.length < respostas.length
        ? perguntas.length
        : respostas.length;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(44, 42, 44, 42),
      header: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 24),
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _bege, width: 1)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MINDFUL YOU',
                style: pw.TextStyle(
                    color: _marrom,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5)),
            pw.Text('CHECK-IN DIÁRIO',
                style: pw.TextStyle(color: _cinza, fontSize: 9)),
          ],
        ),
      ),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _bege, width: 1)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Mindful You • Relatório informativo',
                style: pw.TextStyle(color: _cinza, fontSize: 9)),
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(color: _cinza, fontSize: 9)),
          ],
        ),
      ),
      build: (context) => [
        cabecalho('Relatório de bem-estar', fontSize: 23),
        pw.SizedBox(height: 8),
        if ((usuario ?? '').isNotEmpty || (data ?? '').isNotEmpty)
          pw.Text(
            [
              if ((usuario ?? '').isNotEmpty) usuario!,
              if ((data ?? '').isNotEmpty) data!,
            ].join('  •  '),
            style: pw.TextStyle(color: _cinza, fontSize: 10),
          ),
        pw.SizedBox(height: 20),
        if (bemEstar != null) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(19),
            decoration: pw.BoxDecoration(
              color: _fundo,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BEM-ESTAR INFORMADO',
                    style: pw.TextStyle(color: _cinza, fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Text('$bemEstar%',
                    style: pw.TextStyle(
                        color: _marrom,
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Como você avaliou seu dia',
                    style: pw.TextStyle(color: _cinza, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
        ],
        if ((principalPonto ?? '').isNotEmpty) ...[
          pw.Text('Principal ponto de atenção',
              style: pw.TextStyle(color: _cinza, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(principalPonto!,
              style: pw.TextStyle(
                  color: _marrom,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Seus indicadores',
            style: pw.TextStyle(
                color: _marrom, fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        ...List.generate(total, (i) => _indicador(perguntas[i], respostas[i])),
        pw.SizedBox(height: 13),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: _fundo,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sobre este relatório',
                  style: pw.TextStyle(
                      color: _marrom,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(
                'Os indicadores refletem respostas autorrelatadas e estimativas simples. '
                'Este resultado possui caráter informativo e não representa diagnóstico '
                'nem substitui avaliação por profissional especializado.',
                style: pw.TextStyle(color: _cinza, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ));
    return pdf;
  }

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
