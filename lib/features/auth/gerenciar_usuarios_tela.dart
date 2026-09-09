import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindful_you/services/admin_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class GerenciarUsuariosTela extends StatefulWidget {
  const GerenciarUsuariosTela({super.key});

  @override
  State<GerenciarUsuariosTela> createState() => _GerenciarUsuariosTelaState();
}

class _GerenciarUsuariosTelaState extends State<GerenciarUsuariosTela> {
  late Future<List<Map<String, dynamic>>> _futureUsuarios;

  bool _verificando = true;
  bool _autorizado = false;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = DatabaseService.instance.listarTodos();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarAcesso());
  }

  // ── Controle de acesso ──────────────────────────────────────────
  //
  // Protege a tela mesmo que alguém navegue direto para a rota
  // '/usuarios' sem passar pelo item do menu: exige (1) que o e-mail
  // logado esteja na lista de admins e (2) a senha extra de admin.

  Future<void> _verificarAcesso() async {
    final ehAdmin = await AdminService.statusAdminSalvo();

    if (!mounted) return;

    if (!ehAdmin) {
      Navigator.pop(context);
      return;
    }

    final senhaOk = await _pedirSenhaAdmin();

    if (!mounted) return;

    if (!senhaOk) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _autorizado = true;
      _verificando = false;
    });
  }

  /// Mostra o diálogo pedindo a senha de admin. Retorna `true` somente
  /// se a senha digitada bateu com `AdminService.senhaAdminValida`.
  Future<bool> _pedirSenhaAdmin() async {
    final senhaCtrl = TextEditingController();
    String? erro;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            void tentarEntrar() {
              if (AdminService.senhaAdminValida(senhaCtrl.text)) {
                Navigator.pop(ctx, true);
              } else {
                setStateDialog(() => erro = 'Senha incorreta');
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Área restrita',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F4039),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digite a senha de administrador para continuar.',
                    style: TextStyle(
                      color: Color(0xFF7A6C65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: senhaCtrl,
                    obscureText: true,
                    autofocus: true,
                    onChanged: (_) {
                      if (erro != null) setStateDialog(() => erro = null);
                    },
                    onSubmitted: (_) => tentarEntrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha de admin',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8D6E63),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F5F3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      errorText: erro,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Color(0xFF8D6E63))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: tentarEntrar,
                  child: const Text('Entrar'),
                ),
              ],
            );
          },
        );
      },
    );

    return ok ?? false;
  }

  void _recarregar() {
    setState(() {
      _futureUsuarios = DatabaseService.instance.listarTodos();
    });
  }

  // ── Editar ────────────────────────────────────────────────────
  //
  // Bottom sheet com TODOS os campos editáveis do usuário: nome,
  // e-mail, foto (remover) e senha (redefinir). Como o admin já passou
  // pela verificação de acesso (e-mail + senha de admin), a troca de
  // senha aqui não pede a senha atual do usuário — é uma redefinição
  // administrativa, diferente da troca de senha em "Meu perfil".

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    final nomeCtrl = TextEditingController(text: usuario['nome'] as String);
    final emailCtrl = TextEditingController(text: usuario['email'] as String);
    final novaSenhaCtrl = TextEditingController();
    final confirmarSenhaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? fotoPathAtual = usuario['foto_path'] as String?;
    bool removerFoto = false;
    bool salvando = false;
    bool obscureNovaSenha = true;
    bool obscureConfirmarSenha = true;
    String? erro;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final temFoto = !removerFoto &&
                fotoPathAtual != null &&
                fotoPathAtual!.isNotEmpty &&
                File(fotoPathAtual!).existsSync();

            final iniciais = nomeCtrl.text
                .trim()
                .split(' ')
                .where((w) => w.isNotEmpty)
                .take(2)
                .map((w) => w[0].toUpperCase())
                .join();

            Future<void> salvar() async {
              if (!formKey.currentState!.validate()) return;

              final novaSenha = novaSenhaCtrl.text;
              final confirmarSenha = confirmarSenhaCtrl.text;
              final quisRedefinirSenha =
                  novaSenha.isNotEmpty || confirmarSenha.isNotEmpty;

              if (quisRedefinirSenha) {
                if (novaSenha.isEmpty || confirmarSenha.isEmpty) {
                  setModal(() => erro =
                      'Preencha os dois campos de senha, ou deixe ambos em branco.');
                  return;
                }
                if (novaSenha.length < 8) {
                  setModal(() =>
                      erro = 'A nova senha deve ter pelo menos 8 caracteres.');
                  return;
                }
                if (novaSenha != confirmarSenha) {
                  setModal(() => erro = 'As senhas não coincidem.');
                  return;
                }
              }

              setModal(() {
                erro = null;
                salvando = true;
              });

              final id = usuario['id'] as int;

              try {
                await DatabaseService.instance.atualizarUsuario(
                  id: id,
                  nome: nomeCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );

                if (quisRedefinirSenha) {
                  await DatabaseService.instance.atualizarSenha(
                    id: id,
                    novaSenha: novaSenha,
                  );
                }

                if (removerFoto) {
                  await DatabaseService.instance.atualizarFoto(
                    id: id,
                    fotoPath: null,
                  );
                }
              } on DatabaseException {
                setModal(() {
                  salvando = false;
                  erro = 'E-mail já cadastrado para outro usuário.';
                });
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(ctx);
              _recarregar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuário atualizado com sucesso!'),
                  backgroundColor: Color(0xFF6E9B7B),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0D8D3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFE8DCD4),
                              backgroundImage: temFoto
                                  ? FileImage(File(fotoPathAtual!))
                                  : null,
                              child: temFoto
                                  ? null
                                  : Text(
                                      iniciais,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8D6E63),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Editar usuário',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F4039),
                                    ),
                                  ),
                                  Text(
                                    'ID ${usuario['id']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF95877F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (temFoto)
                              TextButton.icon(
                                onPressed: () {
                                  setModal(() => removerFoto = true);
                                },
                                icon: const Icon(
                                  Icons.no_photography_outlined,
                                  size: 18,
                                  color: Color(0xFFB05C55),
                                ),
                                label: const Text(
                                  'Remover foto',
                                  style: TextStyle(color: Color(0xFFB05C55)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _campo(
                          controller: nomeCtrl,
                          label: 'Nome',
                          icon: Icons.person_outline,
                          onChanged: (_) => setModal(() {}),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Nome muito curto'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _campo(
                          controller: emailCtrl,
                          label: 'E-mail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final e = (v ?? '').trim();
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(e)) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(height: 1, color: const Color(0xFFE8DFDA)),
                        const SizedBox(height: 16),
                        const Text(
                          'Redefinir senha',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF40352F),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Opcional — deixe em branco para manter a senha atual. Não é preciso saber a senha antiga.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF95877F),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _campo(
                          controller: novaSenhaCtrl,
                          label: 'Nova senha',
                          icon: Icons.lock_reset_outlined,
                          obscureText: obscureNovaSenha,
                          onToggleObscure: () => setModal(
                              () => obscureNovaSenha = !obscureNovaSenha),
                        ),
                        const SizedBox(height: 14),
                        _campo(
                          controller: confirmarSenhaCtrl,
                          label: 'Confirmar nova senha',
                          icon: Icons.lock_reset_outlined,
                          obscureText: obscureConfirmarSenha,
                          onToggleObscure: () => setModal(() =>
                              obscureConfirmarSenha = !obscureConfirmarSenha),
                        ),
                        if (erro != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC0392B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFC0392B), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    erro!,
                                    style: const TextStyle(
                                      color: Color(0xFFC0392B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    salvando ? null : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8D6E63),
                                  side: const BorderSide(
                                      color: Color(0xFFD9CCC3)),
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: salvando ? null : salvar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8D6E63),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: salvando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Salvar alterações',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Deletar ───────────────────────────────────────────────────

  Future<void> _deletarUsuario(Map<String, dynamic> usuario) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir usuário',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F4039),
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF7A6C65), height: 1.5),
            children: [
              const TextSpan(text: 'Deseja excluir o usuário '),
              TextSpan(
                text: usuario['nome'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Esta ação não pode ser desfeita.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8D6E63))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    await DatabaseService.instance.deletarUsuario(usuario['id'] as int);
    _recarregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuário excluído.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_verificando || !_autorizado) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F5F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: const Color(0xFF40352F),
        centerTitle: true,
        title: const Text(
          'Usuários cadastrados',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4F4039),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar usuários:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC0392B)),
              ),
            );
          }

          final usuarios = snapshot.data ?? [];

          if (usuarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_off_outlined,
                      size: 64,
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum usuário cadastrado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF80675C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cadastre-se na tela de cadastro para começar.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF95877F)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: usuarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _CartaoUsuario(
                usuario: usuarios[index],
                onEditar: () => _editarUsuario(usuarios[index]),
                onExcluir: () => _deletarUsuario(usuarios[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool? obscureText,
    VoidCallback? onToggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscureText == true
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8D6E63),
                ),
                onPressed: onToggleObscure,
              ),
        filled: true,
        fillColor: const Color(0xFFF7F5F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
        ),
      ),
    );
  }
}

// ── Cartão de usuário (design novo, sem overflow) ──────────────────
//
// Antes, a linha "Cadastrado em .. · ID .." vivia dentro do `subtitle`
// de um `ListTile`, competindo por espaço horizontal com o `leading`
// (avatar) e o `trailing` (dois IconButtons) — em telas estreitas ou
// com nome/e-mail longos, isso não cabia e o Flutter jogava o erro de
// overflow (listras amarelas/pretas, "RenderFlex overflowed"). Aqui,
// nome e e-mail usam `Expanded` + reticências, os metadados ficam num
// `Wrap` (que quebra linha em vez de estourar) e as ações viraram
// botões de largura total abaixo do conteúdo, sem disputar espaço com
// mais nada.
class _CartaoUsuario extends StatelessWidget {
  const _CartaoUsuario({
    required this.usuario,
    required this.onEditar,
    required this.onExcluir,
  });

  final Map<String, dynamic> usuario;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final nome = usuario['nome'] as String;
    final email = usuario['email'] as String;
    final fotoPath = usuario['foto_path'] as String?;

    final temFoto =
        fotoPath != null && fotoPath.isNotEmpty && File(fotoPath).existsSync();

    final iniciais = nome
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final criadoEm = DateTime.tryParse(usuario['criado_em'] as String? ?? '');
    final dataFormatada = criadoEm != null
        ? '${criadoEm.day.toString().padLeft(2, '0')}/'
            '${criadoEm.month.toString().padLeft(2, '0')}/'
            '${criadoEm.year}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8DCD4),
                backgroundImage: temFoto ? FileImage(File(fotoPath)) : null,
                child: temFoto
                    ? null
                    : Text(
                        iniciais,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8D6E63),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF40352F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF80675C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 11, color: Color(0xFFB09080)),
                  const SizedBox(width: 4),
                  Text(
                    'Cadastrado em $dataFormatada',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB09080),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DFDA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ID ${usuario['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8D6E63),
                    side: const BorderSide(color: Color(0xFFD9CCC3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExcluir,
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    side: const BorderSide(color: Color(0xFFF1D0CC)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
