import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:mindful_you/services/theme_service.dart';
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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cardBackground = dark ? const Color(0xFF292324) : Colors.white;
    final accent = dark ? const Color(0xFFD9AAA9) : const Color(0xFF965052);
    final secondaryText = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful You • Terapeuta'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.mode,
            builder: (context, mode, child) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Ativar tema claro' : 'Ativar tema escuro',
                onPressed: () => ThemeService.setDark(!isDark),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              );
            },
          ),
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
              Text('Painel demonstrativo para o TCC.',
                  style: TextStyle(color: secondaryText)),
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
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: Text('Vínculos',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
                Icon(Icons.people_outline, color: accent),
              ]),
              const SizedBox(height: 8),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            color: cardBackground,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.25)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: accent.withValues(alpha: 0.14),
                                child:
                                    Icon(Icons.person_outline, color: accent),
                              ),
                              title: Text(
                                  item['nome']?.toString() ?? 'Paciente',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item['email']?.toString() ?? '',
                                      style: TextStyle(color: secondaryText)),
                                  const SizedBox(height: 5),
                                  Text(
                                    item['status'] == 'aceito'
                                        ? 'Vínculo aceito'
                                        : 'Status: ${item['status']}',
                                    style: TextStyle(
                                      color: item['status'] == 'aceito'
                                          ? accent
                                          : secondaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                item['status'] == 'aceito'
                                    ? Icons.chevron_right
                                    : Icons.lock_outline,
                                color: secondaryText,
                              ),
                              onTap: item['status'] == 'aceito'
                                  ? () async {
                                      final pacienteId =
                                          item['paciente_id'] as int;
                                      await Navigator.of(context)
                                          .push(MaterialPageRoute<void>(
                                        builder: (_) => HistoricoPacienteTela(
                                          pacienteId: pacienteId,
                                          nomePaciente:
                                              item['nome']?.toString() ??
                                                  'Paciente',
                                        ),
                                      ));
                                      if (!mounted) return;
                                      setState(_recarregar);
                                    }
                                  : null,
                            ),
                          ),
                        ),
                    ]);
                  }),
              const SizedBox(height: 12),
              _PainelInfoCard(
                icon: Icons.show_chart,
                title: 'Evolução emocional',
                description:
                    'Toque em um paciente com vínculo aceito para visualizar seus registros.',
                background: cardBackground,
                accent: accent,
                secondaryText: secondaryText,
              ),
              const SizedBox(height: 8),
              _PainelInfoCard(
                icon: Icons.assignment_outlined,
                title: 'Questionários',
                description:
                    'Avaliações demonstrativas de ansiedade e humor disponíveis no histórico de pacientes autorizados. Burnout ainda não integrado.',
                background: cardBackground,
                accent: accent,
                secondaryText: secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Protótipo acadêmico. Não oferece diagnóstico, atendimento emergencial ou monitoramento clínico em tempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PainelInfoCard extends StatelessWidget {
  const _PainelInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.background,
    required this.accent,
    required this.secondaryText,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color background;
  final Color accent;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.14),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(description,
                      style: TextStyle(color: secondaryText, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
