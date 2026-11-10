import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/features/auth/screens/account_link_preflight_screen.dart';
import 'package:mindful_you/features/auth/firebase_teste_tela.dart';
import 'package:mindful_you/core/theme/mindful_cores.dart';
import 'package:mindful_you/features/settings/vincular_firebase_demo_tela.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/features/settings/services/exclusao_local_adapters.dart';
import 'package:mindful_you/features/settings/services/exclusao_local_coordinator.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/features/profile/services/foto_perfil_service.dart';
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
  bool _exclusaoEmAndamento = false;

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

  Future<String?> _solicitarSenhaExclusao() async {
    final controlador = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar identidade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite sua senha local para confirmar '
                'a exclusão dos dados deste dispositivo.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controlador,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, controlador.text);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } finally {
      controlador.dispose();
    }
  }

  Future<void> _excluirDadosLocais() async {
    if (_exclusaoEmAndamento || !mounted) return;

    setState(() => _exclusaoEmAndamento = true);
    var contaExcluida = false;

    try {
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Excluir dados locais?'),
          content: const Text(
            'Sua conta e seus históricos salvos neste dispositivo '
            'serão excluídos permanentemente. '
            'Esta ação não exclui contas ou dados do Firebase.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) return;

      final sessao = await SessionService.validar();
      if (sessao == null || !mounted) return;

      final senha = await _solicitarSenhaExclusao();
      if (senha == null || senha.isEmpty || !mounted) return;

      final db = await DatabaseService.instance.database;

      final usuario = await db.query(
        'usuarios',
        columns: ['foto_path'],
        where: 'id = ?',
        whereArgs: [sessao.id],
        limit: 1,
      );

      if (!mounted || usuario.length != 1) return;

      final coordinator = ExclusaoLocalCoordinator(
        sessao: SessaoLocalAdapter(),
        senha: SenhaLocalAdapter(),
        repositorio: RepositorioExclusaoLocalAdapter(),
      );

      final resultado = await coordinator.executar(
        senhaDigitada: senha,
        usuarioEsperadoId: sessao.id,
      );

      if (!mounted) return;

      switch (resultado) {
        case ResultadoExclusaoLocal.excluido:
          contaExcluida = true;
          break;

        case ResultadoExclusaoLocal.senhaIncorreta:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha incorreta. Nenhum dado foi excluído.'),
            ),
          );
          return;

        case ResultadoExclusaoLocal.sessaoInvalida:
        case ResultadoExclusaoLocal.sessaoAlterada:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A sessão mudou ou expirou. Nenhum dado foi excluído.',
              ),
            ),
          );
          return;

        case ResultadoExclusaoLocal.contaNaoEncontrada:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A conta local não foi encontrada.'),
            ),
          );
          return;

        case ResultadoExclusaoLocal.vinculoOuOperacaoBloqueada:
          await _mostrarCanalPrivacidade();
          return;
      }

      // Uma falha na limpeza da foto não deve manter uma sessão de conta excluída.
      try {
        await FotoPerfilService.removerFotoAntiga(
          usuario.single['foto_path'] as String?,
        );
      } catch (_) {
        // Limpeza de arquivo secundária; a conta já foi excluída do SQLite.
      }

      await SessionService.encerrar();
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contaExcluida
                ? 'Os dados locais foram excluídos, mas não foi possível '
                    'finalizar a sessão. Reinicie o aplicativo.'
                : 'Exclusão bloqueada: há um vínculo Firebase registrado '
                    'ou a operação não pôde ser concluída.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contaExcluida
                ? 'Os dados locais foram excluídos, mas ocorreu uma falha '
                    'ao encerrar a sessão. Reinicie o aplicativo.'
                : 'Não foi possível concluir a exclusão. '
                    'Verifique os dados e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exclusaoEmAndamento = false);
      }
    }
  }

  static const _emailPrivacidade = 'victorhfbellini.dev@gmail.com';

  Future<void> _mostrarCanalPrivacidade() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitação de privacidade'),
        content: const Text(
            'A exclusão automática pode ser impedida por vínculos Firebase, '
            'históricos identificados ou registros de migração. '
            'Nenhuma exclusão desses registros foi confirmada.\n\n'
            'Para solicitar a análise de exclusão ou acesso aos dados, '
            'escreva para $_emailPrivacidade. Informe apenas o necessário '
            'para localizar a conta; não envie sua senha nem registros emocionais.'),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: _emailPrivacidade),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-mail de privacidade copiado.')),
              );
            },
            child: const Text('Copiar e-mail'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.03),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 106,
                height: 106,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emailUsuario.isEmpty
                    ? "Nenhum e-mail cadastrado"
                    : emailUsuario,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? MindfulCores.rosaPrimarioEscuro
                                  : const Color(0xFF8D6E63),
                          foregroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? MindfulCores.contrasteRosaEscuro
                                  : Colors.white,
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
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
              if (kDebugMode && !kIsWeb)
                _sectionCard(
                    child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Pré-verificação Firebase (laboratório)'),
                  subtitle: const Text('Somente testes; sem criar vínculos'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountLinkPreflightScreen(),
                      )),
                )),
              if (kDebugMode && !kIsWeb) const SizedBox(height: 18),
              if (kDebugMode && !kIsWeb)
                _sectionCard(
                  child: ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Laboratório Firebase F2.3'),
                    subtitle: const Text('Entrar na conta Firebase de teste'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const FirebaseTesteTela(),
                      ),
                    ),
                  ),
                ),
              if (kDebugMode && !kIsWeb) const SizedBox(height: 18),
              if (kDebugMode &&
                  const bool.fromEnvironment(
                    'MINDFUL_FIREBASE_EMULATORS',
                    defaultValue: false,
                  ))
                _sectionCard(
                    child: ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Vincular Firebase (demonstração)'),
                  subtitle:
                      const Text('Solicitação pendente; sem sincronização'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const VincularFirebaseDemoTela(),
                      )),
                )),
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
                      onPressed:
                          _exclusaoEmAndamento ? null : _excluirDadosLocais,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Excluir dados locais",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _mostrarCanalPrivacidade,
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Solicitar análise de exclusão'),
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
