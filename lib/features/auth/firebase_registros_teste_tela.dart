import 'package:flutter/material.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';

/// Testes F3.1: dados fictícios fixos; não substitui as telas reais.
class FirebaseRegistrosTesteTela extends StatefulWidget {
  const FirebaseRegistrosTesteTela({super.key});

  @override
  State<FirebaseRegistrosTesteTela> createState() =>
      _FirebaseRegistrosTesteTelaState();
}

class _FirebaseRegistrosTesteTelaState
    extends State<FirebaseRegistrosTesteTela> {
  bool _ocupado = false;
  String _resultado = 'Nenhum teste executado.';

  Future<void> _executar(Future<String> Function() operacao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      final texto = await operacao();
      if (!mounted) return;
      setState(() => _resultado = texto);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resultado = 'Falha ou acesso bloqueado: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servico = FirebaseRegistrosService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase F3.1 • Registros fictícios')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Somente demonstração. Os botões criam registros '
                  'fictícios de teste na conta paciente autenticada.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _ocupado
                    ? null
                    : () => _executar(() async {
                          final id = await servico.registrarCheckin(
                            bemEstar: 7,
                            ansiedade: 3,
                            cansaco: 4,
                            sono: 6,
                            produtividade: 5,
                            sentimento: 'Teste fictício F3.1',
                          );
                          return 'Check-in salvo: $id';
                        }),
                child: const Text('Salvar check-in fictício'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _ocupado
                    ? null
                    : () => _executar(() async {
                          final id = await servico.registrarAvaliacao(
                            instrumento: 'GAD7',
                            versao: 'demonstracao-dominios-v1',
                            respostas: [0, 1, 2, 1, 0, 1, 0],
                          );
                          return 'Avaliação demonstrativa salva: $id';
                        }),
                child: const Text('Salvar avaliação fictícia GAD7'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _ocupado
                    ? null
                    : () => _executar(() async {
                          final dados = await servico.meusCheckins();
                          return 'Meus check-ins (${dados.length}):\n'
                              '${dados.map((r) => '${r['id']} • bem-estar ${r['bem_estar']}').join('\n')}';
                        }),
                child: const Text('Consultar meus check-ins'),
              ),
              OutlinedButton(
                onPressed: _ocupado
                    ? null
                    : () => _executar(() async {
                          final dados = await servico.minhasAvaliacoes();
                          return 'Minhas avaliações (${dados.length}):\n'
                              '${dados.map((r) => '${r['instrumento']} • ${r['pontuacao']} pontos').join('\n')}';
                        }),
                child: const Text('Consultar minhas avaliações'),
              ),
              if (_ocupado) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              SelectableText(_resultado),
            ],
          ),
        ),
      ),
    );
  }
}
