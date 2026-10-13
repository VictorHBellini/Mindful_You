import 'package:flutter/material.dart';
import 'package:mindful_you/services/avaliacao_service.dart';

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

  void _atualizar() {
    _avaliacoes = AvaliacaoService.instance.listarMinhasAvaliacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações de rastreio')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Módulo em preparação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('GAD-7 e PHQ-9: estrutura de armazenamento e pontuação preparada. '
                'A aplicação dos questionários ainda não está disponível, '
                'aguardando revisão da versão brasileira e do protocolo de segurança.'),
            SizedBox(height: 12),
            Text('Esses instrumentos são de rastreio; não fornecem diagnóstico.'),
          ]))),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: Text('Minhas avaliações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => setState(_atualizar),
              icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
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
              return const ListTile(title: Text('Nenhuma avaliação registrada'),
                subtitle: Text('A aplicação das escalas será habilitada em uma próxima atualização.'));
            }
            return Column(children: [
              for (final item in itens)
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text('${item['instrumento']} • ${item['pontuacao']} pontos'),
                  subtitle: Text('Versão ${item['versao']} • ${item['criado_em']}'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
