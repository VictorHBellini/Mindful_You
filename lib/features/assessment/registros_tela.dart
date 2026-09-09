import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mindful_you/services/pdf_service.dart';

class RegistrosTela extends StatelessWidget {
  const RegistrosTela({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> dados =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final List<String> perguntas =
        (dados['perguntas'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final List<String> respostas =
        (dados['respostas'] as List?)?.map((e) => e.toString()).toList() ?? [];

    // BUG CORRIGIDO: se 'perguntas' e 'respostas' viessem com tamanhos
    // diferentes, `respostas[index]` lançava um RangeError e quebrava a
    // tela. Agora truncamos as duas listas para o mesmo tamanho seguro.
    final int totalItens = perguntas.length < respostas.length
        ? perguntas.length
        : respostas.length;
    final List<String> perguntasSeguras = perguntas.take(totalItens).toList();
    final List<String> respostasSeguras = respostas.take(totalItens).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          "Relatório",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: perguntasSeguras.isEmpty
          ? const Center(
              child: Text(
                "Nenhum relatório encontrado.",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: perguntasSeguras.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perguntasSeguras[index],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5D5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          respostasSeguras[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: perguntasSeguras.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFFC89494),
              onPressed: () async {
                final pdf = pw.Document();

                pdf.addPage(
                  pw.MultiPage(
                    build: (context) => [
                      PdfService.cabecalho("Relatório Mindful You"),
                      pw.SizedBox(height: 20),
                      ...List.generate(
                        perguntasSeguras.length,
                        (index) {
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
                                  perguntasSeguras[index],
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  respostasSeguras[index],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );

                final sucesso = await PdfService.share(
                  document: pdf,
                  filename: PdfService.gerarNomeArquivo(),
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sucesso
                          ? 'PDF pronto para salvar ou compartilhar.'
                          : 'Não foi possível gerar o PDF. Tente novamente.',
                    ),
                    backgroundColor: sucesso ? null : const Color(0xFFC0392B),
                  ),
                );
              },
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              label: const Text(
                "Baixar PDF",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
