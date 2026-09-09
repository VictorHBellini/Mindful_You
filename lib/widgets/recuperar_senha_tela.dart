import 'package:flutter/material.dart';
import 'package:mindful_you/services/database_service.dart';

/// Tela de recuperação de senha.
///
/// Como o app funciona 100% localmente (sem backend/e-mail), o fluxo é:
/// 1. Usuário informa o e-mail cadastrado.
/// 2. Se o e-mail existir no banco local, libera os campos para definir
///    uma nova senha diretamente (não há como enviar link/código por
///    e-mail sem um servidor).
///
/// Quando a autenticação online for conectada (ver comentário na tela de
/// login), este fluxo pode ser trocado por um de verdade (envio de
/// e-mail/OTP).
class RecuperarSenhaTela extends StatefulWidget {
  const RecuperarSenhaTela({super.key});

  @override
  State<RecuperarSenhaTela> createState() => _RecuperarSenhaTelaState();
}

class _RecuperarSenhaTelaState extends State<RecuperarSenhaTela> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeySenha = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _carregando = false;
  String? _erro;

  // Etapa 0 = informar e-mail; etapa 1 = definir nova senha.
  int _etapa = 0;
  Map<String, dynamic>? _usuarioEncontrado;

  @override
  void dispose() {
    _emailController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _verificarEmail() async {
    if (!(_formKeyEmail.currentState?.validate() ?? false)) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final email = _emailController.text.trim();
    final usuario = await DatabaseService.instance.buscarPorEmail(email);

    if (!mounted) return;

    if (usuario == null) {
      setState(() {
        _carregando = false;
        _erro = 'Não encontramos nenhuma conta com esse e-mail.';
      });
      return;
    }

    setState(() {
      _carregando = false;
      _usuarioEncontrado = usuario;
      _etapa = 1;
    });
  }

  Future<void> _redefinirSenha() async {
    if (!(_formKeySenha.currentState?.validate() ?? false)) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final id = _usuarioEncontrado!['id'] as int;

    await DatabaseService.instance.atualizarSenha(
      id: id,
      novaSenha: _novaSenhaController.text,
    );

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida com sucesso! Faça login novamente.'),
      ),
    );

    Navigator.pop(context);
  }

  InputDecoration _decoracaoCampo({
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icone, color: const Color(0xFF8D6E63)),
      suffixIcon: sufixo,
      filled: true,
      fillColor: const Color(0xFFF7F5F3),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 1.5),
      ),
    );
  }

  Widget _etapaEmail() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Esqueceu sua senha?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4039),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Informe o e-mail cadastrado para redefinir sua senha.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF7A6C65)),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'E-mail inválido';
              }
              return null;
            },
            decoration: _decoracaoCampo(hint: "E-mail", icone: Icons.email_outlined),
          ),
          const SizedBox(height: 20),
          if (_erro != null) _avisoErro(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _carregando ? null : _verificarEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Continuar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etapaNovaSenha() {
    return Form(
      key: _formKeySenha,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Nova senha",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4039),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Definindo uma nova senha para ${_usuarioEncontrado?['email']}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF7A6C65)),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _novaSenhaController,
            obscureText: _obscureNovaSenha,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe a nova senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
            decoration: _decoracaoCampo(
              hint: "Nova senha",
              icone: Icons.lock_outline,
              sufixo: IconButton(
                icon: Icon(
                  _obscureNovaSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8D6E63),
                ),
                onPressed: () {
                  setState(() => _obscureNovaSenha = !_obscureNovaSenha);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: _obscureConfirmarSenha,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme a nova senha';
              }
              if (value != _novaSenhaController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
            decoration: _decoracaoCampo(
              hint: "Confirmar nova senha",
              icone: Icons.lock_outline,
              sufixo: IconButton(
                icon: Icon(
                  _obscureConfirmarSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8D6E63),
                ),
                onPressed: () {
                  setState(
                      () => _obscureConfirmarSenha = !_obscureConfirmarSenha);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_erro != null) _avisoErro(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _carregando ? null : _redefinirSenha,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Redefinir senha",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _carregando
                ? null
                : () {
                    setState(() {
                      _etapa = 0;
                      _erro = null;
                      _usuarioEncontrado = null;
                    });
                  },
            child: const Text(
              "Usar outro e-mail",
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoErro() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC0392B), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _erro!,
                style: const TextStyle(color: Color(0xFFC0392B), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3DDD6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4F4039)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _etapa == 0 ? _etapaEmail() : _etapaNovaSenha(),
          ),
        ),
      ),
    );
  }
}
