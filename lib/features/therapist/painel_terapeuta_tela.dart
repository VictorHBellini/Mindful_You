import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/features/therapist/services/vinculo_service.dart';
import 'package:mindful_you/features/therapist/historico_paciente_tela.dart';

/// Painel demonstrativo: não mostra dados de pacientes até que
/// vínculos e consentimentos sejam implementados e verificados.
class PainelTerapeutaTela extends StatefulWidget {
  const PainelTerapeutaTela({super.key});

  @override
  State<PainelTerapeutaTela> createState() => _PainelTerapeutaTelaState();
}

class _PainelTerapeutaTelaState extends State<PainelTerapeutaTela> {
  bool _carregando = true;
  bool _autorizado = false;
  String _nome = 'Profissional';
  final _emailController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _vinculos;
  void _recarregar() {
    _vinculos = VinculoService.instance.listarParaTerapeuta();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');
    bool permitido = false;
    String nome = 'Profissional';
    if (id != null) {
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'usuarios',
        columns: ['nome', 'tipo_usuario'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty && rows.first['tipo_usuario'] == 'terapeuta') {
        permitido = true;
        nome = rows.first['nome']?.toString() ?? nome;
      }
    }
    if (permitido) _recarregar();
    if (!mounted) return;
    setState(() {
      _autorizado = permitido;
      _nome = nome;
      _carregando = false;
    });
  }

  Future<void> _sair() async {
    await SessionService.encerrar();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_autorizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso restrito')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Esta área é exclusiva de contas demonstrativas de terapeuta.'),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false),
                child: const Text('Ir para o login'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful You • Terapeuta'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Olá, $_nome',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Painel demonstrativo para o TCC.'),
              const SizedBox(height: 24),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail do paciente (conta fictícia)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Solicitar vínculo'),
                  onPressed: () async {
                    try {
                      await VinculoService.instance
                          .solicitar(_emailController.text);
                      if (!mounted) return;

                      setState(_recarregar);
                      _emailController.clear();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Solicitação enviada neste dispositivo.'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                        ),
                      );
                    }
                  }),
              const SizedBox(height: 12),
              Text('Vínculos', style: Theme.of(context).textTheme.titleLarge),
              FutureBuilder<List<Map<String, dynamic>>>(
                  future: _vinculos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Erro: ${snapshot.error}');
                    }
                    final lista = snapshot.data ?? [];
                    if (lista.isEmpty) {
                      return const Text('Nenhum vínculo cadastrado.');
                    }
                    return Column(children: [
                      for (final item in lista)
                        Card(
                            child: ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(item['nome'].toString()),
                          subtitle:
                              Text('${item['email']} • ${item['status']}'),
                          trailing: item['status'] == 'aceito'
                              ? const Icon(Icons.chevron_right)
                              : const Icon(Icons.lock_outline),
                          onTap: item['status'] == 'aceito'
                              ? () async {
                                  final pacienteId = item['paciente_id'] as int;
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute<void>(
                                    builder: (_) => HistoricoPacienteTela(
                                      pacienteId: pacienteId,
                                      nomePaciente: item['nome']?.toString() ??
                                          'Paciente',
                                    ),
                                  ));
                                  if (!mounted) return;
                                  setState(_recarregar);
                                }
                              : null,
                        ))
                    ]);
                  }),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.show_chart),
                  title: Text('Evolução emocional'),
                  subtitle: Text(
                      'Toque em um paciente com vínculo aceito para visualizar seus registros.'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.assignment_outlined),
                  title: Text('Questionários'),
                  subtitle: Text(
                      'Avaliações demonstrativas de ansiedade e humor disponíveis no histórico de pacientes autorizados. Burnout ainda não integrado.'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Protótipo acadêmico. Não oferece diagnóstico, atendimento emergencial ou monitoramento clínico em tempo real.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
