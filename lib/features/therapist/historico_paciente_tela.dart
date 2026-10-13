import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mindful_you/services/vinculo_service.dart';
import 'package:mindful_you/features/therapist/avaliacoes_paciente_tela.dart';

/// Histórico de check-ins autorizado para demonstração acadêmica.
/// Não exibe notas livres nem instrumentos clínicos validados.
class HistoricoPacienteTela extends StatefulWidget {
  final int pacienteId;
  final String nomePaciente;

  const HistoricoPacienteTela({
    super.key,
    required this.pacienteId,
    required this.nomePaciente,
  });

  @override
  State<HistoricoPacienteTela> createState() => _HistoricoPacienteTelaState();
}

class _HistoricoPacienteTelaState extends State<HistoricoPacienteTela>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _consulta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    // Oculta dados já carregados ao sair do app; revalida ao retornar.
    if (state != AppLifecycleState.resumed) {
      setState(() => _oculto = true);
    } else {
      setState(() {
        _oculto = false;
        _atualizar();
      });
    }
  }

  bool _oculto = false;

  void _atualizar() {
    _consulta = VinculoService.instance.historicoAutorizado(widget.pacienteId);
  }

  double _valor(Map<String, dynamic> item, String chave) {
    final v = item[chave];
    if (v is num) return v.toDouble().clamp(0.0, 100.0);
    return 0;
  }

  String _data(Map<String, dynamic> item) {
    final formatada = item['data_formatada']?.toString() ?? '';
    if (formatada.isNotEmpty) return formatada;
    final iso = item['data_iso']?.toString() ?? '';
    return iso.length >= 10 ? iso.substring(0, 10) : 'Sem data';
  }

  Widget _indicador(String titulo, double valor) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Text('${valor.round()} / 100',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: valor / 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grafico(List<Map<String, dynamic>> registros) {
    final ordem = registros.reversed.toList();
    if (ordem.length < 2) {
      return const Text(
          'São necessários pelo menos dois check-ins para o gráfico.');
    }
    final pontos = ordem
        .asMap()
        .entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              _valor(e.value, 'bem_estar'),
            ))
        .toList();
    return SizedBox(
      height: 210,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 25,
          )),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: false,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          )
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico • ${widget.nomePaciente}'),
        actions: [
          IconButton(
            tooltip: 'Atualizar e verificar consentimento',
            onPressed: () => setState(_atualizar),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _oculto
          ? const Center(
              child: Text(
                  'Conteúdo oculto. Retorne ao aplicativo para revalidar o acesso.'))
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
                      const Icon(Icons.lock_outline, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                          'Não foi possível consultar o histórico. Verifique o vínculo e a sessão.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: () => setState(_atualizar),
                          child: const Text('Tentar novamente')),
                    ]),
                  ));
                }
                final registros = snapshot.data ?? [];
                if (registros.isEmpty) {
                  return const Center(
                      child: Text(
                          'Nenhum registro disponível ou consentimento não ativo.'));
                }
                final ultimo = registros.first;
                return ListView(padding: const EdgeInsets.all(16), children: [
                  const Text(
                      'Dados demonstrativos de autoavaliação, sem finalidade diagnóstica.',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  Text('Último registro: ${_data(ultimo)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    _indicador('Bem-estar', _valor(ultimo, 'bem_estar')),
                    _indicador(
                        'Ansiedade percebida', _valor(ultimo, 'ansiedade')),
                  ]),
                  Row(children: [
                    _indicador('Cansaço', _valor(ultimo, 'cansaco')),
                    _indicador('Falta de sono', _valor(ultimo, 'sono')),
                  ]),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Ver avaliações demonstrativas'),
                    onPressed: () async {
                      setState(() => _oculto = true);
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AvaliacoesPacienteTela(
                            pacienteId: widget.pacienteId,
                            nomePaciente: widget.nomePaciente,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {
                        _oculto = false;
                        _atualizar();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Evolução do bem-estar (até 60 registros)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _grafico(registros),
                  const SizedBox(height: 20),
                  Text('Check-ins recentes',
                      style: Theme.of(context).textTheme.titleMedium),
                  for (final registro in registros)
                    Card(
                        child: ListTile(
                      leading: Text(registro['emoji']?.toString() ?? '•',
                          style: const TextStyle(fontSize: 24)),
                      title: Text(
                          '${_data(registro)} • ${registro['sentimento'] ?? ''}'),
                      subtitle: Text(
                        'Bem-estar: ${_valor(registro, 'bem_estar').round()} | '
                        'Ansiedade percebida: ${_valor(registro, 'ansiedade').round()}\n'
                        'Humor: ${_rotulo(registro, 'humor_frequencia')} | '
                        'Interesse: ${_rotulo(registro, 'interesse_frequencia')}\n'
                        'Exaustão: ${_rotulo(registro, 'exaustao_burnout')} | '
                        'Distanciamento: ${_rotulo(registro, 'distanciamento_burnout')}',
                      ),
                      isThreeLine: true,
                    )),
                  const SizedBox(height: 12),
                  const Text(
                      'A visualização é local e demonstrativa. Atualize a tela para verificar o consentimento novamente. Não há alertas de emergência em tempo real.',
                      style: TextStyle(fontSize: 12)),
                ]);
              },
            ),
    );
  }

  String _rotulo(Map<String, dynamic> registro, String chave) {
    final v = registro[chave]?.toString() ?? '';
    return v.isEmpty ? 'Não informado' : v;
  }
}
