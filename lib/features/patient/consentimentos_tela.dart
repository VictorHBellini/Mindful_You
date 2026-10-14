import 'package:flutter/material.dart';
import 'package:mindful_you/services/vinculo_service.dart';

class ConsentimentosTela extends StatefulWidget {
  const ConsentimentosTela({super.key});
  @override
  State<ConsentimentosTela> createState() => _ConsentimentosTelaState();
}

class _ConsentimentosTelaState extends State<ConsentimentosTela> {
  late Future<List<Map<String, dynamic>>> _dados;
  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    _dados = VinculoService.instance.listarParaPaciente();
  }

  Future<void> _decidir(int id, String acao) async {
    try {
      await VinculoService.instance.decidir(id, acao);
      if (!mounted) return;
      setState(_recarregar);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitação atualizada: $acao')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Meus consentimentos')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _dados,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(
                  child: Text('Nenhuma solicitação de acompanhamento.'));
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Acesso local demonstrativo. Aceitar autoriza um vínculo, mas ainda não compartilha registros clínicos. Você pode revogar a qualquer momento.'),
              const SizedBox(height: 16),
              for (final item in items)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nome'].toString(),
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(item['email'].toString()),
                            Text('Situação: ${item['status']}'),
                            if (item['status'] == 'pendente')
                              Wrap(spacing: 8, children: [
                                FilledButton(
                                    onPressed: () =>
                                        _decidir(item['id'] as int, 'aceito'),
                                    child: const Text('Aceitar')),
                                OutlinedButton(
                                    onPressed: () =>
                                        _decidir(item['id'] as int, 'recusado'),
                                    child: const Text('Recusar')),
                              ]),
                            if (item['status'] == 'aceito')
                              OutlinedButton(
                                  onPressed: () =>
                                      _decidir(item['id'] as int, 'revogado'),
                                  child: const Text('Revogar acesso')),
                          ],
                        ))),
            ]);
          },
        ),
      );
}
