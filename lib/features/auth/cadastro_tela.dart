import 'package:flutter/material.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/services/admin_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool aceitarTermos = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    final formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) return;

    if (!aceitarTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final nome = _nomeController.text.trim();
      final email = _emailController.text.trim();

      // Salva no SQLite
      final usuarioId = await DatabaseService.instance.criarUsuario(
        nome: nome,
        email: email,
        senha: _senhaController.text,
      );

      // Mantém SharedPreferences para exibição em outras telas
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomeUsuario', nome);
      await prefs.setString('emailUsuario', email);
      await prefs.setInt('usuarioId', usuarioId);

      // Conta nova ainda não tem foto — remove qualquer valor deixado
      // por uma conta anterior usada neste aparelho.
      await prefs.remove('fotoPerfil');

      // Mesma checagem feita no login, para liberar "Gerenciar
      // Usuários" no menu lateral quando o e-mail cadastrado for um
      // dos administradores (ver AdminService).
      await AdminService.salvarStatusAdmin(email);

      // Garante que a lista em memória comece vazia para esta conta
      // nova, sem herdar o histórico de quem usou o app antes no
      // mesmo aparelho.
      await carregarHistorico();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/inicial');
    } on DatabaseException catch (e) {
      setState(() => _enviando = false);
      if (!mounted) return;
      final msg = e.isUniqueConstraintError()
          ? 'Este e-mail já está cadastrado.'
          : 'Erro ao criar conta. Tente novamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      setState(() => _enviando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro inesperado. Tente novamente.'),
          backgroundColor: Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3DDD6),
      body: Stack(
        children: [
          // Imagem topo
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Image.asset(
              'assets/img/1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Botão voltar
          SafeArea(
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Card principal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(
                28,
                32,
                28,
                20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Título
                      const Text(
                        "Cadastre-se",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F4039),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Crie sua conta e comece sua jornada",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF7A6C65),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Nome
                      TextFormField(
                        controller: _nomeController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return 'Informe seu nome completo';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Nome completo",
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF8D6E63),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF8D6E63),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Informe um e-mail válido';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "E-mail",
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF8D6E63),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF8D6E63),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Senha
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').length < 8) {
                            return 'Use pelo menos 8 caracteres';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Senha",
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF8D6E63),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8D6E63),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF8D6E63),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirmar senha
                      TextFormField(
                        controller: _confirmarSenhaController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _criarConta(),
                        validator: (value) {
                          if (value != _senhaController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Confirmar senha",
                          prefixIcon: const Icon(
                            Icons.lock_reset_outlined,
                            color: Color(0xFF8D6E63),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8D6E63),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF8D6E63),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Termos de uso
                      CheckboxListTile(
                        value: aceitarTermos,
                        activeColor: const Color(0xFF8D6E63),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          "Aceito os Termos de Uso e Política de Privacidade",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            aceitarTermos = value ?? false;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      // Botão criar conta
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _enviando ? null : _criarConta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D6E63),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _enviando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Criar Conta",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Link Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Já possui uma conta?",
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Entrar",
                              style: TextStyle(
                                color: Color(0xFF8D6E63),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
