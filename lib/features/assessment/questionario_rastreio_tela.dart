import 'package:mindful_you/core/utils/operacao_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';
import 'package:mindful_you/features/assessment/services/avaliacao_service.dart';

/// Formulário DEMONSTRATIVO inspirado nos domínios do GAD-7 e PHQ-9.
/// A redação abaixo NÃO é uma versão brasileira validada das escalas.
/// Não usar os resultados para decisões clínicas.
class QuestionarioRastreioTela extends StatefulWidget {
  final String instrumento;
  const QuestionarioRastreioTela({super.key, required this.instrumento});

  @override
  State<QuestionarioRastreioTela> createState() =>
      _QuestionarioRastreioTelaState();
}

class _QuestionarioRastreioTelaState extends State<QuestionarioRastreioTela> {
  static const _gad = [
    'Sentiu nervosismo ou tensão?',
    'Teve dificuldade para controlar suas preocupações?',
    'Preocupou-se excessivamente com diferentes situações?',
    'Teve dificuldade para relaxar?',
    'Sentiu inquietação a ponto de ser difícil permanecer parado?',
    'Ficou irritado ou impaciente com facilidade?',
    'Sentiu receio de que algo ruim pudesse acontecer?',
  ];

  static const _phq = [
    'Percebeu pouco interesse ou prazer nas atividades?',
    'Sentiu tristeza, desânimo ou desesperança?',
    'Teve dificuldades com o sono ou dormiu além do habitual?',
    'Sentiu cansaço ou pouca energia?',
    'Percebeu mudanças no apetite?',
    'Teve pensamentos negativos sobre si ou sentimento de fracasso?',
    'Teve dificuldade para se concentrar?',
    'Percebeu lentidão ou agitação incomum nos movimentos?',
    'Teve pensamentos sobre morte ou sobre machucar a si mesmo?',
  ];

  static const _opcoes = [
    'Nenhuma vez',
    'Alguns dias',
    'Mais da metade dos dias',
    'Quase todos os dias',
  ];

  late final List<int?> _respostas;
  bool _salvando = false;
  bool _finalizado = false;
  late final String _operacaoId = novaOperacaoId();

  bool get _phq9 => widget.instrumento == 'PHQ9';
  List<String> get _perguntas => _phq9 ? _phq : _gad;

  @override
  void initState() {
    super.initState();
    _respostas = List<int?>.filled(_phq9 ? 9 : 7, null);
  }

  Future<void> _salvar() async {
    if (_salvando || _finalizado) return;
    if (_respostas.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Responda a todas as perguntas para continuar.')),
      );
      return;
    }
    final respostas = _respostas.cast<int>();
    final sensivel =
        AvaliacaoService.itemSensivelPositivo(widget.instrumento, respostas);
    if (sensivel) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Você merece apoio'),
          content: const Text(
            'Sua resposta indica que pode ser importante conversar com alguém de confiança '
            'ou com um profissional de saúde agora. Este aplicativo não monitora emergências '
            'nem envia alertas em tempo real. Se houver perigo imediato, procure um serviço '
            'de emergência local. No Brasil, o CVV oferece apoio emocional pelo telefone 188.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }
    setState(() => _salvando = true);
    try {
      final total = AvaliacaoService.pontuar(widget.instrumento, respostas);
      if (kIsWeb) {
        await FirebaseRegistrosService.instance.registrarAvaliacao(
          instrumento: widget.instrumento,
          versao: 'demonstracao-dominios-v1',
          respostas: respostas,
          operacaoId: _operacaoId,
        );
      } else {
        await AvaliacaoService.instance.registrar(
          instrumento: widget.instrumento,
          versao: 'demonstracao-dominios-v1',
          respostas: respostas,
          operacaoId: _operacaoId,
        );
      }
      if (!mounted) return;
      setState(() => _finalizado = true);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Respostas registradas'),
          content: Text(
            'Pontuação demonstrativa: $total. A soma das respostas não é um diagnóstico '
            'e não deve ser interpretada como escore clínico validado. '
            'Converse com um profissional para avaliar seus sintomas e contexto.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Concluir'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.instrumento != 'GAD7' && widget.instrumento != 'PHQ9') {
      return const Scaffold(body: Center(child: Text('Instrumento inválido')));
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(
              _phq9 ? 'Humor • demonstração' : 'Ansiedade • demonstração')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Protótipo acadêmico com perguntas ilustrativas inspiradas nos domínios '
              'de rastreio. Não é a versão validada em português do GAD-7 ou PHQ-9. '
              'Considere os últimos 14 dias. Responda somente com dados fictícios '
              'nesta demonstração. Não há monitoramento emergencial.',
            ),
          )),
          for (var i = 0; i < _perguntas.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${_perguntas[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (var valor = 0; valor < 4; valor++)
                          ChoiceChip(
                            label: Text(_opcoes[valor]),
                            selected: _respostas[i] == valor,
                            onSelected: _salvando
                                ? null
                                : (_) {
                                    setState(() => _respostas[i] = valor);
                                  },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _salvando || _finalizado ? null : _salvar,
            child: Text(
                _salvando ? 'Salvando...' : 'Registrar respostas fictícias'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
