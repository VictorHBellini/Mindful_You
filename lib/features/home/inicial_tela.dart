import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/core/widgets/menu_lateral_widget.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';

class InicialTela extends StatefulWidget {
  const InicialTela({super.key});

  @override
  State<InicialTela> createState() => _InicialTelaState();
}

class _InicialTelaState extends State<InicialTela> {
  // Paleta local da tela Inicial. Mantém os valores do tema claro.
  // Os tons escuros são aplicados apenas quando o tema está ativo.
  Color _cor(BuildContext context, int valor) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return Color(valor);
    }
    const tonsEscuros = <int, int>{
      0xFF40352F: 0xFFF1E8E4,
      0xFF4F4039: 0xFFF1E8E4,
      0xFF62554E: 0xFFE0CFCA,
      0xFF665B55: 0xFFE0CFCA,
      0xFF75665E: 0xFFE0CFCA,
      0xFF796B63: 0xFFD3C0BB,
      0xFF80675C: 0xFFE0B6B3,
      0xFF8A7B73: 0xFFC9B7B2,
      0xFF8D6E63: 0xFFD9ABA9,
      0xFF95877F: 0xFFC9B7B2,
      0xFFB0A29A: 0xFFB9A4A0,
      0xFFD8C8BE: 0xFF685656,
      0xFFE6D5C8: 0xFF302626,
      0xFFE8D5CA: 0xFF382C2C,
      0xFFE8DFDA: 0xFF685656,
      0xFFF0E2DA: 0xFF2B2323,
      0xFFF3ECE8: 0xFF382C2C,
      0xFFF8F5F2: 0xFF151313,
      0xFFFFFFFF: 0xFF241F1F,
    };
    return Color(tonsEscuros[valor] ?? valor);
  }

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

    // BUG CORRIGIDO: "último sentimento/emoji/data" vinham de chaves
    // globais do SharedPreferences (as mesmas para qualquer conta do
    // aparelho), então quem logasse via o último check-in de outra
    // pessoa. Agora eles são derivados do histórico do usuário
    // atualmente logado (tabela `checkins`, via `historico_global.dart`).
    await carregarHistorico();

    if (!mounted) return;

    final ultimo = historicoGlobal.isNotEmpty ? historicoGlobal.last : null;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? "Usuário";

      ultimoSentimento = (ultimo?['sentimento'] as String?)?.isNotEmpty == true
          ? ultimo!['sentimento'] as String
          : "Nenhum";

      ultimoEmoji = (ultimo?['emoji'] as String?) ?? "🙂";

      ultimaData = (ultimo?['data'] as String?) ?? "Ainda não realizado";
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/questionario'),
        icon: Icon(Icons.edit_note_rounded),
        label: Text('Fazer check-in'),
        tooltip: 'Iniciar check-in emocional',
      ),
      drawer: MenuLateral(),
      backgroundColor: _cor(context, 0xFFF8F5F2),
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
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
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
                              color: _cor(context, 0xFFFFFFFF),
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
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.menu_rounded,
                                    size: 27,
                                    color: _cor(context, 0xFF75665E),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // TÍTULO
                        Column(
                          children: [
                            Text(
                              "Mindful You",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _cor(context, 0xFF4F4039),
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
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _cor(context, 0xFFD8C8BE),
                                width: 2,
                              ),
                            ),
                            child: AvatarPerfil(
                              radius: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 28),

                    // ==================================================
                    // SAUDAÇÃO
                    // ==================================================

                    Text(
                      "${obterSaudacao()}, $nomeUsuario 👋",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _cor(context, 0xFF40352F),
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Que bom ter você por aqui.",
                      style: TextStyle(
                        fontSize: 15,
                        color: _cor(context, 0xFF8A7B73),
                      ),
                    ),

                    SizedBox(height: 25),

                    // ==================================================
                    // CARD DE CHECK-IN
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _cor(context, 0xFFE8D5CA),
                            _cor(context, 0xFFF0E2DA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: Offset(0, 7),
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
                                  color: _cor(context, 0xFFFFFFFF).withValues(
                                    alpha: 0.65,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.favorite_outline,
                                  color: _cor(context, 0xFF80675C),
                                  size: 25,
                                ),
                              ),
                              SizedBox(
                                width: 13,
                              ),
                              Expanded(
                                child: Text(
                                  "Seu momento de hoje",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _cor(context, 0xFF4F4039),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 18,
                          ),
                          Text(
                            "Como você está se sentindo?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _cor(context, 0xFF40352F),
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            "Escolha uma opção que representa melhor o seu momento.",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: _cor(context, 0xFF796B63),
                            ),
                          ),
                          SizedBox(height: 20),
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

                    SizedBox(height: 28),

                    // ==================================================
                    // ÚLTIMO CHECK-IN
                    // ==================================================

                    Text(
                      "Seu último check-in",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: _cor(context, 0xFF40352F),
                      ),
                    ),

                    SizedBox(height: 13),

                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: ultimoSentimento == "Nenhum"
                          ? null
                          : () => Navigator.pushNamed(context, '/historico'),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cor(context, 0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _cor(context, 0xFFE8DFDA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: _cor(context, 0xFFF3ECE8),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  ultimoEmoji,
                                  style: TextStyle(
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ultimoSentimento == "Nenhum"
                                        ? "Ainda não realizado"
                                        : "Você se sentiu $ultimoSentimento",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _cor(context, 0xFF4F4039),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    ultimaData,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _cor(context, 0xFF95877F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ultimoSentimento != "Nenhum")
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: _cor(context, 0xFFB0A29A),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 28),

                    // ==================================================
                    // SUGESTÃO
                    // ==================================================

                    Text(
                      "Sugestão para você 🌱",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: _cor(context, 0xFF40352F),
                      ),
                    ),

                    SizedBox(height: 13),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cor(context, 0xFFE6D5C8),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: _cor(context, 0xFFFFFFFF).withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: Icon(
                              Icons.spa_outlined,
                              color: _cor(context, 0xFF80675C),
                              size: 25,
                            ),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sugestao["titulo"]!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _cor(context, 0xFF4F4039),
                                  ),
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  sugestao["descricao"]!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: _cor(context, 0xFF665B55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28),

                    // ==================================================
                    // ACESSO RÁPIDO
                    // ==================================================

                    Text(
                      "Acesso rápido",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: _cor(context, 0xFF40352F),
                      ),
                    ),

                    SizedBox(height: 13),

                    Row(
                      children: [
                        acessoRapido(
                          context,
                          Icons.edit_note_rounded,
                          "Check-in",
                          '/questionario',
                        ),
                        SizedBox(width: 10),
                        acessoRapido(
                          context,
                          Icons.bar_chart_rounded,
                          "Histórico",
                          '/historico',
                        ),
                        SizedBox(width: 10),
                        acessoRapido(
                          context,
                          Icons.lightbulb_outline_rounded,
                          "Dicas",
                          '/dicas',
                        ),
                      ],
                    ),

                    SizedBox(height: 18),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.assignment_outlined),
                        title: Text('Avaliações de rastreio'),
                        subtitle: Text('Módulo em preparação para o TCC'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/avaliacoes'),
                      ),
                    ),
                    SizedBox(height: 30),
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
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _cor(context, 0xFFFFFFFF).withValues(alpha: 0.65),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              path,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 7),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cor(context, 0xFF62554E),
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
          style: TextStyle(
            fontSize: 24,
          ),
        ),
        SizedBox(height: 5),
        Text(
          "$quantidade",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _cor(context, 0xFF4F4039),
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 10,
            color: _cor(context, 0xFF95877F),
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
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: _cor(context, 0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _cor(context, 0xFFE8DFDA),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: _cor(context, 0xFF8D6E63),
                size: 27,
              ),
              SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _cor(context, 0xFF62554E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
