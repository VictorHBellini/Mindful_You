import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/services/theme_service.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';

class ConfiguracaoTela extends StatefulWidget {
  const ConfiguracaoTela({super.key});

  @override
  State<ConfiguracaoTela> createState() => _ConfiguracaoTelaState();
}

class _ConfiguracaoTelaState extends State<ConfiguracaoTela> {
  bool notificacao = false;
  bool temaEscuro = false;

  String nomeUsuario = "Usuário";
  String emailUsuario = "";

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? "Usuário";
      emailUsuario = prefs.getString('emailUsuario') ?? "";
      notificacao = prefs.getBool('notificacao') ?? false;
      temaEscuro = prefs.getBool('temaEscuro') ?? false;
    });
  }

  Future<void> salvarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'notificacao',
      notificacao,
    );

    await prefs.setBool(
      'temaEscuro',
      temaEscuro,
    );
  }

  Future<void> _excluirDadosLocais() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir dados locais?'),
        content: const Text(
          'Seu perfil e histórico salvos neste dispositivo serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final prefs = await SharedPreferences.getInstance();

    // Exclui o usuário do banco SQLite pelo e-mail salvo
    final email = prefs.getString('emailUsuario');
    if (email != null && email.isNotEmpty) {
      final usuario = await DatabaseService.instance.buscarPorEmail(email);
      if (usuario != null) {
        await DatabaseService.instance.deletarUsuario(usuario['id'] as int);
      }
    }

    await limparHistorico();

    // BUG CORRIGIDO: antes só removíamos 3 chaves (nomeUsuario,
    // emailUsuario, ultimoQuestionario), deixando pra trás outros
    // dados reais do usuário salvos no aparelho — foto de perfil,
    // último check-in, contadores de humor, preferências de tema e
    // notificação. Se outra pessoa criasse uma conta nova no mesmo
    // aparelho depois, esses dados antigos apareciam na conta nova.
    // Agora limpamos tudo de uma vez.
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8DFDA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF8A7B73),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 106,
                height: 106,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const AvatarPerfil(radius: 50),
              ),
              const SizedBox(height: 18),
              Text(
                nomeUsuario,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40352F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emailUsuario.isEmpty
                    ? "Nenhum e-mail cadastrado"
                    : emailUsuario,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8A7B73),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              _sectionCard(
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF8D6E63),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Minha Conta",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/perfil',
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text(
                          "Editar Perfil",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF8D6E63),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Preferências",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Notificações",
                      ),
                      secondary: const Icon(
                        Icons.notifications_none_rounded,
                      ),
                      value: notificacao,
                      onChanged: (value) {
                        setState(() {
                          notificacao = value;
                        });

                        salvarPreferencias();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Tema escuro",
                      ),
                      secondary: const Icon(
                        Icons.dark_mode_outlined,
                      ),
                      value: temaEscuro,
                      onChanged: (value) {
                        setState(() {
                          temaEscuro = value;
                        });

                        ThemeService.setDark(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Zona Sensível",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _excluirDadosLocais,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Excluir conta permanentemente",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
