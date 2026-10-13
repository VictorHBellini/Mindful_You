import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';

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
    if (!mounted) return;
    setState(() {
      _autorizado = permitido;
      _nome = nome;
      _carregando = false;
    });
  }

  Future<void> _sair() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'usuarioId', 'nomeUsuario', 'emailUsuario',
      'tipoUsuario', 'isAdmin', 'fotoPerfil',
    ]) {
      await prefs.remove(key);
    }
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
              const Text('Esta área é exclusiva de contas demonstrativas de terapeuta.'),
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
              Text('Olá, $_nome', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Painel demonstrativo para o TCC.'),
              const SizedBox(height: 24),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.people_outline),
                  title: Text('Pacientes vinculados'),
                  subtitle: Text('Nenhum paciente vinculado. A vinculação com consentimento será implementada na próxima etapa.'),
                  trailing: Text('0'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.show_chart),
                  title: Text('Evolução emocional'),
                  subtitle: Text('Os gráficos aparecerão somente após vínculo e autorização do paciente.'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.assignment_outlined),
                  title: Text('Questionários'),
                  subtitle: Text('PHQ-9, GAD-7 e burnout: integração planejada, não disponível nesta versão.'),
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
