import 'package:flutter/material.dart';
import 'package:mindful_you/core/utils/operacao_id.dart';
import 'package:mindful_you/services/checkin_indicadores.dart';

/// Check-in breve de autorrelato. Não é instrumento diagnóstico ou escala validada.
class QuestionarioTela extends StatefulWidget {
  const QuestionarioTela({super.key});

  @override
  State<QuestionarioTela> createState() => _QuestionarioTelaState();
}

class _QuestionarioTelaState extends State<QuestionarioTela> {
  bool get _escuro => Theme.of(context).brightness == Brightness.dark;
  Color get _fundo =>
      _escuro ? const Color(0xFF151414) : const Color(0xFFF8F5F2);
  Color get _texto =>
      _escuro ? const Color(0xFFF1E9E6) : const Color(0xFF40352F);
  Color get _secundario =>
      _escuro ? const Color(0xFFBDAFAB) : const Color(0xFF80675C);
  Color get _destaque =>
      _escuro ? const Color(0xFFD5A0A4) : const Color(0xFFC89494);
  Color get _botao =>
      _escuro ? const Color(0xFFAD8587) : const Color(0xFF8D6E63);
  Color get _borda =>
      _escuro ? const Color(0xFF423738) : const Color(0xFFEDE5E0);
  Color get _superficie => _escuro ? const Color(0xFF251F20) : Colors.white;
  Color get _selecionado =>
      _escuro ? const Color(0xFF403035) : const Color(0xFFEFE2DF);
  Color get _trilha =>
      _escuro ? const Color(0xFF403637) : const Color(0xFFE7DED9);
  Color get _iconeFundo =>
      _escuro ? const Color(0xFF382D30) : const Color(0xFFEFE2DF);
  Color get _iconeInativo =>
      _escuro ? const Color(0xFF9B8987) : const Color(0xFFCCBEB7);
  static const _total = 7;

  final _controller = PageController();
  final _registroController = TextEditingController();
  final String _operacaoId = novaOperacaoId();
  int _pagina = 0;
  bool _enviando = false;
  // Registra uma escolha consciente em cada escala (páginas 2 a 5).
  final Set<int> _escalasRespondidas = <int>{};
  String _sentimento = '';
  String _emoji = '';
  double _bemEstar = 50;
  double _ansiedade = 50;
  double _energia = 50;
  double _qualidadeSono = 50;
  String _atividadeImportante = '';

  static const _humores = <(String, String)>[
    ('😄', 'Feliz'),
    ('😌', 'Calmo'),
    ('🙂', 'Neutro'),
    ('😔', 'Triste'),
    ('😣', 'Cansado'),
    ('😰', 'Ansioso'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sentimento.isNotEmpty) return;
    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is String) {
      for (final item in _humores) {
        if (item.$2.toLowerCase() == argumento.toLowerCase()) {
          _sentimento = item.$2;
          _emoji = item.$1;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _registroController.dispose();
    super.dispose();
  }

  void _voltar() {
    if (_enviando) return;
    if (_pagina == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _pagina--);
      _controller.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _continuar() {
    if (_enviando) return;
    if (_pagina == 0 && _sentimento.isEmpty ||
        _pagina == 5 && _atividadeImportante.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma opção para continuar.')),
      );
      return;
    }
    if (_pagina >= 1 &&
        _pagina <= 4 &&
        !_escalasRespondidas.contains(_pagina)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toque ou mova a escala para registrar sua resposta.'),
        ),
      );
      return;
    }
    if (_pagina < _total - 1) {
      setState(() => _pagina++);
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _concluir();
    }
  }

  void _concluir() {
    setState(() => _enviando = true);
    final indicadores = CheckinIndicadores(
      bemEstar: _bemEstar,
      ansiedade: _ansiedade,
      energia: _energia,
      qualidadeSono: _qualidadeSono,
      atividadeSignificativa: _atividadeImportante,
    );
    Navigator.of(context).pushReplacementNamed(
      '/grafico',
      arguments: <String, dynamic>{
        'operacaoId': _operacaoId,
        ...indicadores.toDados(),
        'sentimento': _sentimento,
        'emoji': _emoji.isEmpty ? '🙂' : _emoji,
        'emocaoPredominante': _sentimento,
        // Chaves legadas preservadas. Campos não perguntados ficam vazios,
        // sem inventar respostas ou atribuir frequências clínicas.
        'humorFrequencia': '',
        'interesseFrequencia': '',
        'exaustaoBurnout': '',
        'distanciamentoBurnout': '',
        'acontecimento': '',
        'acontecimentoDescricao': '',
        'pensamentos': '',
        'efeitoPensamentos': '',
        'reacaoDiferente': '',
        'dificuldadeLidar': '',
        'estrategias': <String>[],
        'ajudou': null,
        'atividadeImportante': _atividadeImportante,
        'energia': _energia,
        'autocuidado': '',
        'momentoLeveza': '',
        'momentoDificil': '',
        'registro': _registroController.text.trim(),
      },
    );
  }

  Widget _cabecalho(String titulo, String descricao, IconData icone) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: _iconeFundo,
          child: Icon(icone, color: _botao),
        ),
        const SizedBox(height: 20),
        Text(titulo,
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: _texto)),
        const SizedBox(height: 10),
        Text(descricao,
            style: TextStyle(fontSize: 14, height: 1.5, color: _secundario)),
        const SizedBox(height: 26),
      ]);

  Widget _cartao(String titulo, bool selecionado, VoidCallback onTap,
          {String? emoji}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selecionado ? _selecionado : _superficie,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selecionado ? _destaque : _borda),
              ),
              child: Row(children: [
                if (emoji != null) ...[
                  Text(emoji, style: TextStyle(fontSize: 27)),
                  const SizedBox(width: 14),
                ],
                Expanded(
                    child: Text(titulo,
                        style: TextStyle(
                            color: _texto, fontWeight: FontWeight.w600))),
                Icon(selecionado ? Icons.check_circle : Icons.circle_outlined,
                    color: selecionado ? _destaque : _iconeInativo),
              ]),
            ),
          ),
        ),
      );

  Widget _escala(String titulo, String descricao, IconData icone, double valor,
      ValueChanged<double> alterar, String minimo, String maximo,
      {String? orientacao}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cabecalho(titulo, descricao, icone),
      Center(
          child: Text('${valor.round()}',
              style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold, color: _botao))),
      const SizedBox(height: 18),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: _destaque,
          thumbColor: _botao,
          inactiveTrackColor: _trilha,
          trackHeight: 6,
        ),
        child: Slider(
          value: valor,
          min: 0,
          max: 100,
          divisions: 10,
          label: '${valor.round()}',
          onChanged: (novoValor) {
            _escalasRespondidas.add(_pagina);
            alterar(novoValor);
          },
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(minimo, style: TextStyle(color: _secundario))),
        const SizedBox(width: 16),
        Flexible(
            child: Text(maximo,
                textAlign: TextAlign.end,
                style: TextStyle(color: _secundario))),
      ]),
      const SizedBox(height: 28),
      Text(
          orientacao ??
              'Não existe resposta certa ou errada. Considere como foi seu dia.',
          style: TextStyle(color: _secundario, height: 1.5)),
    ]);
  }

  Widget _conteudo(int pagina) {
    switch (pagina) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cabecalho(
              'Como você está se sentindo neste momento?',
              'Escolha a opção que melhor descreve como você se sente agora. Não existe resposta certa ou errada.',
              Icons.mood_outlined),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _humores.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1),
            itemBuilder: (_, i) {
              final item = _humores[i];
              return _cartao(item.$2, _sentimento == item.$2, () {
                setState(() {
                  _sentimento = item.$2;
                  _emoji = item.$1;
                });
              }, emoji: item.$1);
            },
          ),
        ]);
      case 1:
        return _escala(
            'Considerando o dia de hoje, como você avalia seu bem-estar geral?',
            'Considere como você se sentiu ao longo de hoje, de muito baixo a muito alto.',
            Icons.favorite_outline,
            _bemEstar,
            (v) => setState(() => _bemEstar = v),
            'Muito baixo',
            'Muito alto');
      case 2:
        return _escala(
            'Quanto você percebeu preocupação, tensão ou nervosismo hoje?',
            'Considere a intensidade dessas sensações ao longo de hoje, mesmo que tenham variado.',
            Icons.psychology_outlined,
            _ansiedade,
            (v) => setState(() => _ansiedade = v),
            'Nenhuma',
            'Muito intensa');
      case 3:
        return _escala(
            'Como esteve sua disposição física e mental hoje?',
            'Pense na energia que percebeu ao longo de hoje, sem se comparar com outras pessoas.',
            Icons.battery_charging_full_outlined,
            _energia,
            (v) => setState(() => _energia = v),
            'Muito baixa',
            'Muito alta');
      case 4:
        return _escala(
            'Como você avalia a qualidade do seu último período de sono?',
            'Considere o descanso percebido e como você se sentiu ao acordar. Avalie apenas o último período de sono.',
            Icons.bedtime_outlined,
            _qualidadeSono,
            (v) => setState(() => _qualidadeSono = v),
            'Muito ruim',
            'Muito boa',
            orientacao:
                'Não existe resposta certa ou errada. Considere apenas a qualidade do seu último período de sono.');
      case 5:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cabecalho(
              'Hoje, você conseguiu realizar alguma atividade que considera importante?',
              'Pode ser uma tarefa, um momento de descanso, cuidado pessoal ou algo significativo para você.',
              Icons.task_alt_outlined),
          for (final opcao in [
            'Sim',
            'Parcialmente',
            'Não',
            'Prefiro não responder'
          ])
            _cartao(opcao, _atividadeImportante == opcao,
                () => setState(() => _atividadeImportante = opcao)),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cabecalho(
              'Há algo sobre seu dia que você gostaria de registrar?',
              'Este espaço é opcional. Você pode registrar uma experiência, um sentimento ou simplesmente seguir em frente.',
              Icons.edit_note_outlined),
          TextField(
            controller: _registroController,
            minLines: 5,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Como foi seu dia? O que gostaria de lembrar?',
              filled: true,
              fillColor: _superficie,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: _borda)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: _borda)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
              'Este check-in registra percepções pessoais. Não é uma escala psicológica validada nem substitui avaliação profissional.',
              style: TextStyle(color: _secundario, height: 1.5)),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        foregroundColor: _texto,
        elevation: 0,
        leading: IconButton(
            onPressed: _enviando ? null : _voltar,
            icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Meu check-in', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_pagina + 1) / _total,
                  minHeight: 7,
                  backgroundColor: _trilha,
                  valueColor: AlwaysStoppedAnimation(_destaque),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text('${_pagina + 1} de $_total',
                    style: TextStyle(color: _secundario)),
                const Spacer(),
                Text('Check-in rápido', style: TextStyle(color: _secundario)),
              ]),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _total,
              itemBuilder: (_, i) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                child: _conteudo(i),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _enviando ? null : _continuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _botao,
                  foregroundColor:
                      _escuro ? const Color(0xFF191516) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                    _pagina == _total - 1 ? 'Ver meu resultado' : 'Continuar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
