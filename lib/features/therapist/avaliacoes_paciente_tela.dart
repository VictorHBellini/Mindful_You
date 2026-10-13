import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mindful_you/services/vinculo_service.dart';

/// Somente resultados demonstrativos; não são escores clínicos validados.
class AvaliacoesPacienteTela extends StatefulWidget {
  final int pacienteId;
  final String nomePaciente;
  const AvaliacoesPacienteTela({
    super.key,
    required this.pacienteId,
    required this.nomePaciente,
  });

  @override
  State<AvaliacoesPacienteTela> createState() => _AvaliacoesPacienteTelaState();
}

class _AvaliacoesPacienteTelaState extends State<AvaliacoesPacienteTela>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _consulta;
  bool _oculto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reconsultar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state != AppLifecycleState.resumed) {
      setState(() => _oculto = true);
    } else {
      setState(() {
        _oculto = false;
        _reconsultar();
      });
    }
  }

  void _reconsultar() {
    _consulta =
        VinculoService.instance.avaliacoesAutorizadas(widget.pacienteId);
  }

  String _data(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Data indisponível';
    final local = parsed.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year}';
  }

  Widget _serie(String instrumento, List<Map<String, dynamic>> registros) {
    final itens =
        registros.where((r) => r['instrumento'] == instrumento).toList()
          ..sort((a, b) {
            final data =
                a['criado_em'].toString().compareTo(b['criado_em'].toString());
            if (data != 0) return data;
            return (a['id'] as int).compareTo(b['id'] as int);
          });
    final maximo = instrumento == 'GAD7' ? 21.0 : 27.0;
    final titulo =
        instrumento == 'GAD7' ? 'Ansiedade (7 itens)' : 'Humor (9 itens)';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const Text('Nenhuma avaliação registrada.')
          else ...[
            Text(
                'Última soma: ${itens.last['pontuacao']} / ${maximo.toInt()} (demonstrativa)'),
            const SizedBox(height: 12),
            if (itens.length < 2)
              const Text(
                  'São necessárias duas avaliações para mostrar a evolução.')
            else
              SizedBox(
                height: 180,
                child: LineChart(LineChartData(
                  minY: 0,
                  maxY: maximo,
                  minX: 0,
                  maxX: (itens.length - 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < itens.length; i++)
                          FlSpot(i.toDouble(),
                              (itens[i]['pontuacao'] as num).toDouble())
                      ],
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                    )
                  ],
                )),
              ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliações • ${widget.nomePaciente}'),
        actions: [
          IconButton(
            tooltip: 'Revalidar consentimento e atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_reconsultar),
          )
        ],
      ),
      body: _oculto
          ? const Center(
              child: Text('Conteúdo oculto. Acesso será revalidado.'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _consulta,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                          'Acesso não autorizado ou sessão indisponível.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(_reconsultar),
                        child: const Text('Verificar novamente'),
                      ),
                    ]),
                  ));
                }
                final registros = snapshot.data ?? [];
                return ListView(padding: const EdgeInsets.all(16), children: [
                  const Text(
                    'Dados fictícios para demonstração acadêmica. As perguntas e somas '
                    'não constituem instrumentos clínicos validados, diagnóstico ou '
                    'monitoramento de emergência.',
                  ),
                  const SizedBox(height: 16),
                  _serie('GAD7', registros),
                  _serie('PHQ9', registros),
                  const SizedBox(height: 16),
                  Text('Registros (${registros.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  if (registros.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child:
                          Text('Nenhuma avaliação demonstrativa disponível.'),
                    ),
                  for (final registro in registros)
                    Card(
                        child: ListTile(
                      title: Text(
                          '${registro['instrumento'] == 'GAD7' ? 'Ansiedade' : 'Humor'} '
                          '• ${registro['pontuacao']} pontos'),
                      subtitle: Text('${_data(registro['criado_em'])} '
                          '• Versão: ${registro['versao']}'),
                    )),
                  const SizedBox(height: 12),
                  const Text('Atualize a tela para revalidar o consentimento. '
                      'O acesso também é revalidado quando o aplicativo volta ao primeiro plano.'),
                ]);
              },
            ),
    );
  }
}
