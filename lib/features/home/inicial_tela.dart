import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/widgets/menu_lateral_tela.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';

class InicialTela extends StatefulWidget {
  const InicialTela({super.key});

  @override
  State<InicialTela> createState() => _InicialTelaState();
}

class _InicialTelaState extends State<InicialTela> {
  String nomeUsuario = "Usuário";
  String ultimoSentimento = "Nenhum";
  String ultimoEmoji = "🙂";
  String ultimaData = "Ainda não realizado";

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  // ================================================================
  // CARREGAR DADOS
  // ================================================================

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? "Usuário";

      ultimoSentimento = prefs.getString('ultimoSentimento') ?? "Nenhum";

      ultimoEmoji = prefs.getString('ultimoEmoji') ?? "🙂";

      ultimaData = prefs.getString('ultimaData') ?? "Ainda não realizado";
    });
  }

  // ================================================================
  // SAUDAÇÃO
  // ================================================================

  String obterSaudacao() {
    final hora = DateTime.now().hour;

    if (hora < 12) {
      return "Bom dia";
    } else if (hora < 18) {
      return "Boa tarde";
    } else {
      return "Boa noite";
    }
  }

  // ================================================================
  // SUGESTÃO PERSONALIZADA
  // ================================================================

  Map<String, String> obterSugestao() {
    switch (ultimoSentimento.toLowerCase()) {
      case "feliz":
        return {
          "titulo": "Aproveite esse momento ☀️",
          "descricao":
              "Tente registrar o que tornou seu dia especial. Pequenos momentos também merecem ser lembrados.",
        };

      case "calmo":
        return {
          "titulo": "Continue nesse ritmo 🌿",
          "descricao":
              "Aproveite essa sensação de tranquilidade. Respire profundamente e permita-se aproveitar o momento.",
        };

      case "neutro":
        return {
          "titulo": "Observe como você está 🧠",
          "descricao":
              "Talvez alguns minutos de reflexão possam ajudar você a entender melhor como está se sentindo.",
        };

      case "cansado":
        return {
          "titulo": "Que tal fazer uma pausa? 🌙",
          "descricao":
              "Reserve alguns minutos para descansar, respirar e se afastar um pouco das telas.",
        };

      default:
        return {
          "titulo": "Cuide de você 🌱",
          "descricao":
              "Reserve alguns minutos do seu dia para refletir sobre seus pensamentos e emoções.",
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugestao = obterSugestao();

    return Scaffold(
      drawer: const MenuLateral(),
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Stack(
          children: [
            // ========================================================
            // DECORAÇÃO DE FUNDO
            // ========================================================

            Positioned(
              top: -100,
              right: -100,
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  'assets/img/6.png',
                  width: 340,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ========================================================
            // CONTEÚDO
            // ========================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TOPO
                    // ==================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // MENU
                        Builder(
                          builder: (context) {
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  14,
                                ),
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.menu_rounded,
                                    size: 27,
                                    color: Color(0xFF75665E),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // TÍTULO
                        const Column(
                          children: [
                            Text(
                              "Mindful You",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F4039),
                              ),
                            ),
                          ],
                        ),

                        // PERFIL
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/perfil',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFFD8C8BE,
                                ),
                                width: 2,
                              ),
                            ),
                            child: const AvatarPerfil(
                              radius: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SAUDAÇÃO
                    // ==================================================

                    Text(
                      "${obterSaudacao()}, $nomeUsuario 👋",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Que bom ter você por aqui.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8A7B73),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // CARD DE CHECK-IN
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE8D5CA),
                            Color(0xFFF0E2DA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.65,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.favorite_outline,
                                  color: Color(0xFF80675C),
                                  size: 25,
                                ),
                              ),
                              const SizedBox(
                                width: 13,
                              ),
                              const Expanded(
                                child: Text(
                                  "Seu momento de hoje",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F4039),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 18,
                          ),
                          const Text(
                            "Como você está se sentindo?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF40352F),
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            "Escolha uma opção que representa melhor o seu momento.",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF796B63),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              emoji(
                                context,
                                'assets/img/7.png',
                                'Feliz',
                              ),
                              emoji(
                                context,
                                'assets/img/8.png',
                                'Calmo',
                              ),
                              emoji(
                                context,
                                'assets/img/9.png',
                                'Neutro',
                              ),
                              emoji(
                                context,
                                'assets/img/10.png',
                                'Cansado',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // ÚLTIMO CHECK-IN
                    // ==================================================

                    const Text(
                      "Seu último check-in",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFFE8DFDA,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF3ECE8,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                ultimoEmoji,
                                style: const TextStyle(
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ultimoSentimento == "Nenhum"
                                      ? "Ainda não realizado"
                                      : "Você se sentiu $ultimoSentimento",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                      0xFF4F4039,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  ultimaData,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(
                                      0xFF95877F,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFB0A29A),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SUGESTÃO
                    // ==================================================

                    const Text(
                      "Sugestão para você 🌱",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6D5C8),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: const Icon(
                              Icons.spa_outlined,
                              color: Color(0xFF80675C),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sugestao["titulo"]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                      0xFF4F4039,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  sugestao["descricao"]!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(
                                      0xFF665B55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // ACESSO RÁPIDO
                    // ==================================================

                    const Text(
                      "Acesso rápido",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        acessoRapido(
                          context,
                          Icons.edit_note_rounded,
                          "Check-in",
                          '/questionario',
                        ),
                        const SizedBox(width: 10),
                        acessoRapido(
                          context,
                          Icons.bar_chart_rounded,
                          "Histórico",
                          '/historico',
                        ),
                        const SizedBox(width: 10),
                        acessoRapido(
                          context,
                          Icons.lightbulb_outline_rounded,
                          "Dicas",
                          '/dicas',
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMOJI
  // ================================================================

  Widget emoji(
    BuildContext context,
    String path,
    String texto,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/questionario',
          arguments: texto,
        );
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              path,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF62554E),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RESUMO DE HUMOR
  // ================================================================

  Widget resumoHumor(
    String emoji,
    int quantidade,
    String titulo,
  ) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "$quantidade",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F4039),
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF95877F),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ACESSO RÁPIDO
  // ================================================================

  Widget acessoRapido(
    BuildContext context,
    IconData icon,
    String titulo,
    String rota,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            rota,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8DFDA),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8D6E63),
                size: 27,
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF62554E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
