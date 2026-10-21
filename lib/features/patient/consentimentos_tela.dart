import 'package:flutter/material.dart';
import 'package:mindful_you/features/therapist/services/vinculo_service.dart';

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

  Future<void> _confirmarRevogacao(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revogar acesso?'),
        content: const Text(
          'O vínculo será revogado. Você poderá autorizar um novo vínculo '
          'posteriormente, se desejar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revogar acesso'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await _decidir(id, 'revogado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFBDAFAC) : const Color(0xFF766861);

    return Scaffold(
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
              child: Text('Nenhuma solicitação de acompanhamento.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Text(
                'Acesso local demonstrativo. Aceitar autoriza um vínculo, '
                'mas ainda não compartilha registros clínicos. '
                'Você pode revogar a qualquer momento.',
                style: TextStyle(color: muted, height: 1.55),
              ),
              const SizedBox(height: 20),
              for (final item in items) ...[
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nome'].toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['email'].toString(),
                          style: TextStyle(color: muted),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['status'] == 'aceito'
                                ? 'Vínculo aceito'
                                : item['status'] == 'pendente'
                                    ? 'Aguardando autorização'
                                    : 'Situação: ${item['status']}',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item['status'] == 'pendente') ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                onPressed: () =>
                                    _decidir(item['id'] as int, 'aceito'),
                                child: const Text('Aceitar'),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    _decidir(item['id'] as int, 'recusado'),
                                child: const Text('Recusar'),
                              ),
                            ],
                          ),
                        ],
                        if (item['status'] == 'aceito') ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                _confirmarRevogacao(item['id'] as int),
                            child: const Text('Revogar acesso'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
