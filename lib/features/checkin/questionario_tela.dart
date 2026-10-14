import 'package:mindful_you/services/operacao_id.dart';
import 'package:flutter/material.dart';

class QuestionarioTela extends StatefulWidget {
  const QuestionarioTela({super.key});

  @override
  State<QuestionarioTela> createState() => _QuestionarioTelaState();
}

class _QuestionarioTelaState extends State<QuestionarioTela> {
  static const int _totalPaginas = 22;

  int _paginaAtual = 0;
  bool _enviando = false;
  late final String _operacaoId = novaOperacaoId();

  late final PageController _pageController;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _fundo = Color(0xFFF8F5F2);
  static const Color _textoPrincipal = Color(0xFF40352F);
  static const Color _textoSecundario = Color(0xFF80675C);
  static const Color _textoSuave = Color(0xFFA08F87);
  static const Color _accent = Color(0xFFC89494);
  static const Color _botao = Color(0xFF8D6E63);
  static const Color _borda = Color(0xFFEDE5E0);
  static const Color _fundoSelecionado = Color(0xFFEFE2DF);
  static const Color _fundoNota = Color(0xFFF1EBE7);

  // ============================================================
  // ESCALAS
  // ============================================================

  double _bemEstar = 50;
  double _ansiedade = 50;
  double _energia = 50;
  double _sono = 50;
  double _ajudou = 50;

  // ============================================================
  // ESTADO EMOCIONAL
  // ============================================================

  String _sentimento = '';
  String _emoji = '';
  String _emocaoPredominante = '';

  // ============================================================
  // SINAIS DE HUMOR E ENERGIA (rastreio clínico)
  // ============================================================
  //
  // Itens inspirados nos construtos de afeto deprimido/anedonia
  // (usados em instrumentos de triagem para depressão) e de exaustão
  // emocional/despersonalização (usados em instrumentos de triagem
  // para burnout). O texto das perguntas foi escrito de forma
  // original — não reproduz o enunciado de nenhum instrumento
  // protegido por direitos autorais — mas segue a mesma lógica de
  // "frequência percebida" desses instrumentos, o que dá ao terapeuta
  // um sinal mais consistente ao longo do tempo do que uma escala
  // livre de 0 a 100.
  //
  // Estes 4 itens (humor, interesse/prazer, exaustão e
  // distanciamento) não substituem uma escala validada e licenciada
  // (ex.: PHQ-9, GAD-7, MBI) nem constituem diagnóstico. Se o objetivo
  // do TCC for uso psicométrico formal desses construtos, o ideal é
  // obter autorização de uso da escala oficial e aplicá-la conforme a
  // versão licenciada.

  String _humorFrequencia = '';
  String _interesseFrequencia = '';
  String _exaustaoBurnout = '';
  String _distanciamentoBurnout = '';

  // ============================================================
  // SITUAÇÕES E PENSAMENTOS
  // ============================================================

  String _acontecimento = '';

  final TextEditingController _acontecimentoController =
      TextEditingController();

  final TextEditingController _pensamentosController = TextEditingController();

  String _efeitoPensamentos = '';
  String _reacaoDiferente = '';

  // ============================================================
  // ENFRENTAMENTO
  // ============================================================

  String _dificuldadeLidar = '';
  final Set<String> _estrategias = <String>{};
  String _atividadeImportante = '';

  // ============================================================
  // AUTOCUIDADO
  // ============================================================

  String _autocuidado = '';

  // ============================================================
  // REFLEXÃO
  // ============================================================

  final TextEditingController _levezaController = TextEditingController();

  final TextEditingController _dificilController = TextEditingController();

  final TextEditingController _registroController = TextEditingController();

  // ============================================================
  // OPÇÕES
  // ============================================================

  static const List<Map<String, String>> _emojis = [
    {'emoji': '😄', 'texto': 'Feliz'},
    {'emoji': '😌', 'texto': 'Calmo'},
    {'emoji': '🙂', 'texto': 'Neutro'},
    {'emoji': '😔', 'texto': 'Triste'},
    {'emoji': '😣', 'texto': 'Cansado'},
    {'emoji': '😰', 'texto': 'Ansioso'},
  ];

  static const List<String> _emocoes = [
    'Alegria',
    'Calma',
    'Esperança',
    'Gratidão',
    'Tristeza',
    'Ansiedade',
    'Medo',
    'Irritação',
    'Frustração',
    'Cansaço',
    'Solidão',
    'Outra',
  ];

  static const List<String> _efeitosPensamentos = [
    'Aumentaram meu desconforto',
    'Diminuíram meu desconforto',
    'Não percebi mudança',
    'Não sei dizer',
  ];

  static const List<String> _opcoes = [
    'Sim',
    'Não',
    'Parcialmente',
    'Prefiro não responder',
  ];

  static const List<String> _frequencias = [
    'Nunca',
    'Raramente',
    'Às vezes',
    'Frequentemente',
    'Quase sempre',
  ];

  static const List<String> _estrategiasDisponiveis = [
    'Conversei com alguém',
    'Tirei um tempo para mim',
    'Fiz algo que gosto',
    'Tentei resolver a situação',
    'Descansei',
    'Pratiquei alguma atividade',
    'Organizei minhas tarefas',
    'Procurei apoio',
    'Evitei pensar sobre isso',
    'Não fiz nada',
    'Outra opção',
  ];

  // ============================================================
  // CICLO DE VIDA
  // ============================================================

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String && args.isNotEmpty) {
        final argLower = args.toLowerCase();

        final match = _emojis.firstWhere(
          (e) => e['texto']!.toLowerCase() == argLower,
          orElse: () => {},
        );

        if (match.isNotEmpty && mounted) {
          setState(() {
            _sentimento = match['texto']!;
            _emoji = match['emoji']!;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();

    _acontecimentoController.dispose();
    _pensamentosController.dispose();
    _levezaController.dispose();
    _dificilController.dispose();
    _registroController.dispose();

    super.dispose();
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _proximaPagina() {
    if (!_validarPaginaAtual()) return;

    if (_paginaAtual < _totalPaginas - 1) {
      setState(() {
        _paginaAtual++;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _concluir();
    }
  }

  void _paginaAnterior() {
    if (_enviando) return;

    if (_paginaAtual > 0) {
      setState(() {
        _paginaAtual--;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ============================================================
  // VALIDAÇÃO
  // ============================================================

  bool _validarPaginaAtual() {
    switch (_paginaAtual) {
      case 0:
        if (_sentimento.isEmpty) {
          _mostrarMensagem(
            'Escolha como você está se sentindo.',
          );
          return false;
        }
        break;

      case 1:
        if (_emocaoPredominante.isEmpty) {
          _mostrarMensagem(
            'Escolha a emoção que esteve mais presente hoje.',
          );
          return false;
        }
        break;

      case 3:
        if (_humorFrequencia.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 4:
        if (_interesseFrequencia.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 5:
        if (_exaustaoBurnout.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 6:
        if (_distanciamentoBurnout.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 7:
        if (_acontecimento.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 9:
        if (_efeitoPensamentos.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 10:
        if (_reacaoDiferente.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 12:
        if (_dificuldadeLidar.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 15:
        if (_atividadeImportante.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;

      case 18:
        if (_autocuidado.isEmpty) {
          _mostrarMensagem(
            'Escolha uma opção para continuar.',
          );
          return false;
        }
        break;
    }

    return true;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensagem,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _botao,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ============================================================
  // CONCLUSÃO
  // ============================================================

  Future<void> _concluir() async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
    });

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/grafico',
      arguments: {
        'operacaoId': _operacaoId,
        // Compatibilidade
        'cansaco': 100 - _energia,
        'ansiedade': _ansiedade,
        'sono': _sono,
        'produtividade': _atividadeImportante == 'Sim'
            ? 100.0
            : _atividadeImportante == 'Parcialmente'
                ? 50.0
                : 0.0,

        // Novas respostas
        'sentimento': _sentimento,
        'emoji': _emoji.isEmpty ? '🙂' : _emoji,
        'emocaoPredominante': _emocaoPredominante,
        'bemEstar': _bemEstar,

        // Sinais de humor e energia (rastreio clínico de depressão e
        // burnout — ver observação no topo da classe).
        'humorFrequencia': _humorFrequencia,
        'interesseFrequencia': _interesseFrequencia,
        'exaustaoBurnout': _exaustaoBurnout,
        'distanciamentoBurnout': _distanciamentoBurnout,

        'acontecimento': _acontecimento,
        'acontecimentoDescricao':
            _acontecimento == 'Sim' ? _acontecimentoController.text.trim() : '',

        'pensamentos': _pensamentosController.text.trim(),

        'efeitoPensamentos': _efeitoPensamentos,
        'reacaoDiferente': _reacaoDiferente,

        'dificuldadeLidar': _dificuldadeLidar,
        'estrategias': _estrategias.toList(),

        'ajudou': _ajudou,
        'atividadeImportante': _atividadeImportante,

        'energia': _energia,

        'autocuidado': _autocuidado,

        'momentoLeveza': _levezaController.text.trim(),

        'momentoDificil': _dificilController.text.trim(),

        'registro': _registroController.text.trim(),
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final progresso = (_paginaAtual + 1) / _totalPaginas;

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _fundo,
        foregroundColor: _textoPrincipal,
        leading: IconButton(
          onPressed: _enviando ? null : _paginaAnterior,
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 23,
          ),
        ),
        centerTitle: true,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _tituloSecao(_paginaAtual),
            key: ValueKey(
              _tituloSecao(_paginaAtual),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textoSecundario,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // PROGRESSO
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                2,
                22,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: progresso,
                  ),
                  duration: const Duration(
                    milliseconds: 400,
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE7DED9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _accent,
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                9,
                22,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    '${_paginaAtual + 1} de $_totalPaginas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textoSecundario,
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _tituloCurto(_paginaAtual),
                      key: ValueKey(
                        _tituloCurto(_paginaAtual),
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _textoSuave,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ----------------------------------------------------
            // PÁGINAS
            // ----------------------------------------------------

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _paginaEmoji(),
                  _paginaEmocaoPredominante(),
                  _paginaSlider(
                    titulo: 'Como você avalia seu bem-estar hoje?',
                    subtitulo:
                        'Pense em como você tem se sentido de maneira geral ao longo do dia.',
                    campo: 'bemEstar',
                    icone: Icons.favorite_outline_rounded,
                    cor: const Color(0xFFC89494),
                    labelBaixo: 'Muito baixo',
                    labelAlto: 'Muito alto',
                  ),
                  _paginaHumorFrequencia(),
                  _paginaInteresseFrequencia(),
                  _paginaExaustaoBurnout(),
                  _paginaDistanciamentoBurnout(),
                  _paginaAcontecimento(),
                  _paginaTexto(
                    numero: '09',
                    titulo:
                        'Em uma situação difícil, quais pensamentos passaram pela sua cabeça?',
                    subtitulo:
                        'Se lembrar, descreva brevemente os pensamentos ou interpretações que surgiram.',
                    controller: _pensamentosController,
                    hint:
                        'Ex.: pensei que não daria conta, que precisava resolver tudo imediatamente...',
                    icone: Icons.psychology_alt_outlined,
                    cor: const Color(0xFF9575CD),
                    nota:
                        'O importante é registrar como você percebeu aquele momento, sem julgar seus pensamentos.',
                    maxLines: 7,
                  ),
                  _paginaEfeitoPensamentos(),
                  _paginaReacaoDiferente(),
                  _paginaSlider(
                    titulo:
                        'Quanto você percebeu preocupação, tensão ou nervosismo hoje?',
                    subtitulo:
                        'Considere a intensidade percebida ao longo do seu dia.',
                    campo: 'ansiedade',
                    icone: Icons.psychology_outlined,
                    cor: const Color(0xFF9575CD),
                    labelBaixo: 'Nenhum',
                    labelAlto: 'Muito intenso',
                  ),
                  _paginaDificuldadeLidar(),
                  _paginaEstrategias(),
                  _paginaSlider(
                    titulo: 'O que você fez ajudou você a se sentir melhor?',
                    subtitulo:
                        'Pense nas estratégias que utilizou diante de um momento difícil hoje.',
                    campo: 'ajudou',
                    icone: Icons.self_improvement_rounded,
                    cor: const Color(0xFF7B8D70),
                    labelBaixo: 'Não ajudou',
                    labelAlto: 'Ajudou muito',
                  ),
                  _paginaAtividadeImportante(),
                  _paginaSlider(
                    titulo: 'Como você avalia sua energia hoje?',
                    subtitulo:
                        'Considere sua disposição física e mental para realizar suas atividades.',
                    campo: 'energia',
                    icone: Icons.battery_charging_full_rounded,
                    cor: const Color(0xFF6E9B7B),
                    labelBaixo: 'Muito baixa',
                    labelAlto: 'Muito alta',
                  ),
                  _paginaSlider(
                    titulo: 'Como você avalia seu sono recentemente?',
                    subtitulo:
                        'Considere a qualidade do seu descanso e como você se sentiu ao dormir e acordar.',
                    campo: 'sono',
                    icone: Icons.bedtime_outlined,
                    cor: const Color(0xFF5C8BD6),
                    labelBaixo: 'Muito ruim',
                    labelAlto: 'Excelente',
                  ),
                  _paginaAutocuidado(),
                  _paginaTexto(
                    numero: '20',
                    titulo:
                        'O que trouxe um pouco de leveza ou satisfação para o seu dia?',
                    subtitulo:
                        'Pode ser algo simples: uma conversa, uma conquista, um descanso ou um momento agradável.',
                    controller: _levezaController,
                    hint: 'Se quiser, conte um pouco sobre esse momento...',
                    icone: Icons.wb_sunny_outlined,
                    cor: const Color(0xFFB58A58),
                    nota:
                        'Pequenos momentos também podem ser importantes. Registre aquilo que fez diferença para você.',
                    maxLines: 6,
                  ),
                  _paginaTexto(
                    numero: '21',
                    titulo: 'O que foi mais difícil hoje?',
                    subtitulo:
                        'Descreva, se quiser, uma situação, pensamento, emoção ou atividade que tenha sido especialmente difícil.',
                    controller: _dificilController,
                    hint: 'Escreva aqui o que foi mais difícil para você...',
                    icone: Icons.flag_outlined,
                    cor: const Color(0xFFB07A61),
                    nota:
                        'Você pode responder de forma breve. O importante é registrar aquilo que teve significado para você.',
                    maxLines: 7,
                  ),
                  _paginaRegistro(),
                ],
              ),
            ),

            // ----------------------------------------------------
            // BOTÃO
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                22,
              ),
              child: _botaoContinuar(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TÍTULOS
  // ============================================================

  String _tituloSecao(int pagina) {
    if (pagina <= 2) {
      return 'Como estou?';
    }

    if (pagina <= 6) {
      return 'Sinais de humor e energia';
    }

    if (pagina <= 10) {
      return 'O que aconteceu?';
    }

    if (pagina <= 15) {
      return 'Como lidei com isso?';
    }

    if (pagina <= 18) {
      return 'Autocuidado e rotina';
    }

    return 'Refletindo sobre meu dia';
  }

  String _tituloCurto(int pagina) {
    if (pagina <= 2) {
      return 'Bem-estar';
    }

    if (pagina <= 6) {
      return 'Humor e alerta';
    }

    if (pagina <= 10) {
      return 'Experiências';
    }

    if (pagina <= 15) {
      return 'Enfrentamento';
    }

    if (pagina <= 18) {
      return 'Rotina';
    }

    return 'Reflexão';
  }

  // ============================================================
  // BOTÃO PRINCIPAL
  // ============================================================

  Widget _botaoContinuar() {
    final ultimo = _paginaAtual == _totalPaginas - 1;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _enviando ? null : _proximaPagina,
        style: ElevatedButton.styleFrom(
          backgroundColor: _botao,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8AAA3),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _enviando
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: ValueKey(ultimo),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ultimo ? 'Ver meu resumo' : 'Continuar',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      ultimo
                          ? Icons.insights_rounded
                          : Icons.arrow_forward_rounded,
                      size: 19,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // PÁGINA 01 — EMOJI
  // ============================================================

  Widget _paginaEmoji() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '01',
            titulo: 'Como você está se sentindo neste momento?',
            subtitulo:
                'Escolha a opção que melhor representa seu estado emocional agora.',
            icone: Icons.sentiment_satisfied_alt_rounded,
            cor: _accent,
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final item = _emojis[index];

              final selecionado = _sentimento == item['texto'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _sentimento = item['texto']!;
                    _emoji = item['emoji']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: selecionado ? _fundoSelecionado : Colors.white,
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: selecionado ? _accent : _borda,
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selecionado ? 1.08 : 1,
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: Text(
                          item['emoji']!,
                          style: const TextStyle(
                            fontSize: 34,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        item['texto']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              selecionado ? FontWeight.w700 : FontWeight.w500,
                          color:
                              selecionado ? _textoPrincipal : _textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          _notaInformativa(
            'Não existe resposta certa ou errada. Registre como você percebe seu estado emocional neste momento.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 02 — EMOÇÃO
  // ============================================================

  Widget _paginaEmocaoPredominante() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '02',
            titulo: 'Qual emoção esteve mais presente hoje?',
            subtitulo:
                'Escolha a emoção que melhor representa a experiência emocional predominante do seu dia.',
            icone: Icons.mood_outlined,
            cor: const Color(0xFFB58A58),
          ),
          const SizedBox(height: 24),
          ..._emocoes.map(
            (emocao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: emocao,
                selecionado: _emocaoPredominante == emocao,
                onTap: () {
                  setState(() {
                    _emocaoPredominante = emocao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 04 — HUMOR (afeto deprimido)
  // ============================================================

  Widget _paginaHumorFrequencia() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '04',
            titulo:
                'Nos últimos dias, com que frequência você se sentiu desanimado(a), para baixo ou sem esperança?',
            subtitulo:
                'Pense em como esse sentimento apareceu ao longo do seu dia a dia recente, não só hoje.',
            icone: Icons.filter_drama_outlined,
            cor: const Color(0xFF7C6BA6),
          ),
          const SizedBox(height: 24),
          ..._frequencias.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _humorFrequencia == opcao,
                onTap: () {
                  setState(() {
                    _humorFrequencia = opcao;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _notaInformativa(
            'Esta pergunta ajuda a acompanhar seu humor ao longo do tempo e não representa, por si só, um diagnóstico.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 05 — INTERESSE / PRAZER (anedonia)
  // ============================================================

  Widget _paginaInteresseFrequencia() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '05',
            titulo:
                'Nos últimos dias, com que frequência você sentiu pouco interesse ou prazer em fazer coisas que geralmente gosta?',
            subtitulo:
                'Considere atividades, pessoas ou hobbies que normalmente te dão satisfação.',
            icone: Icons.local_florist_outlined,
            cor: const Color(0xFF7C6BA6),
          ),
          const SizedBox(height: 24),
          ..._frequencias.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _interesseFrequencia == opcao,
                onTap: () {
                  setState(() {
                    _interesseFrequencia = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 06 — EXAUSTÃO EMOCIONAL (burnout)
  // ============================================================

  Widget _paginaExaustaoBurnout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '06',
            titulo:
                'Você tem se sentido emocionalmente esgotado(a) por causa das suas responsabilidades?',
            subtitulo:
                'Pense em trabalho, estudos, cuidado com outras pessoas ou outras obrigações do seu dia a dia.',
            icone: Icons.battery_alert_outlined,
            cor: const Color(0xFFB6763D),
          ),
          const SizedBox(height: 24),
          ..._frequencias.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _exaustaoBurnout == opcao,
                onTap: () {
                  setState(() {
                    _exaustaoBurnout = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 07 — DISTANCIAMENTO / CINISMO (burnout)
  // ============================================================

  Widget _paginaDistanciamentoBurnout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '07',
            titulo:
                'Você tem se sentido mais distante, desmotivado(a) ou indiferente em relação a coisas que normalmente importam para você?',
            subtitulo:
                'Pode incluir trabalho, estudos, relações ou atividades que antes tinham mais significado.',
            icone: Icons.blur_on_rounded,
            cor: const Color(0xFFB6763D),
          ),
          const SizedBox(height: 24),
          ..._frequencias.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _distanciamentoBurnout == opcao,
                onTap: () {
                  setState(() {
                    _distanciamentoBurnout = opcao;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _notaInformativa(
            'Essas perguntas ajudam a identificar sinais de sobrecarga ao longo do tempo, para conversar com seu terapeuta se fizer sentido para você.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 08 — ACONTECIMENTO
  // ============================================================

  Widget _paginaAcontecimento() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '08',
            titulo: 'Aconteceu algo hoje que influenciou como você se sentiu?',
            subtitulo:
                'Pode ser algo positivo, difícil ou simplesmente marcante para você.',
            icone: Icons.event_note_outlined,
            cor: const Color(0xFFB07A61),
          ),
          const SizedBox(height: 26),
          _opcaoSelecao(
            texto: 'Sim',
            selecionado: _acontecimento == 'Sim',
            onTap: () {
              setState(() {
                _acontecimento = 'Sim';
              });
            },
          ),
          const SizedBox(height: 10),
          _opcaoSelecao(
            texto: 'Não',
            selecionado: _acontecimento == 'Não',
            onTap: () {
              setState(() {
                _acontecimento = 'Não';
                _acontecimentoController.clear();
              });
            },
          ),
          const SizedBox(height: 10),
          _opcaoSelecao(
            texto: 'Prefiro não responder',
            selecionado: _acontecimento == 'Prefiro não responder',
            onTap: () {
              setState(() {
                _acontecimento = 'Prefiro não responder';
                _acontecimentoController.clear();
              });
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _acontecimento == 'Sim'
                ? Padding(
                    key: const ValueKey(
                      'campo',
                    ),
                    padding: const EdgeInsets.only(
                      top: 20,
                    ),
                    child: _campoTexto(
                      controller: _acontecimentoController,
                      hintText:
                          'Se quiser, descreva brevemente o que aconteceu...',
                      maxLines: 5,
                    ),
                  )
                : const SizedBox(
                    key: ValueKey(
                      'sem-campo',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINAS DE TEXTO
  // ============================================================

  Widget _paginaTexto({
    required String numero,
    required String titulo,
    required String subtitulo,
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    required Color cor,
    required String nota,
    int maxLines = 6,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: numero,
            titulo: titulo,
            subtitulo: subtitulo,
            icone: icone,
            cor: cor,
          ),
          const SizedBox(height: 26),
          _campoTexto(
            controller: controller,
            hintText: hint,
            maxLines: maxLines,
          ),
          const SizedBox(height: 18),
          _notaInformativa(nota),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 10
  // ============================================================

  Widget _paginaEfeitoPensamentos() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '10',
            titulo:
                'Você percebeu que esses pensamentos influenciaram como se sentiu?',
            subtitulo:
                'Escolha a opção que melhor representa o efeito percebido.',
            icone: Icons.compare_arrows_rounded,
            cor: const Color(0xFF9575CD),
          ),
          const SizedBox(height: 24),
          ..._efeitosPensamentos.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _efeitoPensamentos == opcao,
                onTap: () {
                  setState(() {
                    _efeitoPensamentos = opcao;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _notaInformativa(
            'Não existe uma resposta certa. O importante é registrar como você percebeu essa experiência.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 11
  // ============================================================

  Widget _paginaReacaoDiferente() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '11',
            titulo:
                'Houve alguma situação em que você gostaria de ter reagido de outra maneira?',
            subtitulo:
                'Pense em como você agiu e se existe algo que gostaria de compreender melhor sobre essa reação.',
            icone: Icons.alt_route_rounded,
            cor: const Color(0xFFB07A61),
          ),
          const SizedBox(height: 24),
          ..._opcoes.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _reacaoDiferente == opcao,
                onTap: () {
                  setState(() {
                    _reacaoDiferente = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 13
  // ============================================================

  Widget _paginaDificuldadeLidar() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '13',
            titulo:
                'Em algum momento hoje você sentiu dificuldade para lidar com o que estava acontecendo?',
            subtitulo:
                'Considere situações em que você percebeu poucos recursos para lidar com o momento.',
            icone: Icons.support_outlined,
            cor: const Color(0xFF9B7B70),
          ),
          const SizedBox(height: 24),
          ..._opcoes.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _dificuldadeLidar == opcao,
                onTap: () {
                  setState(() {
                    _dificuldadeLidar = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 14
  // ============================================================

  Widget _paginaEstrategias() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '14',
            titulo: 'O que você fez para lidar com um momento difícil hoje?',
            subtitulo:
                'Selecione uma ou mais opções. Se não passou por um momento difícil, pode deixar sem seleção.',
            icone: Icons.handshake_outlined,
            cor: const Color(0xFF7B8D70),
          ),
          const SizedBox(height: 24),
          ..._estrategiasDisponiveis.map(
            (estrategia) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoMultipla(
                texto: estrategia,
                selecionado: _estrategias.contains(
                  estrategia,
                ),
                onTap: () {
                  setState(() {
                    if (_estrategias.contains(
                      estrategia,
                    )) {
                      _estrategias.remove(
                        estrategia,
                      );
                    } else if (estrategia == 'Não fiz nada') {
                      _estrategias
                        ..clear()
                        ..add(
                          estrategia,
                        );
                    } else {
                      _estrategias.remove(
                        'Não fiz nada',
                      );
                      _estrategias.add(
                        estrategia,
                      );
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _notaInformativa(
            'As opções representam diferentes formas de lidar com situações. Não existe uma estratégia certa para todos os momentos.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 16
  // ============================================================

  Widget _paginaAtividadeImportante() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '16',
            titulo:
                'Você conseguiu realizar alguma atividade que considera importante para você?',
            subtitulo:
                'Pode ser uma tarefa, estudo, trabalho, cuidado pessoal, relacionamento ou outra atividade significativa.',
            icone: Icons.task_alt_rounded,
            cor: const Color(0xFF6E9B7B),
          ),
          const SizedBox(height: 24),
          ..._opcoes.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _atividadeImportante == opcao,
                onTap: () {
                  setState(() {
                    _atividadeImportante = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 19
  // ============================================================

  Widget _paginaAutocuidado() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '19',
            titulo:
                'Você conseguiu reservar algum momento para descansar ou cuidar de si?',
            subtitulo:
                'Considere pausas, descanso, lazer, alimentação, higiene, atividade física ou outros cuidados pessoais.',
            icone: Icons.spa_outlined,
            cor: const Color(0xFF7B8D70),
          ),
          const SizedBox(height: 24),
          ..._opcoes.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _opcaoSelecao(
                texto: opcao,
                selecionado: _autocuidado == opcao,
                onTap: () {
                  setState(() {
                    _autocuidado = opcao;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PÁGINA 22
  // ============================================================

  Widget _paginaRegistro() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: '22',
            titulo: 'Existe algo que você gostaria de registrar?',
            subtitulo:
                'Escreva livremente sobre algo que considere importante no seu dia. Esta etapa é opcional.',
            icone: Icons.edit_note_rounded,
            cor: _botao,
          ),
          const SizedBox(height: 28),
          _campoTexto(
            controller: _registroController,
            hintText: 'Escreva aqui o que você gostaria de registrar...',
            maxLines: 9,
          ),
          const SizedBox(height: 18),
          _notaInformativa(
            'Use este espaço para acrescentar algo que não apareceu nas perguntas anteriores.',
          ),
          const SizedBox(height: 10),
          _notaInformativa(
            'Este check-in é um recurso de acompanhamento e autorreflexão. Ele não realiza diagnóstico psicológico.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLIDERS
  // ============================================================

  Widget _paginaSlider({
    required String titulo,
    required String subtitulo,
    required String campo,
    required IconData icone,
    required Color cor,
    required String labelBaixo,
    required String labelAlto,
  }) {
    double valorAtual = 50;
    String numero = '';

    switch (campo) {
      case 'bemEstar':
        valorAtual = _bemEstar;
        numero = '03';
        break;

      case 'ansiedade':
        valorAtual = _ansiedade;
        numero = '12';
        break;

      case 'ajudou':
        valorAtual = _ajudou;
        numero = '15';
        break;

      case 'energia':
        valorAtual = _energia;
        numero = '17';
        break;

      case 'sono':
        valorAtual = _sono;
        numero = '18';
        break;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            numero: numero,
            titulo: titulo,
            subtitulo: subtitulo,
            icone: icone,
            cor: cor,
          ),

          const SizedBox(height: 42),

          // ----------------------------------------------------
          // VALOR
          // ----------------------------------------------------

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Column(
                key: ValueKey(
                  valorAtual.round(),
                ),
                children: [
                  Text(
                    valorAtual.round().toString(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: cor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _descricaoSlider(
                      valorAtual,
                      campo,
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // ----------------------------------------------------
          // SLIDER
          // ----------------------------------------------------

          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: cor,
              inactiveTrackColor: cor.withValues(alpha: 0.18),
              thumbColor: cor,
              overlayColor: cor.withValues(alpha: 0.10),
              trackHeight: 7,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 20,
              ),
            ),
            child: Slider(
              value: valorAtual,
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (valor) {
                setState(() {
                  switch (campo) {
                    case 'bemEstar':
                      _bemEstar = valor;
                      break;

                    case 'ansiedade':
                      _ansiedade = valor;
                      break;

                    case 'ajudou':
                      _ajudou = valor;
                      break;

                    case 'energia':
                      _energia = valor;
                      break;

                    case 'sono':
                      _sono = valor;
                      break;
                  }
                });
              },
            ),
          ),

          const SizedBox(height: 7),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelBaixo,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textoSecundario,
                ),
              ),
              Text(
                labelAlto,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textoSecundario,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          _notaInformativa(
            'Não existe uma pontuação certa ou errada. Escolha o ponto que melhor representa como você percebeu seu dia.',
          ),
        ],
      ),
    );
  }

  String _descricaoSlider(
    double valor,
    String campo,
  ) {
    if (campo == 'ansiedade') {
      if (valor < 20) return 'Muito tranquilo';
      if (valor < 40) return 'Leve';
      if (valor < 60) return 'Moderado';
      if (valor < 80) return 'Intenso';
      return 'Muito intenso';
    }

    if (campo == 'sono') {
      if (valor < 20) return 'Muito ruim';
      if (valor < 40) return 'Ruim';
      if (valor < 60) return 'Regular';
      if (valor < 80) return 'Bom';
      return 'Excelente';
    }

    if (valor < 20) return 'Muito baixo';
    if (valor < 40) return 'Baixo';
    if (valor < 60) return 'Moderado';
    if (valor < 80) return 'Bom';

    return 'Muito bom';
  }

  // ============================================================
  // CABEÇALHO DAS PERGUNTAS
  // ============================================================

  Widget _cabecalhoPergunta({
    required String numero,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color: cor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Pergunta $numero',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: _textoSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _textoPrincipal,
            height: 1.18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: _textoSecundario,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTA INFORMATIVA
  // ============================================================

  Widget _notaInformativa(
    String texto,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: _fundoNota,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _botao,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: _textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPÇÃO DE SELEÇÃO
  // ============================================================

  Widget _opcaoSelecao({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: selecionado ? _fundoSelecionado : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado ? _accent : _borda,
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selecionado ? _accent : Colors.transparent,
                  border: Border.all(
                    color: selecionado
                        ? _accent
                        : const Color(
                            0xFFB8AAA3,
                          ),
                    width: 1.5,
                  ),
                ),
                child: selecionado
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                    color: _textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPÇÃO MÚLTIPLA
  // ============================================================

  Widget _opcaoMultipla({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 160,
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selecionado ? const Color(0xFFE8E5DE) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado ? const Color(0xFF7B8D70) : _borda,
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 160,
                ),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selecionado
                      ? const Color(
                          0xFF7B8D70,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    7,
                  ),
                  border: Border.all(
                    color: selecionado
                        ? const Color(
                            0xFF7B8D70,
                          )
                        : const Color(
                            0xFFB8AAA3,
                          ),
                    width: 1.5,
                  ),
                ),
                child: selecionado
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                    color: _textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO DE TEXTO
  // ============================================================

  Widget _campoTexto({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 5,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borda,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(
          fontSize: 14,
          color: _textoPrincipal,
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0A39C),
            fontSize: 13.5,
            height: 1.4,
          ),
          contentPadding: const EdgeInsets.all(18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
