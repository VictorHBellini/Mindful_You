import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/pdf_service.dart';
import 'package:mindful_you/widgets/menu_lateral_tela.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';
import 'package:mindful_you/features/history/historico_global.dart';

class GraficoTela extends StatefulWidget {
  const GraficoTela({super.key});

  @override
  State<GraficoTela> createState() => _GraficoTelaState();
}

class _GraficoTelaState extends State<GraficoTela> {
  String nomeUsuario = "Usuário";
  bool _historicoSalvo = false;

  @override
  void initState() {
    super.initState();
    carregarNome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_historicoSalvo) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final possuiDadosDoQuestionario =
          args is Map<String, dynamic> && args.isNotEmpty;

      if (possuiDadosDoQuestionario) {
        _historicoSalvo = true;
        _salvarNoHistorico();
      }
    }
  }

  // ============================================================
  // SALVAR RESULTADO NO HISTÓRICO
  // ============================================================

  Future<void> _salvarNoHistorico() async {
    final Map<String, dynamic> dados =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final double cansaco = (dados['cansaco'] ?? 55).toDouble();
    final double ansiedade = (dados['ansiedade'] ?? 15).toDouble();
    final double sono = (dados['sono'] ?? 25).toDouble();
    final double produtividade = (dados['produtividade'] ?? 5).toDouble();
    final String sentimento = (dados['sentimento'] as String?) ?? '';
    final String emoji = (dados['emoji'] as String?) ?? '🙂';

    // Sinais de humor e energia (ver observação em
    // `historico_global.dart`, seção "SINAIS DE HUMOR E ENERGIA").
    final String humorFrequencia = (dados['humorFrequencia'] as String?) ?? '';
    final String interesseFrequencia =
        (dados['interesseFrequencia'] as String?) ?? '';
    final String exaustaoBurnout = (dados['exaustaoBurnout'] as String?) ?? '';
    final String distanciamentoBurnout =
        (dados['distanciamentoBurnout'] as String?) ?? '';

    final double bemEstar =
        ((100 - cansaco) + (100 - ansiedade) + (100 - sono) + produtividade) /
            4;

    final String principal = obterPrincipalPontoAtencao(
      cansaco,
      ansiedade,
      sono,
      produtividade,
    );

    Color corResultado;
    if (bemEstar >= 70) {
      corResultado = const Color(0xFFD9E8D5);
    } else if (bemEstar >= 40) {
      corResultado = const Color(0xFFF3E5D8);
    } else {
      corResultado = const Color(0xFFE8C7C9);
    }

    const meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final now = DateTime.now();
    final dataFormatada = '${now.day} ${meses[now.month - 1]}. ${now.year}';

    final entrada = <String, dynamic>{
      'operacaoId': dados['operacaoId'],
      'data': dataFormatada,
      // Data em formato ISO (além do texto formatado acima), usada pelo
      // cálculo de sequência de dias consecutivos em `historico_global.dart`.
      'dataIso': now.toIso8601String(),
      'sentimento': sentimento,
      'emoji': emoji,
      'cor': corResultado,
      'bemEstar': bemEstar.round(),
      'dadosGrafico': {
        'cansaco': cansaco,
        'ansiedade': ansiedade,
        'sono': sono,
        'produtividade': produtividade,
      },
      // Mantém compatibilidade com a tela de Relatório (RegistrosTela),
      // que espera 'perguntas' e 'respostas'.
      'perguntas': const [
        'Cansaço',
        'Ansiedade',
        'Falta de sono',
        'Produtividade',
      ],
      'respostas': [
        '${cansaco.toInt()}%',
        '${ansiedade.toInt()}%',
        '${sono.toInt()}%',
        '${produtividade.toInt()}%',
      ],
      'principalPonto': principal,
      'humorFrequencia': humorFrequencia,
      'interesseFrequencia': interesseFrequencia,
      'exaustaoBurnout': exaustaoBurnout,
      'distanciamentoBurnout': distanciamentoBurnout,
    };

    try {
      if (kIsWeb) {
        await FirebaseRegistrosService.instance.registrarCheckin(
          bemEstar: bemEstar.round(),
          ansiedade: ansiedade,
          cansaco: cansaco,
          sono: sono,
          produtividade: produtividade,
          sentimento: sentimento,
          operacaoId: dados['operacaoId'] as String?,
        );
      } else {
        await adicionarHistorico(entrada);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Não foi possível salvar o check-in. Verifique a conexão e tente novamente pelo formulário.'),
      ));
    }
  }

  // ============================================================
  // CARREGAR NOME
  // ============================================================

  Future<void> carregarNome() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? "Usuário";
    });
  }

  // ============================================================
  // GERAR PDF
  // ============================================================

  Future<void> gerarPDF({
    required double cansaco,
    required double ansiedade,
    required double sono,
    required double produtividade,
    String humorFrequencia = '',
    String interesseFrequencia = '',
    String exaustaoBurnout = '',
    String distanciamentoBurnout = '',
  }) async {
    final principal = obterPrincipalPontoAtencao(
      cansaco,
      ansiedade,
      sono,
      produtividade,
    );

    final double bemEstar =
        ((100 - cansaco) + (100 - ansiedade) + (100 - sono) + produtividade) /
            4;

    // Usa o mesmo layout de PDF que a tela de Relatório (aberta a
    // partir do Histórico), em vez de montar o documento aqui. Os
    // itens de humor/energia só entram no relatório quando há
    // resposta salva para eles.
    final pdf = PdfService.construirRelatorioCheckin(
      usuario: nomeUsuario,
      principalPonto: principal,
      bemEstar: bemEstar.round(),
      perguntas: [
        'Cansaço',
        'Ansiedade',
        'Falta de sono',
        'Produtividade',
        if (humorFrequencia.isNotEmpty) 'Humor (desânimo ou tristeza)',
        if (interesseFrequencia.isNotEmpty) 'Interesse ou prazer',
        if (exaustaoBurnout.isNotEmpty) 'Exaustão emocional',
        if (distanciamentoBurnout.isNotEmpty) 'Distanciamento ou desmotivação',
      ],
      respostas: [
        '${cansaco.toInt()}%',
        '${ansiedade.toInt()}%',
        '${sono.toInt()}%',
        '${produtividade.toInt()}%',
        if (humorFrequencia.isNotEmpty) humorFrequencia,
        if (interesseFrequencia.isNotEmpty) interesseFrequencia,
        if (exaustaoBurnout.isNotEmpty) exaustaoBurnout,
        if (distanciamentoBurnout.isNotEmpty) distanciamentoBurnout,
      ],
    );

    final sucesso = await PdfService.share(
      document: pdf,
      filename: PdfService.gerarNomeArquivo(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? "Relatório gerado com sucesso!"
              : "Não foi possível gerar o PDF. Tente novamente.",
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: sucesso ? null : const Color(0xFFC0392B),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> dados =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final double cansaco = (dados['cansaco'] ?? 55).toDouble();

    final double ansiedade = (dados['ansiedade'] ?? 15).toDouble();

    final double sono = (dados['sono'] ?? 25).toDouble();

    final double produtividade = (dados['produtividade'] ?? 5).toDouble();

    // Sinais de humor e energia (ver observação em
    // `historico_global.dart`, seção "SINAIS DE HUMOR E ENERGIA").
    // Ficam vazios quando o resultado exibido vem de um check-in
    // salvo antes desta funcionalidade existir.
    final String humorFrequencia = (dados['humorFrequencia'] as String?) ?? '';
    final String interesseFrequencia =
        (dados['interesseFrequencia'] as String?) ?? '';
    final String exaustaoBurnout = (dados['exaustaoBurnout'] as String?) ?? '';
    final String distanciamentoBurnout =
        (dados['distanciamentoBurnout'] as String?) ?? '';

    final List<Map<String, String>> sinaisHumorEnergia = [
      if (humorFrequencia.isNotEmpty)
        {'titulo': 'Humor', 'frequencia': humorFrequencia},
      if (interesseFrequencia.isNotEmpty)
        {'titulo': 'Interesse ou prazer', 'frequencia': interesseFrequencia},
      if (exaustaoBurnout.isNotEmpty)
        {'titulo': 'Exaustão emocional', 'frequencia': exaustaoBurnout},
      if (distanciamentoBurnout.isNotEmpty)
        {
          'titulo': 'Distanciamento',
          'frequencia': distanciamentoBurnout,
        },
    ];

    final int sinaisElevados = sinaisHumorEnergia
        .where(
          (item) =>
              item['frequencia'] == 'Frequentemente' ||
              item['frequencia'] == 'Quase sempre',
        )
        .length;

    // ============================================================
    // VALORES DE ATENÇÃO
    //
    // Para os três primeiros indicadores:
    // quanto maior, maior a atenção.
    //
    // Para produtividade:
    // quanto menor a produtividade, maior a atenção.
    // ============================================================

    final double atencaoCansaco = cansaco.clamp(0.0, 100.0);

    final double atencaoAnsiedade = ansiedade.clamp(0.0, 100.0);

    final double atencaoSono = sono.clamp(0.0, 100.0);

    final double atencaoProdutividade = (100 - produtividade).clamp(0.0, 100.0);

    final String principalPonto = obterPrincipalPontoAtencao(
      cansaco,
      ansiedade,
      sono,
      produtividade,
    );

    final List<Map<String, dynamic>> recomendacoes = obterRecomendacoes(
      cansaco,
      ansiedade,
      sono,
      produtividade,
    );

    return Scaffold(
      drawer: const MenuLateral(),
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: Stack(
          children: [
            // ====================================================
            // ELEMENTO DECORATIVO
            // ====================================================

            Positioned(
              top: -100,
              right: -120,
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  'assets/img/6.png',
                  width: 330,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ====================================================
            // CONTEÚDO
            // ====================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // CABEÇALHO
                    // ==================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.menu,
                                  size: 27,
                                  color: Color(0xFF8D837A),
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/perfil',
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(
                                    0,
                                    4,
                                  ),
                                ),
                              ],
                            ),
                            child: const AvatarPerfil(
                              radius: 28,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // TÍTULO
                    // ==================================================

                    const Text(
                      "Seu resultado",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292724),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Uma visão geral dos seus indicadores.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A847E),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // CARD DO GRÁFICO
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        15,
                        20,
                        15,
                        10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.055),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ==========================================
                          // GRÁFICO
                          // ==========================================

                          SizedBox(
                            width: 210,
                            height: 210,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 55,
                                    borderData: FlBorderData(
                                      show: false,
                                    ),
                                    sections: [
                                      PieChartSectionData(
                                        color: const Color(
                                          0xFF7895E8,
                                        ),
                                        value: atencaoCansaco,
                                        radius: 42,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(
                                          0xFFA98BE6,
                                        ),
                                        value: atencaoSono,
                                        radius: 42,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(
                                          0xFFE8B46D,
                                        ),
                                        value: atencaoAnsiedade,
                                        radius: 42,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(
                                          0xFFE8D45B,
                                        ),
                                        value: atencaoProdutividade,
                                        radius: 42,
                                        showTitle: false,
                                      ),
                                    ],
                                  ),
                                ),

                                // ====================================
                                // TEXTO CENTRAL
                                // ====================================

                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Nível de",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(
                                          0xFF8A837C,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    const Text(
                                      "atenção",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(
                                          0xFF393532,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    const Icon(
                                      Icons.self_improvement_outlined,
                                      size: 27,
                                      color: Color(
                                        0xFF8D837A,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      principalPonto,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(
                                          0xFF393532,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ==========================================
                          // TEXTO EXPLICATIVO
                          // ==========================================

                          const Text(
                            "O indicador que merece maior atenção no momento é:",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF85807A),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            principalPonto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF393532),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Isso não representa um diagnóstico, "
                            "mas apenas uma indicação de quais "
                            "áreas merecem mais atenção.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF918A84),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==========================================
                          // INDICADORES
                          // ==========================================

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Seus indicadores",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF302D2A),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          indicadorLegenda(
                            "Cansaço",
                            cansaco,
                            const Color(
                              0xFF7895E8,
                            ),
                            Icons.airline_seat_flat,
                          ),

                          indicadorLegenda(
                            "Falta de sono",
                            sono,
                            const Color(
                              0xFFA98BE6,
                            ),
                            Icons.bedtime_outlined,
                          ),

                          indicadorLegenda(
                            "Ansiedade",
                            ansiedade,
                            const Color(
                              0xFFE8B46D,
                            ),
                            Icons.psychology_outlined,
                          ),

                          indicadorLegenda(
                            "Produtividade",
                            produtividade,
                            const Color(
                              0xFFE8D45B,
                            ),
                            Icons.trending_up,
                            produtividade: true,
                          ),

                          const SizedBox(height: 5),

                          // ==========================================
                          // LEGENDA DE STATUS
                          // ==========================================

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Nível dos indicadores",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF77716B),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              legendaStatus(
                                "Normal",
                                const Color(
                                  0xFFD9E8D5,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              legendaStatus(
                                "Atenção",
                                const Color(
                                  0xFFF3E5D8,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              legendaStatus(
                                "Prioridade",
                                const Color(
                                  0xFFE8C7C9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // SINAIS DE HUMOR E ENERGIA
                    // ==================================================

                    if (sinaisHumorEnergia.isNotEmpty) ...[
                      cardSinaisHumorEnergia(
                        sinais: sinaisHumorEnergia,
                        sinaisElevados: sinaisElevados,
                      ),
                      const SizedBox(height: 22),
                    ],

                    // ==================================================
                    // RESUMO
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7DE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF7F7469),
                            ),
                          ),
                          const SizedBox(
                            width: 13,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ponto de atenção",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                      0xFF302D2A,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  "Seus resultados indicam "
                                  "que $principalPonto "
                                  "é o indicador que "
                                  "merece um pouco mais "
                                  "de atenção neste momento. "
                                  "Confira as recomendações "
                                  "abaixo.",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(
                                      0xFF625C56,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // BOTÕES
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: botaoPrincipal(
                            texto: "Histórico",
                            icone: Icons.history_rounded,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/historico',
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: botaoPrincipal(
                            texto: "Relatório",
                            icone: Icons.picture_as_pdf_outlined,
                            onPressed: () async {
                              await gerarPDF(
                                cansaco: cansaco,
                                ansiedade: ansiedade,
                                sono: sono,
                                produtividade: produtividade,
                                humorFrequencia: humorFrequencia,
                                interesseFrequencia: interesseFrequencia,
                                exaustaoBurnout: exaustaoBurnout,
                                distanciamentoBurnout: distanciamentoBurnout,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    // ==================================================
                    // RECOMENDAÇÕES
                    // ==================================================

                    const Text(
                      "Recomendações para você",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292724),
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      "Selecionamos algumas sugestões "
                      "com base nos seus indicadores.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF817A74),
                      ),
                    ),

                    const SizedBox(height: 18),

                    ...recomendacoes.map(
                      (item) => dicaCard(
                        icone: item['icone'] as IconData,
                        titulo: item['titulo'] as String,
                        desc: item['desc'] as String,
                        cor: item['cor'] as Color,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // AVISO
                    // ==================================================

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          "Este resultado é apenas informativo "
                          "e não substitui uma avaliação profissional.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS DO INDICADOR
  // ============================================================

  String obterStatusIndicador(
    double valor, {
    bool produtividade = false,
  }) {
    final double nivelAtencao = produtividade ? 100 - valor : valor;

    if (nivelAtencao >= 80) {
      return "Prioridade";
    }

    if (nivelAtencao >= 50) {
      return "Atenção";
    }

    return "Normal";
  }

  // ============================================================
  // COR DO STATUS
  // ============================================================

  Color obterCorStatus(
    double valor, {
    bool produtividade = false,
  }) {
    final String status = obterStatusIndicador(
      valor,
      produtividade: produtividade,
    );

    switch (status) {
      case "Prioridade":
        return const Color(0xFFE8C7C9);

      case "Atenção":
        return const Color(0xFFF3E5D8);

      default:
        return const Color(0xFFD9E8D5);
    }
  }

  // ============================================================
  // INDICADOR
  // ============================================================

  Widget indicadorLegenda(
    String nome,
    double valor,
    Color cor,
    IconData icone, {
    bool produtividade = false,
  }) {
    final String status = obterStatusIndicador(
      valor,
      produtividade: produtividade,
    );

    final bool atencao = status != "Normal";

    final Color corStatus = obterCorStatus(
      valor,
      produtividade: produtividade,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icone,
                  size: 18,
                  color: cor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF393532),
                  ),
                ),
              ),
              if (atencao)
                Container(
                  margin: const EdgeInsets.only(
                    right: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: corStatus,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A7556),
                    ),
                  ),
                ),
              Text(
                "${valor.toInt()}%",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF55504B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (valor / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EDE9),
              valueColor: AlwaysStoppedAnimation<Color>(
                cor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGENDA DE STATUS
  // ============================================================

  Widget legendaStatus(
    String texto,
    Color cor,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF77716B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO
  // ============================================================

  Widget botaoPrincipal({
    required String texto,
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 49,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icone,
          size: 19,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE4D9C9),
          foregroundColor: const Color(0xFF393532),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE DICA
  // ============================================================

  Widget dicaCard({
    required IconData icone,
    required String titulo,
    required String desc,
    required Color cor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icone,
              color: const Color(0xFF6D625A),
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF403A35),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF5D5650),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE SINAIS DE HUMOR E ENERGIA
  // ============================================================
  //
  // Mostra os itens de humor/interesse/exaustão/distanciamento
  // respondidos no questionário (ver `questionario_tela.dart`), com
  // a frequência escolhida e uma cor de acordo com o quanto aquele
  // sinal apareceu. Não aparece nada aqui se o check-in for antigo e
  // não tiver essas respostas salvas.

  Color _corFrequencia(String frequencia) {
    switch (frequencia) {
      case 'Frequentemente':
      case 'Quase sempre':
        return const Color(0xFFE8C7C9);

      case 'Às vezes':
        return const Color(0xFFF3E5D8);

      default:
        return const Color(0xFFD9E8D5);
    }
  }

  Widget cardSinaisHumorEnergia({
    required List<Map<String, String>> sinais,
    required int sinaisElevados,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6BA6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.filter_drama_outlined,
                  color: Color(0xFF7C6BA6),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Sinais de humor e energia",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF302D2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sinais.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['titulo'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF393532),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _corFrequencia(item['frequencia'] ?? ''),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      item['frequencia'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D5B45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (sinaisElevados >= 2) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8C7C9).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Alguns desses sinais têm aparecido com frequência. "
                "Pode ser um bom assunto para trazer para sua próxima "
                "conversa com seu terapeuta.",
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF6D5B45),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              "Isso não representa um diagnóstico, apenas um "
              "acompanhamento ao longo do tempo.",
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF918A84),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PRINCIPAL PONTO DE ATENÇÃO
  // ============================================================

  String obterPrincipalPontoAtencao(
    double cansaco,
    double ansiedade,
    double sono,
    double produtividade,
  ) {
    final Map<String, double> pontos = {
      "Cansaço": cansaco,
      "Ansiedade": ansiedade,
      "Falta de sono": sono,
      "Baixa produtividade": 100 - produtividade,
    };

    String maior = pontos.keys.first;

    for (final item in pontos.entries) {
      if (item.value > pontos[maior]!) {
        maior = item.key;
      }
    }

    return maior;
  }

  // ============================================================
  // RECOMENDAÇÕES DINÂMICAS
  // ============================================================

  List<Map<String, dynamic>> obterRecomendacoes(
    double cansaco,
    double ansiedade,
    double sono,
    double produtividade,
  ) {
    final List<Map<String, dynamic>> lista = [];

    // ==========================================================
    // CANSAÇO
    // ==========================================================

    if (cansaco >= 50) {
      lista.add({
        'icone': Icons.airline_seat_flat,
        'titulo': "Respeite seus momentos de descanso",
        'desc': "Seu nível de cansaço merece atenção. "
            "Tente incluir pequenos períodos de "
            "descanso durante o dia e evite "
            "sobrecarregar sua rotina.",
        'cor': const Color(0xFFE7C7C9),
        'prioridade': cansaco,
      });
    }

    // ==========================================================
    // ANSIEDADE
    // ==========================================================

    if (ansiedade >= 50) {
      lista.add({
        'icone': Icons.self_improvement_outlined,
        'titulo': "Reserve alguns minutos para desacelerar",
        'desc': "Momentos de respiração, pausa e "
            "atenção ao presente podem ajudar "
            "a organizar os pensamentos e "
            "reduzir a tensão.",
        'cor': const Color(0xFFD9D0E8),
        'prioridade': ansiedade,
      });
    }

    // ==========================================================
    // SONO
    // ==========================================================

    if (sono >= 50) {
      lista.add({
        'icone': Icons.bedtime_outlined,
        'titulo': "Priorize uma rotina de sono",
        'desc': "Procure manter horários regulares "
            "para dormir e acordar e reduza "
            "estímulos antes de dormir.",
        'cor': const Color(0xFFE7C7C9),
        'prioridade': sono,
      });
    }

    // ==========================================================
    // PRODUTIVIDADE
    // ==========================================================

    if (produtividade < 50) {
      lista.add({
        'icone': Icons.trending_up,
        'titulo': "Organize suas tarefas",
        'desc': "Experimente dividir suas atividades "
            "em pequenas etapas e estabelecer "
            "prioridades para evitar sobrecarga.",
        'cor': const Color(0xFFE9C8AE),
        'prioridade': 100 - produtividade,
      });
    }

    // ==========================================================
    // ORDENAR PELAS MAIORES NECESSIDADES
    // ==========================================================

    lista.sort(
      (a, b) => (b['prioridade'] as double).compareTo(
        a['prioridade'] as double,
      ),
    );

    // ==========================================================
    // CASO NENHUM INDICADOR TENHA CHAMADO ATENÇÃO
    // ==========================================================

    if (lista.isEmpty) {
      lista.add({
        'icone': Icons.favorite_outline,
        'titulo': "Continue cuidando de você",
        'desc': "Seus indicadores não apresentam "
            "pontos de atenção elevados. "
            "Continue mantendo hábitos que "
            "favoreçam seu bem-estar.",
        'cor': const Color(0xFFD9D8C5),
        'prioridade': 0.0,
      });
    }

    // ==========================================================
    // MOSTRAR NO MÁXIMO 2 RECOMENDAÇÕES
    // ==========================================================

    return lista.take(2).toList();
  }
}
