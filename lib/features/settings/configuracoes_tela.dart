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

      // Mantém o estado visual sincronizado com o ThemeService.
      temaEscuro = ThemeService.mode.value == ThemeMode.dark;
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

  Future<void> _alterarTema(bool value) async {
    setState(() {
      temaEscuro = value;
    });

    await ThemeService.setDark(value);
  }

  Future<void> _alterarNotificacoes(bool value) async {
    setState(() {
      notificacao = value;
    });

    await salvarPreferencias();
  }

  Future<void> _excluirDadosLocais() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Excluir dados locais?',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Seu perfil e histórico salvos neste dispositivo serão '
            'removidos. Esta ação não pode ser desfeita.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
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
        );
      },
    );

    if (confirmar != true) return;

    final prefs = await SharedPreferences.getInstance();

    // Exclui o usuário do banco SQLite pelo e-mail salvo.
    final email = prefs.getString('emailUsuario');

    if (email != null && email.isNotEmpty) {
      final usuario = await DatabaseService.instance.buscarPorEmail(email);

      if (usuario != null) {
        await DatabaseService.instance.deletarUsuario(
          usuario['id'] as int,
        );
      }
    }

    await limparHistorico();

    // Limpa todos os dados locais do usuário.
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.35),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // ==========================================================
              // BOTÃO VOLTAR
              // ==========================================================
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==========================================================
              // AVATAR
              // ==========================================================
              Container(
                width: 106,
                height: 106,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.35),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                          ),
                        ],
                ),
                child: const AvatarPerfil(radius: 50),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // NOME
              // ==========================================================
              Text(
                nomeUsuario,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 4),

              // ==========================================================
              // E-MAIL
              // ==========================================================
              Text(
                emailUsuario.isEmpty
                    ? "Nenhum e-mail cadastrado"
                    : emailUsuario,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================================
              // MINHA CONTA
              // ==========================================================
              _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Minha Conta",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
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
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          minimumSize: const Size(
                            double.infinity,
                            52,
                          ),
                          elevation: 0,
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

              // ==========================================================
              // PREFERÊNCIAS
              // ==========================================================
              _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Preferências",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ----------------------------------------------------
                    // NOTIFICAÇÕES
                    // ----------------------------------------------------
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Notificações",
                        style: TextStyle(
                          color: colors.onSurface,
                        ),
                      ),
                      secondary: Icon(
                        Icons.notifications_none_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                      value: notificacao,
                      onChanged: _alterarNotificacoes,
                    ),

                    // ----------------------------------------------------
                    // TEMA ESCURO
                    // ----------------------------------------------------
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Tema escuro",
                        style: TextStyle(
                          color: colors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        temaEscuro
                            ? "Tema escuro ativado"
                            : "Tema claro ativado",
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      secondary: Icon(
                        temaEscuro
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                      value: temaEscuro,
                      onChanged: _alterarTema,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // ZONA SENSÍVEL
              // ==========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: isDark ? 0.08 : 0.05,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(
                      alpha: isDark ? 0.25 : 0.20,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Zona Sensível",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "A exclusão remove o perfil e o histórico "
                      "armazenados neste dispositivo.",
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
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
