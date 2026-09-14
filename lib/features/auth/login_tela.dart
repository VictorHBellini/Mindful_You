import 'package:flutter/material.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/services/admin_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/widgets/recuperar_senha_tela.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _obscurePassword = true;
  bool _carregando = false;
  String? _erroCred;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _carregando = true;
      _erroCred = null;
    });

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final usuario = await DatabaseService.instance.buscarPorEmail(email);

    if (!mounted) return;

    if (usuario == null) {
      setState(() {
        _carregando = false;
        _erroCred = 'E-mail ou senha incorretos.';
      });
      return;
    }

    final senhaValida = await DatabaseService.instance.senhaCorreta(
      usuario: usuario,
      senhaDigitada: senha,
    );

    if (!mounted) return;

    if (!senhaValida) {
      setState(() {
        _carregando = false;
        _erroCred = 'E-mail ou senha incorretos.';
      });
      return;
    }

    // Atualiza SharedPreferences com dados do usuário logado
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeUsuario', usuario['nome'] as String);
    await prefs.setString('emailUsuario', usuario['email'] as String);
    await prefs.setInt('usuarioId', usuario['id'] as int);

    // BUG CORRIGIDO: a foto de perfil era lida de uma chave global
    // ('fotoPerfil') que não era atualizada no login — então, se a
    // conta anterior usada no aparelho tivesse foto salva, ela
    // continuava aparecendo para quem loga em seguida, mesmo sem ter
    // escolhido nenhuma foto. Agora sincronizamos com o que está
    // salvo no SQLite para este usuário (ou removemos a chave, se ele
    // não tiver foto).
    final fotoPath = usuario['foto_path'] as String?;
    if (fotoPath != null && fotoPath.isNotEmpty) {
      await prefs.setString('fotoPerfil', fotoPath);
    } else {
      await prefs.remove('fotoPerfil');
    }

    // Marca localmente se este login pertence a um administrador
    // (lista de e-mails em AdminService), para liberar o item
    // "Gerenciar Usuários" no menu lateral.
    await AdminService.salvarStatusAdmin(usuario['email'] as String);

    // Carrega o histórico de check-ins deste usuário para a lista em
    // memória, para não misturar com o de outra conta usada antes no
    // mesmo aparelho.
    await carregarHistorico();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/inicial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFE3DDD6),
      body: Stack(
        children: [
          // Imagem superior
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Image.asset(
              'assets/img/Login.png',
              fit: BoxFit.cover,
            ),
          ),

          // Card Principal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.68,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
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
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              "Bem-vindo",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F4039),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Faça login para continuar!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF7A6C65),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 70),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }

                          final emailRegex = RegExp(
                            r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(
                            value.trim(),
                          )) {
                            return 'E-mail inválido';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "E-mail",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF8D6E63),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
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

                      const SizedBox(height: 18),

                      // Senha
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua senha';
                          }

                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Senha",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                          ),
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
                          filled: true,
                          fillColor: const Color(0xFFF7F5F3),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
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

                      const SizedBox(height: 12),

                      // Esqueceu senha
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecuperarSenhaTela(),
                              ),
                            );
                          },
                          child: const Text(
                            "Esqueceu sua senha?",
                            style: TextStyle(
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ),
                      ),

                      // Mensagem de erro de credenciais
                      if (_erroCred != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFC0392B)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFC0392B), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _erroCred!,
                                    style: const TextStyle(
                                      color: Color(0xFFC0392B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Botão Entrar
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _entrar,
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
                                  "Entrar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cadastro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Não possui uma conta?",
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/cadastro',
                              );
                            },
                            child: const Text(
                              "Cadastrar",
                              style: TextStyle(
                                color: Color(0xFF8D6E63),
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}
