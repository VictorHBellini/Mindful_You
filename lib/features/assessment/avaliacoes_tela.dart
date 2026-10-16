import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';
import 'package:mindful_you/features/assessment/services/avaliacao_service.dart';
import 'package:mindful_you/features/assessment/questionario_rastreio_tela.dart';

/// Entrada do módulo. Aplicação de escalas será liberada após revisão
/// da redação validada e do protocolo para respostas sensíveis.
class AvaliacoesTela extends StatefulWidget {
  const AvaliacoesTela({super.key});

  @override
  State<AvaliacoesTela> createState() => _AvaliacoesTelaState();
}

class _AvaliacoesTelaState extends State<AvaliacoesTela> {
  late Future<List<Map<String, dynamic>>> _avaliacoes;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  Future<void> _abrir(String instrumento) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => QuestionarioRastreioTela(instrumento: instrumento)),
    );
    if (!mounted) return;
    if (salvo == true) setState(_atualizar);
  }

  void _atualizar() {
    _avaliacoes = kIsWeb
        ? FirebaseRegistrosService.instance.minhasAvaliacoes()
        : AvaliacaoService.instance.listarMinhasAvaliacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações de rastreio')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Card(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Formulários demonstrativos',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                          'Perguntas ilustrativas baseadas nos domínios de ansiedade e humor. '
                          'A redação não corresponde a versões validadas do GAD-7 e PHQ-9. '
                          'As pontuações são apenas para demonstrar o fluxo do aplicativo.'),
                      SizedBox(height: 12),
                      Text(
                          'Use apenas respostas fictícias. Não há diagnóstico nem monitoramento emergencial.'),
                    ]))),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _abrir('GAD7'),
          icon: const Icon(Icons.psychology_outlined),
          label: const Text('Simular avaliação de ansiedade (7 itens)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _abrir('PHQ9'),
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Simular avaliação de humor (9 itens)'),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(
              child: Text('Minhas avaliações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(
              onPressed: () => setState(_atualizar),
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar'),
        ]),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _avaliacoes,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Não foi possível consultar as avaliações.');
            }
            final itens = snapshot.data ?? [];
            if (itens.isEmpty) {
              return const ListTile(
                  title: Text('Nenhuma avaliação registrada'),
                  subtitle: Text(
                      'Use os botões acima para registrar respostas fictícias.'));
            }
            return Column(children: [
              for (final item in itens)
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(
                      '${item['instrumento']} • ${item['pontuacao']} pontos demonstrativos'),
                  subtitle:
                      Text('Versão ${item['versao']} • ${item['criado_em']}'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
