import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/services/pdf_service.dart';

class RegistrosTela extends StatelessWidget {
  const RegistrosTela({super.key});

  static const _fundo = Color(0xFFF8F5F2);
  static const _marrom = Color(0xFF40352F);
  static const _cinza = Color(0xFF8A7B73);
  static const _bege = Color(0xFFF3EEEA);

  static int? _percentual(dynamic valor) {
    if (valor is num) return valor.round().clamp(0, 100);
    if (valor == null) return null;
    final texto =
        valor.toString().trim().replaceAll('%', '').replaceAll(',', '.');
    final numero = double.tryParse(texto);
    return numero?.round().clamp(0, 100);
  }

  static String _normalizar(String valor) => valor
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  static String? _resposta(
      List<String> perguntas, List<String> respostas, String termo) {
    for (var i = 0; i < perguntas.length; i++) {
      if (_normalizar(perguntas[i]).contains(termo)) return respostas[i];
    }
    return null;
  }

  static String _atividade(Map<String, dynamic> dados, List<String> perguntas,
      List<String> respostas) {
    final bruto = dados['atividadeSignificativa'] ??
        dados['atividadeImportante'] ??
        _resposta(perguntas, respostas, 'atividade significativa') ??
        _resposta(perguntas, respostas, 'atividade importante');
    final valor = bruto?.toString().trim() ?? '';
    if (valor.isEmpty ||
        valor.toLowerCase() == 'null' ||
        _normalizar(valor) == 'prefiro nao responder' ||
        _normalizar(valor) == 'nao informado') {
      return 'Não informado';
    }
    return valor;
  }

  static Widget _painel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  static Widget _indicador(String titulo, int? valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(titulo,
                  style: const TextStyle(
                      color: _marrom,
                      fontWeight: FontWeight.w600,
                      fontSize: 14))),
          Text(valor == null ? 'Não informado' : '$valor%',
              style: const TextStyle(
                  color: _marrom, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: (valor ?? 0) / 100,
            minHeight: 7,
            backgroundColor: _bege,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final argumentos = ModalRoute.of(context)?.settings.arguments;
    final dados =
        argumentos is Map<String, dynamic> ? argumentos : <String, dynamic>{};
    final perguntas =
        (dados['perguntas'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final respostas =
        (dados['respostas'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final total = perguntas.length < respostas.length
        ? perguntas.length
        : respostas.length;
    final perguntasSeguras = perguntas.take(total).toList();
    final respostasSeguras = respostas.take(total).toList();

    final grafico = dados['dadosGrafico'];
    final indicadores = grafico is Map ? grafico : <String, dynamic>{};
    final bemEstar = _percentual(dados['bemEstar'] ??
        dados['bem_estar'] ??
        _resposta(perguntasSeguras, respostasSeguras, 'bem-estar'));
    final cansaco = _percentual(dados['cansaco'] ??
        indicadores['cansaco'] ??
        _resposta(perguntasSeguras, respostasSeguras, 'cansaco'));
    final ansiedade = _percentual(dados['ansiedade'] ??
        indicadores['ansiedade'] ??
        _resposta(perguntasSeguras, respostasSeguras, 'ansiedade'));
    final sono = _percentual(dados['sono'] ??
        indicadores['sono'] ??
        _resposta(perguntasSeguras, respostasSeguras, 'falta de sono') ??
        _resposta(
            perguntasSeguras, respostasSeguras, 'dificuldade com o sono'));
    final atividade = _atividade(dados, perguntasSeguras, respostasSeguras);
    final principal = dados['principalPonto']?.toString().trim() ?? '';
    final data = dados['data']?.toString().trim() ?? '';
    final possuiConteudo = perguntasSeguras.isNotEmpty ||
        bemEstar != null ||
        cansaco != null ||
        ansiedade != null ||
        sono != null;

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: _fundo,
        elevation: 0,
        foregroundColor: _marrom,
        title: const Text('Relatório',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: !possuiConteudo
          ? const Center(
              child: Text('Nenhum relatório encontrado.',
                  style: TextStyle(color: _cinza, fontSize: 16)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                const Text('SEU CHECK-IN',
                    style: TextStyle(
                        color: _cinza,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3)),
                const SizedBox(height: 6),
                const Text('Relatório de bem-estar',
                    style: TextStyle(
                        color: _marrom,
                        fontSize: 25,
                        fontWeight: FontWeight.w700)),
                if (data.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(data,
                      style: const TextStyle(color: _cinza, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                _painel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('BEM-ESTAR INFORMADO',
                          style: TextStyle(
                              color: _cinza,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7)),
                      const SizedBox(height: 7),
                      Text(bemEstar == null ? 'Não informado' : '$bemEstar%',
                          style: TextStyle(
                              color: _marrom,
                              fontSize: bemEstar == null ? 21 : 38,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Como você avaliou seu dia',
                          style: TextStyle(color: _cinza, fontSize: 12)),
                    ])),
                if (principal.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1E8E1),
                        borderRadius: BorderRadius.circular(18)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.spa_outlined,
                              color: Color(0xFF80675C), size: 23),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Principal ponto de atenção',
                                    style:
                                        TextStyle(color: _cinza, fontSize: 12)),
                                const SizedBox(height: 5),
                                Text(principal,
                                    style: const TextStyle(
                                        color: _marrom,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ])),
                        ]),
                  ),
                ],
                const SizedBox(height: 23),
                const Text('Seus indicadores',
                    style: TextStyle(
                        color: _marrom,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                    'Valores maiores indicam mais atenção nos indicadores abaixo.',
                    style: TextStyle(color: _cinza, fontSize: 12, height: 1.4)),
                const SizedBox(height: 12),
                _painel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _indicador(
                          'Cansaço estimado', cansaco, const Color(0xFF8299EE)),
                      _indicador('Ansiedade percebida', ansiedade,
                          const Color(0xFFEAB46E)),
                      _indicador('Dificuldade com o sono', sono,
                          const Color(0xFFB49BE8)),
                      const Divider(height: 8, color: _bege),
                      const SizedBox(height: 12),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                                child: Text('Atividade significativa',
                                    style: TextStyle(
                                        color: _marrom,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            const SizedBox(width: 12),
                            Flexible(
                                child: Text(atividade,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        color: _marrom,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                          ]),
                    ])),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1E8E1),
                      borderRadius: BorderRadius.circular(17)),
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sobre este relatório',
                            style: TextStyle(
                                color: _marrom,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        SizedBox(height: 7),
                        Text(
                            'Os indicadores refletem respostas autorrelatadas e estimativas simples. Este resultado possui caráter informativo e não substitui uma avaliação profissional.',
                            style: TextStyle(
                                color: _cinza, fontSize: 12, height: 1.5)),
                      ]),
                ),
              ],
            ),
      bottomNavigationBar: !possuiConteudo
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80675C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Baixar PDF',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final nomeUsuario = prefs.getString('nomeUsuario') ?? '';
                      final pdf = PdfService.construirRelatorioCheckin(
                        usuario: nomeUsuario,
                        data: data,
                        principalPonto: principal,
                        bemEstar: bemEstar,
                        perguntas: perguntasSeguras,
                        respostas: respostasSeguras,
                      );
                      final sucesso = await PdfService.share(
                          document: pdf,
                          filename: PdfService.gerarNomeArquivo());
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(sucesso
                            ? 'PDF pronto para salvar ou compartilhar.'
                            : 'Não foi possível gerar o PDF. Tente novamente.'),
                        backgroundColor:
                            sucesso ? null : const Color(0xFFC0392B),
                      ));
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
