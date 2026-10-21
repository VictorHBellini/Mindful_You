import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/pdf_service.dart';
import 'package:mindful_you/core/widgets/menu_lateral_widget.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';
import 'package:mindful_you/features/history/historico_global.dart';

double? _indicadorNumerico(Map<String, dynamic> dados, String chave) {
  final valor = dados[chave];
  if (valor is num && valor.isFinite && valor >= 0 && valor <= 100) {
    return valor.toDouble();
  }
  return null;
}

String _atividadeExibida(String? valor) =>
    valor == null || valor.isEmpty || valor == 'Prefiro não responder'
        ? 'Não informado'
        : valor;

String _percentual(double? valor) =>
    valor == null ? 'Não informado' : '${valor.round()}%';

String _principalAtencao(double? cansaco, double? ansiedade, double? sono) {
  final pontos = <String, double>{
    if (cansaco != null) 'Cansaço estimado': cansaco,
    if (ansiedade != null) 'Ansiedade percebida': ansiedade,
    if (sono != null) 'Dificuldade percebida com o sono': sono,
  };
  if (pontos.isEmpty) return 'Não informado';
  return pontos.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

class GraficoTela extends StatefulWidget {
  const GraficoTela({super.key});

  @override
  State<GraficoTela> createState() => _GraficoTelaState();
}

class _GraficoTelaState extends State<GraficoTela> {
  // Paleta local de apresentação: não altera os cálculos nem os dados.
  bool get _escuro => Theme.of(context).brightness == Brightness.dark;
  Color get _fundo =>
      _escuro ? const Color(0xFF151414) : const Color(0xFFF9F7F4);
  Color get _superficie => _escuro ? const Color(0xFF251F20) : Colors.white;
  Color get _painel =>
      _escuro ? const Color(0xFF332A2A) : const Color(0xFFF7F1EC);
  Color get _texto =>
      _escuro ? const Color(0xFFF3ECE8) : const Color(0xFF393532);
  Color get _textoSecundario =>
      _escuro ? const Color(0xFFC8B9B4) : const Color(0xFF817A74);
  Color get _trilha =>
      _escuro ? const Color(0xFF443A3B) : const Color(0xFFF0EDE9);
  Color get _botaoFundo =>
      _escuro ? const Color(0xFF574347) : const Color(0xFFE4D9C9);
  Color get _sombra => Colors.black;

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

    final double? cansaco = _indicadorNumerico(dados, 'cansaco');
    final double? ansiedade = _indicadorNumerico(dados, 'ansiedade');
    final double? sono = _indicadorNumerico(dados, 'sono');
    final double? produtividade = _indicadorNumerico(dados, 'produtividade');
    final String? atividade = dados['atividadeSignificativa'] as String?;
    final double? bemEstar = _indicadorNumerico(dados, 'bemEstar');
    if (bemEstar == null ||
        cansaco == null ||
        ansiedade == null ||
        sono == null) {
      return;
    }
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

    final String principal = _principalAtencao(cansaco, ansiedade, sono);

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
      'atividadeSignificativa': atividade,
      'dadosGrafico': {
        'cansaco': cansaco,
        'ansiedade': ansiedade,
        'sono': sono,
        'produtividade': produtividade,
      },
      // Mantém compatibilidade com a tela de Relatório (RegistrosTela),
      // que espera 'perguntas' e 'respostas'.
      'perguntas': [
        'Cansaço estimado',
        'Ansiedade percebida',
        'Dificuldade percebida com o sono',
        'Atividade significativa',
      ],
      'respostas': [
        _percentual(cansaco),
        _percentual(ansiedade),
        _percentual(sono),
        _atividadeExibida(atividade),
      ],
      'principalPonto': principal,
      'humorFrequencia': humorFrequencia,
      'interesseFrequencia': interesseFrequencia,
      'exaustaoBurnout': exaustaoBurnout,
      'distanciamentoBurnout': distanciamentoBurnout,
    };

    try {
      if (kIsWeb) {
        // API de demonstração legada: não enviar valores ausentes como zero.
        if (produtividade == null) {
          // A API web legada exige produtividade numérica.
          // Não inventar esse valor a partir da atividade significativa.
          return;
        }
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
    required double? cansaco,
    required double? ansiedade,
    required double? sono,
    required int? bemEstar,
    required String? atividade,
    String humorFrequencia = '',
    String interesseFrequencia = '',
    String exaustaoBurnout = '',
    String distanciamentoBurnout = '',
  }) async {
    final principal = _principalAtencao(cansaco, ansiedade, sono);
    if (bemEstar == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bem-estar não informado; relatório indisponível.'),
      ));
      return;
    }

    // Usa o mesmo layout de PDF que a tela de Relatório (aberta a
    // partir do Histórico), em vez de montar o documento aqui. Os
    // itens de humor/energia só entram no relatório quando há
    // resposta salva para eles.
    final pdf = PdfService.construirRelatorioCheckin(
      usuario: nomeUsuario,
      principalPonto: principal,
      bemEstar: bemEstar,
      perguntas: [
        'Cansaço estimado',
        'Ansiedade percebida',
        'Dificuldade percebida com o sono',
        'Atividade significativa',
        if (humorFrequencia.isNotEmpty) 'Humor (desânimo ou tristeza)',
        if (interesseFrequencia.isNotEmpty) 'Interesse ou prazer',
        if (exaustaoBurnout.isNotEmpty) 'Exaustão emocional',
        if (distanciamentoBurnout.isNotEmpty) 'Distanciamento ou desmotivação',
      ],
      respostas: [
        _percentual(cansaco),
        _percentual(ansiedade),
        _percentual(sono),
        _atividadeExibida(atividade),
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

    final double? cansaco = _indicadorNumerico(dados, 'cansaco');
    final double? ansiedade = _indicadorNumerico(dados, 'ansiedade');
    final double? sono = _indicadorNumerico(dados, 'sono');
    final int? bemEstar = _indicadorNumerico(dados, 'bemEstar')?.round();
    final String? atividade = dados['atividadeSignificativa'] as String?;

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
    // Atividade significativa é categórica e não entra na comparação.
    // ============================================================

    final String principalPonto = _principalAtencao(cansaco, ansiedade, sono);
    final List<Map<String, dynamic>> recomendacoes = obterRecomendacoes(
      cansaco,
      ansiedade,
      sono,
    );

    return Scaffold(
      drawer: const MenuLateral(),
      backgroundColor: _fundo,
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
                opacity: _escuro ? 0.10 : 0.42,
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
                                  color: _superficie,
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _sombra.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.menu,
                                  size: 27,
                                  color: _textoSecundario,
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
                                color: _superficie,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _sombra.withValues(alpha: 0.12),
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

                    Text(
                      "Seu resultado",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: _texto,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Uma visão geral dos seus indicadores.",
                      style: TextStyle(
                        fontSize: 14,
                        color: _textoSecundario,
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
                        color: _superficie,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _sombra.withValues(alpha: 0.055),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Resumo do principal ponto de atenção.
                          // Os indicadores abaixo são independentes:
                          // não devem ser representados como fatias de um total.
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _painel,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.self_improvement_outlined,
                                  size: 30,
                                  color: _textoSecundario,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Principal ponto de atenção',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textoSecundario,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  principalPonto,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: _texto,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Este resultado é informativo e não representa um diagnóstico.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: _textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                'Bem-estar informado: ${bemEstar == null ? 'Não informado' : '$bemEstar%'}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _texto)),
                          ),
                          const SizedBox(height: 14),
                          // ==========================================
                          // INDICADORES
                          // ==========================================

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Seus indicadores",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: _texto,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Cada barra tem sua própria escala de 0% a 100%. '
                              'Valores maiores de cansaço estimado, ansiedade percebida e dificuldade com o sono indicam mais atenção.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: _textoSecundario,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          indicadorLegenda(
                            "Cansaço",
                            cansaco,
                            const Color(
                              0xFF7895E8,
                            ),
                            Icons.airline_seat_flat,
                          ),

                          indicadorLegenda(
                            "Dificuldade com o sono",
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

                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(children: [
                              Icon(Icons.task_alt_outlined,
                                  color: Color(0xFFE8D45B)),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Atividade significativa')),
                              Text(_atividadeExibida(atividade)),
                            ]),
                          ),

                          const SizedBox(height: 5),

                          // ==========================================
                          // LEGENDA DE STATUS
                          // ==========================================

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Nível dos indicadores",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textoSecundario,
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
                        color: _trilha,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _superficie.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: _textoSecundario,
                            ),
                          ),
                          const SizedBox(
                            width: 13,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ponto de atenção",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: _texto,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: _textoSecundario,
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
                                bemEstar: bemEstar,
                                atividade: atividade,
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

                    Text(
                      "Recomendações para você",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: _texto,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "Selecionamos algumas sugestões "
                      "com base nos seus indicadores.",
                      style: TextStyle(
                        fontSize: 14,
                        color: _textoSecundario,
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
                            color: _textoSecundario,
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
    double? valor,
    Color cor,
    IconData icone, {
    bool produtividade = false,
  }) {
    final String status = valor == null
        ? "Não informado"
        : obterStatusIndicador(
            valor,
            produtividade: produtividade,
          );

    final bool atencao = valor != null && status != "Normal";

    final Color corStatus = obterCorStatus(
      valor ?? 0,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _texto,
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF654B4B),
                    ),
                  ),
                ),
              Text(
                _percentual(valor),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ((valor ?? 0) / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _trilha,
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
              style: TextStyle(
                fontSize: 11,
                color: _textoSecundario,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _botaoFundo,
          foregroundColor: _texto,
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
            color: _sombra.withValues(alpha: 0.035),
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
              color: const Color(0xFF65575B).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icone,
              color: Colors.white,
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D3035),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: const Color(0xFF59484D),
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
        color: _superficie,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _sombra.withValues(alpha: 0.045),
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
                child: Icon(
                  Icons.filter_drama_outlined,
                  color: Color(0xFF7C6BA6),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Sinais de humor e energia",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _texto,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _texto,
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _textoSecundario,
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
              child: Text(
                "Alguns desses sinais têm aparecido com frequência. "
                "Pode ser um bom assunto para trazer para sua próxima "
                "conversa com seu terapeuta.",
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _textoSecundario,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              "Isso não representa um diagnóstico, apenas um "
              "acompanhamento ao longo do tempo.",
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: _textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ============================================================
  // RECOMENDAÇÕES DINÂMICAS
  // ============================================================

  List<Map<String, dynamic>> obterRecomendacoes(
    double? cansaco,
    double? ansiedade,
    double? sono,
  ) {
    final List<Map<String, dynamic>> lista = [];

    // ==========================================================
    // CANSAÇO
    // ==========================================================

    if (cansaco != null && cansaco >= 50) {
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

    if (ansiedade != null && ansiedade >= 50) {
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

    if (sono != null && sono >= 50) {
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
