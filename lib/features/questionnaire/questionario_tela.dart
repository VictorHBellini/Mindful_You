import 'package:flutter/material.dart';

class QuestionarioTela extends StatefulWidget {
  const QuestionarioTela({super.key});

  @override
  State<QuestionarioTela> createState() => _QuestionarioTelaState();
}

class _QuestionarioTelaState extends State<QuestionarioTela>
    with TickerProviderStateMixin {
  int _paginaAtual = 0;
  bool _enviando = false;

  late final PageController _pageController;
  late final AnimationController _progressController;

  double _cansaco = 50;
  double _ansiedade = 50;
  double _sono = 50;
  double _produtividade = 50;

  String _sentimento = '';
  String _emoji = '';

  static const List<Map<String, String>> _emojis = [
    {'emoji': '😄', 'texto': 'Feliz'},
    {'emoji': '😌', 'texto': 'Calmo'},
    {'emoji': '🙂', 'texto': 'Neutro'},
    {'emoji': '😔', 'texto': 'Triste'},
    {'emoji': '😣', 'texto': 'Cansado'},
    {'emoji': '😰', 'texto': 'Ansioso'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Pré-selecionar sentimento se passado como argumento da tela inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        final argLower = args.toLowerCase();
        // Mapeia o texto do argumento para o emoji correspondente
        final match = _emojis.firstWhere(
          (e) => e['texto']!.toLowerCase() == argLower,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
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
    _progressController.dispose();
    super.dispose();
  }

  void _proximaPagina() {
    if (_paginaAtual == 0 && _sentimento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione como você está se sentindo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF8D6E63),
        ),
      );
      return;
    }

    if (_paginaAtual < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      setState(() => _paginaAtual++);
    } else {
      _concluir();
    }
  }

  void _paginaAnterior() {
    if (_paginaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      setState(() => _paginaAtual--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _concluir() async {
    if (_enviando) return;
    setState(() => _enviando = true);

    if (!mounted) return;

    // BUG CORRIGIDO: sentimento/emoji/data e os contadores de humor
    // (diasFelizes, diasCalmos etc.) eram salvos aqui em chaves globais
    // do SharedPreferences, iguais para qualquer conta usada no
    // aparelho — então trocar de usuário fazia a pessoa ver o "último
    // check-in" de outra conta. Agora tudo isso é derivado, por
    // usuário, dos registros da tabela `checkins` (ver
    // `historico_global.dart`), então só precisamos repassar o
    // sentimento e o emoji escolhidos para a tela de Gráfico, que é
    // quem grava o check-in.
    Navigator.pushReplacementNamed(
      context,
      '/grafico',
      arguments: {
        'cansaco': _cansaco,
        'ansiedade': _ansiedade,
        'sono': _sono,
        'produtividade': _produtividade,
        'sentimento': _sentimento,
        'emoji': _emoji.isEmpty ? '🙂' : _emoji,
      },
    );
  }

  double _getValorSlider(String campo) {
    switch (campo) {
      case 'cansaco':
        return _cansaco;
      case 'ansiedade':
        return _ansiedade;
      case 'sono':
        return _sono;
      case 'produtividade':
        return _produtividade;
      default:
        return 50;
    }
  }

  void _setValorSlider(String campo, double valor) {
    setState(() {
      switch (campo) {
        case 'cansaco':
          _cansaco = valor;
          break;
        case 'ansiedade':
          _ansiedade = valor;
          break;
        case 'sono':
          _sono = valor;
          break;
        case 'produtividade':
          _produtividade = valor;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progresso = (_paginaAtual + 1) / 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: const Color(0xFF40352F),
        leading: IconButton(
          onPressed: _paginaAnterior,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        centerTitle: true,
        title: Text(
          'Check-in ${_paginaAtual + 1} de 5',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF80675C),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8DFDA),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFC89494)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _paginaEmoji(),
                  _paginaSlider(
                    titulo: 'Nível de cansaço',
                    subtitulo:
                        'O quanto você está se sentindo fisicamente ou mentalmente cansado?',
                    campo: 'cansaco',
                    icone: Icons.battery_alert_outlined,
                    cor: const Color(0xFFC89494),
                    labelBaixo: 'Descansado',
                    labelAlto: 'Muito cansado',
                  ),
                  _paginaSlider(
                    titulo: 'Nível de ansiedade',
                    subtitulo:
                        'O quanto de preocupação, tensão ou nervosismo você está sentindo?',
                    campo: 'ansiedade',
                    icone: Icons.psychology_outlined,
                    cor: const Color(0xFF9575CD),
                    labelBaixo: 'Muito calmo',
                    labelAlto: 'Muito ansioso',
                  ),
                  _paginaSlider(
                    titulo: 'Qualidade do sono',
                    subtitulo:
                        'Como você avalia o seu descanso e qualidade do sono recentemente?',
                    campo: 'sono',
                    icone: Icons.bedtime_outlined,
                    cor: const Color(0xFF5C8BD6),
                    labelBaixo: 'Péssimo',
                    labelAlto: 'Excelente',
                  ),
                  _paginaSlider(
                    titulo: 'Produtividade',
                    subtitulo:
                        'O quanto você conseguiu realizar suas atividades com foco e eficiência?',
                    campo: 'produtividade',
                    icone: Icons.task_alt_outlined,
                    cor: const Color(0xFF6E9B7B),
                    labelBaixo: 'Nada produtivo',
                    labelAlto: 'Muito produtivo',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _proximaPagina,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_paginaAtual == 4 ? 'Ver resultado' : 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginaEmoji() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            titulo: 'Como você está se sentindo?',
            subtitulo:
                'Escolha o emoji que melhor representa o seu humor agora.',
            icone: Icons.sentiment_satisfied_alt_rounded,
            cor: const Color(0xFFC89494),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
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
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: selecionado ? const Color(0xFFE8DCD4) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selecionado
                          ? const Color(0xFFC89494)
                          : const Color(0xFFE8DFDA),
                      width: selecionado ? 2 : 1,
                    ),
                    boxShadow: selecionado
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC89494)
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['emoji']!,
                        style: TextStyle(fontSize: selecionado ? 38 : 34),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['texto']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selecionado ? FontWeight.bold : FontWeight.w500,
                          color: selecionado
                              ? const Color(0xFF5C4A42)
                              : const Color(0xFF80675C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _paginaSlider({
    required String titulo,
    required String subtitulo,
    required String campo,
    required IconData icone,
    required Color cor,
    required String labelBaixo,
    required String labelAlto,
  }) {
    final valor = _getValorSlider(campo);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoPergunta(
            titulo: titulo,
            subtitulo: subtitulo,
            icone: icone,
            cor: cor,
          ),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8DFDA)),
            ),
            child: Column(
              children: [
                Text(
                  '${valor.round()}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: cor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'de 100',
                  style: TextStyle(
                    fontSize: 14,
                    color: cor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: cor,
                    inactiveTrackColor: const Color(0xFFE8DFDA),
                    thumbColor: cor,
                    overlayColor: cor.withValues(alpha: 0.12),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 14),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 26),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: valor,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => _setValorSlider(campo, v),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labelBaixo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF95877F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      labelAlto,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF95877F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _indicadorNivel(valor, cor),
        ],
      ),
    );
  }

  Widget _cabecalhoPergunta({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icone, color: cor, size: 27),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40352F),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF80675C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _indicadorNivel(double valor, Color cor) {
    String texto;
    IconData icone;

    if (valor < 25) {
      texto = 'Nível baixo';
      icone = Icons.arrow_downward_rounded;
    } else if (valor < 50) {
      texto = 'Nível moderado';
      icone = Icons.remove_rounded;
    } else if (valor < 75) {
      texto = 'Nível elevado';
      icone = Icons.arrow_upward_rounded;
    } else {
      texto = 'Nível muito elevado';
      icone = Icons.keyboard_double_arrow_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
